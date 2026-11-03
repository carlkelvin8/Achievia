-- Mock Boards / Pre Boards: keep an unfinished exam on the server
--
-- Why: a student can leave a Mock Boards exam and continue it later from the
-- exact subject, question, answers and remaining time. The app keeps that on
-- the device; with this table it is also kept per account on the server, so
-- it survives reinstalling the app, clearing its data or switching phones.
--
-- What it stores (one row per user and kind):
--   * session:  the board as ids only - per section its id, title and
--               subject, and per question its id and the order of its choice
--               ids. The app downloads the question content again from these
--               ids when it continues on another device.
--   * progress: the answers so far (choice index per question), the subject
--               and question on screen and the seconds left on that subject.
-- The row is removed when the exam is submitted.
--
-- The app works without this table (device only) and starts using it once it
-- exists; missing-table errors are ignored by the client.
--
-- Review, then run it as a single statement in staging first.

begin;
set local lock_timeout = '5s';

create table if not exists public.mock_board_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('mock', 'pre')),
  session jsonb check (session is null or jsonb_typeof(session) = 'object'),
  progress jsonb check (progress is null or jsonb_typeof(progress) = 'object'),
  updated_at timestamptz not null default now(),
  primary key (user_id, kind)
);

alter table public.mock_board_progress enable row level security;

drop policy if exists "Owners manage their unfinished exam"
  on public.mock_board_progress;
create policy "Owners manage their unfinished exam"
  on public.mock_board_progress
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

revoke all on public.mock_board_progress from anon;
grant select, insert, update, delete on public.mock_board_progress
  to authenticated;

commit;
