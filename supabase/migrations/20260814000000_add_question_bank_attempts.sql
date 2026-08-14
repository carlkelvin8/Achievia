create extension if not exists "pgcrypto";

create table if not exists public.question_bank_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  subject_id integer not null references public.subjects(id) on delete cascade,
  quiz_id integer not null references public.quizzes(id) on delete cascade,
  correct_answers integer not null check (correct_answers >= 0),
  total_questions integer not null check (total_questions > 0),
  score numeric(5,2) not null check (score between 0 and 100),
  completed_at timestamptz not null default now(),
  check (correct_answers <= total_questions)
);

create index if not exists question_bank_attempts_user_completed_idx
  on public.question_bank_attempts(user_id, completed_at desc);

create index if not exists question_bank_attempts_user_quiz_idx
  on public.question_bank_attempts(user_id, quiz_id);

alter table public.question_bank_attempts enable row level security;

drop policy if exists "Users can read their own question bank attempts"
  on public.question_bank_attempts;
drop policy if exists "Users can insert their own question bank attempts"
  on public.question_bank_attempts;

create policy "Users can read their own question bank attempts"
  on public.question_bank_attempts
  for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert their own question bank attempts"
  on public.question_bank_attempts
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);
