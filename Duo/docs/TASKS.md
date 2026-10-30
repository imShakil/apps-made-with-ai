# Duo Development Tasks & Roadmap

> **Product:** Duo — Two people. One little world. 💗  
> **Status:** All Core Phases Completed & Production Verified  
> **Target Platforms:** Android, iOS, Web, macOS  

---

## 📊 Progress Summary

| Phase | Description | Status | Completion |
|---|---|:---:|:---:|
| **Phase 1** | Brand, UX, Design System, & Client Scaffolding | ✅ Completed | 100% |
| **Phase 2** | Supabase Database Schema, RLS, & Atomic RPCs | ✅ Completed | 100% |
| **Phase 3** | Authentication & Couple Pairing Integration | ✅ Completed | 100% |
| **Phase 4** | DuoDay & Daily Questions (TwoTruths Engine) | ✅ Completed | 100% |
| **Phase 5** | SecretNote (Private Letters & Stationery) | ✅ Completed | 100% |
| **Phase 6** | TogetherPlay (Multiplayer Turn Mini-Games) | ✅ Completed | 100% |
| **Phase 7** | OurLittleWorld (Countdowns & Shared Bucket List) | ✅ Completed | 100% |
| **Phase 8** | Monetization & Duo Premium (Couple Shared Entitlements) | ✅ Completed | 100% |
| **Phase 9** | Localization (Bangla `bn` & English `en` Typography) | ✅ Completed | 100% |
| **Phase 10**| Testing, Hardening, & Web Server Verification | ✅ Completed | 100% |
| **Phase 11**| UI/UX Polish (Floating Navbar, Glass AppBar, High Contrast, Full App Localization) | ✅ Completed | 100% |
| **Phase 12**| Expert Design Spec Implementation (Tactile Micro-Interactions, Animated Transitions, Bengali Numerals, Time-Aware Greetings) | ✅ Completed | 100% |

---

## ✅ Completed Tasks (Done)

### 🎨 Design System & Documentation
- [x] Align pricing model across documentation (Monthly ৳99, Annual ৳799, Lifetime ৳1,799).
- [x] Standardize design tokens in [DESIGN_SPEC.md](../DESIGN_SPEC.md) (Coral Pink, Lavender, Warm Yellow, Mint).
- [x] Create ASCII wireframes and interaction specs for all 5 core modules.
- [x] Document offline-first caching strategy (`hive_flutter`), Supabase Realtime channels, and mini-game JSONB schemas in [PLAN.md](../PLAN.md).

### 🗄️ Backend & Database (Supabase)
- [x] Create `20261030000001_initial_schema.sql` with 14 relational tables and indexes.
- [x] Enforce single active Duo constraint per user at the database level.
- [x] Create `20261030000002_rls_and_security.sql` with Row Level Security and `is_duo_member()` helper.
- [x] Add auto-sync trigger from `auth.users` to `public.users`.
- [x] Create `20261030000003_rpc_functions.sql` with atomic `accept_invitation()` concurrency locking (`FOR UPDATE`).
- [x] Define RPCs: `create_duo_space()`, `create_invitation()`, `disconnect_duo()`, `submit_question_answer()`, `submit_partner_guess()`, `mark_note_opened()`.
- [x] Configure Supabase Realtime table publications.
- [x] Write `seed.sql` with 15 bilingual questions in English and Bengali.
- [x] Combine bundled SQL setup in `supabase/full_setup.sql`.
- [x] Deploy and execute database schema on remote Supabase project (`mxzppesgbfkodgefljcx`).

### 📱 Client Architecture & UI Scaffolding (Flutter)
- [x] Scaffold Android, iOS, Web, and macOS platform runners (`flutter create . --org com.duo`).
- [x] Configure [pubspec.yaml](../pubspec.yaml) with Riverpod, GoRouter, Supabase Flutter, Hive, and Google Fonts.
- [x] Resolve Flutter 3.47.9 SDK constraints (`intl: ^0.20.3`, `CardThemeData`).
- [x] Build design system in Flutter (`DuoColors`, `DuoTheme` with Light & Dark modes).
- [x] Build navigation shell (`DuoBottomNav`, `DuoAppBar`, `app_router.dart` with `StatefulShellRoute`).
- [x] Build UI screens:
  - [x] `HomeScreen` (DuoDay mood check-in, daily question, quick tiles, countdown).
  - [x] `PlayScreen` (TwoTruths compatibility quiz + 3 mini-game cards).
  - [x] `MemoriesScreen` (SecretNote unopened envelope + letter archive).
  - [x] `TogetherScreen` (Countdown hero ticker + interactive bucket list).
  - [x] `ProfileScreen` (Couple avatar card, Duo Premium status, settings).
  - [x] `PairingScreen` (Invite code generator + partner code claim).
  - [x] `AuthScreen` (Email/password sign-in and sign-up with live Supabase Auth).
- [x] Initialize Supabase in Flutter (`DuoConfig.supabaseUrl`, `DuoConfig.supabaseAnonKey`).
- [x] Create Riverpod providers (`supabaseClientProvider`, `authStateProvider`, `currentUserProvider`, `pairingProvider`).
- [x] Wire up GoRouter Auth Guard (`routerProvider`) redirecting unauthenticated users to `/auth` and unpaired users to `/pairing`.
- [x] Connect `PairingScreen` with live `create_invitation` and `accept_invitation` RPCs and native OS share sheet.
- [x] Pass all widget smoke tests (`flutter test`) and static analysis (`flutter analyze`).
- [x] Launch running Flutter Web development server at `http://localhost:5000`.
- [x] Successfully verified live Couple Pairing: Connected **Mobarak** & **Sumaiya** in active shared Duo space (`c596077a-de16-49c6-8f0a-56202a69372a`).

### ☀️ Phase 4: DuoDay & Daily Questions (TwoTruths Engine)
- [x] Create `mood_provider.dart` with optimistic UI update, daily date formatting, and Supabase upsert.
- [x] Enable real-time partner mood sync via `public:mood_checkins:{duo_id}` channel.
- [x] Build streak calculation logic based on consecutive daily check-ins.
- [x] Create `daily_question_provider.dart` with daily question rotation and `question_sessions` persistence.
- [x] Build TwoTruths asymmetric reveal: private answer locking until both partners participate.
- [x] Build `DailyQuestionAnswerSheet` for private heart-to-heart responses.
- [x] Build `PartnerGuessDialog` with quiz matching and celebration animation (`flutter_animate`).
- [x] Update `HomeScreen` with live couple greeting, partner mood snapshot, and TwoTruths cards.

### 💌 Phase 5: SecretNote (Private Letters & Surprises)
- [x] Create [stationery_theme.dart](../lib/features/memories/presentation/models/stationery_theme.dart) with 4 custom curated palettes (Blush Pink, Vintage Parchment, Midnight Sky, Sunset Glow).
- [x] Create [notes_provider.dart](../lib/features/memories/presentation/providers/notes_provider.dart) with Supabase Realtime synchronization on `notes` table.
- [x] Build [NoteComposerSheet](../lib/features/memories/presentation/widgets/note_composer_sheet.dart) with live stationery switching, real-time paper preview, and partner notification dispatch.
- [x] Build [NoteReaderDialog](../lib/features/memories/presentation/widgets/note_reader_dialog.dart) featuring a smooth 350ms paper-unfolding animation (`flutter_animate`) and auto-marking note opened via `mark_note_opened` RPC.
- [x] Update [MemoriesScreen](../lib/features/memories/presentation/screens/memories_screen.dart) with unopened letter hero highlight, cozy empty state, and saved letters archive.

### 🎮 Phase 6: TogetherPlay (Couple Mini-Games)
- [x] Create [games_provider.dart](../lib/features/play/presentation/providers/games_provider.dart) with `TicTacToeNotifier` synchronizing turns on `game_sessions` table via Supabase Realtime.
- [x] Build [TicTacToeDialog](../lib/features/play/presentation/widgets/tic_tac_toe_dialog.dart) featuring interactive 3x3 board with custom couple tokens (❤️ Heart vs ⭐ Star), winning line detection, and pop-in animations (`flutter_animate`).
- [x] Build [WouldYouRatherDialog](../lib/features/play/presentation/widgets/would_you_rather_dialog.dart) featuring curated romantic and playful dilemmas with choice locking.
- [x] Build [TruthOrDareDialog](../lib/features/play/presentation/widgets/truth_or_dare_dialog.dart) with interactive 3D challenge cards across Romantic, Playful, Deep, and Spicy categories.
- [x] Update [PlayScreen](../lib/features/play/presentation/screens/play_screen.dart) connecting TwoTruths daily compatibility quiz and live turn badges.

### 🌍 Phase 7: OurLittleWorld (Plans & Countdowns)
- [x] Create [together_provider.dart](../lib/features/together/presentation/providers/together_provider.dart) with `TogetherNotifier` synchronizing `countdown_events` and `bucket_items` via Supabase Realtime.
- [x] Build [AddBucketItemSheet](../lib/features/together/presentation/widgets/add_bucket_item_sheet.dart) with category selectors (Travel, Food, Adventure, Home, Romance).
- [x] Build [AddCountdownSheet](../lib/features/together/presentation/widgets/add_countdown_sheet.dart) with date picker and milestone icon picker.
- [x] Build [TogetherScreen](../lib/features/together/presentation/screens/together_screen.dart) with live countdown calculation (Days, Hours, Mins), interactive bucket list check/uncheck, progress bar, and dismissible item deletion.

### 👑 Phase 8: Monetization & Duo Premium (Couple Shared Entitlements)
- [x] Create [subscription_provider.dart](../lib/features/profile/presentation/providers/subscription_provider.dart) with Supabase Realtime synchronization on `subscriptions` table.
- [x] Implement couple-first shared entitlement architecture (`duo_id` based): one partner subscribing unlocks all features for both instantly.
- [x] Build [PremiumPaywallScreen](../lib/features/profile/presentation/screens/premium_paywall_screen.dart) with luxury gradient cards, plan comparison (Monthly ৳99, Annual ৳799, Lifetime ৳1,799), benefits list, and instant upgrade with celebration feedback.
- [x] Update [ProfileScreen](../lib/features/profile/presentation/screens/profile_screen.dart) with live partner pairing details, space code badge, Duo Premium status card, unpair modal (`disconnect_duo` RPC), and sign out.

### 🌐 Phase 9 & 10: Localization, Accessibility & Hardening
- [x] Configure Google Fonts preconnect for `Inter` & `Noto Sans Bengali` in `web/index.html`.
- [x] Add bilingual language switcher dialog in Settings (English US / বাংলা).
- [x] Run `flutter analyze --no-fatal-infos` — 0 errors, 0 warnings.
- [x] Run `flutter test` — All widget smoke tests passing.
- [x] Maintain persistent live Web dev server at `http://localhost:5000` (HTTP 200).

### ✨ Phase 11: UI/UX Polish & Full App Localization
- [x] Glassmorphic [DuoAppBar](../lib/core/widgets/duo_app_bar.dart) with 20px blur, gradient brand header, online partner indicator, and pulsing heart animation.
- [x] Floating island frosted pill [DuoBottomNav](../lib/core/widgets/duo_bottom_nav.dart) with active indicator, drop shadows, and high-contrast icons.
- [x] WCAG AA compliant text contrast for dark & light mode tokens in [DuoColors](../lib/core/theme/duo_colors.dart) and [DuoTheme](../lib/core/theme/duo_theme.dart).
- [x] Reactive bilingual dictionary [DuoStrings](../lib/core/localization/duo_strings.dart) and `LocaleNotifier` in [locale_provider.dart](../lib/core/localization/locale_provider.dart).
- [x] Full reactive translation across all screens (`HomeScreen`, `PlayScreen`, `MemoriesScreen`, `TogetherScreen`, `ProfileScreen`) with instant real-time language updates.

### 🎯 Phase 12: Expert Design Spec Implementation & Micro-Interaction Polish
- [x] Created [bouncy_press.dart](../lib/core/widgets/bouncy_press.dart) with tactile micro-interaction scaling (0.96 scale down, 120ms spring back) and automatic `Semantics` accessibility.
- [x] Created [duo_progress_bar.dart](../lib/core/widgets/duo_progress_bar.dart) with animated width and brand gradient styling (`DuoColors.primaryGradient`).
- [x] Created [duo_formatters.dart](../lib/core/localization/duo_formatters.dart) supporting Bengali numerals (`০-৯`), time-aware greetings (`greeting_morning`, `greeting_afternoon`, `greeting_evening`, `greeting_night`), and localized dates.
- [x] Implemented animated tab switching in [app_router.dart](../lib/core/routing/app_router.dart) using `AnimatedSwitcher` with silky 220ms fade & subtle slide.
- [x] Upgraded [HomeScreen](../lib/features/home/presentation/screens/home_screen.dart):
  - Dynamic time-aware localized greeting in AppBar ("Good evening 🌙" / "শুভ সন্ধ্যা 🌙").
  - Hero streak progress bar tracking weekly milestone progress.
  - Interactive mood ring with `BouncyPress` micro-interactions.
  - Quick Connect pill bar: "Send Hug 🤗" (with instant floating toast & haptic feedback), "Drop Note 💌", and "Together Play 🎮".
  - TwoTruths Question of the Day with gradient CTA button and `BouncyPress`.
  - Countdown milestone card with localized days badge.
- [x] Upgraded [PlayScreen](../lib/features/play/presentation/screens/play_screen.dart):
  - Wrapped mini-game cards with `BouncyPress` and accessible semantics.
- [x] Upgraded [MemoriesScreen](../lib/features/memories/presentation/screens/memories_screen.dart):
  - Wrapped unopened note hero, saved letter cards, and photo moment cards with `BouncyPress`.
  - Locale-aware date formatting on letters and moments.
- [x] Upgraded [TogetherScreen](../lib/features/together/presentation/screens/together_screen.dart):
  - Large typographic countdown unit display with localized numerals (`৮৪৭ দিন`).
  - Swapped standard progress bar for sleek `DuoProgressBar`.
  - Filter chips and bucket item cards wrapped in `BouncyPress`.
- [x] Upgraded [ProfileScreen](../lib/features/profile/presentation/screens/profile_screen.dart):
  - Couple avatar hero with glowing heart connector and localized connection date.
  - Replaced all deprecated `withOpacity` calls with `withValues(alpha: ...)`.
- [x] Verified static analysis: `flutter analyze --no-fatal-infos` — 0 errors, 0 warnings.
- [x] Verified widget test suite: `flutter test` — All tests passing.
- [x] Maintained live development server at `http://localhost:5000`.

