begin;

-- Distinguishes subtopic practice from the official 100-item subject exam
-- ("Take an Exam"). Only subject exams feed Best / Weakest Subject.
-- Existing rows were all created by subtopic practice, so they keep the
-- 'practice' default and stop counting toward subject ranking.
alter table public.question_bank_attempts
  add column if not exists attempt_type text not null default 'practice';

alter table public.question_bank_attempts
  drop constraint if exists question_bank_attempts_attempt_type_check;
alter table public.question_bank_attempts
  add constraint question_bank_attempts_attempt_type_check
  check (attempt_type in ('practice', 'subject_exam'));

-- A subject exam spans many subtopics, so it has no single quiz_id.
alter table public.question_bank_attempts
  alter column quiz_id drop not null;

alter table public.question_bank_attempts
  drop constraint if exists question_bank_attempts_quiz_required_for_practice;
alter table public.question_bank_attempts
  add constraint question_bank_attempts_quiz_required_for_practice
  check (attempt_type = 'subject_exam' or quiz_id is not null);

create index if not exists question_bank_attempts_user_type_subject_idx
  on public.question_bank_attempts(user_id, attempt_type, subject_id);

notify pgrst, 'reload schema';
commit;
