-- PROPOSED PATCH - NOT APPLIED, deliberately kept out of supabase/migrations.
--
-- Why: the client's MTLE blueprint takes some subjects as ONE pool instead of
-- fixed per-topic counts, e.g. "Mycology: randomly select 2 questions from any
-- of these topics; make sure to include all topics in the pool" (same for
-- Virology). 20261008000000 only has per-topic counts
-- (quizzes.configured_question_count), which cannot express that.
--
-- This patch adds subjects.mock_board_pool_count:
--   * NULL (default): the subject's topics use their own
--     configured_question_count, as before.
--   * N >= 0: every Mock Board takes N questions at random from ANY live topic
--     of the subject; the topics' own configured_question_count is ignored
--     (leave it NULL). N counts toward the section's 100.
--
-- The app (lib/core/utils/questions_helpers.dart mockBoardSectionBlueprint)
-- and save_mock_board_attempt (20261013000000) both read this column through
-- to_jsonb / select *, so either may be deployed first.
--
-- Apply AFTER 20261008000000. Set the values with
-- supabase/reconciliation/set_mock_board_question_counts.sql.

begin;

alter table public.subjects
  add column if not exists mock_board_pool_count integer;

alter table public.subjects
  drop constraint if exists subjects_mock_board_pool_count_check;
alter table public.subjects
  add constraint subjects_mock_board_pool_count_check
  check (mock_board_pool_count is null or mock_board_pool_count >= 0);

notify pgrst, 'reload schema';
commit;
