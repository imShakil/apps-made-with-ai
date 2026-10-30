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
