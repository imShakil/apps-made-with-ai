# Changelog

All notable changes to the **Duo** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- **Expert UI/UX Design Spec Implementation & Micro-Interaction Polish (Phase 12)**:
  - **Tactile Micro-Interactions**: Built [bouncy_press.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/widgets/bouncy_press.dart) providing high-fidelity spring scale down (0.96) on touch down and organic spring rebound (120ms easeInOutCubic), paired with automatic WCAG `Semantics` labels and accessibility attributes across all buttons, navigation pills, cards, and list tiles.
  - **Animated Shell Tab Switching**: Integrated `AnimatedSwitcher` into [app_router.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/routing/app_router.dart) with 220ms fade & subtle slide for silky, native iOS/Android-like page transitions between tabs.
  - **Brand Progress Bar Component**: Created [duo_progress_bar.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/widgets/duo_progress_bar.dart) featuring animated width transitions, rounded pill geometry, and vibrant brand gradient fills (`DuoColors.primaryGradient`).
  - **Bilingual Formatter & Bengali Numerals**: Built [duo_formatters.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/localization/duo_formatters.dart) supporting Bengali numerals (`০১২৩৪৫৬৭৮৯`), time-of-day greetings (Good morning ☀️ / Good afternoon 🌤️ / Good evening 🌙 / Good night ⭐️), and locale-aware date rendering.
  - **HomeScreen Polish**:
    - Added time-aware personalized greeting in the glassmorphic header bar.
    - Added weekly streak progress milestone bar with localized count indicators.
    - Upgraded mood check-in ring with bouncy touch feedback.
    - Added Quick Connect pill bar: "Send Hug 🤗" with instant floating toast feedback, "Drop Note 💌", and "Together Play 🎮".
    - Enhanced TwoTruths daily question card with gradient action button and bouncy physics.
  - **TogetherScreen & MemoriesScreen Enhancements**:
    - Upgraded countdown display with localized numeric typography and [DuoProgressBar](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/widgets/duo_progress_bar.dart).
    - Wrapped bucket items, category filter chips, and letter envelope cards in [BouncyPress](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/widgets/bouncy_press.dart).
    - Replaced all deprecated `withOpacity` calls across the codebase with `withValues(alpha: ...)`.
- **UI/UX, Header, Navbar, Contrast & Full Localization Overhaul (Phase 11)**:
  - **Glassmorphic Header & Animated Brand Title**: Redesigned [DuoAppBar](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/widgets/duo_app_bar.dart) with 20px frosted backdrop filter, subtle glowing bottom border, gradient brand typography, dynamic partner online status indicator, and animated pulsing couple heart (`flutter_animate`).
  - **Floating Island Bottom Navbar**: Upgraded [DuoBottomNav](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/widgets/duo_bottom_nav.dart) into a modern floating frosted glass pill container (28px radius) with subtle drop shadows, smooth active indicator pill, localized label typography, and refined Cupertino/Material 3 icons (`favorite_rounded`, `sports_esports_rounded`, `auto_stories_rounded`, `explore_rounded`, `settings_rounded`). Set `extendBody: true` on shell Scaffold for fluid under-navbar scroll.
  - **WCAG High-Contrast Typography & Themes**: Upgraded [DuoColors](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/theme/duo_colors.dart) and [DuoTheme](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/theme/duo_theme.dart) tokens. Enhanced text contrast against both light (`#1C1618` primary, `#524348` secondary) and dark (`#FFFFFF` primary, `#D1C4C9` secondary) surfaces, meeting WCAG AA standards. Refined card corner radii (20px) and button elevations.
  - **Complete Reactive Localization (`en` & `bn`)**:
    - Created [locale_provider.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/localization/locale_provider.dart) with `LocaleNotifier` managing active locale application-wide.
    - Created [duo_strings.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/localization/duo_strings.dart) with comprehensive bilingual dictionaries covering tabs, headers, mood labels, quiz reveals, countdown units, bucket filters, and settings.
    - Wired reactive real-time language switching in [ProfileScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/profile/presentation/screens/profile_screen.dart) language dialog with active language checkmarks.
    - Localized all screens: [HomeScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/home/presentation/screens/home_screen.dart), [PlayScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/play/presentation/screens/play_screen.dart), [MemoriesScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/memories/presentation/screens/memories_screen.dart), [TogetherScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/together/presentation/screens/together_screen.dart), and [ProfileScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/profile/presentation/screens/profile_screen.dart). Instant language change across the entire app without page reloads.
- **DuoDay Mood Check-In & Streak Engine (Phase 4)**:
  - Created [lib/features/home/presentation/providers/mood_provider.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/home/presentation/providers/mood_provider.dart) with optimistic UI updates and live Supabase upserting (`mood_checkins`).
  - Implemented real-time partner sync via Supabase Realtime channel `public:mood_checkins:{duo_id}`.
  - Calculated continuous couple daily streaks with consecutive calendar date checking.
  - Added live partner mood status card in [HomeScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/home/presentation/screens/home_screen.dart) with dynamic emoji and custom notes.
- **TwoTruths Daily Questions & Asymmetric Reveal Engine (Phase 4)**:
  - Created [lib/features/home/presentation/providers/daily_question_provider.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/home/presentation/providers/daily_question_provider.dart) with automatic daily question rotation and Supabase Realtime answer listeners.
  - Implemented asymmetric lock & reveal: answers remain private until both partners participate.
  - Built [DailyQuestionAnswerSheet](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/home/presentation/widgets/daily_question_answer_sheet.dart) bottom sheet modal with bilingual question cards and privacy notices.
  - Built [PartnerGuessDialog](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/home/presentation/widgets/partner_guess_dialog.dart) featuring TwoTruths partner guessing and match celebration effects with `flutter_animate`.
- **SecretNote Private Letters & Stationery Engine (Phase 5)**:
  - Defined 4 custom stationery themes in [lib/features/memories/presentation/models/stationery_theme.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/memories/presentation/models/stationery_theme.dart): Blush Pink 🌸, Vintage Parchment 📜, Midnight Sky 🌙, and Sunset Glow 🌅.
  - Built [lib/features/memories/presentation/providers/notes_provider.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/memories/presentation/providers/notes_provider.dart) with Supabase Realtime synchronization on `notes` and partner notification triggers.
  - Created [NoteComposerSheet](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/memories/presentation/widgets/note_composer_sheet.dart) featuring live stationery switching and styled paper canvas.
  - Created [NoteReaderDialog](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/memories/presentation/widgets/note_reader_dialog.dart) featuring 350ms paper-unfolding animation (`flutter_animate`) and `mark_note_opened` RPC integration.
  - Enhanced [MemoriesScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/memories/presentation/screens/memories_screen.dart) with unopened letter hero highlight, cozy empty state, and saved letters archive.
- **TogetherPlay Couple Mini-Games (Phase 6)**:
  - Created [lib/features/play/presentation/providers/games_provider.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/play/presentation/providers/games_provider.dart) with `GamesNotifier` synchronizing turns on `game_sessions` table via Supabase Realtime.
  - Built [TicTacToeDialog](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/play/presentation/widgets/tic_tac_toe_dialog.dart) with custom couple tokens (❤️ Heart vs ⭐ Star), winning line detection, and pop-in animations (`flutter_animate`).
  - Built [WouldYouRatherDialog](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/play/presentation/widgets/would_you_rather_dialog.dart) featuring curated couple dilemmas and choice locking.
  - Built [TruthOrDareDialog](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/play/presentation/widgets/truth_or_dare_dialog.dart) featuring interactive 3D challenge cards across Romantic, Playful, Deep, and Spicy categories.
  - Enhanced [PlayScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/play/presentation/screens/play_screen.dart) with live turn badges, category chips, and TwoTruths compatibility quiz integration.
- **OurLittleWorld Plans & Countdowns (Phase 7)**:
  - Created [lib/features/together/presentation/providers/together_provider.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/together/presentation/providers/together_provider.dart) with `TogetherNotifier` synchronizing `countdown_events` and `bucket_items` in real-time.
  - Built [AddBucketItemSheet](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/together/presentation/widgets/add_bucket_item_sheet.dart) with category selectors (Travel, Food, Adventure, Home, Romance).
  - Built [AddCountdownSheet](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/together/presentation/widgets/add_countdown_sheet.dart) with date picker and milestone icon picker.
- **Monetization & Duo Premium (Phase 8)**:
  - Built couple-first shared entitlement architecture via [lib/features/profile/presentation/providers/subscription_provider.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/profile/presentation/providers/subscription_provider.dart) with Supabase Realtime synchronization on `subscriptions` table.
  - Implemented `activatePlan()` supporting Monthly (৳99), Annual (৳799, save 33%), and Forever Duo Lifetime (৳1,799). Subscribing unlocks premium perks for both partners instantly in real-time.
  - Built luxury [PremiumPaywallScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/profile/presentation/screens/premium_paywall_screen.dart) featuring gradient hero, interactive plan cards, benefits breakdown, and celebration effects (`flutter_animate`).
  - Updated [ProfileScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/profile/presentation/screens/profile_screen.dart) to show live partner names, space code badge, shared Duo Premium status, unpair confirmation modal (`disconnect_duo` RPC), and account sign out.
- **Interactive Functional Polish & Feature Expansion**:
  - **Dynamic Theme Mode**: Created [theme_provider.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/theme/theme_provider.dart) with instant Light ☀️, Dark 🌙, and System 🌓 appearance switching from Profile Settings.
  - **Home Navigation & Live Countdowns**: Linked Quick Action tiles ("Secret Note" -> Memories, "Together Play" -> Play) with GoRouter. Connected Upcoming Countdown card to dynamic nearest milestone from Supabase with days calculation. Added quick mood note dialog ("Add a thought for partner 💭").
  - **Play Category Explorer**: Made question category chips (Deep Talks, Romance, Memories, Playful) interactive, displaying full bilingual question pools with instant answer sheets.
  - **Tic-Tac-Toe Couch Mode**: Added "Pass & Play / Couch Mode" toggle alongside Realtime Sync so couples can play together on a single screen without waiting for a separate device.
  - **Would You Rather & Truth or Dare Expansion**: Expanded dilemmas to 16 curated couple choices and Truth or Dare to 20 romantic/playful prompts.
  - **Memories Dual Mode (Photo Moments & Letters)**: Added TabBar to [MemoriesScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/memories/presentation/screens/memories_screen.dart) supporting both stationery letters and photo scrapbook moments via [AddPhotoMomentSheet](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/memories/presentation/widgets/add_photo_moment_sheet.dart).
  - **Together Bucket Filters & Multiple Countdowns**: Added category filter chips (Travel, Romance, Food, Adventure, Home) and an all-milestones list in [TogetherScreen](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/together/presentation/screens/together_screen.dart).
  - **Real Memories Export**: Added formatted Markdown couple archive generation with one-tap clipboard copying in Profile Settings.

### Fixed
- **Web Blank Screen on Dev Server**:
  - Fixed invalid relative import path in [lib/features/auth/presentation/screens/auth_screen.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/auth/presentation/screens/auth_screen.dart) that caused hot reload to exit the previous Flutter runner.
  - Updated [lib/core/routing/app_router.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/core/routing/app_router.dart) `initialLocation` to `/auth` to prevent unauthenticated redirect flickers during initial boot.
  - Migrated `anonKey` to `publishableKey` in [lib/main.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/main.dart) to conform with Supabase Flutter 2.x standards.
  - Successfully relaunched Flutter web server on `http://localhost:5000` with clean Supabase initialization.
- **Pairing & Invitation Flow**:
  - Resolved `ALREADY_PAIRED` false positive in `accept_invitation()` and `create_duo_space()` RPCs: users are now only considered paired if in an active 2-person space (`status = 'active'`).
  - Automatically discard empty pending spaces when a user accepts their partner's invitation.
  - Made invite code generation lazy in [lib/features/pairing/presentation/screens/pairing_screen.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/pairing/presentation/screens/pairing_screen.dart).
  - Added user-friendly error translations in [lib/features/pairing/presentation/providers/pairing_provider.dart](file:///Users/imshakil/apps-made-by-ai/Duo/lib/features/pairing/presentation/providers/pairing_provider.dart).

---

## [0.1.0] - 2026-10-30

### Added
- **Product Architecture & Design Specs**:
  - Authored comprehensive [DESIGN_SPEC.md](../DESIGN_SPEC.md) with design system tokens (Coral Pink `#FF6B81`, Lavender `#9B8AFB`, Warm Yellow `#FFC857`, Mint `#56C596`), typography scale (Inter + Noto Sans Bengali), 8px spacing grid, ASCII wireframes for all 5 core modules, haptic feedback guidelines, and accessibility standards.
  - Revamped [PLAN.md](../PLAN.md) with technical blueprint: atomic PostgreSQL RPCs (`accept_invitation()`, `is_duo_member()`), Supabase Realtime channel publications, mini-game JSONB schemas (Tic-Tac-Toe, Would You Rather, Truth or Dare), offline-first caching strategy, and couple-first shared entitlement model.
  - Aligned pricing structure across [PLAN.md](../PLAN.md) and [README.md](../README.md) (Monthly ৳99, Annual ৳799, Lifetime ৳1,799).

- **Supabase Backend Foundation**:
  - `20261030000001_initial_schema.sql`: 14 relational tables (`users`, `duo_spaces`, `duo_members`, `duo_invitations`, `mood_checkins`, `daily_questions`, `question_sessions`, `question_answers`, `notes`, `game_sessions`, `bucket_items`, `countdown_events`, `subscriptions`, `notifications`) with foreign keys, indexes, and single-active-Duo constraint.
  - `20261030000002_rls_and_security.sql`: Full Row Level Security (RLS) enforcement with security-definer helper `is_duo_member()` and `auth.users` auto-sync trigger.
  - `20261030000003_rpc_functions.sql`: Concurrency-safe atomic pairing RPC (`accept_invitation()` using `FOR UPDATE`), `create_duo_space()`, `create_invitation()`, `disconnect_duo()`, `submit_question_answer()`, `submit_partner_guess()`, `mark_note_opened()`, and Realtime table publication.
  - `seed.sql`: 15 curated bilingual couple questions in English and Bengali across *Deep Talks*, *Memories*, *Romance*, and *Playful* categories.
  - `config.toml` & `.env.example`: Local Supabase emulator configuration and environment variables template.

- **Flutter Client Application Scaffolding**:
  - Generated native platform runners for Android, iOS, Web, and macOS (`com.duo.duo`).
  - Configured [pubspec.yaml](../pubspec.yaml) dependencies: `flutter_riverpod`, `go_router`, `supabase_flutter`, `hive_flutter`, `cached_network_image`, `share_plus`, `connectivity_plus`, `google_fonts`, `flutter_animate`, and resolved SDK constraints (`intl: ^0.20.3`).
  - Created theme system: `DuoColors` and `DuoTheme` with complete Light & Dark mode support.
  - Built shell navigation: `DuoBottomNav` with 5 custom animated navigation pill tabs and `DuoAppBar`.
  - Built initial presentation screens:
    - **Home (DuoDay)**: Interactive mood selector (😊, 🥰, 😴, 😔, 🤩), partner status preview, question of the day card, quick action tiles, and countdown badge.
    - **Play (TwoTruths & Games)**: Tabbed layout with TwoTruths compatibility quiz and mini-game cards (Tic-Tac-Toe, Would You Rather, Truth or Dare).
    - **Memories (SecretNote)**: New unopened letter envelope with paper-opening trigger and saved letters archive.
    - **Together (OurLittleWorld)**: 1-Year anniversary countdown ticker and shared couple bucket list with interactive checkboxes.
    - **Profile (Settings)**: Couple avatar card, Duo Premium status banner, language selection, and unpair safety modal.
    - **Pairing**: 8-character invitation code generator (`DUO-XXXX`) and partner invitation claim flow.
    - **Auth**: Full email/password sign-in and sign-up with live Supabase Auth integration.
  - Initialized `Supabase.initialize()` in `main.dart` with `DuoConfig`.
  - Added Riverpod state management: `supabaseClientProvider`, `authStateProvider`, `currentUserProvider`, and `pairingProvider` with atomic RPC binding.
  - Set up `app_router.dart` with `StatefulShellRoute` preserving branch state between tabs and `/auth` route.
  - Passed all widget smoke tests (`flutter test`) and static analysis (`flutter analyze`).
  - Deployed running local development server on Chrome at `http://localhost:5000`.
