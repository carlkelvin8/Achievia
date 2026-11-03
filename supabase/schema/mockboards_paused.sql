-- Fresh-install contract: DTO id is String, quiz_id is int, page is numeric.
create table public.mockboards_paused (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id),
  quiz_id integer not null,
  current_page double precision not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
-- Do not assume quiz_id refers to quizzes.id: generated mockboard section IDs
-- are also integers. A production mapping must establish the semantic target.
alter table public.mockboards_paused enable row level security;
create policy "Owners manage paused exams" on public.mockboards_paused
  for all to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
