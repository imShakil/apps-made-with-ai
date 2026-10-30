-- ====================================================================
-- Duo Migration 04: Fix Pairing RPCs (Idempotent Pending Spaces & Concurrency)
-- ====================================================================

-- 1. Create or Reuse Pending Duo Space
CREATE OR REPLACE FUNCTION public.create_duo_space(p_name TEXT DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_existing_active_id UUID;
  v_existing_pending_id UUID;
  v_duo_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
  END IF;

  -- Check if user is already actively paired in a 2-person space
  SELECT ds.id INTO v_existing_active_id
  FROM duo_members dm
  JOIN duo_spaces ds ON ds.id = dm.duo_id
  WHERE dm.user_id = v_user_id AND dm.status = 'active' AND ds.status = 'active'
  LIMIT 1;

  IF v_existing_active_id IS NOT NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'ALREADY_PAIRED', 'duo_id', v_existing_active_id);
  END IF;

  -- If user already has an uncompleted pending space, reuse it!
  SELECT ds.id INTO v_existing_pending_id
  FROM duo_members dm
  JOIN duo_spaces ds ON ds.id = dm.duo_id
  WHERE dm.user_id = v_user_id AND dm.status = 'active' AND ds.status = 'pending'
  LIMIT 1;

  IF v_existing_pending_id IS NOT NULL THEN
    RETURN jsonb_build_object('success', true, 'duo_id', v_existing_pending_id);
  END IF;

  -- Otherwise create new pending space
  INSERT INTO duo_spaces (name, status, created_by)
  VALUES (p_name, 'pending', v_user_id)
  RETURNING id INTO v_duo_id;

  -- Add Creator as Owner Member
  INSERT INTO duo_members (duo_id, user_id, role, status)
  VALUES (v_duo_id, v_user_id, 'owner', 'active')
  ON CONFLICT (duo_id, user_id) DO NOTHING;

  RETURN jsonb_build_object('success', true, 'duo_id', v_duo_id);
END;
$$;

-- 2. Create or Retrieve Active Invitation Code
CREATE OR REPLACE FUNCTION public.create_invitation(
  p_duo_id UUID,
  p_expires_hours INT DEFAULT 48
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_code TEXT;
  v_token_hash TEXT;
  v_expires_at TIMESTAMPTZ := now() + (p_expires_hours || ' hours')::interval;
  v_invite_id UUID;
  v_member_count INT;
  v_existing_code TEXT;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
  END IF;

  -- Verify caller is active member of this Duo
  IF NOT EXISTS (SELECT 1 FROM duo_members WHERE duo_id = p_duo_id AND user_id = v_user_id AND status = 'active') THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_A_MEMBER');
  END IF;

  -- Verify active member count < 2
  SELECT count(*) INTO v_member_count FROM duo_members WHERE duo_id = p_duo_id AND status = 'active';
  IF v_member_count >= 2 THEN
    RETURN jsonb_build_object('success', false, 'error', 'DUO_FULL');
  END IF;

  -- Check if there's already an active unexpired invitation for this space
  SELECT invite_code INTO v_existing_code
  FROM duo_invitations
  WHERE duo_id = p_duo_id AND status = 'pending' AND expires_at > now()
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_existing_code IS NOT NULL THEN
    RETURN jsonb_build_object(
      'success', true,
      'invite_code', v_existing_code,
      'duo_id', p_duo_id
    );
  END IF;

  -- Revoke any stale expired invitations
  UPDATE duo_invitations
  SET status = 'revoked'
  WHERE duo_id = p_duo_id AND status = 'pending';

  -- Generate readable 8-character code: DUO-XXXXX
  v_code := 'DUO' || upper(substring(md5(random()::text) from 1 for 5));
  v_token_hash := encode(sha256(v_code::bytea), 'hex');

  INSERT INTO duo_invitations (duo_id, invite_code, token_hash, created_by, expires_at, status)
  VALUES (p_duo_id, v_code, v_token_hash, v_user_id, v_expires_at, 'pending')
  RETURNING id INTO v_invite_id;

  RETURN jsonb_build_object(
    'success', true,
    'invitation_id', v_invite_id,
    'invite_code', v_code,
    'expires_at', v_expires_at
  );
END;
$$;

-- 3. Accept Partner Invitation (Enhanced to Clean Up Pending Solo Spaces)
CREATE OR REPLACE FUNCTION public.accept_invitation(p_invite_code TEXT)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_clean_code TEXT := upper(trim(p_invite_code));
  v_token_hash TEXT;
  v_invite RECORD;
  v_member_count INT;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
  END IF;

  -- 1. Check if user is already actively paired in an active 2-person space
  IF EXISTS (
    SELECT 1 
    FROM duo_members dm
    JOIN duo_spaces ds ON ds.id = dm.duo_id
    WHERE dm.user_id = v_user_id 
      AND dm.status = 'active'
      AND ds.status = 'active'
  ) THEN
    RETURN jsonb_build_object('success', false, 'error', 'ALREADY_PAIRED');
  END IF;

  v_token_hash := encode(sha256(v_clean_code::bytea), 'hex');

  -- 2. Lock invitation row
  SELECT * INTO v_invite
  FROM duo_invitations
  WHERE (token_hash = v_token_hash OR invite_code = v_clean_code)
    AND status = 'pending'
    AND expires_at > now()
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'INVALID_OR_EXPIRED_INVITE');
  END IF;

  -- Cannot accept own invite
  IF v_invite.created_by = v_user_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'CANNOT_PAIR_WITH_SELF');
  END IF;

  -- 3. Lock duo space and verify active member count < 2
  PERFORM 1 FROM duo_spaces WHERE id = v_invite.duo_id FOR UPDATE;

  SELECT count(*) INTO v_member_count
  FROM duo_members
  WHERE duo_id = v_invite.duo_id AND status = 'active';

  IF v_member_count >= 2 THEN
    RETURN jsonb_build_object('success', false, 'error', 'DUO_FULL');
  END IF;

  -- 4. Clean up any lone pending spaces created by this user while they were waiting
  DELETE FROM duo_members
  WHERE user_id = v_user_id
    AND duo_id != v_invite.duo_id
    AND duo_id IN (SELECT id FROM duo_spaces WHERE status = 'pending');

  UPDATE duo_spaces
  SET status = 'archived'
  WHERE created_by = v_user_id
    AND status = 'pending'
    AND id != v_invite.duo_id;

  -- 5. Add user to partner's space
  INSERT INTO duo_members (duo_id, user_id, role, status)
  VALUES (v_invite.duo_id, v_user_id, 'member', 'active')
  ON CONFLICT (duo_id, user_id) 
  DO UPDATE SET status = 'active', role = 'member';

  -- 6. Mark invitation accepted
  UPDATE duo_invitations
  SET status = 'accepted', accepted_by = v_user_id, accepted_at = now()
  WHERE id = v_invite.id;

  -- 7. Mark duo_space active
  UPDATE duo_spaces
  SET status = 'active'
  WHERE id = v_invite.duo_id;

  -- 8. Send pairing celebration notifications
  INSERT INTO notifications (user_id, duo_id, type, payload)
  VALUES 
    (v_invite.created_by, v_invite.duo_id, 'paired', jsonb_build_object('message', 'Your partner has joined your Duo! 💗')),
    (v_user_id, v_invite.duo_id, 'paired', jsonb_build_object('message', 'Connected to your Duo space! ✨'));

  RETURN jsonb_build_object('success', true, 'duo_id', v_invite.duo_id);
END;
$$;
