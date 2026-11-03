# Staging deployment checklist — Mock Board server grading and related patches

Status: **prepared, not executed.** Nothing here has been applied to any
hosted Supabase project, and none of the proposed migrations has been
promoted into `supabase/migrations/`. This is the runbook to rehearse on a
*staging* project first.

Open decisions that this checklist deliberately does **not** assume:
exam time limit (60 vs 120 min per subject), soft delete of Question Bank
content, final application id, signing credentials, Syncfusion licensing, and
the staging project details. Where one of them matters it is marked **[HOLD]**.

## 1. Artifacts

| File | Purpose |
|---|---|
| `supabase/proposed/20261008000000_mock_board_question_counts.sql` | Adds `quizzes.configured_question_count` (blueprint) |
| `supabase/proposed/20261010000000_sync_profile_email.sql` | Keeps `profiles.email` in step with `auth.users` |
| `supabase/proposed/20261011000000_qotd_answer_integrity.sql` | Server derives QOTD `is_correct`, one answer per day |
| `supabase/proposed/20261012000000_exam_attempts_server_authoritative.sql` | Subject-exam attempts only through the grading RPC |
| `supabase/proposed/20261013000000_mock_board_server_grading.sql` | **Phase A**: server grading, start session, trusted leaderboards |
| `supabase/proposed/20261013100000_mock_board_lockdown_legacy_insert.sql` | **Phase B**: removes the legacy client insert |
| `supabase/reconciliation/rollback_mock_board_server_grading_20261013.sql` | Tested rollback for Phase A + B |
| `supabase/proposed/20261006100000_content_soft_delete_columns.sql`, `20261007000000_exam_rpc_respect_soft_delete.sql` | **[HOLD]** soft delete pair |
| `scripts/test_mock_board_grading.py`, `scripts/test_proposed_patches.py` | Local executable tests (Docker, `--network none`) |

## 2. Pre-flight (staging)

Run each step and record the result in the sign-off table (section 9).

1. **Backups**: confirm Point-in-Time Recovery (or a fresh logical backup) and
   note the restore time. Rehearse a restore at least once.
2. **Capture schema + ledger**: run `supabase/reconciliation/inspect_deployed_schema.sql`
   and export `supabase_migrations.schema_migrations`. Confirm which of
   `20260930` … `20261009` are applied. Migrations in `supabase/migrations`
   must be applied first and in order.
3. **Blueprint column** — `select column_name from information_schema.columns
   where table_name = 'quizzes' and column_name = 'configured_question_count';`
   If it is missing, patch `20261008` must run **before** `20261002`
   (that migration's schema guard aborts without it).
4. **Duplicate checks** (each must return 0 rows, otherwise repair by hand):
   ```sql
   -- attempt numbering (index in 20261013 is skipped with a WARNING otherwise)
   select student_id, no_of_attempt, count(*) from public.quiz_attempts
   where no_of_attempt is not null group by 1, 2 having count(*) > 1;
   -- QOTD (index in 20261011 fails otherwise)
   select user_id, question_id, (answered_at at time zone 'Asia/Manila')::date, count(*)
   from public.qotd_answers group by 1, 2, 3 having count(*) > 1;
   ```
5. **Role audit**: list `profiles.role in ('ADMIN','TEACHER')` and confirm each
   is legitimate (old signup trigger accepted client roles).
6. **Local gates** on the exact commit to be deployed:
   `flutter analyze`, `flutter test`, `python scripts/test_mock_board_grading.py`,
   `python scripts/test_proposed_patches.py`.

## 3. Migration order

Promotion means copying the file into `supabase/migrations/` with a real
timestamp **and** updating `supabase/schema/baseline_manifest.json`
(`scripts/build_database_baseline.py` rejects an unknown migration). Do that
only after sign-off; it has not been done.

| Step | Migration | Depends on | Verify after applying | Rollback |
|---|---|---|---|---|
| 0 | pending files in `supabase/migrations` up to `20261009` | ledger from 2.2 | `scripts/audit_database.py`-style assertions on staging | restore backup |
| 1 | `20261008` question counts | none (before `20261002` if column missing) | column exists; **set counts**, then the section totals query below returns 100 for all six sections | `alter table … drop column` is *not* advised once counts are filled |
| 2 | `20261010` email sync | `profiles.email` | change an email in Auth; `profiles.email` follows | `drop trigger on_auth_user_email_changed on auth.users` |
| 3 | `20261011` QOTD integrity | duplicate check 2.4 | answering twice the same Manila day → 23505; foreign choice → 23514 | drop trigger + index |
| 4 | `20261012` exam attempts authoritative | `20261004`, `20261005` | forged `subject_exam` insert → RLS error; a real 100-item exam still saves | re-create the two policies it replaces (originals: `20260814`, `20261005`) and `alter function … security invoker` |
| 5 | **`20261013` Phase A** | steps 1 (counts configured), `20261001001000` | section totals query; the SQL suite's scenarios on staging data; leaderboards empty until trusted attempts exist | `rollback_mock_board_server_grading_20261013.sql` |
| — | *adoption window (section 5)* | | | |
| 6 | **`20261013100000` Phase B** | go/no-go in section 5 | legacy-style insert → permission denied; RPC still saves | rollback script (same file) |
| HOLD | `20261006100000` → `20261007` → `20261012` again | decision on soft delete | `scripts/test_proposed_patches.py` scenarios | drop the columns only if never used |

Section totals query (after step 5, uses the server's own mapping):

```sql
select sec.s as section,
       count(z.id) as topics,
       count(*) filter (where z.configured_question_count is null) as missing,
       coalesce(sum(z.configured_question_count), 0) as total   -- must be 100
from generate_series(1, 6) as sec(s)
join public.subjects s on public.mock_board_section_matches(sec.s, s.title)
join public.quizzes z on z.subject_id = s.id
group by sec.s order by sec.s;
```

Time limit **[HOLD]**: `mock_board_settings.per_subject_minutes` stays `NULL`
(= not enforced) until the 60/120 decision is made.

## 4. App ↔ database compatibility

| App build | Database | Mock Board behaviour |
|---|---|---|
| current store build | before step 5 | unchanged: the device inserts the score |
| current store build | after Phase A | still saves (legacy columns remain insertable); the row is `server_graded = false` and **never ranks**; update/delete are denied |
| current store build | after Phase B | **cannot save** a Mock Board ("could not be saved") → must be updated first |
| new build (this tree) | before step 5 | START EXAM opens the exam with no warning (the start RPC is missing and nothing requires it yet); result is saved through the legacy insert and ranks on the current leaderboards |
| new build | after Phase A / B | server graded; ranks when the server saw the start and (if configured) the time limit was met |
| new build | blueprint counts missing | board cannot be generated (same as today); the server also rejects with "blueprint is not configured" |

Other features: QOTD and subject exams work with old builds after steps 3–4
(the server ignores client `is_correct`; incomplete exams already treat a
refused save as "not recorded").

## 5. Adoption window and force-update plan

Reality check: **the app has no minimum-version gate** (no package-info,
remote config or in-app-update code). The plan therefore relies on Phase A
being backwards compatible and on measuring adoption from the data itself.

1. Bump the version in `pubspec.yaml` (currently `1.0.0+1`) — **[HOLD]** until
   the application id and signing are decided; release the new build to the
   stores and enable an in-app/store update prompt (store-managed immediate
   update on Android; release notes on iOS).
2. Apply Phase A (step 5). Old builds keep working; they just do not rank.
3. Measure adoption from `quiz_attempts` (no analytics SDK is needed):
   ```sql
   select count(*) filter (where server_graded) * 100.0 / nullif(count(*), 0) as pct_new_build,
          count(*) as attempts
   from public.quiz_attempts where attempted_at > now() - interval '14 days';
   -- legacy writers still active in the last 7 days
   select count(distinct student_id) from public.quiz_attempts
   where not server_graded and attempted_at > now() - interval '7 days';
   ```
4. **Go / no-go for Phase B** — all must hold: `pct_new_build >= 95 %` for 14
   days, no legacy writers in the last 7 days (or an accepted exception),
   support/announcement period completed, rollback script rehearsed on staging.
5. If a hard cut-off is required earlier, ship a build with a version gate
   first (needs a decision: remote config table vs store mechanism).

## 6. Staging smoke test (after steps 1–5)

| # | Action | Expected |
|---|---|---|
| 1 | New build, START EXAM with network | exam opens, no warning |
| 2 | Airplane mode, START EXAM | "Ranking unavailable" dialog; Cancel returns; Continue starts an unranked exam |
| 3 | Finish a board | result screen; `quiz_attempts` row has `server_graded = true`, `time_verified = true`, `started_at` set |
| 4 | Same user, submit twice (retry) | one row, same attempt number |
| 5 | Open Leaderboards | the attempt from 3 ranks; the unranked one from 2 does not |
| 6 | Old build on the same database | saves, not ranked; history shows both |
| 7 | Direct REST insert with `server_graded = true` | permission denied |
| 8 | Forged payload (duplicate question / wrong topic counts) via RPC | 22023 error, nothing saved |

## 7. Monitoring (first 72 hours)

```sql
select server_graded, time_verified, count(*) from public.quiz_attempts
where attempted_at > now() - interval '3 days' group by 1, 2;
select count(*) from public.mock_board_sessions
where started_at > now() - interval '3 days';
```
Watch the Postgres log for `blueprint is not configured`, `do not match the
board blueprint` (blueprint drift) and `permission denied for table
quiz_attempts` (old builds after Phase B).

## 8. Recovery

| Situation | Action |
|---|---|
| Phase A causes unexpected errors | run `rollback_mock_board_server_grading_20261013.sql` (idempotent, keeps all data and the new columns); new builds fall back to the legacy insert automatically (PGRST202) and warn the user |
| Users cannot save after Phase B | run the same script (re-creates the insert policy and table grants) while a fix ships |
| "blueprint is not configured" for everyone | counts missing or not summing to 100 per section: fix `configured_question_count` (section totals query) — no migration rollback needed |
| Numbering index was skipped (WARNING) | repair the duplicate `(student_id, no_of_attempt)` rows, then create `quiz_attempts_student_attempt_uidx` by hand |
| Data corruption suspected | restore from PITR to the time noted in 2.1; the patches only add columns/tables/functions, so a restore does not need schema repair |
| Leaderboard looks empty after Phase A | expected until trusted attempts exist; verify with the monitoring query, not by relaxing the filter |

## 9. Sign-off

| Gate | Owner | Done |
|---|---|---|
| Backup + restore rehearsed | | ☐ |
| Ledger/schema captured, history up to `20261009` applied on staging | | ☐ |
| Counts configured; section totals = 100 | | ☐ |
| Steps 1–5 applied on staging; smoke test passed | | ☐ |
| Adoption gate for Phase B decided | | ☐ |
| Time-limit decision (60 vs 120) | | ☐ [HOLD] |
| Soft-delete decision | | ☐ [HOLD] |
| App id / signing / licensing | | ☐ [HOLD] |
