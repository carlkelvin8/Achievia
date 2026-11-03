-- Pre Boards: one take per student, unlocked 2 weeks before the student's
-- board exam date (profiles.date_of_examination).
--
--   * public.pre_board_claims        one row per student who started Pre Boards
--   * get_pre_board_status()         exam date, whether it was already taken,
--                                    and the server clock (so a wrong phone
--                                    clock cannot unlock it)
--   * claim_pre_board_attempt()      called when the student presses START
--                                    EXAM; rejects when locked, past the exam
--                                    day or already taken, otherwise records
--                                    the claim. Quitting midway keeps it used.
--
-- The unlock window is [exam_date - 14 days, exam_date + 1 day). The exam date
-- is stored as local midnight in UTC, so the window starts at local midnight.
-- The exam itself is graded and saved like a Mock Board.
begin;

create table if not exists public.pre_board_claims (
  student_id uuid primary key references public.profiles(id) on delete cascade,
  claimed_at timestamptz not null default now(),
  exam_date timestamptz
);

alter table public.pre_board_claims enable row level security;

-- Clients may only read their own claim; rows are written by the function.
revoke all on public.pre_board_claims from anon, authenticated;
grant select on public.pre_board_claims to authenticated;

drop policy if exists "Students read their own pre board claim"
  on public.pre_board_claims;
create policy "Students read their own pre board claim"
  on public.pre_board_claims
  for select to authenticated
  using (student_id = (select auth.uid()));

create or replace function public.get_pre_board_status()
returns table (
  exam_date timestamptz,
  used boolean,
  server_now timestamptz
)
language sql
security definer
set search_path = public
as $$
  select
    p.date_of_examination,
    exists (
      select 1 from public.pre_board_claims c where c.student_id = p.id
    ),
    now()
  from public.profiles p
  where p.id = (select auth.uid());
$$;

revoke all on function public.get_pre_board_status() from public;
grant execute on function public.get_pre_board_status() to authenticated;

create or replace function public.claim_pre_board_attempt()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := (select auth.uid());
  v_exam timestamptz;
begin
  if v_uid is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select p.date_of_examination into v_exam
  from public.profiles p where p.id = v_uid;

  if v_exam is null then
    raise exception 'pre_board_no_exam_date' using errcode = 'P0001';
  end if;
  if now() < v_exam - interval '14 days' then
    raise exception 'pre_board_locked' using errcode = 'P0001';
  end if;
  if now() >= v_exam + interval '1 day' then
    raise exception 'pre_board_passed' using errcode = 'P0001';
  end if;

  insert into public.pre_board_claims (student_id, exam_date)
  values (v_uid, v_exam);
exception
  when unique_violation then
    raise exception 'pre_board_already_taken' using errcode = 'P0001';
end;
$$;

revoke all on function public.claim_pre_board_attempt() from public;
grant execute on function public.claim_pre_board_attempt() to authenticated;

commit;

-- To let one student retake it while testing (run as the project owner):
--   delete from public.pre_board_claims where student_id = '<profile uuid>';
