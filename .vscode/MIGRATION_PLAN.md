# Tarlan Bank — Migration & Architecture Plan

Status: planning (no code changed yet). Git is the fallback — current working repo is committed.

## 1. Goal & constraints
- **Demo now, production-path later.** Polished enough to pass production checks down the line.
- **~3 weeks**, no rush. Original app built in ~2 weeks; competition winner (2024 2nd, 2025 1st) — aiming higher.
- **Free on low usage.** Scale by swapping backends, not rewriting UI.
- **Backend swappable.** Local AI now → hosted AI API fallback; Firestore now → other backend later.
- **No tests today** → a safety net must come before behaviour changes.
- Preserve existing behaviour screen-by-screen; verify per feature.

## 2. Guiding principles
1. **Every backend behind an interface (repository pattern).** "Swap the backend as we scale" = change one provider implementation, not the UI. (This is kitaphub's strength; reuse its shape.)
2. **Degrade availability, never trust.** Offline = read-only / queued-pending. Never unvalidated money movement.
3. **One ledger.** Firestore is the single source of truth for balances. No parallel Node ledger.
4. **Typed errors, no swallowed failures, no dev code in prod.** These are the polish differentiators.

## 3. Target stack & layout
Stack: **Firebase Auth + Firestore (free Spark) + flutter_riverpod + go_router + material_ui.**
Reference: `N:\Coding\Projects\Flutter\kitaphub` (feature-first, repository pattern, modern Riverpod, go_router shell+redirect).

```
lib/
  core/
    router/        app_router.dart (go_router shell + auth redirect), shell_index_provider.dart
    server/        dio_manager.dart (keep existing), interceptors.dart, ai/ (chat interface + impls)
    theme/         app_theme.dart
    locale/        app_locale.dart
    errors/        app_failure.dart (sealed failure types), logger.dart
  features/
    auth/          data/ (auth_repository.dart), providers/, screens/
    accounts/      data/ (accounts_repository.dart, account_model.dart), providers/, screens/
    transactions/  data/ (transactions_repository.dart, transaction_model.dart), providers/, screens/
    chat/          data/ (ai_chat_repository.dart + local/remote impls), providers/, screens/
    exchange/      data/ (exchange_repository.dart), providers/
    profile/       settings/ ...
  widgets/         shared UI (split the current god-files)
  generated/       l10n
```

Rule: import `material_ui`, never `flutter/material` (avoids the double ThemeData/ThemeMode/Colors conflict).

## 4. Transaction design (DECISION RECORD)
**Chosen:** Firestore = single ledger. Transfers run as client-side Firestore transactions
(read sender + recipient → validate balance → write both atomically, auto-retry on contention),
with security rules enforcing `balance >= 0` and auth-scoped access. Validation logic lives ONLY in
`TransactionsRepository` so it can be lifted to a trusted callable later.

- **Demo impl:** `FirestoreTransactionsRepository` (client transaction + rules). Demo-grade, honestly labeled.
- **Production impl:** `TrustedTransactionsRepository` → callable Cloud Function (Blaze) OR Node callable
  operating on Firestore via Admin SDK. Swap the provider; UI unchanged.

**Rejected alternative — "online → Node validates; offline → direct Firestore writes":**
- A client can force the offline path (block Node / call Firestore directly) → bypasses all validation. The fallback becomes the attack vector.
- Offline writes are bounded only by Firestore rules, which cannot enforce cross-account atomic invariants → overdraw / double-spend.
- Two ledgers (Node + Firestore) → split-brain balances, painful reconciliation.
- **Fix:** offline = read-only / queued-pending; trusted validation never degrades to unvalidated. One ledger (Firestore).

**Offline behaviour:** browse cached accounts/history (Firestore offline persistence). Transfers disabled
or queued as `pending` and validated/synced when the trusted validator is reachable. Never silent unvalidated writes.

## 5. AI design (interface + fallback)
`AiChatRepository` interface, two impls:
- `RemoteAiChat` — hosted AI API. **Reliable default for the demo** (runs without the local PC).
- `LocalAiChat` — existing Node SSE endpoint (`/api/chat/:sessionId`, keep `DioManager.postStream`).
Fallback provider: try local → on timeout/error fall back to remote. This implements "local can't keep up → API".
Node is reused for AI; exchange rates move to a free public rates API cached in Firestore (removes a Node dependency).

## 6. Firestore data model (FINAL — D8)
```
users/{uid}              email, fullName, phoneNumber(E164), role, createdAt, updatedAt
accounts/{number}        ownerId, type(current|deposit|credit), currency, balance>=0,
                         status, createdAt, terms{...} per product
                         deposit terms: annualRate(0..1), termMonths, maturityAt, autoRenew
                         credit terms:  creditLimit, annualRate, termMonths, nextPaymentAt
                         credit balance = outstanding DEBT (positive); available = limit - debt
cards/{cardId}           accountId, ownerId, last4, expiry, holderName, status, label
                         NO CVV / NO full PAN (PCI-DSS); many cards → one current account
transactions/{txId}      fromAccountId?, toAccountId?, fromOwnerId?, toOwnerId?, amount>0,
                         currency, type, status, createdAt, message<=280 — create-only
phone_index/{E164}       uid, accountNumber (first current account) — transfer lookup
exchange_rates/{FROM_TO} rate>0, updatedAt — free-API cache
```
Transfer = Firestore transaction touching the two account docs + one transaction doc atomically.
Node monthly job (Admin SDK, trusted): deposit interest accrual + credit interest/payments.

## 7. Security rules (outline)
- Auth-scoped: a user reads/writes only their own `users/{uid}` and their accounts.
- Accounts: `balance >= 0` invariant on write; owner-only.
- Transactions: owner-of-from-account create; immutable after commit (cancellation = status change via validated path).
- Demo caveat: cross-account atomic sufficiency is enforced by the client transaction, NOT rules → production moves this to a callable. Documented.

## 8. Week-by-week
### Week 1 — Foundation + safety net
- [ ] Restructure to `core/` + `features/` (copy kitaphub shape).
- [ ] go_router skeleton: shell + auth `redirect` (lift kitaphub `app_router.dart` pattern), `ref.onDispose`.
- [ ] Riverpod providers + theme + locale wiring.
- [ ] Firebase Auth replacing custom JWT + OTP (delete `auth_service` token/verification code).
- [ ] Repository interfaces first; `AppFailure` sealed types + logger.
- [ ] Safety net: characterization tests on current API responses + golden screenshots of key screens.

### Week 2 — Features on the new backend
- [ ] Accounts + transactions on Firestore (client transactions, validation isolated in repo).
- [ ] AI chat behind interface with API fallback; exchange rates via free API + Firestore cache.
- [ ] Migrate screens to ConsumerWidget/ConsumerStatefulWidget.
- [ ] Split god-views: chatbot_screen (1123), qr_transfer_screen (904), accounts_screen (725).

### Week 3 — Polish / production-readiness
- [ ] Typed error handling everywhere; remove `print` + swallowed `catch → return null`.
- [ ] `addTestMoney` behind kDebugMode/flavor flag; remove dev-tunnel URLs + hardcoded secrets.
- [ ] Firestore security rules deployed + tested.
- [ ] Unit tests: transaction validation + repositories. Widget tests: critical flows.
- [ ] Accessibility (semantics, contrast, text scaling); full ru/en/kk l10n; loading/empty/error/offline states.
- [ ] Architecture README explaining the seams + scaling path (the "we thought about production" story).

## 9. Production-readiness checklist (the "aim higher" differentiators)
- [ ] No dev/test code reachable in release builds.
- [ ] No secrets/tunnel URLs in source; config via flavor/env.
- [ ] Trusted transaction validation path documented + swappable.
- [ ] Test coverage on money logic + auth.
- [ ] Consistent error/loading/empty/offline UX.
- [ ] Accessibility + localization complete.
- [ ] Security rules reviewed; least-privilege access.
- [ ] Logger (no print); crash/error reporting hook.

## 10. Risks & mitigations
- **No tests + banking logic** → Week 1 safety net BEFORE behaviour changes; migrate feature-by-feature.
- **Scope (re-architecture + backend move) in 3 weeks** → reuse kitaphub patterns; repository seam de-risks backend swap; keep existing DioManager.
- **Demo-grade validation mistaken for production** → explicit decision record (§4) + README; single seam to upgrade.
- **Firebase free-tier daily quotas (50K reads / 20K writes)** → fine for demo; cache reads, batch writes; upgrade path = Blaze.

## 11. Decision log
- D1: Firebase Auth + Firestore + Riverpod + go_router, kitaphub-style. (Matches reference, free, always-on, managed auth.)
- D2: Firestore single ledger; validation behind TransactionsRepository; demo client-transactions → production callable.
- D3: REJECTED online-Node-validate / offline-direct-Firestore-write fallback (bypass + split-brain). Offline = read-only/queued.
- D4: AI behind interface; remote API default for demo, local Node fallback; exchange via free API + cache.
- D5: Supabase noted as alternative for trusted-validation-on-free-tier (Postgres RPC); not chosen — Firebase orientation + kitaphub reuse.
- D6: Cloud Functions are NOT on Spark (official pricing: "Not applicable"); Blaze-only, 2M invocations/mo free. The "Analytics enables Functions" marketing line means integration, not free availability. OPTION: Blaze + callable Function gives *trusted* balance validation at ~$0 on low usage (card + budget alert required). Decide Spark-demo-grade vs Blaze-trusted when wiring Firebase; same repository seam either way.
- D7: **Firestore confirmed as the ledger** (option B) after auditing the old Postgres schema (`Servers/postgresql/init/schema.sql`). Supabase-Postgres (D5) offered trusted validation on free tier but was rejected — Firebase already configured, plan coherence. Old SQL is retired as a backend; its *concepts* were ported to `firestore.rules` with the audit fixes applied:
  - Audit findings (old schema): no FKs anywhere; `users`/`transactions` had NO primary keys; no `balance >= 0`; no atomic transfer path (Node-side validation → double-spend races); `transaction_reference` not UNIQUE (no idempotency); `check_currency_consistency()` existed but was never attached via CREATE TRIGGER and only checked `from_account`; `timestamp without time zone`; phone varchar(10) not unique/E.164; no indexes on history queries; dump contained real bcrypt hash + PII + TEST rows (never commit it).
  - Ports: balance>=0 on every account write; currency+ownership verified on BOTH parties via rules `get()`; transactions create-only (immutable); account number UNIQUE via doc-ID = number; txId client UUID + create-only = idempotency; owner-scoped reads (denormalized fromOwnerId/toOwnerId); composite indexes for history.
  - Demo caveats (documented in rules header): any signed-in user can adjust balances within invariants (rules can't enforce cross-account atomicity/sufficiency — client transaction does); `get` on accounts open to anyone knowing the 16-digit number (recipient lookup), `list` owner-only. Production: callable validator + tighten rules.
- D8: **Accounts remodel.** One `accounts` collection + product discriminator IS industry-standard (account master + product parameters, à la Mambu/Thought Machine); the old breakage was (1) `card` as an account type — cards are instruments → separate `cards/{id}`, last4 only, NO CVV (old model stored cvv on every account incl. deposits), (2) no product terms → `DepositTerms`/`CreditTerms` for the Node monthly interest job (Admin SDK = trusted writer), (3) no product behavior. Credit balance = positive outstanding debt (keeps balance>=0 universal; available = limit − debt; never a transfer source). Accounts close via status, never hard-delete (interface's deleteAccount/deleteAllAccounts removed). `phone_index/{E164}` added for recipient lookup (users reads stay owner-only). DONE: models + FirestoreAccountsRepository + providers + rules deployed/verified; 36/36 tests.

## 12. Week 1 progress (scaffolding — backend-agnostic, additive)
Done (verified: `dart analyze` 0 errors, new files lint-clean; `flutter test` 7/7 pass):
- [x] Added `flutter_riverpod ^3.3.1` + `go_router ^17.3.0`; `flutter pub get` OK.
- [x] `core/errors/app_failure.dart` — sealed failure types (Network/Server/Auth/Validation/NotFound/Unknown).
- [x] `core/logging/app_logger.dart` — `dart:developer` logger (replaces print).
- [x] Repository interfaces reusing existing models: auth, accounts, transactions, ai_chat, exchange.
- [x] `features/auth` — `AuthUser`, `AuthRepository`, `StubAuthRepository` (signed-out, throws AuthFailure), composable providers (`authStateProvider`/`currentUserProvider`/`isLoggedInProvider`).
- [x] `core/router/app_router.dart` — go_router skeleton, declarative auth `redirect`, `refreshListenable`, `ref.onDispose`. TRANSITIONAL: builders bridge to existing GetX screens.
- [x] `core/app.dart` — `TarlanBankApp` (ProviderScope + MaterialApp.router). ADDITIVE: not wired into main.dart yet.
- [x] Safety-net tests: `test/core/app_failure_test.dart`, `test/features/auth/stub_auth_repository_test.dart`.

Notes / gotchas:
- Project pins `sdk: ^3.5.3` → Dart wildcard `(_, _)` params NOT allowed (needs 3.7+); use distinct names. (kitaphub uses newer SDK.)
- Stub auth stream must replay current state to new subscribers (`async* { yield _user; yield* ... }`); a broadcast controller drops constructor-time events. Caught by test.
- Current app still runs on GetX `GetMaterialApp`; cutover to `TarlanBankApp` is the final Week 2 step.

Next (Week 1 remainder / Week 2):
- [x] Wire Firebase Auth (`FirebaseAuthRepository`) once project configured; replace stub provider. DONE: `firebase_auth ^7.1.0` + `cloud_firestore ^7.2.0` (7.x pairs with firebase_core 5.2.0; 6.x does NOT), `auth_error_mapping.dart` (pure, 11 unit tests), provider swapped. `flutter analyze` 0 errors, 18/18 tests pass.
- [x] Firestore model + rules + indexes written (`firestore.rules`, `firestore.indexes.json`, `.firebaserc`, firebase.json firestore section) — see D7.
- [x] Firestore database exists: `tarlan` (europe, Native mode, Enterprise edition w/ auto-indexes) — NOT `(default)`. `firebase.json` pins `"database":"tarlan"`; app-side seam `lib/core/firebase/firestore_db.dart` (`tarlanFirestore()`) — all repos must use it, `FirebaseFirestore.instance` alone hits a nonexistent default. Rules + indexes deployed (`firebase deploy --only firestore:rules,firestore:indexes`); rules read back via Rules API and confirmed ours (release `cloud.firestore/tarlan`). NOTE: named-DB REST `/indexes` list 404s on Enterprise edition; deploy success + auto-indexes cover it. Auth → Email/Password sign-in enabled by user.
- [ ] Characterization tests / goldens for existing screens before behaviour changes.
- [ ] Migrate features to Firestore repos + ConsumerWidgets; upgrade MainScreen to StatefulShellRoute.