# Database migration inventory

Reviewed 24 pre-existing SQL files plus one new forward migration. Versions below are filename order, not proof of deployment. Two historical files are empty; there are no byte-identical non-empty migrations. Logical duplicates and conflicting definitions are listed explicitly. Original files were not edited.

| Migration | Findings | Fresh-install treatment |
|---|---|---|
| `20260601171702_users.sql` | Drops/recreates profiles CASCADE, loses rows and dependent objects; minimal/full definitions disagree. | Destructive profiles reset; replaced by non-destructive profile definition. |
| `20260601172733_modify_profile.sql` | Adds mantra; guarded columns do not validate existing types; replaces policies/triggers. | Included unchanged in empty-install baseline. |
| `20260601172906_drop_unnecessary_tables.sql` | Unconditional DROP sessions and verification; neither created in history. FIRST replay failure. | Unconditional sessions/verification drops; obsolete and omitted. |
| `20260603003208_add_mantra_table.sql` | Adds profiles.mantra a second time without guard. | Duplicate mantra; included by modify_profile. |
| `20260603011346_add_tasks_table.sql` | DROP tasks CASCADE; UUID then bigint CREATE IF NOT EXISTS in same file silently keeps UUID. | Extract UUID CREATE plus indexes/policies; omit destructive DROP and contradictory bigint CREATE. |
| `20260603011601_add_tasks_table.sql` | Zero-byte duplicate task migration; no schema effect. | Empty no-op. |
| `20260605000000_add_chat_tables.sql` | Depends on profiles UUID; creates three chat tables, policies/triggers. | Included unchanged in empty-install baseline. |
| `20260606000000_add__atler_userid.sql` | Alters modules.user_id before modules exists in history; arbitrary text-to-UUID cast can fail. | Absent modules dependency and unsafe UUID cast; canonical modules uses UUID. |
| `20260606000001_add_chat_person_search.sql` | Requires profiles/chat; replaces direct-chat RPC (DROP function); pg_trgm extension/indexes. | Included unchanged in empty-install baseline. |
| `20260606010000_allow_authenticated_read_choices.sql` | Missing choices silently skips policy; no table created. | Included unchanged in empty-install baseline. |
| `20260607000000_fix_quiz_attempts_student_id_rls.sql` | Legacy student_id rename/add leaves UUIDs unbackfilled; to_jsonb(text) can encode JSON text as string. | Included unchanged in empty-install baseline. |
| `20260607001000_make_quiz_attempt_quiz_id_optional.sql` | Drops all quiz_id FKs, allows null; intentional app writes omit quiz_id. No row drop. | Included unchanged in empty-install baseline. |
| `20260607150148_account_that_have_mockboard_ended.sql` | Paused id UUID, quiz_id UUID, no FKs; later definition incompatible. | UUID quiz_id incompatible with Dart; replaced by canonical paused schema. |
| `20260608033923_account_that_mockboards_paused.sql` | Paused id integer identity, quiz_id integer FK; CREATE IF NOT EXISTS does not reconcile earlier table; same policy name causes duplicate policy error. Missing quizzes dependency. | Integer row id conflicts with DTO and duplicate policy; canonical replacement. |
| `20260610044531_add_token_column_to_resume.sql` | Zero-byte token migration; no token column exists from it. | Empty no-op. |
| `20260707002000_weekly_achievements_and_streak_rpc.sql` | RPCs depend on quiz_attempts/profiles; later replaced by 20261001001000. | Included unchanged in empty-install baseline. |
| `20260814000000_add_question_bank_attempts.sql` | Foreign keys require missing subjects/quizzes tables. | Included unchanged in empty-install baseline. |
| `20260814001000_fix_progress_days_user_id.sql` | Legacy user_id renamed/add UUID without backfill; duplicates may prevent unique index. Resets all policies. | Included unchanged in empty-install baseline. |
| `20260827000000_dynamic_application_data.sql` | Creates six tables; qotd_answers depends on missing questions/quizzes/choices; supplemental_items differs from tables queried by app. | Included unchanged in empty-install baseline. |
| `20260829000000_username_availability.sql` | Username RPC requires profiles.username. | Included unchanged in empty-install baseline. |
| `20260930000000_create_modules_table.sql` | Misleading filename: only policies, no modules CREATE; comment confirms manual enum/table. | Included unchanged in empty-install baseline. |
| `20261001000000_production_security.sql` | Existing audit delta depends on profiles/chat/paused; unguarded new constraint/policies are one-shot (not reentrant). | Included unchanged in empty-install baseline. |
| `20261001001000_rpc_privacy_and_streaks.sql` | Existing audit RPC replacements; same signatures, revised bodies. | Included unchanged in empty-install baseline. |
| `20261001002000_module_access.sql` | Existing audit module policies/view; requires modules.status; security_invoker view requires PG15+; one-shot policies. | Included unchanged in empty-install baseline. |
| `20261002000000_schema_consistency.sql` | NEW: checked forward reconciliation; blocked on unknown/missing/incompatible schema; preserves legacy UUIDs. | Included unchanged in empty-install baseline. |

Normalized LF SHA-256 hashes for every migration are pinned in `supabase/schema/baseline_manifest.json`. The builder rejects changed history or an unreviewed new migration. This detects accidental local drift; these hashes are NOT hosted migration checksums.

## Missing objects / dependency order

`auth.users` and `auth.uid()` come from Supabase. `profiles` precedes tasks/chat/module ownership. Missing content chain: `subjects -> quizzes -> questions -> choices`; `modules`, `mnemonics`, `abbreviations`, and `procedures` reference subjects. Attempts and QOTD follow content. Module policy/view migrations follow modules. Eight content tables have no historical CREATE. There is no app query for a courses table; course_id remains an integer without an invented course FK.

Other destructive or semantic DDL: policy/trigger/function replacements; dropped quiz-attempt foreign keys; legacy column renames and JSON conversion. Policy/function drops are not table-data deletion but can change permissions/dependencies. No obsolete tables need to be dropped for the new baseline.

The repository includes migration versions later than the environment date (2026-09-27). Their filenames do not establish that they are deployed. Reconcile the actual ledger before scheduling any upgrade.
