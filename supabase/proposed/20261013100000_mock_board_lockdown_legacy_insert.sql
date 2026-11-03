-- PROPOSED PATCH - NOT APPLIED. Phase B of the Mock Board server grading
-- rollout (see 20261013000000_mock_board_server_grading.sql, Phase A).
--
-- Closes the last client write path to public.quiz_attempts: the legacy
-- column insert that Phase A keeps for app versions that still insert scores
-- directly. After this file clients cannot insert, update or delete attempts
-- at all; only save_mock_board_attempt (SECURITY DEFINER) writes.
--
-- WHEN: only after the app version that calls save_mock_board_attempt has
-- been adopted (see docs/STAGING_DEPLOYMENT_CHECKLIST.md, "Go / no-go for
-- Phase B"). Applying it earlier makes every old app version fail to save a
-- Mock Board ("could not be saved").
--
-- Data: nothing is read, changed or deleted. Rollback:
-- supabase/reconciliation/rollback_mock_board_server_grading_20261013.sql

begin;
set local lock_timeout = '5s';

drop policy if exists "Users can insert their own quiz attempts"
  on public.quiz_attempts;
revoke insert on public.quiz_attempts from anon, authenticated;
-- Also remove the column level grant Phase A created.
revoke insert (quiz_id, student_id, score, attempted_at, answer, no_of_attempt, summary)
  on public.quiz_attempts from authenticated;

notify pgrst, 'reload schema';
commit;
