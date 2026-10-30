-- ====================================================================
-- Duo Migration 03: Atomic RPC Functions & Realtime Publication
-- Version: 1.0
-- Target: PostgreSQL / Supabase
-- ====================================================================

-- 1. Create Duo Space (Atomic Transaction)
CREATE OR REPLACE FUNCTION public.create_duo_space(p_name TEXT DEFAULT NULL)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_duo_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
  END IF;

  -- Ensure user is not currently in an active Duo
  IF EXISTS (SELECT 1 FROM duo_members WHERE user_id = v_user_id AND status = 'active') THEN
    RETURN jsonb_build_object('success', false, 'error', 'ALREADY_PAIRED');
  END IF;

  -- Create Space
  INSERT INTO duo_spaces (name, status, created_by)
  VALUES (p_name, 'pending', v_user_id)
  RETURNING id INTO v_duo_id;

  -- Add Creator as Owner Member
  INSERT INTO duo_members (duo_id, user_id, role, status)
  VALUES (v_duo_id, v_user_id, 'owner', 'active');

  RETURN jsonb_build_object('success', true, 'duo_id', v_duo_id);
END;
$$;

-- 2. Create Partner Invitation Code
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

  -- Revoke any previous pending invitations for this space
  UPDATE duo_invitations
  SET status = 'revoked'
  WHERE duo_id = p_duo_id AND status = 'pending';

  -- Generate readable 8-character code: DUO-XXXX
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

-- 3. Accept Partner Invitation (Atomic Concurrency Protection)
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

  -- 1. Check if user is already actively paired
  IF EXISTS (SELECT 1 FROM duo_members WHERE user_id = v_user_id AND status = 'active') THEN
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

  -- 4. Add member
  INSERT INTO duo_members (duo_id, user_id, role, status)
  VALUES (v_invite.duo_id, v_user_id, 'member', 'active');

  -- 5. Mark invitation accepted
  UPDATE duo_invitations
  SET status = 'accepted', accepted_by = v_user_id, accepted_at = now()
  WHERE id = v_invite.id;

  -- 6. Mark duo_space active
  UPDATE duo_spaces
  SET status = 'active'
  WHERE id = v_invite.duo_id;

  -- 7. Send pairing celebration notification
  INSERT INTO notifications (user_id, duo_id, type, payload)
  VALUES 
    (v_invite.created_by, v_invite.duo_id, 'paired', jsonb_build_object('message', 'Your partner has joined your Duo! 💗')),
    (v_user_id, v_invite.duo_id, 'paired', jsonb_build_object('message', 'Connected to your Duo space! ✨'));

  RETURN jsonb_build_object('success', true, 'duo_id', v_invite.duo_id);
END;
$$;

-- 4. Disconnect Duo Space (Unpair)
CREATE OR REPLACE FUNCTION public.disconnect_duo(p_duo_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
  END IF;

  -- Verify active member
  IF NOT EXISTS (SELECT 1 FROM duo_members WHERE duo_id = p_duo_id AND user_id = v_user_id AND status = 'active') THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_A_MEMBER');
  END IF;

  -- Mark space disconnected
  UPDATE duo_spaces
  SET status = 'disconnected', disconnected_at = now()
  WHERE id = p_duo_id;

  -- Revoke active memberships
  UPDATE duo_members
  SET status = 'removed'
  WHERE duo_id = p_duo_id;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 5. Submit TwoTruths Personal Answer
CREATE OR REPLACE FUNCTION public.submit_question_answer(
  p_session_id UUID,
  p_answer TEXT
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_session RECORD;
  v_answer_id UUID;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
  END IF;

  SELECT * INTO v_session FROM question_sessions WHERE id = p_session_id;
  IF NOT FOUND OR NOT is_duo_member(v_session.duo_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'SESSION_NOT_FOUND');
  END IF;

  INSERT INTO question_answers (session_id, user_id, answer)
  VALUES (p_session_id, v_user_id, p_answer)
  ON CONFLICT (session_id, user_id) 
  DO UPDATE SET answer = p_answer
  RETURNING id INTO v_answer_id;

  RETURN jsonb_build_object('success', true, 'answer_id', v_answer_id);
END;
$$;

-- 6. Submit Guess For Partner's Answer & Check Match
CREATE OR REPLACE FUNCTION public.submit_partner_guess(
  p_session_id UUID,
  p_guess TEXT
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_session RECORD;
  v_partner_answer RECORD;
  v_is_correct BOOLEAN := false;
  v_answers_count INT;
  v_guesses_count INT;
BEGIN
  IF v_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'UNAUTHORIZED');
  END IF;

  SELECT * INTO v_session FROM question_sessions WHERE id = p_session_id;
  IF NOT FOUND OR NOT is_duo_member(v_session.duo_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'SESSION_NOT_FOUND');
  END IF;

  -- Look up partner's answer to evaluate guess
  SELECT * INTO v_partner_answer
  FROM question_answers
  WHERE session_id = p_session_id AND user_id != v_user_id;

  IF FOUND AND trim(lower(v_partner_answer.answer)) = trim(lower(p_guess)) THEN
    v_is_correct := true;
  END IF;

  -- Update user's guess
  UPDATE question_answers
  SET guessed_answer = p_guess, is_guess_correct = v_is_correct
  WHERE session_id = p_session_id AND user_id = v_user_id;

  -- Check if both answered and both guessed
  SELECT count(*) INTO v_answers_count FROM question_answers WHERE session_id = p_session_id;
  SELECT count(*) INTO v_guesses_count FROM question_answers WHERE session_id = p_session_id AND guessed_answer IS NOT NULL;

  IF v_answers_count = 2 AND v_guesses_count = 2 THEN
    UPDATE question_sessions SET status = 'completed' WHERE id = p_session_id;
  END IF;

  RETURN jsonb_build_object('success', true, 'is_correct', v_is_correct);
END;
$$;

-- 7. Mark Secret Note Opened
CREATE OR REPLACE FUNCTION public.mark_note_opened(p_note_id UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_note RECORD;
BEGIN
  SELECT * INTO v_note FROM notes WHERE id = p_note_id;
  IF NOT FOUND OR NOT is_duo_member(v_note.duo_id) THEN
    RETURN jsonb_build_object('success', false, 'error', 'NOT_FOUND');
  END IF;

  -- Only mark opened if current user is not the sender
  IF v_note.sender_id != v_user_id AND v_note.opened_at IS NULL THEN
    UPDATE notes SET opened_at = now() WHERE id = p_note_id;
  END IF;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 8. Add Tables to Supabase Realtime Publication
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE mood_checkins;
    ALTER PUBLICATION supabase_realtime ADD TABLE question_answers;
    ALTER PUBLICATION supabase_realtime ADD TABLE notes;
    ALTER PUBLICATION supabase_realtime ADD TABLE game_sessions;
    ALTER PUBLICATION supabase_realtime ADD TABLE bucket_items;
    ALTER PUBLICATION supabase_realtime ADD TABLE duo_spaces;
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Handle gracefully if table is already in publication
  NULL;
END $$;
