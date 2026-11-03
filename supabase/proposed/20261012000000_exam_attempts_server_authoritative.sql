-- PROPOSED PATCH - NOT APPLIED, deliberately kept out of supabase/migrations.
--
-- Closes the forged-exam hole: today any authenticated user can INSERT a
-- `subject_exam` row (any score, no items) straight into
-- question_bank_attempts, bypassing save_subject_exam_attempt's grading.
--
--   * save_subject_exam_attempt becomes SECURITY DEFINER (body unchanged; it
--     already pins search_path and derives the owner from auth.uid()), so it
--     can write attempts and items while clients no longer can;
--   * direct client INSERTs are limited to `practice` attempts;
--   * clients can no longer insert exam attempt items at all.
--
-- Behaviour change: an exam with fewer than 100 usable questions can no longer
-- be saved score-only (the app now treats the refused save as "not recorded").
-- Apply AFTER 20261007000000_exam_rpc_respect_soft_delete.sql, because that
-- patch re-creates the function with default (invoker) rights.
-- Review, then run it as a single reviewed statement.
-- Move to supabase/migrations/ only once approved.

begin;

alter function public.save_subject_exam_attempt(integer, uuid, jsonb)
  security definer;

drop policy if exists "Users can insert their own question bank attempts"
  on public.question_bank_attempts;
create policy "Users can insert their own question bank attempts"
  on public.question_bank_attempts
  for insert
  to authenticated
  with check (
    (select auth.uid()) = user_id
    and attempt_type = 'practice'
    and client_attempt_id is null
  );

drop policy if exists "Users can insert their own exam attempt items"
  on public.question_bank_attempt_items;

notify pgrst, 'reload schema';
commit;
