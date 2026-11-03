# Full codebase audit — Achievia

Date: 2026-10-11 (third remediation pass). Scope: the working tree, including
uncommitted changes. Builds on `PRODUCTION_READINESS_AUDIT.md` (2026-09-27)
and re-checks its open items (R01–R13). The deployment runbook is
`STAGING_DEPLOYMENT_CHECKLIST.md`.

**Verdict: not ready for production.** The Flutter code is in good shape
(0 analyzer issues, 628 tests passing, 25 executable SQL check groups). What
remains is staging rehearsal and deployment of reviewed database patches, plus
decisions and credentials that cannot come from the repository. **Everything
is local: nothing was applied to a live Supabase project, committed, pushed,
or promoted into `supabase/migrations/`.**

## 1. Status of this pass

| # | Request | Status | Evidence |
|---|---|---|---|
| 1 | Keep everything local | **Done** | `git log -1` is unchanged (`ee85630`); proposed patches live in `supabase/proposed/`; SQL tests run in a `--network none` container |
| 2 | Time-limit and soft-delete decisions pending | **Pending (held)** | `mock_board_settings.per_subject_minutes` stays `NULL` (not enforced); `20261006100000` + `20261007` stay in `supabase/proposed/`, not applied, not dropped |
| 3 | Redact personal paths in the two evidence files | **Done** | 162 occurrences of the absolute repo path replaced by `<repo>` in `docs/audit-evidence/baseline-tests.txt` and `flutter-tests.txt`; a repo-wide search of `docs`, `scripts`, `supabase`, `test`, `lib` finds no other local path |
| 4 | An attempt without a valid server-recorded start cannot enter the leaderboard | **Done** (not deployed) | `scripts/test_mock_board_grading.py` check 11: never started, started *after* submit (and re-submitted), start recorded by *another* user, and a legacy client insert with score 100 — all excluded from both leaderboards; check 13: with a limit configured a late board is saved but not ranked. Leaderboards filter `server_graded and time_verified` |
| 5 | If the server start is unavailable, say so before the exam starts | **Done** | START EXAM now waits for the server (10 s timeout). If it fails, a dialog "Ranking unavailable" explains the attempt will not be eligible for the leaderboard, with *Cancel / Try again / Continue without ranking*. `test/presentation/widgets/dialogs/ranking_unavailable_dialog_test.dart` (5 tests): the exam does not start before the user decides; try-again records the start and proceeds silently |
| 6 | Server validates the complete expected question set, duplicate ids and the scoring denominator | **Done** (not deployed) | See section 3 |
| 7 | Staging deployment checklist (order, compatibility, force-update, recovery) | **Done** | `docs/STAGING_DEPLOYMENT_CHECKLIST.md`; recovery script tested (check 16) |
| 8 | Do not promote proposed migrations | **Done** | no file moved or added under `supabase/migrations/`; `baseline_manifest.json` untouched |

## 2. Findings resolved so far (cumulative)

| ID | Finding | Resolution | Status |
|---|---|---|---|
| H1 | Mock Board scores were computed on the device | `save_mock_board_attempt` grades on the server; trust columns are not client writable; server numbering, idempotency, section/blueprint validation, start/limit tracking | Implemented + tested; **not deployed** |
| H1b | Rollout would break old app versions | Split into **Phase A** (additive, old builds keep saving but never rank) and **Phase B** (removes the legacy insert after adoption) | Implemented + tested |
| R10 | `max+1` attempt number race | Per-user advisory lock + partial unique index | In Phase A |
| R04 | QOTD question/choice matching | Client fixed earlier; server integrity is patch 20261011 | Client done; patch pending |
| H5 | "Syncfusion needs a license key in code" | **Withdrawn**: v31 has no runtime registration API | Decision only |
| — | Progress / supplementals capped at 1000 rows; raw errors in the UI; unused deps; 25 unreferenced files; Android backup / signing hook | Fixed in earlier passes | Done |

## 3. Server validation of a submitted board (item 6)

All of this is enforced inside `save_mock_board_attempt`; the client sends
only `(section, question_id, selected_choice_id)`.

| Property | How the server decides | Test evidence (`test_mock_board_grading.py`) |
|---|---|---|
| Complete question set | exactly 600 items; exactly 100 per section 1–6 | 599 items → "exactly 600"; a shifted section → "exactly 100" |
| Duplicate question ids | `count(distinct question_id) = 600`, across **all** sections | duplicate in a section and a question reused in another section → "duplicate question" |
| Section ↔ subject | question → quiz → subject title must match the section (same normalisation and matchers as the app; Dart/SQL parity test) | Anatomy question and a Microbiology question inside section 1 → "does not belong to its section" |
| Expected composition | for every topic of the section's subjects the number of submitted questions must equal its configured blueprint count; counts must be configured and add up to 100 | topic 1a given 41 / 1b 59 → "do not match the board blueprint"; a missing or 39-sum count → "blueprint is not configured" |
| Eligibility | every question has ≥ 2 live choices and exactly one correct; not soft deleted | two correct choices, or a single choice → "no single correct choice" |
| Choice belongs to the question | selected id must be a live choice of exactly that question | unknown id and another question's choice → "does not belong to its question" |
| Scoring denominator | fixed `100` per section (`c_per_section`), weights `20/20/20/20/10/10`; never the number of answers received | all-unanswered board = 0.00; one correct answer = 1.00 and GWA 0.20 |

Dependency worth stating plainly: **the blueprint counts must exist**
(`quizzes.configured_question_count`, patch `20261008`). Without them the
app cannot generate a board today, and the server rejects submissions with
"blueprint is not configured".

## 4. Proposed patch verification (PostgreSQL 16, Docker, `--network none`)

| Patch | Result | Dependencies / findings |
|---|---|---|
| `20261006100000` content soft-delete columns | Idempotent | Held for a content-owner decision. No data/policy change; client filtering is a follow-up (file list in its header) |
| `20261007` exam RPC soft delete | Refuses to apply without the columns; with them rejects soft-deleted questions | **As originally written it applied cleanly and then broke every exam save** |
| `20261008` question counts | Idempotent | `20261002`'s schema guard requires the column: apply **before** it if production lacks it |
| `20261010` email sync | Works | Trigger on `auth.users`: staging first |
| `20261011` QOTD integrity | Works (23514 / 23505) | Run the duplicate query first |
| `20261012` exam attempts authoritative | Forged exam rows/items denied; practice and RPC still work | After 20261007 if both are applied |
| `20261013` Phase A | 14 checks incl. 8 parallel submissions → 8 distinct numbers, 8 identical retries → 1 row | After `20261001001000`; needs blueprint counts |
| `20261013100000` Phase B | Legacy insert denied; RPC still saves; history unchanged | Only after the adoption gate (checklist §5) |
| rollback script | Idempotent; no data lost; direct writes and old leaderboard ranking restored | `supabase/reconciliation/rollback_mock_board_server_grading_20261013.sql` |

Order, compatibility matrix, force-update plan and recovery are in
`STAGING_DEPLOYMENT_CHECKLIST.md`.

## 5. Pending, blocked, and open

### Pending (needs only your decision/credentials)

| Item | Needed |
|---|---|
| Final app id | e.g. `com.<org>.achievia` — Android `-PappId=<id>`; iOS `PRODUCT_BUNDLE_IDENTIFIER` (6 places); macOS `AppInfo.xcconfig`; Linux `CMakeLists.txt`; Windows `Runner.rc`; Supabase redirect allowlist |
| Android / Apple signing | keystore + passwords → `android/key.properties` (template provided); Apple team id / provisioning |
| Syncfusion licensing | commercial license, or Community eligibility, or replace `syncfusion_flutter_charts` |
| Staging details | schema export, migration ledger, a staging project |

### Blocked on a product decision

| Item | Why |
|---|---|
| **Exam time limit** | Code: 60 min/subject (`mockBoardSubjectMinutes`, = 6 h). Intro screen text: "2-hour (120-minute)" per subject (= 12 h). The server records the start and enforces whatever `per_subject_minutes` is set to; it is `NULL` until you choose |
| Soft delete of Question Bank content | Approve `20261006100000` + `20261007`, or drop both |

### Open risks (documented, not fixed)

Correct answers remain readable by clients (Study Mode), so a user can look up
answers and a scripted client could start and submit within seconds (no
minimum duration); the app has no minimum-version gate (the checklist uses
Phase A/B instead); inactive users and case-insensitive usernames
(R08/R13); no CI; custom URL scheme instead of App Links;
`search_profiles_for_chat` does not escape `%`/`_`; historical client-written
rows stop ranking after Phase A (they stay in history).

## 6. Untracked files review (153 files; 114 entries when directories are collapsed)

| Group | Count | Findings |
|---|---|---|
| `lib/**` | 37 | All imports resolve; no undeclared package. **26 are imported by already-tracked files** (e.g. `main.dart` → `account_scope.dart`; `onboarding_mockboard_screen.dart` → the new `ranking_unavailable_dialog.dart`), so committing only tracked files breaks the build |
| `test/**` | 59 | 7 are imported by tracked tests; no missing imports |
| `supabase/**` | 28 | migrations 20260930–20261009, `proposed/` (not applied by design), `reconciliation/` (diagnostics + rollback), `schema/` |
| `scripts/**` | 6 | Local-only DB harnesses (no URLs or credentials) |
| `docs/**` | 20 | Audit reports, checklist and `audit-evidence/` (paths redacted) |
| `web/**`, `android/` | 3 | Assets referenced by `web/manifest.json`; `key.properties.example` (template) |

* **Secrets:** pattern scan over all untracked files: none. The only hits are
  prose/negative assertions that mention the word "service_role".
* **Temporary files:** none among the untracked files (`coverage/` was
  deleted and is ignored). Ignored clutter on disk: `%SystemDrive%/`,
  `audit-*.log`, `.kilo/`, `apk/`.
* **`pubspec.lock`:** not ignored (`git check-ignore -v pubspec.lock` exits 1),
  tracked, currently modified.
* **Tracked deletions:** 36 tracked files are deleted in the working tree;
  nothing imports any of them (analyzer clean).

## 7. Test evidence

| Suite | Result |
|---|---|
| `flutter analyze` | 0 issues |
| `flutter test` | 628 passed |
| `scripts/test_mock_board_grading.py` | 16 checks passed |
| `scripts/test_proposed_patches.py` | 9 checks passed |
