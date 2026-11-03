# PRODUCTION READINESS AUDIT

Date: 2026-09-27. Application: Achievia. Audited the current working tree, including the user's pre-existing uncommitted changes.

**Overall Status: NOT READY FOR PRODUCTION**

> **Update 2026-10-11:** R01 and R10 (Mock Board scores and attempt numbering) now have a
> tested server-side fix in `supabase/proposed/20261013000000_mock_board_server_grading.sql` (not deployed).
> R04 is fixed in the client. R03 signing/app-id are prepared but need your credentials/decision. See
> [FULL_AUDIT_2026-10-11.md](FULL_AUDIT_2026-10-11.md) for the current status and remaining blockers.

| Measure | Count |
|---|---:|
| Critical Issues Found | 3 |
| High Issues Found | 7 |
| Medium Issues Found | 19 |
| Low Issues Found | 5 |
| Issues Fixed in source | 23 |
| Issues Remaining in source/configuration | 11 |

Counts refer to the distinct F01–F23 and the 11 remaining R findings below. **Fixed means a local source change, not a deployed production fix.** None of the migrations were applied to the hosted project. Deploying and validating those changes is an additional release gate. Existing compromised roles, exposed messages, or incorrect historical data are not automatically repaired.

## Verification definitions and limits

- **VERIFIED:** the specified test or observation actually ran successfully, within the stated scope.
- **CODE VERIFIED:** inspected implementation; the affected end-to-end behavior was not executed.
- **REQUIRES MANUAL VERIFICATION:** needs deployed schema, credentials, service configuration, or device testing.
- **FAILED:** executed check failed.

This was a repository-wide inventory and risk review with targeted source inspection, local PostgreSQL adversarial tests, Flutter tests, release builds, dependency queries, and limited browser checks. It is not proof that every screen, device, backend policy, historical migration, or failure scenario works. No authenticated hosted test account, production database export, SMTP dashboard, signing credentials, or admin application was supplied. No real payments, hosted writes, destructive hosted tests, or account registrations were performed.

Evidence files are retained in [audit-evidence](audit-evidence/), including final tests, analyzer output, release build logs, SQL regression/replay output, and dependency/anonymous-API scan results.

## Architecture and critical flows

- Flutter 3.38.9 / Dart 3.10.8; `pubspec.yaml` requires Dart ^3.8.1. Riverpod, GoRouter, GetIt/Injectable; data source → repository → use case → provider → widget structure.
- Supabase Flutter 2.12.4 provides Auth, direct PostgREST table/RPC access, and Realtime. There is no separate application HTTP server or Edge Function source in this repository. Database grants, RLS, functions, and constraints are the server security boundary; Dart guards are only client checks.
- Critical flows: registration/profile trigger, password login, email confirmation/recovery OTP, logout/account switching, reviewer/module downloads, QOTD, practice attempts, mock-board generation/submission/results, reminders/goals, progress/leaderboards, chat, notifications, and Pomodoro sessions.
- Roles declared by the schema: USER, ADMIN, TEACHER. No complete admin UI/uploader is present. Content tables and storage configuration partly live outside migration history.
- Storage URLs reference a public `admin` bucket. The application consumes remote files; no upload endpoint or uploader implementation was found here.
- No payment processor, payment webhook, subscription-granting flow, background worker, or application email sender was found. Email is delegated to Supabase Auth. Google login is a visible preview button, not an OAuth implementation.
- Platforms contain Flutter shells for Android, iOS, web, Windows, macOS, and Linux. Only Android/web release builds were executed; iOS/macOS builds require another host/toolchain.

## Executed evidence

| Check | Result | Scope |
|---|---|---|
| Baseline `flutter test` | VERIFIED: 77 passed | Before audit changes |
| Final `flutter test` | VERIFIED: 83 passed | Existing tests plus transport, cache isolation, timer and concurrent-login regressions |
| `flutter analyze` | FAILED quality gate: 45 informational findings | No analyzer errors or warnings; same 45 as baseline; command exits nonzero |
| `flutter build web --release` | VERIFIED | Final release compilation succeeds |
| `flutter build apk --release` | VERIFIED | Final release compilation succeeds; approximately 83.2 MB universal APK; debug signing remains a blocker |
| `python scripts/audit_database.py` | VERIFIED hardening tests; FAILED clean replay | PostgreSQL 16 in network-isolated Docker with an Auth/Realtime schema shim |
| SQL baseline exploits | VERIFIED reproduction | Signup ADMIN injection, own-role update, cross-user paused-exam read |
| SQL hardening regressions | VERIFIED | Role/identity write restrictions, legitimate profile edit, ownership denial, chat membership restrictions, message size, server timestamp/preview, email suppression, unrelated-profile denial, private typing RLS, anonymous denial, module enum visibility, streak calculation |
| Chat concurrency | VERIFIED | Eight simultaneous SQL RPC calls return one conversation ID |
| Chat HTTP contract tests | VERIFIED using mocked HTTP | JSON-object RPC result, newest message page, single transactional send request, oversized body rejection |
| Account isolation test | VERIFIED using provider overrides | Alice → logout → Bob invalidates profile cache; same identity does not |
| Timer regression | VERIFIED | Configured 30-minute timer, countdown, reset and timer disposal |
| npm audit | VERIFIED | Zero reported vulnerabilities in the installed npm graph; npm is only the Supabase CLI toolchain here |
| OSV query | VERIFIED | 200 locked Dart package/version entries queried; no advisories returned; not a native Gradle/CocoaPods/SBOM audit |
| Secret-pattern scan | VERIFIED bounded scan | 522 tracked files scanned for private keys, service-role JWTs and common secret token patterns; no matches; not a full Git-history or high-entropy secret audit |
| Hosted anonymous GETs | VERIFIED observation only | Profiles, tasks, chat_messages, quiz_attempts, mockboards_paused, notifications each returned HTTP 200 with zero rows, using the configured public key and `select=id&limit=1`. Empty results alone do not prove policies are correct or that tables contain protected rows |
| Browser smoke | VERIFIED limited scope | Local release rendered in Codex browser; `/main/profile` redirected to `/login` without login; blank login showed required-field errors; login at desktop/375px, signup at 375px, recovery entry at 768px inspected; no captured warning/error console logs at final observation |
| Entire responsive/device matrix | REQUIRES MANUAL VERIFICATION | No authenticated browser flow, mobile keyboard, real Android device, iOS, Safari, accessibility audit, or full offline/slow-network matrix |

Several original migration tests inspect SQL strings; they do **not** execute RLS. The new SQL harness executes statements as database roles and uses assertions/expected exceptions. Its Auth shim supplies `auth.uid()` from a session setting; it does not exercise JWT signature verification, PostgREST, SMTP, WebSockets, or hosted Supabase administrative controls. Module schema in that harness is explicitly a fixture because the authoritative table creation is missing.

## SECURITY

**Status: NOT READY; local hardening VERIFIED in the specified SQL tests, deployed security REQUIRES MANUAL VERIFICATION.**

Issues found: F01–F07; unresolved R01, R02, R07–R10. Fixes remove client role assignment, cross-user pause access, public message broadcasts, client membership/preview mutation, unrestricted module publication, stale private caches, and unnecessary email payloads. Remaining risks include client-trusted scores, unknown live policies/content schema, inactive profile enforcement, rate limits, and pre-existing access grants. Supabase documents why user metadata cannot be trusted for authorization and why row policies alone do not restrict writable columns: [RLS](https://supabase.com/docs/guides/database/postgres/row-level-security), [column privileges](https://supabase.com/docs/guides/database/postgres/column-level-security).

SQL injection/command execution/SSRF server routes were not found in the client architecture. PostgREST builders are used; HTML widgets are Flutter renderers rather than a server template or arbitrary browser HTML execution endpoint. This does not validate content storage permissions or all remote URLs.

## AUTHENTICATION

**Status: CODE VERIFIED; hosted lifecycle REQUIRES MANUAL VERIFICATION.**

Supabase password login, signup, recovery OTP, session persistence/refresh and logout are wired. Password whitespace is now preserved. Re-entrant auth submissions are guarded. Email confirmation, actual OTP delivery/expiration, disabled/deleted users, refresh/revocation, multiple sessions, and native callbacks have not been exercised against a test account. Recovery expects eight-digit OTPs; align dashboard/email templates. Google OAuth remains a preview (R09). Native app-link handling and allowed redirect URLs must be checked with actual email links. Frontend redirects were tested and are not claimed as server authorization.

## AUTHORIZATION

**Status: VERIFIED for isolated regression cases; full deployment REQUIRES MANUAL VERIFICATION.**

The tests deny own-role escalation, insertion into another user's pause rows, outsider chat reads, third-party membership injection, unauthorized typing channels and ordinary-user module writes. Module RLS denies outsiders access to drafts while preserving active staff access to their own drafts; a published-only invoker-security view filters student lists before pagination. Existing staff roles need review because the old trigger accepted arbitrary signup roles. Profile `status=inactive` is not a general server-wide access gate (R08).

## DATABASE

**Status: FAILED clean migration replay.**

The actual first clean replay failure is `20260601172906_drop_unnecessary_tables.sql`: `table "sessions" does not exist`. Further inspected problems include duplicate `mantra` addition, missing base content tables, destructive historical table drops, and incompatible repeated `mockboards_paused` definitions. Do not fix this by blindly replaying or rewriting production migration history. Capture the deployed schema and migration ledger, then establish a safe baseline and upgrade path. Forward hardening migrations were tested only against explicit local fixtures. Existing duplicates, foreign-key drift, orphan rows, backups, restore capability and query plans remain unverified.

## API

**Status: partially VERIFIED; NOT READY.**

Direct Supabase table operations are the APIs. Owners' IDs are filtered in many clients, and RLS must independently enforce them. Six hosted anonymous GETs returned no rows, but authenticated A/B REST tests were not available. Fixed the chat RPC map/list mismatch and added a 10,000-character database limit. There is no comprehensive server validation/rate-limiting layer for exam submissions, QOTD, study sessions, or content authoring. SQL tests are not claimed as live REST tests. Empty/malformed/oversized/unauthorized cases were covered only where explicitly listed above.

## PAYMENTS

**Status: N/A.** No payment implementation found. No charges performed.

## FRONTEND

**Status: limited browser/widget checks VERIFIED; full UI REQUIRES MANUAL VERIFICATION.**

Fixed latest-chat loading, save-failure navigation, timer defaults/disposal, account cache invalidation, an OTP label and one dark-theme footer. Existing widget tests cover practice selection/results, reminders/progress-related views and supplemental tiles. Browser checks found low-contrast signup/recovery text, subsequently corrected in F22; missing web icon references were corrected in F23. Google login remains a preview. Protected screens, empty/error states throughout the app, keyboard navigation, browser refresh during exams and all phone/tablet orientations are not certified.

## PERFORMANCE

**Status: CODE VERIFIED risks; load/performance acceptance NOT VERIFIED.**

Leaderboard RPCs are capped at 100 results, chat initially loads the latest 100 records, and module filtering precedes ranges. Several other queries load complete tables or default PostgREST windows; large-question sampling, history and progress can truncate or grow poorly (R07). No realistic data-volume benchmark, query EXPLAIN, memory profile, native startup profile or production CDN test was run. Main compiled web JavaScript is approximately 4.8 MB before transfer compression.

## PRODUCTION CONFIG

**Status: NOT READY.**

Android still uses `com.example.achievia` and a debug signing key (R03). macOS outbound networking entitlement is added but needs a macOS runtime check. `lib/const.dart` is tracked despite being listed in `.gitignore`; it contains a publishable client key, not a discovered service secret. Its hard-coded project URL/key need an intentional deployment/configuration process. `.env` patterns are now ignored. There is no production Supabase configuration baseline, documented hosting/header configuration, CI release gate or verified backup/restore setup. No API keys or tokens are reproduced in this report.

## BUILD

**Status: Android/web release compilation VERIFIED; lint gate FAILED.**

The final tests pass. Analyzer's 45 informational naming/deprecation/style findings predate the audit. Broad unrelated style rewrites were avoided. `git diff --check` also reports whitespace in pre-existing user changes; those are not new audit defects. Native Apple/Linux/Windows builds and clean-room code generation/install reproducibility remain unverified.

## Changes made — every local fix

Paths below are relative to the repository. S1 = `supabase/migrations/20261001000000_production_security.sql`; S2 = `supabase/migrations/20261001001000_rpc_privacy_and_streaks.sql`; S3 = `supabase/migrations/20261001002000_module_access.sql`.

| ID / Issue / Severity | Root cause and affected files | Fix applied | Verification / Final status |
|---|---|---|---|
| F01 Privilege escalation — CRITICAL | Signup trigger trusted user metadata; profile RLS allowed every column and deletion/reinsertion. Historical profile migrations; S1 | Signup always creates USER/active without client trial entitlement; revoke client insert/delete/table-wide update; allowlist editable columns | Baseline exploit reproduced and fixed denial/legitimate edit executed in SQL. **VERIFIED locally**, deployment pending |
| F02 Cross-user paused exams — CRITICAL | Legacy `USING(true)` / `WITH CHECK(true)` policy; S1 | Remove legacy policies, enforce `auth.uid()=user_id` on every operation | Baseline cross-account read and post-fix denial/insert rejection executed. **VERIFIED locally** |
| F03 Chat broadcast exposure/spoofing — CRITICAL | Public channels transported trusted client-authored message objects; chat datasource, S1 | Persist/send only through database; subscribe to RLS-filtered Postgres changes; private typing channels with membership RLS | SQL outsider typing/message denial; build and transport tests. **CODE VERIFIED client delivery**, real WebSocket authorization still manual |
| F04 Chat member privilege/preview tampering — HIGH | Members could add arbitrary people or edit conversation identity; S1 | Client membership and conversation writes revoked; atomic trusted direct-chat RPC retained; preview maintained by trigger | Third-party member and conversation mutation denied; eight concurrent direct-chat calls deduplicated. **VERIFIED locally** |
| F05 Draft disclosure and ordinary-user publication — HIGH | Module select allowed all rows; insert/update checked ownership only; S3, module datasource | Published/active text-cast RLS, staff-owned draft access, restrictive staff writes, and published-only invoker-security view before pagination | Enum fixture denies outsider draft access and ordinary-user publication; staff draft read/publish and published-only list pass. **VERIFIED fixture**, live schema/manual admin workflow check required |
| F06 Cross-account cached private state — HIGH | Profile/chat/history/notification providers and local exam date survived identity changes; `account_scope.dart`, `main.dart`, `local_storage_service.dart` | Observe identity changes, invalidate private caches and timers; namespace exam date by account; preserve auth/recovery form lifecycle | Account-switch profile regression passes; other invalidations/key names inspected. **VERIFIED test / CODE VERIFIED broader behavior** |
| F07 Unnecessary email/profile disclosure — HIGH | Security-definer chat search/summaries returned email and arbitrary unrelated profiles; S2 | Keep compatible response shape with null email; exact email lookup only; summaries restricted to self/co-members | SQL email suppression and unrelated-profile denial pass. **VERIFIED locally** |
| F08 Direct-chat creation crashes — MEDIUM | Dart expected a list, SQL returns JSONB object; chat datasource | Decode a map | Mocked HTTP actual-shape regression passes. **VERIFIED** |
| F09 Long chats show oldest messages — MEDIUM | Ascending order followed by limit 100; chat datasource | Query newest page, reverse for chronological display | HTTP ordering/result regression passes. **VERIFIED**; older-history UI still absent |
| F10 Partial message-send failure and load race — MEDIUM | Insert, preview update and broadcast were separate fallible steps; initial load could overwrite arriving events; chat datasource/provider, S1 | Transactional preview trigger, server timestamp/body limit; single client insert; merge loaded/live messages by ID | SQL transaction/timestamp/body tests and single-request transport test pass. Merge inspected. **VERIFIED core / CODE VERIFIED merge** |
| F11 Streak active-day overcount — MEDIUM | Join repeated each day for each streak group; S2 | Count distinct active dates; bound leaderboard result limit | Three dates across two streaks yield 3 active days/2 longest streak. **VERIFIED locally** |
| F12 Ten-second mock exam and timer leaks — MEDIUM | Hard-coded test duration, missing timer disposal; Pomodoro provider | Read configured exam minutes, cancel timers on disposal, initialize subsequent focus-session start times | Configured duration/reset/disposal regression passes. Focus restart inspected. **VERIFIED core / CODE VERIFIED focus restart** |
| F13 Password whitespace mutation — MEDIUM | Login/signup/password change trimmed passwords; auth datasource | Send passwords unchanged | All tests/builds pass; direct implementation inspection, no hosted password lifecycle. **CODE VERIFIED** |
| F14 Missing pause record null crash — MEDIUM | Forced unwrap after `maybeSingle`; questions datasource | Handle null as an empty result | Null branch inspected and builds pass; no live pause fixture. **CODE VERIFIED** |
| F15 Failed exam save navigated to result 0 — MEDIUM | Submission failure returned 0; provider still navigated; questions provider | Remain on exam and show retry message when ID is nonpositive; remove duplicated QOTD fetch | Branch inspected; suite/build pass. **CODE VERIFIED**, failure UX needs integration test |
| F16 Re-entrant auth/chat submissions — MEDIUM | Public notifier methods lacked in-flight checks; auth/reset/chat providers | Early-return while an operation is active | Concurrent login and failed-login retry regression passes; other guards inspected. **VERIFIED login / CODE VERIFIED others**; not server retry idempotency |
| F17 macOS release has no outbound network entitlement — MEDIUM | Sandboxed release omitted network client permission; `macos/Runner/Release.entitlements` | Add outbound network entitlement | XML inspected. **CODE VERIFIED**, macOS build/runtime manual |
| F18 Future .env credential commits — LOW | `.env` patterns absent; `.gitignore` | Ignore `.env` / `.env.*`, allow placeholder example | Patterns inspected; bounded secret scan passes. **CODE VERIFIED** |
| F19 OTP error says six while validating eight — LOW | Mismatched label; reset-password provider | Correct label to eight digits | UI/validator source consistent. **CODE VERIFIED**; dashboard OTP setting manual |
| F20 Dark login footer text unreadable — LOW | Hard-coded black; `placeholder_gesture.dart` | Use theme onSurface text color | Reproduced visually; source fix inspected; build/suite pass. **CODE VERIFIED fix** |
| F21 Timezone-free timestamp writes — MEDIUM | Local ISO strings lacked UTC offset for timestamptz fields; questions/goal/study-session datasources | Serialize attempted/updated/start/end timestamps in UTC; retain local calendar-date fields | Source inspected; build/suite pass. **CODE VERIFIED**, historical shifted rows need review |
| F22 Auth dark-theme contrast - LOW | Fixed foreground colors on dark surfaces or inherited light text on a light card; AuthH1, AuthAppBar, AuthLabel, PasswordResetForm | Use theme foregrounds for dark headers/labels, explicit contrasting recovery-card body and button text; preserve light-theme branding | Browser defect reproduced; updated release inspected. **VERIFIED visually**, not a complete WCAG audit |
| F23 Broken web icon references - LOW | Web index/manifest referenced nonexistent files; web assets/manifest | Reuse existing Android app icon files as favicon and 192px web icon; remove nonexistent manifest entries | Release build and HTTP asset existence verified. **VERIFIED references**, PWA install eligibility not certified |

## Remaining issues and why they are not silently rewritten

| ID | Severity | Finding / evidence | Required resolution |
|---|---|---|---|
| R01 | HIGH | `QuestionsRemoteDatasource.putToAttempt` and question-bank `saveAttempt` accept client-computed scores; answers/correct flags are exposed to the client. Own-row RLS does not establish score truth. Leaderboard data can be fabricated; exam time limits also lack an authoritative server session/deadline. | Define authoritative exam sessions/questions and server grading; submit selected choice IDs, calculate scores and enforce deadlines server-side, restrict direct score writes. Missing authoritative content schema and exam contract prevent a safe drop-in rewrite. |
| R02 | HIGH | Clean migration replay fails; missing content schema and incompatible historical DDL described above. | Export/compare live schema and ledger; establish baseline and non-destructive upgrade tests. Do not deploy by replaying old destructive migrations. |
| R03 | HIGH | Android release is debug-signed and still has example application ID; no verified release environment. | Supply release signing configuration and final package identity; keep keystore credentials outside Git. Verify intended production backend/domain. |
| R04 | MEDIUM | QOTD always chooses the first question; answer lookup is global by choice text; unrelated repeated choice text can save the wrong question. Correctness/IDs and duplicate answers are client-trusted. | Define daily assignment and persist exact question/choice IDs through a server validation/idempotency operation. Current DTO only submits text; this needs coordinated contract/data migration. |
| R05 | MEDIUM | Pause migrations disagree on UUID versus integer quiz IDs; upsert includes empty generated ID/timestamps, lacks an explicit unique conflict target; generated exam lives in memory. | Reconcile actual deployed schema, persist exam snapshot/state, enforce one resume record per intended session and implement refresh/restart recovery. Null handling alone does not repair the flow. |
| R06 | MEDIUM | Raw exception text is rendered/logged in chat, auth, author/supplemental views and other providers; startup initialization has no user-facing failure boundary. | Centralize safe user errors and redacted diagnostic logging; exercise database/service outage and startup failure. Preserve actionable auth messages without leaking raw internals. |
| R07 | MEDIUM | Unbounded/default-window queries in tasks, notifications, progress, question-bank sampling and attempt-number calculation; large IN filters; no realistic scale test. | Add appropriate pagination/aggregates/server sampling with representative data. Avoid arbitrary caps that silently corrupt progress totals. |
| R08 | MEDIUM | `profiles.status='inactive'` is not enforced across owner-table policies/security-definer RPCs. | Define whether inactive means disabled; enforce that centrally or use Supabase Auth banning/revocation and test existing access tokens. |
| R09 | MEDIUM | Visible Google login button only displays “design preview.” | Implement configured OAuth with verified callbacks or explicitly remove/disable the advertised feature. Product/provider choice required. |
| R10 | MEDIUM | Mock attempt number is count+1 without atomic allocation; retries can duplicate quiz/QOTD/study/chat writes. UI in-flight flags do not protect multiple tabs or a lost response after commit. | Add persistent operation/session idempotency keys, unique constraints and transactional server operations. Check existing duplicates before adding constraints. |
| R13 | MEDIUM | Username availability compares lower(trim(username)), but uniqueness is case-sensitive and the preflight check races. | Reconcile existing case-colliding usernames, then enforce normalized uniqueness in the database. Do not auto-rename live users. |

## Manual actions required before release

1. Obtain a staging copy of the authoritative schema, storage policies and migration ledger. Resolve R02; validate all three new forward migrations there in order. Review staff profile changes and any externally managed admin operations affected by the new column grants. The app now depends on the chat trigger and module policies, so coordinate backend-first rollout.
2. Review existing ADMIN/TEACHER assignments and trial values for abuse under the old signup/profile policies. Security hardening cannot determine which historical assignments were legitimate.
3. Enable/verify `chat_messages` in the `supabase_realtime` publication. Ensure the private typing policies apply, remove conflicting permissive Realtime policies, and disable public channel access if unused by other apps. Test two members and an outsider over actual WebSockets; existing old app versions must be retired. See [Realtime authorization](https://supabase.com/docs/guides/realtime/authorization).
4. Finish R01/R04/R05/R10 before treating scores, rankings, daily answers or resumed exams as authoritative. Review existing duplicate/incorrect records using backups and an explicit repair plan.
5. Verify Supabase Auth email confirmation, eight-digit recovery OTP template/expiry, SMTP delivery, rate limits/CAPTCHA, banned/deleted-account behavior, session revocation and refresh. Test registration collisions and network failure. Configure site URL/redirect allowlist for production web and `achievia://callback`; test Android/iOS cold/warm links and Flutter/app_links interaction.
6. Configure release signing, app IDs, production domain/TLS, hosting cache/security headers, environment selection and deployment checks. Keep service-role/admin credentials exclusively in trusted backend/admin infrastructure. The current public client key is not a server secret.
7. Audit the external admin uploader and public `admin` bucket: intended public/private access, ownership, content types, maximum size, malicious filenames, executable content, and retention. This repository cannot verify the absent uploader. Private files should not be passed to an external document viewer without an intentional access/privacy design.
8. Establish backups and a tested restore procedure, monitoring with redaction, database/index/load checks, incident response and account deletion/privacy rules. Review leaderboard names/university/exam-date visibility and chat discovery policy with the product owner.
9. Run staging end-to-end A/B/staff/anonymous REST and WebSocket tests; devices/browsers; refresh/back/multi-tab flows; timezones/DST; slow/offline/network-timeout; expired sessions; deleted resources; unavailable database/email/storage; large/malformed inputs. iOS/macOS/Linux/Windows production builds require their respective toolchains.

## Final checklist

PASS below is restricted to the stated evidence. FAIL means the release gate is unresolved; it does not falsely imply that an unexecuted test ran and failed.

| Gate | Result | Explanation |
|---|---|---|
| Production Build | PASS | Android and web release compilation; signing is separately blocked |
| Critical Bugs | FAIL | Three critical fixes exist locally but are not deployed/verified in the hosted environment |
| Authentication | FAIL | Hosted signup/reset/verification/expiration/disabled-user matrix not executed; Google feature incomplete |
| Authorization | FAIL | Local tests pass, but full live role/RLS/storage validation and inactive-user handling remain |
| Database Integrity | FAIL | Clean replay fails; unknown authoritative schema; scoring/resume/retry integrity unresolved |
| API Security | FAIL | Client-trusted scores/answer values and missing comprehensive validation/rate limits |
| Payment Security | N/A | No payment flow found |
| Input Validation | FAIL | Server grading, answer relationships, duplicate writes and normalized username uniqueness remain |
| Secrets Protection | PASS, bounded | No recognized server-secret patterns in scanned tracked files; public client key is expected; history/dashboard/configuration not certified |
| Error Handling | FAIL | Raw error exposure, swallowed failures and incomplete startup/outage recovery |
| Responsive UI | FAIL | Limited views checked and reported auth contrast defects fixed; full authenticated/device coverage absent |
| Performance | FAIL | Unbounded/default-window queries; no production-volume evidence |
| Dependency Security | PASS, bounded | npm/OSV reported no known findings; native/transitive platform libraries not comprehensively audited |
| Production Configuration | FAIL | Debug signing/example app ID, missing verified schema/deployment/service settings |
| Regression Testing | FAIL as release gate | 83 tests and local SQL regressions pass, but full live auth/API/business-flow/device matrix is incomplete; lint gate still fails |

## Reproducing the local database evidence

Use an isolated disposable container, never a production connection:

```powershell
docker run --detach --name achievia-audit-db --network none -e POSTGRES_HOST_AUTH_METHOD=trust postgres:16-alpine
python scripts/audit_database.py
docker stop achievia-audit-db
```

The harness creates uniquely named test databases in that container. The deliberate clean-replay failure is printed separately from passing hardening assertions; it is an expected audit finding, not a successful migration check. The container used for this audit is stopped after verification and retained for inspection. If it already exists, use `docker start achievia-audit-db` instead of creating it again. Do not run these fixture statements against hosted Supabase.
