# Changelog — intentional changes

## 2026-11-19 — GetX 4.7.2 → GetX 5 (material_ui-based)

**Why:** GetX 5's GitHub master (`jonataslaw/getx`) migrated fully to
`material_ui`/`cupertino_ui` — zero `flutter/material` imports in its `lib/` —
matching this app's material_ui migration. The pub.dev archive of
`5.0.0-release-candidate-9.3.3` (published ~5 months ago) predates that
migration (still 55 `flutter/material` imports), and no stable 5.x exists on
pub.dev. Master carries the same version string but different code, so the
dependency is pinned to the git commit instead of a pub.dev version.

### Changes
- `pubspec.yaml`: `get: 4.7.2` → git dependency on
  `https://github.com/jonataslaw/getx.git` @
  `a294d2fbfc65856ca1da1bd37e5018e778e8939a` (master HEAD 2026-10-31,
  merge of PR #3472 "fix-flutter-3.47-compatible"; requires Flutter ≥3.47 /
  Dart ≥3.13, `material_ui ^1.8.0`, `cupertino_ui ^1.1.4`).
  Switch to a pub.dev `get: ^5.x` once a post-migration version is published.
- `lib/main.dart`: back to `GetMaterialApp` — in GetX 5 it is material_ui-native
  (its `ThemeData`/`ThemeMode` come from `material_ui`, and it builds
  material_ui's `MaterialApp.router` internally), so the original reason for
  avoiding it (flutter/material type mixing) no longer applies.
  - Removed manual wiring that GetX 5 deleted: `Get.addPages()`,
    `navigatorKey: Get.key`, `navigatorObservers: [GetObserver()]`,
    `onGenerateRoute: PageRedirect(...).page()`. Replaced by
    `getPages: AppRoutes.routes`; `GetObserver` is registered internally.
  - Everything else unchanged: locale ru_RU, localization delegates,
    supportedLocales (ru/en/kk), title, light/dark themes, `themeMode` via
    `Obx` + `ThemeController`, `initialRoute: Routes.main`, debug banner off,
    permanent `Get.put` service registrations in `main()`.
- `lib/routes/app_routes.dart`: `binding: BindingsBuilder(() { Get.lazyPut(...) })`
  → `binds: [Bind.lazyPut(() => CreateAccountController())]` on the
  createAccount route (`BindingsBuilder` was removed in GetX 5; same lazy
  registration semantics).

### Verified
- `flutter pub get` resolves: get `5.0.0-release-candidate-9.3.3` from git
  (resolved-ref matches the pin), material_ui 1.11.1, cupertino_ui 1.1.7.
- Pub-cache git checkout confirmed to import `package:material_ui/material_ui.dart`.
- `flutter analyze`: **0 errors** (50 pre-existing warnings/infos — unchanged
  set; before the upgrade it was 53 issues incl. 3 errors from removed GetX APIs).
- No `package:flutter/material.dart` imports anywhere in app `lib/`.

### Not yet done
- Runtime test on device (flutter run) — navigation, auth middleware redirects,
  theme switching, createAccount controller injection.
- Riverpod migration is paused: no flutter_riverpod dependency, `lib/providers/`
  empty. GetX is retained for now.

## 2026-11-19 — Fix: .env missing from Android APK (Flutter 3.50 regression)

**Symptom:** app hangs at `await dotenv.load()` with
`FileNotFoundError: Environment file ".env" not found`, although `.env` exists
and is listed under `flutter: assets:` in pubspec.yaml.

**Root cause (not the pubspec):** flutter/flutter#196444 — since Flutter 3.50
the Flutter Gradle plugin registers `flutter_assets/` as an AGP assets source
directory; AGP's default `androidResources.ignoreAssetsPattern` contains `.*`,
which drops dotfiles. The AssetManifest still lists `.env`, but the file never
enters the APK, so `rootBundle.loadString('.env')` fails. Android-only.

**Fix:** `android/app/build.gradle` — added inside `android {}`:
`androidResources { ignoreAssetsPattern = "!.svn:!.git:!.ds_store:!*.scc:!CVS:!thumbs.db:!picasa.ini:!*~" }`
(the default pattern minus `.*` and `<dir>_*`; workaround from the upstream
issue). Remove when flutter/flutter#196465 ships in a stable Flutter release.
pubspec.yaml unchanged — it was already correct.

**Verified:** `flutter build apk --debug` succeeds; the APK now contains
`assets/flutter_assets/.env` (354 bytes, byte-identical to the on-disk file).

## 2026-11-20 — Firebase Auth wiring + Firestore ledger (Week 1 → Week 2)

**Why:** Firebase project `tarlan-bank` configured (FlutterFire); migration
plan D7 confirms Firestore as the single ledger. Old Postgres schema audited
and retired as a backend (concepts ported to rules with fixes).

### Changes
- `pubspec.yaml`: + `firebase_auth ^7.1.0`, `cloud_firestore ^7.2.0`
  (7.x generation pairs with the existing `firebase_core ^5.2.0`; 6.x does not).
- `lib/features/auth/data/firebase_auth_repository.dart`: real Auth impl
  (login/register/logout/deleteAccount), profile doc `users/{uid}`,
  best-effort rollback of the Auth account if the profile write fails,
  `phone_index/{E164}` written at registration and cleaned at deletion.
  Provider swapped off `StubAuthRepository` (stub kept for tests).
- `lib/core/errors/firebase_error_mapping.dart`: Firebase exceptions → sealed
  `AppFailure` (moved from features/auth; generic). Credential errors
  deliberately indistinguishable. 11 unit tests.
- `lib/core/firebase/firestore_db.dart`: named-database seam — the DB is
  `tarlan` (europe, Enterprise), NOT `(default)`; all repos use
  `tarlanFirestore()`. `firebase.json` pins `"database":"tarlan"`.
- **Accounts remodel (D8)** — fixes the old model's category errors:
  - `lib/features/accounts/data/account_model.dart`: `Account` with products
    `current`/`deposit`/`credit` (old `'card'` was an instrument, not an
    account type) + per-product `DepositTerms`/`CreditTerms` (rate, term,
    maturity / limit, payment date) for the Node monthly interest job.
    Credit `balance` = outstanding DEBT (positive); `availableCredit` =
    limit − debt; credit is never a transfer source (`isSpendable`).
  - `card_model.dart`: `BankCard` in separate `cards/{id}` — last4 only,
    **no CVV, no full PAN** (old `AccountModel` carried cvv/expiry on every
    account incl. deposits; PCI-DSS forbids CVV storage).
  - `accounts_repository.dart`: interface remodeled; `deleteAccount` /
    `deleteAllAccounts` REMOVED — accounts close via status, never hard-delete.
  - `firestore_accounts_repository.dart`: Firestore impl — doc ID = 16-digit
    number (UNIQUE, collision retry), realtime streams, phone/account lookup,
    card issue/block. First current account links into `phone_index`.
  - `lib/core/utils/phone_number.dart`: E.164 normalization (KZ 7/8 prefixes).
  - `accounts_providers.dart`: repository + realtime accounts/cards providers.
- `firestore.rules`: balance>=0 everywhere; currency+ownership verified on
  BOTH transfer parties via `get()`; transactions create-only (immutable);
  per-product terms validation; key whitelists (no cvv possible); `cards`
  and `phone_index` collections; default deny. Deployed to `tarlan` and
  read back via Rules API (release `cloud.firestore/tarlan`).

### Verified
- `flutter analyze`: 0 errors. `flutter test`: **36/36 pass** (was 7).
- Rules + indexes deployed; live ruleset confirmed to contain the new model.

### Not yet done
- TransactionsRepository Firestore impl (client-transaction transfers).
- Screen migration to ConsumerWidgets; GetX cutover. Old GetX/REST flow
  untouched and still running (additive migration).