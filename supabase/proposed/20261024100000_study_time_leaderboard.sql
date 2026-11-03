-- Top 10 Achievians by Study Time: ranks students by their total accumulated
-- time with the Achievia app open (foreground), replacing the monthly streak
-- leaderboard on the homepage.
--
-- The app sends its foreground time as rows of public.study_sessions with
-- session_type = 'app' (about every 5 minutes and when it goes to the
-- background). Pomodoro rows (session_type 'pomodoro') are not counted again:
-- that time is already inside the app's foreground time.
--
-- Trust: rows are written by the student's own app (RLS: own rows only). To
-- keep the total from being padded:
--   * a trigger only accepts an 'app' row that describes a recent, short
--     stretch (ending no later than now, at most 15 minutes long, started in
--     the last 30 minutes), so time cannot be back-dated or invented in bulk;
--   * the ranking merges overlapping stretches (range_agg), so the same
--     minutes sent twice, or from two phones at once, count once.
-- A student can therefore gain at most real wall-clock time.
--
-- Requires PostgreSQL 14+ (range_agg), which Supabase provides.

begin;

create index if not exists study_sessions_type_user_idx
  on public.study_sessions (session_type, user_id);

create or replace function public.check_app_study_session()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.session_type = 'app' then
    if new.ended_at > now() + interval '2 minutes'
       or new.started_at < now() - interval '30 minutes'
       or new.ended_at - new.started_at > interval '15 minutes' then
      raise exception 'app study time must be a recent stretch of at most 15 minutes'
        using errcode = '22023';
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists check_app_study_session on public.study_sessions;
create trigger check_app_study_session
  before insert or update on public.study_sessions
  for each row execute function public.check_app_study_session();

create or replace function public.get_top_study_time_achievians(p_limit integer default 10)
returns table (
  profile_id uuid,
  first_name text,
  middle_name text,
  last_name text,
  profile_image text,
  university text,
  purpose text,
  date_of_examination timestamptz,
  total_minutes integer
)
language sql
stable
security definer
set search_path = public
as $$
  with merged as (
    select
      s.user_id,
      range_agg(tstzrange(s.started_at, least(s.ended_at, now()))) as spans
    from public.study_sessions s
    where s.session_type = 'app'
      and s.started_at < now()
      and s.ended_at > s.started_at
    group by s.user_id
  ), totals as (
    select
      m.user_id,
      (coalesce(sum(extract(epoch from upper(r) - lower(r))), 0) / 60)::integer
        as total_minutes
    from merged m
    cross join lateral unnest(m.spans) as r
    group by m.user_id
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
    t.total_minutes
  from totals t
  join public.profiles p on p.id = t.user_id
  where t.total_minutes > 0
  order by t.total_minutes desc, p.created_at asc
  limit least(greatest(coalesce(p_limit, 10), 0), 100);
$$;

revoke all on function public.get_top_study_time_achievians(integer) from public, anon;
grant execute on function public.get_top_study_time_achievians(integer) to authenticated;

notify pgrst, 'reload schema';
commit;
