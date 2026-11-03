-- PROPOSED PATCH - NOT APPLIED, prepared for review only.
-- (Sorts before 20261007 on purpose: it is that patch's prerequisite.)
--
-- Why: 20261007_exam_rpc_respect_soft_delete.sql reads deleted_at on
-- subjects, quizzes, questions and choices, but no migration or schema file
-- ever creates those columns (mnemonics / abbreviations / procedures have it;
-- see 20261002 which only lists it for those three). Without them that patch
-- now refuses to apply (see its guard) and the app cannot soft delete
-- Question Bank content at all.
--
-- What it does: adds a nullable timestamptz `deleted_at` to the four content
-- tables, plus partial indexes for the "live rows" lookups. It changes no
-- data, no policy and no grant. NULL = live, non-NULL = soft deleted.
--
-- DECISION NEEDED BEFORE PROMOTING (it is a content-owner decision):
--   * Do you want Question Bank content to be soft-deletable? If not, drop
--     this file and 20261007 together.
--
-- What it does NOT do (follow-ups, deliberately separate):
--   1. Hide soft deleted rows from clients. Either add the RLS policy shown
--      at the bottom, or make the app filter `deleted_at is null`:
--        - lib/data/data_source/home/questions_remote_datasource.dart
--          (subjects select list, getLiveQuestionIds, filterEligibleQuestionIds)
--        - lib/core/utils/mock_board_loader.dart (questions / choices selects)
--        - lib/data/data_source/reviewer/question_bank_remote_datasource.dart
--      The helpers already honour the column when a row carries it
--      (isSoftDeleted in lib/core/utils/question_eligibility.dart); the
--      queries just do not select it yet. Do NOT ship those client filters
--      before this migration is applied: selecting a missing column fails.
--   2. Server grading already respects it: save_mock_board_attempt
--      (20261013) ignores rows whose deleted_at is non-NULL via
--      to_jsonb(row) ->> 'deleted_at', so it works before and after.
--
-- Order: this file -> 20261007 -> 20261012 (20261007 re-creates the exam RPC
-- with invoker rights; 20261012 makes it SECURITY DEFINER again).
-- Verified by scripts/test_proposed_patches.py.

begin;
set local lock_timeout = '5s';

alter table public.subjects  add column if not exists deleted_at timestamptz;
alter table public.quizzes   add column if not exists deleted_at timestamptz;
alter table public.questions add column if not exists deleted_at timestamptz;
alter table public.choices   add column if not exists deleted_at timestamptz;

create index if not exists quizzes_live_subject_idx
  on public.quizzes (subject_id) where deleted_at is null;
create index if not exists questions_live_quiz_idx
  on public.questions (quiz_id) where deleted_at is null;
create index if not exists choices_live_question_idx
  on public.choices (question_id) where deleted_at is null;

notify pgrst, 'reload schema';
commit;

-- OPTIONAL, separate review (changes what clients can read). Inspect the
-- existing select policies on these tables first and replace, not add:
-- permissive policies combine with OR, so an old "using (true)" policy would
-- keep exposing deleted rows.
--
--   create policy "Authenticated users read live content"
--     on public.questions for select to authenticated
--     using (deleted_at is null);
--   -- repeat for subjects, quizzes, choices; staff keep access through their
--   -- own policy or the service role.
