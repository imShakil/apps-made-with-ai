# Duo 💗

> **Two people. One little world.**

Duo is a private, playful mobile app designed for two people in a relationship. It gives couples one shared space to connect, play games, exchange private notes, track meaningful moments, and build memories together.

Built with **Flutter** for Android and iOS, with **Supabase** as the backend.

---

## ✨ Overview

Duo is designed for couples who want to stay connected and make everyday interactions more meaningful.

Unlike traditional messaging or social media apps, Duo focuses on a private shared space for exactly two people.

It is not intended to replace WhatsApp or other messaging platforms. Instead, it complements them with relationship-focused activities, games, questions, memories, and shared plans.

### Product principles

- **Private by design:** A Duo space belongs to two connected partners.
- **Simple and playful:** Make everyday interactions enjoyable.
- **Meaningful interactions:** Encourage couples to communicate and participate.
- **Shared experiences:** Build memories and plans together.
- **Freemium:** Essential features remain free, with optional Premium upgrades.

---

## 🎯 Core Features

Duo consists of five feature modules within one mobile application.

### 1. DuoDay — Daily Connection

A daily space for couples to check in and stay connected.

- Daily mood check-ins.
- Share how you are feeling.
- Daily questions.
- Conversation starters.
- Daily activities and prompts.
- Shared timeline and moments.

### 2. TwoTruths — Questions & Quizzes

A playful way to learn more about each other.

- Relationship questions.
- Personality and compatibility quizzes.
- Guess your partner's answers.
- Reveal answers together.
- Scores and game history.
- Different question categories.

### 3. SecretNote — Private Messages

A personal space for sending thoughtful messages.

- Private text notes and letters.
- Note titles and content.
- Read/open status.
- Scheduled messages (planned).
- Voice notes (planned).
- Photo attachments (planned).

### 4. TogetherPlay — Couple Games

Simple games and challenges designed for two players.

- Tic-tac-toe.
- Would You Rather.
- Truth or Dare.
- Word guessing.
- Emoji guessing.
- Drawing challenges.

### 5. OurLittleWorld — Shared Plans & Memories

A shared space for things couples want to do and remember.

- Shared bucket list.
- Upcoming event countdowns.
- Relationship milestones.
- Travel plans.
- Shared goals.
- Habit tracking (planned).

---

## 📱 Navigation Structure

| Navigation | Included features |
|---|---|
| Home | DuoDay |
| Play | TwoTruths, TogetherPlay |
| Memories | SecretNote, shared moments |
| Together | OurLittleWorld |
| Profile | Account, pairing, settings, Premium |

---

## 🛠️ Technology Stack

### Mobile application

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform mobile development |
| Dart | Application programming language |
| Riverpod | State management |
| GoRouter | Navigation and routing |
| Freezed | Immutable models and unions |
| json_serializable | JSON serialization |
| Flutter localization | Bangla and English support |

### Backend & infrastructure

| Technology | Purpose |
|---|---|
| Supabase Auth | Authentication |
| PostgreSQL | Relational database |
| Supabase Realtime | Live synchronization |
| Supabase Storage | Private media storage |
| Supabase Edge Functions | Server-side business logic |
| PostgreSQL RPC | Transactional operations |
| Firebase Cloud Messaging | Push notifications |

### Monetization & analytics

| Technology | Purpose |
|---|---|
| Google AdMob | Mobile advertisements |
| Google Play Billing | Android purchases |
| Apple StoreKit | iOS purchases |
| Firebase Analytics | Product analytics |
| Firebase Crashlytics | Crash reporting |

### Development & delivery

- Git and GitHub
- GitHub Actions
- Flutter DevTools
- Supabase CLI
- Android Studio / VS Code
- Xcode for iOS builds

---

## 🏗️ Project Architecture

Duo follows a **feature-first architecture** with separation between presentation, domain, and data layers.

### Suggested directory structure

```text
duo/
├── android/
├── ios/
├── assets/
│   ├── images/
│   ├── icons/
│   ├── illustrations/
│   └── fonts/
│
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── config/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── routing/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   │
│   ├── shared/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── services/
│   │   └── repositories/
│   │
│   ├── features/
│   │   ├── auth/
│   │   ├── pairing/
│   │   ├── home/
│   │   ├── duoday/
│   │   ├── twotruths/
│   │   ├── secretnote/
│   │   ├── togetherplay/
│   │   ├── ourlittleworld/
│   │   ├── notifications/
│   │   ├── premium/
│   │   └── profile/
│   │
│   └── l10n/
│
├── supabase/
│   ├── migrations/
│   ├── functions/
│   └── seed.sql
│
├── docs/
│   ├── CHANGELOG.md
│   └── TASKS.md
├── test/
├── integration_test/
├── .env.example
├── .gitignore
├── pubspec.yaml
└── README.md
```

Each feature should organize its code into appropriate layers:

```text
feature_name/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── controllers/
    ├── providers/
    ├── screens/
    └── widgets/
```

Keep business rules outside the UI layer. Screens should communicate with controllers or providers, which use repositories to access data.

---

## 🗄️ Backend Data Model

The initial database will use PostgreSQL through Supabase.

| Table | Purpose |
|---|---|
| `users` | User profiles and preferences |
| `duo_spaces` | Shared couple spaces |
| `duo_members` | Members of a Duo space |
| `duo_invitations` | Partner invitation management |
| `mood_checkins` | Daily mood records |
| `daily_questions` | Localized daily questions |
| `question_sessions` | Daily question sessions |
| `question_answers` | Individual answers and guesses |
| `notes` | Private notes and letters |
| `game_sessions` | Couple game sessions and state |
| `bucket_items` | Shared bucket list |
| `countdown_events` | Important dates and events |
| `subscriptions` | Premium entitlement records |
| `notifications` | User notification records |

Additional tables may be introduced for media assets, shared goals, milestones, devices, purchase events, and notification preferences.

---

## 🔐 Security & Privacy

Privacy is a core product requirement.

### Duo membership

- A Duo space supports exactly two active members.
- A user can only access their own active Duo space.
- Membership limits must be enforced at the database level.
- Invitation acceptance must be atomic and protected against concurrent claims.
- Invitation tokens must be high-entropy, expire, and be stored as hashes.

### Database security

- Enable Row Level Security (RLS) on private tables.
- Allow access only to authenticated members of the relevant Duo space.
- Derive user identity from the verified authentication token.
- Never trust client-provided user IDs for authorization.
- Never expose the Supabase service role key in the mobile application.

### Private content

- Keep private media in protected storage buckets.
- Use signed URLs for private media access.
- Revoke access immediately when a member disconnects.
- Ensure re-pairing does not expose previous shared content.
- Avoid exposing private note or mood content in analytics and notification previews.

### Account and data controls

- Account deletion.
- Duo disconnection.
- Privacy settings.
- Appropriate data retention policies.
- Secure purchase verification.

**Note:** Duo should not claim end-to-end encryption unless it has actually been implemented and independently reviewed.

---

## 🔄 Main Application Flows

### Authentication & Pairing

```text
Open App
   |
Sign Up / Sign In
   |
Create Profile
   |
Create a Duo Space
   |
Generate Invitation Link / Code
   |
Partner Opens Invitation
   |
Partner Signs In
   |
Accept Invitation
   |
Duo Space Connected
   |
Home
```

### Daily Interaction

```text
Open Home
   |
View Today's Question
   |
Submit Personal Answer
   |
Wait for Partner
   |
Guess Partner's Answer
   |
Reveal Answers
   |
Save Result
```

### SecretNote

```text
Compose Note
   |
Send to Partner
   |
Partner Receives Notification
   |
Partner Opens Note
   |
Read Status Updated
```

### Premium Purchase

```text
Open Premium
   |
Select Subscription
   |
Complete Store Purchase
   |
Verify Purchase on Backend
   |
Update Duo Entitlement
   |
Premium Available to Both Partners
```

---

## 💰 Monetization Strategy

Duo follows a freemium model.

### Free plan

- Core couple pairing.
- Daily mood check-ins.
- Basic daily questions.
- Basic private notes.
- Selected couple games.
- Basic bucket list and countdowns.
- Non-intrusive advertisements.

### Premium plan

Potential Premium benefits:

- Ad-free experience.
- Premium question collections.
- Additional games and activities.
- More customization options.
- Expanded memory and media storage.
- Additional shared features.

### Initial pricing hypotheses

| Plan | Proposed price |
|---|---:|
| Monthly | ৳99 |
| Annual | ৳799 |
| Lifetime | ৳1,799 |

These are initial pricing hypotheses for validation, not final prices. Pricing should be tested with users and reviewed against platform fees, taxes, and infrastructure costs.

### Advertising guidelines

- Use AdMob for native mobile advertising.
- Never interrupt private notes, mood check-ins, onboarding, or pairing.
- Avoid interstitial advertisements during active gameplay.
- Consider optional rewarded ads for additional non-essential content.
- Premium users should receive an ad-free experience.

Premium entitlement is intended to be shared at the Duo-space level, subject to purchase verification and clear policies for subscription expiry, disconnection, and unpairing.

---

## 🌐 Localization

Initial target market: **Bangladesh**.

Supported languages:

- English (`en`)
- Bangla (`bn`)

Localization should cover:

- UI labels and messages.
- Daily questions.
- Game content.
- Notifications.
- Date and time formatting.
- Onboarding and help content.

Use Inter for English and Noto Sans Bengali for Bangla, with layouts tested for both languages.

---

## 🎨 UI/UX Design Direction

The visual identity should feel warm, modern, playful, and personal without looking childish.

### Brand identity

- Brand name: **duo.**
- Tagline: *Two people. One little world.*
- Personality: Playful, warm, private, and friendly.

### Initial color palette

| Color | Hex | Usage |
|---|---|---|
| Coral Pink | `#FF6B81` | Primary brand color |
| Lavender | `#9B8AFB` | Secondary accent |
| Warm Yellow | `#FFC857` | Highlights |
| Mint | `#8EDCC2` | Positive states |
| Light Background | `#FFF8F7` | Light theme |
| Dark Background | `#191821` | Dark theme |
| Primary Text | `#292633` | Text |

### Design principles

- Rounded cards and soft surfaces.
- Consistent spacing and typography.
- Subtle shadows and gradients.
- Friendly illustrations.
- Purposeful micro-interactions.
- Accessible contrast and touch targets.
- Light and dark themes.

---

## 🚀 Getting Started

### Prerequisites

Install the following:

- Flutter SDK (stable channel).
- Dart SDK (included with Flutter).
- Android Studio or VS Code.
- Xcode for iOS development on macOS.
- A Supabase project.
- Firebase project for push notifications and analytics.

Verify your Flutter installation:

```bash
flutter doctor
```

### 1. Clone the repository

```bash
git clone <YOUR_REPOSITORY_URL>
cd duo
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure environment variables

Create a local environment configuration file using `.env.example` as a reference.

Example:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

Use your project's actual configuration values.

Only public client configuration belongs in the mobile app. Never put service role keys, database passwords, or other privileged secrets in the Flutter application.

### 4. Configure Supabase

Apply database migrations:

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

Deploy Edge Functions when required:

```bash
supabase functions deploy
```

Configure authentication, database policies, storage buckets, and required secrets in Supabase.

### 5. Run the application

```bash
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run -d DEVICE_ID
```

### 6. Generate model files

If using Freezed and json_serializable:

```bash
dart run build_runner build --delete-conflicting-outputs
```

During development:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

---

## 🧪 Testing

Testing should cover application behavior, backend authorization, and critical user journeys.

### Flutter tests

```bash
flutter test
```

### Static analysis

```bash
flutter analyze
```

### Recommended test coverage

- Authentication and session management.
- Duo creation and invitation acceptance.
- Two-member membership enforcement.
- RLS authorization.
- Mood check-ins.
- Question and answer synchronization.
- Private notes and read status.
- Game state recovery.
- Offline and reconnect behavior.
- Purchase verification and entitlement.
- Account deletion and disconnection.

Critical backend security rules should be tested independently of the mobile UI.

---

## 📦 Build & Release

### Android

Build an Android App Bundle:

```bash
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

### iOS

Build for iOS:

```bash
flutter build ipa --release
```

Complete signing, provisioning, and App Store Connect configuration before distribution.

### Release checklist

- [ ] App version and build number updated.
- [ ] Production Supabase configuration verified.
- [ ] RLS policies reviewed and tested.
- [ ] Firebase configuration verified.
- [ ] AdMob production IDs configured.
- [ ] Store purchase verification tested.
- [ ] Privacy policy published.
- [ ] Terms of service published.
- [ ] Account deletion flow tested.
- [ ] Crash reporting enabled.
- [ ] Android and iOS release builds tested.
- [ ] Store listing and screenshots prepared.

---

## 🗺️ Development Roadmap

Development should prioritize the core couple experience before adding advanced features.

| Phase | Scope | Priority |
|---|---|---|
| Phase 1 | Brand, UX, design system, architecture | Foundation |
| Phase 2 | Authentication, profiles, pairing | P0 |
| Phase 3 | DuoDay and daily questions | P0 |
| Phase 4 | TwoTruths and SecretNote | P0 |
| Phase 5 | Basic TogetherPlay games | P1 |
| Phase 6 | OurLittleWorld features | P1 |
| Phase 7 | AdMob and Premium billing | P1 |
| Phase 8 | Beta testing, optimization, release | P0 |

### MVP scope

The first release should focus on:

- Authentication.
- Partner pairing.
- Daily mood check-ins.
- Daily questions.
- Basic answer guessing.
- Private text notes.
- Core privacy controls.
- Push notifications.
- Account deletion.

Advanced features such as voice notes, photo memories, scheduled notes, AI-generated questions, and travel planning can follow after validating the core experience.

---

## 📊 Product Success Metrics

Duo should measure meaningful couple engagement rather than focusing only on downloads.

| Metric | What it measures |
|---|---|
| Weekly Active Pairs | Number of active connected couples |
| Invitation Acceptance Rate | How often invited partners join |
| First Interaction Rate | Couples completing their first activity |
| D7 Retention | Couples returning after seven days |
| D30 Retention | Couples returning after thirty days |
| Module Engagement | Usage across the five modules |
| Premium Conversion | Free pairs upgrading to Premium |
| Revenue per Pair | Average revenue generated per active pair |

Initial closed beta target: **30–50 couples**.

The main product hypothesis is:

> Will two people regularly use one private app to interact, play, and build shared memories?

---

## 🔒 Privacy & Legal

Duo is intended for couples aged 18 and above in its initial release.

Before public launch, prepare:

- Privacy Policy.
- Terms of Service.
- Account deletion policy.
- Data retention policy.
- Subscription and cancellation policy.
- Advertising disclosure.
- Appropriate consent and permissions for notifications and media access.

Follow applicable Google Play and Apple App Store requirements, as well as relevant data protection laws.

---

## 🤝 Contributing

Development conventions:

- Use feature-first architecture.
- Keep business logic separate from UI.
- Follow Dart and Flutter best practices.
- Write tests for critical business logic.
- Use meaningful branch and commit names.
- Never commit secrets or production credentials.
- Review database migrations and RLS changes carefully.

Suggested branch naming:

```text
feature/pairing
feature/daily-mood
feature/secret-notes
feature/couple-games
fix/auth-session
chore/ci-setup
```

Suggested commit format:

```text
feat: add duo pairing flow
fix: resolve invitation acceptance issue
refactor: improve mood check-in repository
test: add note authorization tests
chore: update dependencies
```

---

## 📄 License

License: To be determined.

Do not assume this project is open source until a license has been selected and added to the repository.

---

<p align="center">

**duo.**

*Two people. One little world.* 💗

</p>
