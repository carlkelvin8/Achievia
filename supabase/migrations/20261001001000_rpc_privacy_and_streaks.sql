begin;
create or replace function public.search_profiles_for_chat(
  search_query text,
  result_limit integer default 20
)
returns table (
  id uuid,
  first_name varchar,
  last_name varchar,
  username varchar,
  email varchar,
  profile_image varchar
)
language sql
security definer
set search_path = public
as $$
  select
    p.id,
    p.first_name,
    p.last_name,
    p.username,
    null::varchar as email,
    p.profile_image
  from public.profiles p
  where (select auth.uid()) is not null
    and p.id <> (select auth.uid())
    and length(trim(search_query)) >= 2
    and (
      lower(coalesce(p.username, '')) like '%' || lower(trim(search_query)) || '%'
      or lower(coalesce(p.email, '')) = lower(trim(search_query))
      or lower(coalesce(p.first_name, '')) like '%' || lower(trim(search_query)) || '%'
      or lower(coalesce(p.last_name, '')) like '%' || lower(trim(search_query)) || '%'
    )
  order by
    case
      when lower(coalesce(p.username, '')) = lower(trim(search_query)) then 0
      when lower(coalesce(p.email, '')) = lower(trim(search_query)) then 1
      when lower(coalesce(p.username, '')) like lower(trim(search_query)) || '%' then 2
      when lower(coalesce(p.first_name, '')) like lower(trim(search_query)) || '%' then 3
      else 4
    end,
    p.first_name nulls last,
    p.last_name nulls last,
    p.username nulls last
  limit least(greatest(coalesce(result_limit, 20), 1), 30);
$$;

revoke all on function public.search_profiles_for_chat(text, integer) from public;
grant execute on function public.search_profiles_for_chat(text, integer) to authenticated;

create or replace function public.chat_profile_summaries(profile_ids uuid[])
returns table (
  id uuid,
  first_name varchar,
  last_name varchar,
  username varchar,
  email varchar,
  profile_image varchar
)
language sql
security definer
set search_path = public
as $$
  select
    p.id,
    p.first_name,
    p.last_name,
    p.username,
    null::varchar as email,
    p.profile_image
  from public.profiles p
  where (select auth.uid()) is not null
    and p.id = any(profile_ids)
    and (p.id = (select auth.uid()) or exists (
      select 1 from public.chat_members mine
      join public.chat_members other on other.conversation_id = mine.conversation_id
      where mine.profile_id = (select auth.uid()) and other.profile_id = p.id
    ))
  limit 50;
$$;

revoke all on function public.chat_profile_summaries(uuid[]) from public;
grant execute on function public.chat_profile_summaries(uuid[]) to authenticated;

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

commit;
