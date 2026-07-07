create index if not exists quiz_attempts_attempted_at_idx
  on public.quiz_attempts(attempted_at);

create index if not exists quiz_attempts_weekly_leaderboard_idx
  on public.quiz_attempts(student_id, attempted_at, score);

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
  limit greatest(coalesce(p_limit, 10), 0);
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
      count(md.attempt_date)::integer as active_days
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
  limit greatest(coalesce(p_limit, 10), 0);
$$;

revoke all on function public.get_weekly_mockboard_achievians(integer) from public;
revoke all on function public.get_monthly_streak_achievians(integer) from public;

grant execute on function public.get_weekly_mockboard_achievians(integer) to authenticated;
grant execute on function public.get_monthly_streak_achievians(integer) to authenticated;
