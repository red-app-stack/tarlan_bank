<p align="center">
  <a href="https://github.com/red-app-stack/tarlan_bank">
    <img src="assets/images/app_icon.png" alt="Tarlan Bank logo" width="160" />
  </a>
</p>

<h1 align="center">Tarlan Bank</h1>

<p align="center"><b>A bank you actually enjoy using: payments, cards and investing with an AI assistant.</b></p>

<p align="center">
  <a href="README.md"><img src="https://img.shields.io/badge/Language-Русский-green?style=flat-square" alt="Russian" /></a>
  <a href="README.en.md"><img src="https://img.shields.io/badge/Language-English-blue?style=flat-square" alt="English" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.50-02569B?style=flat-square&logo=flutter" alt="Flutter 3.50.1" />
  <img src="https://img.shields.io/badge/Dart-3.14-0175C2?style=flat-square&logo=dart" alt="Dart 3.14.0" />
  <img src="https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?style=flat-square&logo=firebase" alt="Firebase" />
  <img src="https://img.shields.io/badge/Hackathon-2026-7C3AED?style=flat-square" alt="Hackathon 2026" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue?style=flat-square" alt="Apache License 2.0" /></a>
</p>

---

## About

**Tarlan Bank** is a Flutter banking super app: accounts and cards, transfers and payments, exchange rates, an investing section and an AI assistant. It was built for **[Hackathon 2026]** as a prototype bank for a young audience — fast, clear and secure.

> This is a demo prototype, not a real bank: no real money is moved and the data is test data.

---

## Problem and solution (Hackathon 2026)

### Problem

- **Banking apps are painful.** A simple transfer takes too many screens and taps, the UI is cluttered, and the terminology is confusing for beginners.
- **Beginners are afraid to invest.** Inexperience and emotions make people lose money, and investing feels like a club for experts only.
- **People aged 18–35** expect modern, fast services. Convenience and technology matter more to them than old-school banking, yet decent options barely exist.

### Our solution

1. **A bank you enjoy using.** Modern glass UI, light and dark themes, responsive spacing, three languages (Russian, English, Kazakh), short payment and transfer flows — including QR transfers.
2. **Security you can trust.** Firebase Auth (email/password and Google), email verification, mandatory profile completion, access PIN, biometrics and active liveness face verification on the device (ML Kit, video is never stored), Firestore rules and secure storage.
3. **Tarlan Assistant.** Explains cards, payments, deposits and loans in plain language and gives beginners the confidence to take the first step. Replies are streamed over SSE, with a local/remote backend fallback. Next product step: portfolio suggestions matched to the user's goal and risk profile.

**Target audience:** people 18–35 who want to try investing without fear and prefer convenience over traditional banking.

---

## What works in the demo

- **Accounts and cards:** multiple accounts, a starter debit card with a test balance, card details and transaction history.
- **Transfers:** by phone number, between own accounts, to a bank card, via QR code, plus currency conversion.
- **Payments:** utilities, internet, mobile, transport and other services, with payment history (demo-only).
- **Exchange rates** on the home screen and a market overview in the investing section.
- **AI chat** with streamed assistant replies and switchable local/remote backend.
- **Security:** email and Google sign-in, email verification, profile completion, PIN, biometrics, on-device active-liveness face check, re-authentication for sensitive actions.
- **Localization:** Russian, English and Kazakh (`lib/l10n`, `flutter gen-l10n`).

---

## Architecture and stack

Layers: `views` (screens and shared widgets) → `features` (domain data and providers) → `services` / `core` (Firebase, network, security, routing, notifications, themes).

- **Flutter 3.50.1 / Dart 3.14.0**, cross-platform UI (Android, iOS); web and desktop targets are not declared.
- **State and navigation:** `flutter_riverpod` + `go_router` (StatefulShellRoute), a single global `ProviderContainer`.
- **UI:** `material_ui`, `liquid_glass_easy`, `cupertino_ui`, custom themes and reusable widgets in `lib/views/shared`.
- **Backend:** Firebase Auth, Cloud Firestore, Cloud Messaging and local notifications; Firestore rules and indexes live in `firestore.rules` / `firestore.indexes.json`.
- **Chat/AI:** `AiChatRepository` with streamed replies, a Dio-based SSE client and a local/remote fallback channel.
- **Tests:** `flutter test` (unit and widget tests under `test/`).

---

## Install the APK

<details>
<summary><strong>Install an APK from Releases (recommended)</strong></summary>

1. Open the [Releases](https://github.com/red-app-stack/tarlan_bank/releases) page.
2. Download the APK from the latest release.
3. Allow installation from unknown sources in Android settings.
4. Install the APK and launch the app.

</details>

---

## Quick start

Requires Flutter 3.50+ (Dart 3.14+) and a configured Android SDK or simulator.

```bash
git clone https://github.com/red-app-stack/tarlan_bank.git
cd tarlan_bank
flutter pub get
flutter gen-l10n
flutter test
flutter run
```

A full run needs your own Firebase project: add the platform configs (`google-services.json` / `GoogleService-Info.plist`), enable the required sign-in providers and deploy the Firestore rules. The chat backend URL is set through `BANK_API_URL` in `.env`, loaded via `flutter_dotenv`. Without a backend, the rest of the app runs on test Firestore data.

Checks before committing:

```bash
dart format .
flutter analyze
flutter test
```

<details>
<summary><strong>Build your own APK</strong></summary>

```bash
flutter pub get
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`.

</details>

---

## Repository structure

```
lib/
  core/        # routing, providers, Firebase, security, services, themes, localization
  features/    # accounts, auth, chat, exchange, payments, transfers
  services/    # network, storage, notifications, LLM/SSE client
  views/       # screens and reusable widgets
  l10n/        # *.arb translations (ru, en, kk)
test/          # unit and widget tests
.md/CHANGES.md # change log
```

---

## Feedback

Questions and suggestions: open an [Issue](https://github.com/red-app-stack/tarlan_bank/issues) in the repository.

---

## License

Released under the [Apache License 2.0](LICENSE). Attribution: [NOTICE](NOTICE).
