# Duo — UI/UX Design Specification

> **Mobile-first · Flutter · Android + iOS**  
> **Brand tagline:** *Two people. One little world.* 💗

---

## 1. Executive Design Direction

Duo is designed to feel like an intimate, playful, and warm private sanctuary shared exclusively by two people in a relationship. It is neither a generic utility messenger nor a collection of disconnected mini-apps; every screen emphasizes **togetherness**, **asynchronous intimacy**, and **shared history**.

### Brand Personality
- **Warm & Intimate:** Soft gradients, organic curves, and gentle lighting that evoke comfort.
- **Playful & Deliberate:** Joyful micro-animations, expressive emojis, and celebratory feedback without childish clutter.
- **Private & Safe:** Visual privacy cues, subtle notification defaults, and clear boundaries around shared vs. private states.
- **Calm & Unhurried:** Respects partners' busy schedules with gentle asynchronous turns rather than anxiety-inducing "seen" timestamps or typing indicators.

---

## 2. Design System & Foundations

### 2.1 Color Palette & Theme Tokens

The palette balances emotional warmth with clean modern utility. Contrast ratios strictly adhere to **WCAG 2.1 AA** standards (minimum 4.5:1 for body text).

#### Core Palette Tokens

| Token Name | Hex Code | Light Theme Usage | Dark Theme Usage |
|---|---|---|---|
| **Coral Pink** (`primary`) | `#FF6B81` | Primary brand accent, hero CTA, hearts | Primary brand accent, active state |
| **Lavender** (`secondary`) | `#9B8AFB` | Secondary actions, badges, quiz cards | Secondary accent, interactive chips |
| **Warm Yellow** (`accent`) | `#FFC857` | Streaks, celebrations, countdowns | Star ratings, highlights, milestones |
| **Mint** (`success`) | `#56C596` | Completed goals, correct guesses | Success indicators, verified status |
| **Tender Peach** (`surface-warm`) | `#FFEBE8` | Tinted card backgrounds, note paper | Subtle accent surfaces (20% opacity) |
| **Soft Cream** (`bg-light`) | `#FFF8F7` | Light mode canvas background | — |
| **Obsidian Slate** (`bg-dark`) | `#15141C` | — | Dark mode canvas background |
| **Dark Plum** (`surface-dark`) | `#201E2B` | — | Dark mode elevated cards |
| **Deep Charcoal** (`text-primary-light`)| `#292633` | Primary text in light theme | — |
| **Off-White** (`text-primary-dark`) | `#F8F7FA` | — | Primary text in dark theme |
| **Muted Mauve** (`text-muted-light`) | `#7D798E` | Secondary/placeholder text (light) | — |
| **Soft Gray** (`text-muted-dark`) | `#A39FB4` | — | Secondary/placeholder text (dark) |
| **Border Light** (`border-light`) | `#F0E7E6` | Subtle dividers and card outlines | — |
| **Border Dark** (`border-dark`) | `#2F2C3D` | — | Subtle dividers and card outlines |

### 2.2 Typography Scale

- **English Typography:** `Inter` (Clean, contemporary, highly legible at small sizes)
- **Bangla Typography:** `Noto Sans Bengali` (Matched x-height, harmonious weights)

| Style Token | Size / Line-Height | Weight | Tracking | Primary Usage |
|---|---|---|---|---|
| **Display Large** | 32sp / 40sp | Bold (700) | -0.5px | Hero greeting, anniversary countdown |
| **Display Medium** | 24sp / 32sp | SemiBold (600) | -0.2px | Section headlines, modal titles |
| **Headline Small** | 20sp / 28sp | SemiBold (600) | 0.0px | Card titles, question headers |
| **Title Medium** | 16sp / 24sp | Medium (500) | +0.1px | Subheadings, button text |
| **Body Large** | 16sp / 24sp | Regular (400) | 0.0px | Note content, quiz questions |
| **Body Medium** | 14sp / 20sp | Regular (400) | 0.0px | Standard body, bucket item descriptions |
| **Caption / Label** | 12sp / 16sp | Medium (500) | +0.2px | Timestamps, status chips, bottom tabs |

### 2.3 Spacing, Radii & Elevation

- **Base Spacing Grid:** 8px system (`4px`, `8px`, `12px`, `16px`, `20px`, `24px`, `32px`, `48px`)
- **Screen Margin:** `20px` (standard mobile viewport padding)
- **Corner Radii:**
  - Standard Cards: `20px`
  - Floating Action Buttons & Inputs: `14px`
  - Bottom Sheets: `24px` top corners
  - Avatars & Badges: Fully rounded (`999px`)
- **Elevation & Shadows:**
  - **Level 1 (Cards):** `0px 4px 16px rgba(41, 38, 51, 0.06)` (Light) / `0px 4px 16px rgba(0, 0, 0, 0.35)` (Dark)
  - **Level 2 (Modals / Floating CTA):** `0px 8px 24px rgba(255, 107, 129, 0.18)`
  - **Level 0 (Flat / Outlined):** 1px border with `border-light` / `border-dark`

---

## 3. Information Architecture & Navigation

Duo adopts a persistent 5-tab bottom navigation bar designed for effortless single-hand access:

```text
┌─────────────────────────────────────────────────────────────────┐
│                      DUO SHELL NAVIGATION                       │
├───────────┬───────────┬─────────────┬─────────────┬─────────────┤
│   Home    │   Play    │  Memories   │  Together   │   Profile   │
│  (DuoDay) │(TwoTruths │ (SecretNote │ (OurLittle  │ (Settings & │
│           │+ Games)   │ & Moments)  │   World)    │   Premium)  │
└───────────┴───────────┴─────────────┴─────────────┴─────────────┘
```

| Destination | Primary Feature Modules | Key User Objective |
|---|---|---|
| **1. Home** | **DuoDay** | Quick daily ritual: mood check-in, daily question snapshot, countdown |
| **2. Play** | **TwoTruths** & **TogetherPlay** | Interactive quizzes, guess partner's answers, Tic-tac-toe, Truth or Dare |
| **3. Memories**| **SecretNote** & Shared History | Heartfelt letters, private surprises, opened statuses, timeline log |
| **4. Together**| **OurLittleWorld** | Shared bucket list, countdown timers, relationship milestones & goals |
| **5. Profile** | Account & Space Settings | Duo connection status, unpair/recovery, localization, theme, Duo Premium |

---

## 4. Screen-by-Screen UX & Wireframe Specifications

### 4.1 Onboarding & Pairing Flow

Before the shared space can be accessed, the user progresses through an intuitive, low-friction pairing journey:

```text
[Splash] ──> [Welcome / Value Prop] ──> [Auth: Google / Apple / Email]
                                                     │
                                                     ▼
                                            [Profile Setup]
                                       (Name, Avatar, Birthday)
                                                     │
                         ┌───────────────────────────┴───────────────────────────┐
                         ▼                                                       ▼
               [Create Duo Space]                                        [Join Duo Space]
                         │                                                       │
                         ▼                                                       ▼
                [Invite Partner]                                         [Enter Invite Code /]
            (Share Code / Deep Link)                                     [Click Deep Link]
                         │                                                       │
                         └───────────────────────────┬───────────────────────────┘
                                                     ▼
                                          [Atomic Confirmation]
                                        (Avatars merge animation)
                                                     │
                                                     ▼
                                             [Shared Home]
```

#### Screen Details:
1. **Invite Partner Screen:**
   - Displays a clean 8-character invitation code (e.g. `DUO-LOVE`) with a 1-tap Copy action.
   - Large CTA: `"Share Invite Link"` (triggers native OS share sheet with dynamic universal link).
   - Realtime pulsing status chip: `"Waiting for your partner to join..."`.
2. **Accept Invitation Screen:**
   - Shows inviter's profile photo and display name: *“Rahim invited you to join their Duo.”*
   - Clear confirmation CTA: `"Accept & Connect"`.
   - Security fallback: `"Not your partner? Decline"`.

---

### 4.2 Home Screen — DuoDay

The home screen is the couple’s daily hearth. It is scannable in under 15 seconds, focusing on lightweight daily interactions.

#### Visual ASCII Wireframe:

```text
┌────────────────────────────────────────────────────────┐
│ [Duo. 💗]                                   [🔔] [⚙️]  │
│                                                        │
│ Friday, 30 October                                     │
│ Good morning, Shakil & Ayesha ✨                       │
│ ────────────────────────────────────────────────────── │
│ ┌────────────────────────────────────────────────────┐ │
│ │  TODAY'S MOOD                                      │ │
│ │  How are you feeling today?                        │ │
│ │                                                    │ │
│ │    [😊]      [🥰]      [😴]      [😔]      [🤩]    │ │
│ │   Happy     Loved     Tired     Down     Excited   │ │
│ │                                                    │ │
│ │  Partner: 🥰 Ayesha checked in ("Feeling cozy!")   │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │  QUESTION OF THE DAY                   [TwoTruths] │ │
│ │  "What is one little thing that always makes       │ │
│ │   you smile?"                                      │ │
│ │                                                    │ │
│ │  [🔒 Ayesha answered! Guess her answer]            │ │
│ │  [ Submit Your Answer ]                            │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ ┌──────────────────────────┐┌────────────────────────┐ │
│ │  SECRET NOTE 💌          ││  TOGETHER PLAY 🎮      │ │
│ │  "New note waiting!"     ││  Tic-Tac-Toe           │ │
│ │  Sent 2 hrs ago          ││  Your turn!            │ │
│ └──────────────────────────┘└────────────────────────┘ │
│                                                        │
│ ┌────────────────────────────────────────────────────┐ │
│ │  NEXT SPECIAL DAY                      [Together]  │ │
│ │  🎉 1 Year Anniversary                12 days left │ │
│ └────────────────────────────────────────────────────┘ │
│                                                        │
│ [ Home ]   [ Play ]   [ Memories ] [ Together ] [ 👤 ] │
└────────────────────────────────────────────────────────┘
```

#### Interaction Rules:
- **Mood Tap:** Tapping an emoji triggers a gentle haptic vibration, an upward spring animation, and immediately updates the partner's home card via Supabase Realtime.
- **Asymmetric Question State:**
  - Neither answered: Card displays the prompt and a `"Share your answer"` input.
  - Partner answered, user has not: Partner's answer is obscured with a frosted-glass blur and lock icon (*"Partner has answered! Submit yours to reveal"*).
  - Both answered: Card flips to a guess/reveal dialog with celebrating confetti.

---

### 4.3 Play — TwoTruths & TogetherPlay

The **Play** tab houses both asynchronous quizzes and real-time/turn-based couple games.

```text
┌────────────────────────────────────────────────────────┐
│  Play & Connect 🎲                                     │
│  ────────────────────────────────────────────────────  │
│  [ TwoTruths Quizzes ]       [ TogetherPlay Games ]    │
│  ────────────────────────────────────────────────────  │
│                                                        │
│  TODAY'S QUIZ SESSION                                  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ Category: Deep Talks & Dreams       [Score: 8/10]│  │
│  │ "If we could travel anywhere tomorrow, where     │  │
│  │  would I pick?"                                  │  │
│  │                                                  │  │
│  │  (A) Kyoto, Japan                                │  │
│  │  (B) Cox's Bazar Beach                           │  │
│  │  (C) Swiss Alps                                  │  │
│  │  (D) Cappadocia Balloon Ride                     │  │
│  │                                                  │  │
│  │  [ Tap your guess for Ayesha ]                   │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  COUPLE MINI-GAMES                                     │
│  ┌──────────────────────────┐┌──────────────────────┐  │
│  │ ⭕ Tic-Tac-Toe            ││ 💬 Would You Rather? │  │
│  │ Active Game · Your Turn  ││ 12 unanswered cards │  │
│  └──────────────────────────┘└──────────────────────┘  │
│  ┌──────────────────────────┐┌──────────────────────┐  │
│  │ 🔥 Truth or Dare         ││ 🎨 Drawing Challenge │  │
│  │ Playful romantic prompts ││ (Coming soon)        │  │
│  └──────────────────────────┘└──────────────────────┘  │
│                                                        │
│ [ Home ]   [ Play ]   [ Memories ] [ Together ] [ 👤 ] │
└────────────────────────────────────────────────────────┘
```

#### Mini-Game State Specifications:
1. **Tic-Tac-Toe:**
   - 3x3 grid with custom couple tokens (e.g. Coral Heart ❤️ vs Lavender Star ⭐).
   - Clear banner: *"Your turn"* vs *"Waiting for [Partner]..."*.
   - Move timeout: 48 hours before auto-draw, with turn reminder push notification.
2. **Would You Rather:**
   - Asynchronous card choice. Answer is sealed until both choose, then side-by-side match percentage is celebrated.
3. **Truth or Dare:**
   - 3 intimacy levels: *Cute & Silly*, *Romantic*, *Deep & Spicy*.
   - Complete / Forfeit buttons with optional photo/note proof.

---

### 4.4 Memories — SecretNote

A distraction-free, elegant space for intentional love letters, surprises, and anniversary notes.

```text
┌────────────────────────────────────────────────────────┐
│  Memories & Notes 💌                     [+ New Note]  │
│  ────────────────────────────────────────────────────  │
│  [ Received (4) ]                  [ Sent (6) ]        │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 💌 "Just thinking about you"       [NEW UNOPENED]│  │
│  │ From Shakil · Today, 08:30 AM                    │  │
│  │ Tap envelope to open                             │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 📜 "Why I love our quiet Sunday mornings"        │  │
│  │ From Shakil · 24 Oct · Opened                    │  │
│  │ "The way the light hits our kitchen table..."    │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  SHARED MOMENTS ARCHIVE                                │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 📸 15 October 2026                               │  │
│  │ First rainy day drive after marriage             │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│ [ Home ]   [ Play ]   [ Memories ] [ Together ] [ 👤 ] │
└────────────────────────────────────────────────────────┘
```

#### Note UX Details:
- **Envelope Open Interaction:** Tapping an unopened note plays a gentle 350ms paper-unfolding animation before revealing the letter.
- **Read Receipts:** Displays a subtle `"Opened at [Time]"` tag. No intrusive instant typing bubbles.
- **Compose Screen:** Full-height rich-text card with optional background stationery styles (Blush, Parchment, Midnight, Sunset).

---

### 4.5 Together — OurLittleWorld

Co-planning future dreams, shared milestones, and anniversary countdowns.

```text
┌────────────────────────────────────────────────────────┐
│  Our Little World 🌍                                   │
│  ────────────────────────────────────────────────────  │
│  COUNTDOWNS                                            │
│  ┌──────────────────────────────────────────────────┐  │
│  │ 🎉 1 Year Anniversary                            │  │
│  │ 12 Days · 14 Hours · 32 Mins                     │  │
│  │ 11 November 2026                    [Edit / View]│  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│  SHARED BUCKET LIST                     [+ Add Dream]  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ [✓] Watch sunset together at Cox's Bazar         │  │
│  │     Completed on 12 Sep 2026                     │  │
│  │ [ ] Cook homemade pasta from scratch             │  │
│  │     Added by Ayesha                              │  │
│  │ [ ] Stargazing camping trip in Sajek             │  │
│  │     Target: Winter 2026                          │  │
│  └──────────────────────────────────────────────────┘  │
│                                                        │
│ [ Home ]   [ Play ]   [ Memories ] [ Together ] [ 👤 ] │
└────────────────────────────────────────────────────────┘
```

---

### 4.6 Profile & Couple Settings

Manages individual account settings, Duo pairing status, privacy, and subscriptions.

- **Partner Profile Card:** Displays both avatars linked by a pulsing infinity/heart symbol with connection date (*"Connected since 14 February 2026"*).
- **Duo Premium Banner:** Highlights shared access (*"Both of you enjoy ad-free & unlimited memories"*).
- **Destructive Actions:**
  - `"Disconnect Duo"`: Requires confirmation modal with 5-second countdown to prevent accidental unpairing. Explains data archival rules.
  - `"Delete Account"`: Full GDPR-compliant permanent erasure.

---

## 5. Reusable UI Widget Specifications

To maintain consistency and speed up Flutter development, the following shared widgets are standardized in `lib/core/widgets/`:

| Widget Class | Purpose & Parameters | States Supported |
|---|---|---|
| `DuoAppBar` | Standardized header with partner status and notification icon | Default, transparent, custom back action |
| `PartnerAvatarPair`| Overlapping circular avatars with connecting heart badge | Single, paired, offline indicator |
| `MoodCheckinGrid` | 5 expressive animated emoji buttons with label | Idle, selected, partner-view only |
| `DuoCard` | Base elevated card with 20px radius, subtle border & shadow | Default, pressed, elevated, tinted |
| `DuoButton` | Primary coral, secondary lavender, or ghost button with loader | Default, loading, disabled, pressed |
| `AsymmetricBlurBox`| Frosted-glass container hiding answers until unlocked | Locked (blurred), Unlocked (clear) |
| `CountdownTimerCard`| Dynamic countdown ticker showing days/hours/minutes | Active, today celebration, past event |
| `EmptyStateView` | Warm illustration + encouraging message + primary action | Initial load, no memories, offline |

---

## 6. Interaction, Haptics & Animation Guidelines

Micro-interactions must feel alive and affectionate, but never sluggish.

- **Button Press:** Scale down to `0.97` over `100ms`, curve `Curves.easeInOut`.
- **Haptic Feedback:**
  - Mood selection: `HapticFeedback.lightImpact()`
  - Question submission & Game move: `HapticFeedback.mediumImpact()`
  - Error or unpair warning: `HapticFeedback.vibrate()`
- **Celebrations:** Confetti explosion when both answers match or a bucket item is completed (duration `800ms`, dismissible).
- **Reduced Motion:** If device accessibility setting `disableAnimations` is active, instantly transition states without scaling or confetti.

---

## 7. Comprehensive State Matrix

Every screen must explicitly support all fundamental states:

| Screen | Loading State | Empty State | Error / Offline State |
|---|---|---|---|
| **Home** | Skeleton shimmer on mood card & question card | *"Your little world is starting fresh!"* | Offline banner; shows cached mood & prompt |
| **Play** | Shimmer question skeleton | *"Pick a game and challenge your favorite person!"* | Retry button; game state cached locally |
| **Memories** | Envelope outline shimmer | *"Your first love letter is waiting to be written."* | Offline indicator; local drafts saved |
| **Together** | Shimmer countdown cards | *"Add your first shared dream to the bucket list."* | Read-only cached list with sync indicator |

---

## 8. Localization & Cultural Adaptation (Bangladesh First)

- **Supported Locales:** `en` (English) and `bn` (Bangla).
- **Bangla Typography:** Ensure adequate vertical line-height (`1.4x` to `1.5x`) for `Noto Sans Bengali` to prevent clipping of vowel diacritics (*hoshonto*, *akar*, *ikar*).
- **Date & Number Formatting:** Full support for Bengali numerals (`১, ২, ৩...`) via `intl` package when the Bangla locale is selected.
- **Cultural Nuance:** Prompts, questions, and celebration messages tailored to respectful, romantic, and relatable Bangladeshi couple dynamics.

---

## 9. Monetization & Ad Placement Rules

1. **Strictly Sacred Spaces (NO ADS EVER):**
   - Private SecretNote reading or composing.
   - Mood check-in interaction.
   - Onboarding, pairing, and unpairing flows.
   - Between turns in active mini-games.
2. **Acceptable Free-Tier Ad Surfaces:**
   - Small native ad card integrated into the bottom of the Play category browse list.
   - Occasional native banner at the very bottom of the Together tab below completed bucket items.
   - Optional rewarded ad to unlock extra cosmetic game themes or bonus question packs.
3. **Duo Premium Integration:**
   - Complete removal of all ad placements.
   - Unlocked storage for high-resolution photo memories.
   - Exclusive question categories (*Spicy*, *Future Planning*, *Deep Compatibility*).
   - Shared entitlement: **One partner pays, both enjoy Premium.**
