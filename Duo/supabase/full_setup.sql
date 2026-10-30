-- ====================================================================
-- Duo Migration 01: Core Relational Database Schema
-- Version: 1.0
-- Target: PostgreSQL / Supabase
-- ====================================================================

-- 1. Enable Required Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. User Profiles Table (Mirrors auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_path TEXT,
  language TEXT NOT NULL DEFAULT 'en' CHECK (language IN ('en', 'bn')),
  timezone TEXT NOT NULL DEFAULT 'Asia/Dhaka',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Duo Spaces (Shared Private Sanctum for 2 People)
CREATE TABLE IF NOT EXISTS public.duo_spaces (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'disconnected')),
  created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  disconnected_at TIMESTAMPTZ
);

-- 4. Duo Members (Strict membership records)
CREATE TABLE IF NOT EXISTS public.duo_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  duo_id UUID NOT NULL REFERENCES public.duo_spaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'removed')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_duo_member UNIQUE (duo_id, user_id)
);

-- Enforce: A user can belong to only ONE active Duo at any time
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_single_active_duo 
  ON public.duo_members(user_id) 
  WHERE status = 'active';

-- 5. Duo Invitations (Atomic Pairing Keys)
CREATE TABLE IF NOT EXISTS public.duo_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  duo_id UUID NOT NULL REFERENCES public.duo_spaces(id) ON DELETE CASCADE,
  invite_code TEXT NOT NULL,
  token_hash TEXT NOT NULL,
  created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  expires_at TIMESTAMPTZ NOT NULL,
  accepted_by UUID REFERENCES public.users(id) ON DELETE SET NULL,
  accepted_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired', 'revoked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_invitations_token_hash ON public.duo_invitations(token_hash);
CREATE INDEX IF NOT EXISTS idx_invitations_code ON public.duo_invitations(invite_code);

-- 6. Mood Check-ins (Daily Emotional Pulse)
CREATE TABLE IF NOT EXISTS public.mood_checkins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  duo_id UUID NOT NULL REFERENCES public.duo_spaces(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  mood TEXT NOT NULL CHECK (mood IN ('happy', 'loved', 'tired', 'down', 'excited', 'neutral', 'romantic')),
  message TEXT,
  local_date DATE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_mood_daily_entry UNIQUE (duo_id, user_id, local_date)
);

CREATE INDEX IF NOT EXISTS idx_mood_duo_date ON public.mood_checkins(duo_id, local_date DESC);

-- 7. Daily Questions Pool (Bilingual: English + Bangla)
CREATE TABLE IF NOT EXISTS public.daily_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  text_en TEXT NOT NULL,
  text_bn TEXT NOT NULL,
  category TEXT NOT NULL DEFAULT 'deep_talk',
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 8. Question Sessions (Duo Daily Quiz Anchor)
CREATE TABLE IF NOT EXISTS public.question_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  duo_id UUID NOT NULL REFERENCES public.duo_spaces(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES public.daily_questions(id) ON DELETE CASCADE,
  session_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'completed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_session_duo_date UNIQUE (duo_id, session_date)
);

-- 9. Question Answers & Guesses (TwoTruths Logic)
CREATE TABLE IF NOT EXISTS public.question_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.question_sessions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  answer TEXT NOT NULL,
  guessed_answer TEXT,
  is_guess_correct BOOLEAN,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT uq_answer_session_user UNIQUE (session_id, user_id)
);

-- 10. Secret Notes & Letters
CREATE TABLE IF NOT EXISTS public.notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  duo_id UUID NOT NULL REFERENCES public.duo_spaces(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title TEXT,
  body TEXT NOT NULL,
  stationery_theme TEXT NOT NULL DEFAULT 'blush',
  opened_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notes_duo_created ON public.notes(duo_id, created_at DESC);

-- 11. Multiplayer Game Sessions (Turn-based / Asynchronous)
CREATE TABLE IF NOT EXISTS public.game_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  duo_id UUID NOT NULL REFERENCES public.duo_spaces(id) ON DELETE CASCADE,
  game_type TEXT NOT NULL CHECK (game_type IN ('tic_tac_toe', 'would_you_rather', 'truth_or_dare')),
  state JSONB NOT NULL DEFAULT '{}'::jsonb,
  current_turn UUID REFERENCES public.users(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('waiting', 'active', 'completed', 'abandoned')),
  winner_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_game_duo_active ON public.game_sessions(duo_id, status);

-- 12. Shared Bucket List
CREATE TABLE IF NOT EXISTS public.bucket_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  duo_id UUID NOT NULL REFERENCES public.duo_spaces(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  is_completed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  target_date DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bucket_duo_completed ON public.bucket_items(duo_id, is_completed);

-- 13. Countdown Events & Anniversaries
CREATE TABLE IF NOT EXISTS public.countdown_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  duo_id UUID NOT NULL REFERENCES public.duo_spaces(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  event_date DATE NOT NULL,
  category TEXT NOT NULL DEFAULT 'anniversary',
  created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_countdowns_duo_date ON public.countdown_events(duo_id, event_date ASC);

-- 14. Duo Space Subscriptions & Shared Entitlement
CREATE TABLE IF NOT EXISTS public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  duo_id UUID NOT NULL REFERENCES public.duo_spaces(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('google', 'apple', 'mock')),
  purchase_token_ref TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'grace_period', 'expired', 'revoked')),
  expires_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 15. In-App Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  duo_id UUID REFERENCES public.duo_spaces(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  payload JSONB NOT NULL DEFAULT '{}'::jsonb,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id, read_at);
-- ====================================================================
-- Duo Migration 02: Row Level Security (RLS) & Authorization
-- Version: 1.0
-- Target: PostgreSQL / Supabase
-- ====================================================================

-- 1. Security Definer Helper: Check Active Duo Membership
CREATE OR REPLACE FUNCTION public.is_duo_member(target_duo_id UUID)
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.duo_members
    WHERE duo_id = target_duo_id
      AND user_id = auth.uid()
      AND status = 'active'
  );
$$;

-- 2. Helper: Get Current User's Active Duo ID
CREATE OR REPLACE FUNCTION public.get_active_duo_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT duo_id FROM public.duo_members
  WHERE user_id = auth.uid()
    AND status = 'active'
  LIMIT 1;
$$;

-- 3. Trigger: Automatically Sync auth.users to public.users on Sign Up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.users (id, display_name, avatar_path, language, timezone)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url',
    COALESCE(NEW.raw_user_meta_data->>'language', 'en'),
    COALESCE(NEW.raw_user_meta_data->>'timezone', 'Asia/Dhaka')
  )
  ON CONFLICT (id) DO UPDATE SET
    updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ====================================================================
-- Enable RLS On All Tables
-- ====================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duo_spaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duo_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.duo_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_checkins ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bucket_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.countdown_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- --------------------------------------------------------------------
-- Table: users
-- --------------------------------------------------------------------
CREATE POLICY "Users can view own profile or partner profile"
  ON public.users FOR SELECT
  USING (
    id = auth.uid()
    OR id IN (
      SELECT m2.user_id 
      FROM public.duo_members m1
      JOIN public.duo_members m2 ON m1.duo_id = m2.duo_id
      WHERE m1.user_id = auth.uid() 
        AND m1.status = 'active' 
        AND m2.status = 'active'
    )
  );

CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- --------------------------------------------------------------------
-- Table: duo_spaces
-- --------------------------------------------------------------------
CREATE POLICY "Members can view their own Duo space"
  ON public.duo_spaces FOR SELECT
  USING (is_duo_member(id));

-- --------------------------------------------------------------------
-- Table: duo_members
-- --------------------------------------------------------------------
CREATE POLICY "Members can view members in their Duo space"
  ON public.duo_members FOR SELECT
  USING (is_duo_member(duo_id));

-- --------------------------------------------------------------------
-- Table: duo_invitations
-- --------------------------------------------------------------------
CREATE POLICY "Creators can view their invitations"
  ON public.duo_invitations FOR SELECT
  USING (created_by = auth.uid());

-- --------------------------------------------------------------------
-- Table: mood_checkins
-- --------------------------------------------------------------------
CREATE POLICY "Members can view mood check-ins in their Duo"
  ON public.mood_checkins FOR SELECT
  USING (is_duo_member(duo_id));

CREATE POLICY "Members can insert their own mood check-in"
  ON public.mood_checkins FOR INSERT
  WITH CHECK (is_duo_member(duo_id) AND user_id = auth.uid());

CREATE POLICY "Members can update their own mood check-in"
  ON public.mood_checkins FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- --------------------------------------------------------------------
-- Table: daily_questions
-- --------------------------------------------------------------------
CREATE POLICY "Authenticated users can view active questions"
  ON public.daily_questions FOR SELECT
  TO authenticated
  USING (active = true);

-- --------------------------------------------------------------------
-- Table: question_sessions
-- --------------------------------------------------------------------
CREATE POLICY "Members can view daily question sessions"
  ON public.question_sessions FOR SELECT
  USING (is_duo_member(duo_id));

-- --------------------------------------------------------------------
-- Table: question_answers (Asymmetric Sealing)
-- --------------------------------------------------------------------
CREATE POLICY "Users can view answers in their session"
  ON public.question_answers FOR SELECT
  USING (
    session_id IN (
      SELECT id FROM public.question_sessions WHERE is_duo_member(duo_id)
    )
  );

CREATE POLICY "Users can insert their own answer"
  ON public.question_answers FOR INSERT
  WITH CHECK (
    user_id = auth.uid() 
    AND session_id IN (
      SELECT id FROM public.question_sessions WHERE is_duo_member(duo_id)
    )
  );

CREATE POLICY "Users can update their own answer or guess"
  ON public.question_answers FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- --------------------------------------------------------------------
-- Table: notes
-- --------------------------------------------------------------------
CREATE POLICY "Members can read notes in their Duo space"
  ON public.notes FOR SELECT
  USING (is_duo_member(duo_id));

CREATE POLICY "Members can send notes in their Duo space"
  ON public.notes FOR INSERT
  WITH CHECK (is_duo_member(duo_id) AND sender_id = auth.uid());

CREATE POLICY "Recipients can mark notes opened"
  ON public.notes FOR UPDATE
  USING (is_duo_member(duo_id));

-- --------------------------------------------------------------------
-- Table: game_sessions
-- --------------------------------------------------------------------
CREATE POLICY "Members can view game sessions in their Duo space"
  ON public.game_sessions FOR SELECT
  USING (is_duo_member(duo_id));

CREATE POLICY "Members can create game sessions in their Duo space"
  ON public.game_sessions FOR INSERT
  WITH CHECK (is_duo_member(duo_id));

CREATE POLICY "Members can update game sessions in their Duo space"
  ON public.game_sessions FOR UPDATE
  USING (is_duo_member(duo_id));

-- --------------------------------------------------------------------
-- Table: bucket_items
-- --------------------------------------------------------------------
CREATE POLICY "Members can view bucket items"
  ON public.bucket_items FOR SELECT
  USING (is_duo_member(duo_id));

CREATE POLICY "Members can add bucket items"
  ON public.bucket_items FOR INSERT
  WITH CHECK (is_duo_member(duo_id) AND created_by = auth.uid());

CREATE POLICY "Members can update bucket items"
  ON public.bucket_items FOR UPDATE
  USING (is_duo_member(duo_id));

CREATE POLICY "Members can delete bucket items"
  ON public.bucket_items FOR DELETE
  USING (is_duo_member(duo_id));

-- --------------------------------------------------------------------
-- Table: countdown_events
-- --------------------------------------------------------------------
CREATE POLICY "Members can view countdown events"
  ON public.countdown_events FOR SELECT
  USING (is_duo_member(duo_id));

CREATE POLICY "Members can add countdown events"
  ON public.countdown_events FOR INSERT
  WITH CHECK (is_duo_member(duo_id) AND created_by = auth.uid());

CREATE POLICY "Members can update countdown events"
  ON public.countdown_events FOR UPDATE
  USING (is_duo_member(duo_id));

CREATE POLICY "Members can delete countdown events"
  ON public.countdown_events FOR DELETE
  USING (is_duo_member(duo_id));

-- --------------------------------------------------------------------
-- Table: subscriptions
-- --------------------------------------------------------------------
CREATE POLICY "Members can view their Duo subscriptions"
  ON public.subscriptions FOR SELECT
  USING (is_duo_member(duo_id));

-- --------------------------------------------------------------------
-- Table: notifications
-- --------------------------------------------------------------------
CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update their own notifications"
  ON public.notifications FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
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
-- ====================================================================
-- Duo Seed Data: Initial Bilingual Questions & Couple Prompts
-- Version: 1.0
-- Locales: English (`en`) and Bangla (`bn`)
-- ====================================================================

-- 1. Curated Daily Questions (TwoTruths / DuoDay)
INSERT INTO public.daily_questions (text_en, text_bn, category, active) VALUES
-- Category: Deep Talks & Emotional Intimacy
('What is one small thing I do that makes you feel deeply loved?', 
 'আমার এমন কোন ছোট্ট অভ্যাস বা কাজ আছে যা তোমাকে সবচেয়ে বেশি ভালোবাসার অনুভূতি দেয়?', 
 'deep_talk', true),

('What is your favorite memory of us from the past year?', 
 'গত এক বছরে আমাদের কাটানো কোন স্মৃতিটি তোমার সবচেয়ে প্রিয়?', 
 'memories', true),

('When you are feeling stressed or overwhelmed, what comforts you the most?', 
 'যখন তুমি মানসিক চাপে বা ক্লান্ত থাকো, তখন কোন জিনিসটি তোমাকে সবচেয়ে বেশি স্বস্তি দেয়?', 
 'deep_talk', true),

('What was the first thing you noticed about me when we first met?', 
 'আমাদের প্রথম দেখার দিনে আমার কোন দিকটা তোমার প্রথম চোখে পড়েছিল?', 
 'romance', true),

('If we could freeze one moment in time from our relationship, which one would you choose?', 
 'আমাদের সম্পর্কের যে কোনো একটি মুহূর্তকে যদি চিরতরে থামিয়ে রাখা যেত, তুমি কোনটি বেছে নিতে?', 
 'memories', true),

('What is one dream or goal for our future that excites you the most?', 
 'আমাদের ভবিষ্যৎ নিয়ে কোন স্বপ্ন বা লক্ষ্যটি তোমাকে সবচেয়ে বেশি রোমাঞ্চিত করে?', 
 'future', true),

-- Category: Playful & Fun
('If we were stranded on a deserted tropical island, which of us would survive longer?', 
 'যদি আমরা কোনো নির্জন দ্বীপে আটকে যাই, আমাদের দুজনের মধ্যে কে বেশি দিন টিকে থাকতে পারবে বলে মনে হয়?', 
 'playful', true),

('What is the funniest or most silly misunderstanding we have ever had?', 
 'আমাদের মধ্যে হওয়া সবচেয়ে মজার বা অদ্ভুত ভুল বোঝাবুঝি কোনটি ছিল?', 
 'playful', true),

('If we could adopt any pet in the world together tomorrow, what would you pick?', 
 'কালই যদি আমরা একসঙ্গে যেকোনো একটি পোষা প্রাণী নিতে পারতাম, তুমি কোনটি পছন্দ করতে?', 
 'playful', true),

('What is my guilty pleasure food that I secretly love the most?', 
 'আমার এমন কোন খাবারটি খুব পছন্দ যা আমি একটু লুকিয়ে বা অপরাধবোধ নিয়ে উপভোগ করি?', 
 'playful', true),

-- Category: Romance & Appreciation
('What is a quality in me that you admire, even if you do not say it often?', 
 'আমার এমন কোন গুণটি তোমার ভালো লাগে যা তুমি হয়তো সচরাচর মুখে বলো না?', 
 'romance', true),

('What is your ideal romantic date: a rainy day inside or an adventurous road trip?', 
 'তোমার কাছে পারফেক্ট রোমান্টিক ডেট কোনটি: বৃষ্টির দিনে ঘরে একসাথে বসে থাকা, নাকি লং ড্রাইভে বের হওয়া?', 
 'romance', true),

('What song or melody always reminds you of me when you hear it?', 
 'কোন গান বা সুর শুনলেই তোমার আমার কথা মনে পড়ে?', 
 'romance', true),

('What is one tradition or routine that you want us to start doing together?', 
 'এমন কোন নতুন সুন্দর অভ্যাস বা নিয়ম আছে যা তুমি চাও আমরা দুজন নিয়মিত পালন করি?', 
 'future', true),

('If you had to describe our relationship in three words, what would they be?', 
 'আমাদের সম্পর্কটাকে যদি মাত্র তিনটি শব্দে প্রকাশ করতে হয়, সেগুলো কী হবে?', 
 'deep_talk', true);
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
