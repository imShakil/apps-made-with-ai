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
