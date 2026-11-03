-- ROLLBACK for supabase/proposed/20261013000000_mock_board_server_grading.sql
-- and 20261013100000_mock_board_lockdown_legacy_insert.sql.
-- Run only against the database those patches were applied to, as a single
-- reviewed script, ideally inside a maintenance window. Idempotent.
--
-- What it restores:
--   * client insert/update/delete on public.quiz_attempts (policies + table
--     privileges exactly as in 20260607000000);
--   * the two leaderboard functions as created by 20261001001000 (they rank
--     every row again, including client written ones);
--   * removes the new functions.
--
-- What it deliberately KEEPS (no data loss): the columns client_attempt_id,
-- server_graded, time_verified, started_at on quiz_attempts, every attempt
-- row, and the tables mock_board_sessions / mock_board_settings. Drop them by
-- hand only after you no longer need the audit trail (commented at the end).
--
-- After rolling back, new app versions keep working: when the RPC is missing
-- they fall back to the legacy insert (PGRST202) and open the exam without a
-- ranking warning, because the restored leaderboards do not need a start.

begin;
set local lock_timeout = '5s';

drop function if exists public.save_mock_board_attempt(uuid, jsonb);
drop function if exists public.start_mock_board_attempt(uuid);
drop function if exists public.mock_board_section_matches(integer, text);
drop function if exists public.mock_board_normalize_title(text);
drop function if exists public.mock_board_configured_count(jsonb);

drop policy if exists "Users can insert their own quiz attempts"
  on public.quiz_attempts;
drop policy if exists "Users can update their own quiz attempts"
  on public.quiz_attempts;
drop policy if exists "Users can delete their own quiz attempts"
  on public.quiz_attempts;

create policy "Users can insert their own quiz attempts"
  on public.quiz_attempts
  for insert
  to authenticated
  with check ((select auth.uid()) = student_id);

create policy "Users can update their own quiz attempts"
  on public.quiz_attempts
  for update
  to authenticated
  using ((select auth.uid()) = student_id)
  with check ((select auth.uid()) = student_id);

create policy "Users can delete their own quiz attempts"
  on public.quiz_attempts
  for delete
  to authenticated
  using ((select auth.uid()) = student_id);

grant insert, update, delete on public.quiz_attempts to authenticated;

-- Leaderboards exactly as 20261001001000 (no trust filter).
create or replace function public.get_weekly_mockboard_achievians(p_limit integer default 10)
returns table (
  profile_id uuid,
  first_name text,
  middle_name text,
  last_name text,
  profile_image text,
  university text,
  purpose text,
  date_of_examination timestamptz,
  average_score numeric,
  best_score numeric,
  attempts_count bigint
)
language sql
security definer
set search_path = public
as $$
  with ranked_attempts as (
    select
      qa.student_id,
      round(avg(qa.score)::numeric, 2) as average_score,
      max(qa.score) as best_score,
      count(*) as attempts_count,
      max(qa.attempted_at) as latest_attempt_at
    from public.quiz_attempts qa
    where qa.attempted_at >= (date_trunc('week', timezone('Asia/Manila', now())) at time zone 'Asia/Manila')
      and qa.attempted_at < ((date_trunc('week', timezone('Asia/Manila', now())) + interval '7 days') at time zone 'Asia/Manila')
    group by qa.student_id
  )
  select
    p.id as profile_id,
    p.first_name::text,
    p.middle_name::text,
    p.last_name::text,
    p.profile_image::text,
    p.university::text,
    p.purpose::text,
    p.date_of_examination,
    r.average_score,
    r.best_score,
    r.attempts_count
  from ranked_attempts r
  join public.profiles p on p.id = r.student_id
  order by r.average_score desc, r.best_score desc, r.attempts_count desc, r.latest_attempt_at asc
  limit least(greatest(coalesce(p_limit, 10), 0), 100);
$$;

create or replace function public.get_monthly_streak_achievians(p_limit integer default 10)
returns table (
  profile_id uuid,
  first_name text,
  middle_name text,
  last_name text,
  profile_image text,
  university text,
  purpose text,
  date_of_examination timestamptz,
  longest_streak integer,
  active_days integer
)
language sql
security definer
set search_path = public
as $$
  with month_attempt_days as (
    select distinct
      qa.student_id,
      timezone('Asia/Manila', qa.attempted_at)::date as attempt_date
    from public.quiz_attempts qa
    where qa.attempted_at >= (date_trunc('month', timezone('Asia/Manila', now())) at time zone 'Asia/Manila')
      and qa.attempted_at < ((date_trunc('month', timezone('Asia/Manila', now())) + interval '1 month') at time zone 'Asia/Manila')
  ), sequenced_days as (
    select
      student_id,
      attempt_date,
      attempt_date - (row_number() over (partition by student_id order by attempt_date))::integer as streak_group
    from month_attempt_days
  ), streaks as (
    select
      student_id,
      count(*)::integer as streak_length
    from sequenced_days
    group by student_id, streak_group
  ), ranked_streaks as (
    select
      md.student_id,
      coalesce(max(s.streak_length), 0)::integer as longest_streak,
      count(distinct md.attempt_date)::integer as active_days
    from month_attempt_days md
    left join streaks s on s.student_id = md.student_id
    group by md.student_id
  )
  select
    p.id as profile_id,
    p.first_name::text,
    p.middle_name::text,
    p.last_name::text,
    p.profile_image::text,
    p.university::text,
    p.purpose::text,
    p.date_of_examination,
    r.longest_streak,
    r.active_days
  from ranked_streaks r
  join public.profiles p on p.id = r.student_id
  order by r.longest_streak desc, r.active_days desc, p.created_at asc
  limit least(greatest(coalesce(p_limit, 10), 0), 100);
$$;

revoke all on function public.get_weekly_mockboard_achievians(integer) from public;
revoke all on function public.get_monthly_streak_achievians(integer) from public;
grant execute on function public.get_weekly_mockboard_achievians(integer) to authenticated;
grant execute on function public.get_monthly_streak_achievians(integer) to authenticated;

notify pgrst, 'reload schema';
commit;

-- Optional, only when the audit trail is no longer needed:
--   drop table if exists public.mock_board_sessions;
--   drop table if exists public.mock_board_settings;
--   alter table public.quiz_attempts
--     drop column if exists client_attempt_id,
--     drop column if exists server_graded,
--     drop column if exists time_verified,
--     drop column if exists started_at;
