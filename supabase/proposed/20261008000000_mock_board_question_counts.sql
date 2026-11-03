-- PROPOSED PATCH - NOT APPLIED, deliberately kept out of supabase/migrations.
--
-- Why: Mock Boards read a per-subtopic question count from public.quizzes
-- (first match of: configured_question_count, question_count,
-- mock_board_question_count, number_of_questions, ...). Production has NONE of
-- these columns, so every Mock Board preparation fails with
-- "<topic> must define a configured question count".
--
-- This patch only adds the column. It deliberately does NOT invent counts:
-- the blueprint (how many of the 100 questions of each section come from each
-- subtopic) is a content decision for the client.
--
-- After applying, set the counts for the live subtopics, e.g. (example values
-- only - replace with the client's blueprint):
--
--   update public.quizzes set configured_question_count = 8  where id = 1207;
--   update public.quizzes set configured_question_count = 12 where id = 1208;
--   ...
--
-- Rules the app enforces (per Mock Board section):
--   * every live subtopic of the section's subjects has a count (0 skips it)
--   * the counts of the section add up to EXACTLY 100
--   * each subtopic has at least that many eligible questions
--     (not deleted, with exactly one live correct choice)
--
-- Read-only validation once counts are set (every row must show ok = true):
--
--   select s.id as subject_id, s.title,
--          count(z.id) filter (where z.configured_question_count is null) as missing,
--          coalesce(sum(z.configured_question_count), 0) as total
--   from public.subjects s
--   left join public.quizzes z on z.subject_id = s.id and z.deleted_at is null
--   where s.deleted_at is null
--   group by s.id, s.title order by s.id;
--   -- sections group several subjects (e.g. Microbiology and Parasitology =
--   -- Bacteriology + Parasitology + Mycology + Virology), so check the SUM
--   -- over the subjects of a section = 100.

begin;

alter table public.quizzes
  add column if not exists configured_question_count integer;

alter table public.quizzes
  drop constraint if exists quizzes_configured_question_count_check;
alter table public.quizzes
  add constraint quizzes_configured_question_count_check
  check (configured_question_count is null or configured_question_count >= 0);

notify pgrst, 'reload schema';
commit;
