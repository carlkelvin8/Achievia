-- PROPOSED PATCH - NOT APPLIED, deliberately kept out of supabase/migrations.
-- (supabase/schema/baseline_manifest.json pins the migration inventory, so a
--  new file there must also update the manifest; do that when promoting.)
--
-- Makes Mock Board results server-authoritative (audit finding H1 / R01 / R10).
--
-- Today the app computes the GWA on the device and INSERTs it into
-- public.quiz_attempts; the "Users can insert/update/delete their own quiz
-- attempts" policies let any signed-in user write, overwrite or delete any
-- score for their own id, and the weekly / monthly leaderboards rank by it.
--
-- After this patch:
--   * the client sends only WHAT IT ANSWERED (section, question id, chosen
--     choice id); the server reads which choice is correct, computes the six
--     section scores and the weighted GWA, and stores them;
--   * the server validates that every question really belongs to the section
--     it was submitted under (section <-> subject mapping, the same title
--     matching the app uses), that every question is gradable (>= 2 choices,
--     exactly one correct) and that the chosen choice belongs to that
--     question;
--   * the server also validates the board COMPOSITION: exactly 600 distinct
--     questions, exactly 100 per section, and for every topic (quiz) the
--     number of submitted questions equals the configured blueprint count
--     (for a pooled subject, subjects.mock_board_pool_count, the total over
--     all of its topics equals the pool count). The scoring denominator is the fixed 100 per section, never the number
--     of answers the client sent;
--   * clients can no longer update or delete attempts, and can no longer set
--     the trust columns (server_graded, time_verified, started_at,
--     client_attempt_id). Phase A (this file) deliberately KEEPS the legacy
--     column insert so app versions that still insert directly keep working
--     (their rows never rank). Phase B
--     (20261013100000_mock_board_lockdown_legacy_insert.sql) removes it once
--     the new app version is adopted;
--   * the attempt number is allocated under a per-user advisory lock, with a
--     unique index as a backstop (atomic numbering);
--   * the same client_attempt_id always returns the first saved attempt
--     (idempotent retries, no duplicate submissions);
--   * the server records WHEN a board was started (start_mock_board_attempt)
--     and, when a limit is configured, whether the submission arrived inside
--     it (time_verified);
--   * the leaderboards only count rows that are server graded AND time
--     verified. Older client-written rows are untouched: they stay in the
--     owner's history (select policy unchanged) and in progress charts, but
--     never rank.
--
-- TIME LIMIT: 120 minutes per subject, matching the app
-- (mockBoardSubjectMinutes = 120). The allowed time is
-- 6 sections * per_subject_minutes + grace_minutes, measured on the wall clock
-- from the recorded start. NOTE: the app lets a student leave the exam and
-- continue it later (the subject clock pauses), so a board continued after a
-- long break is still saved and graded but is not time_verified, i.e. it does
-- not rank. To disable the check set
--   update public.mock_board_settings set per_subject_minutes = null;
--
-- Residual risk (documented): correct answers are readable by clients (Study
-- Mode needs them), so a user can still look answers up; per-topic question
-- counts of the blueprint are not re-checked here.
--
-- Soft deletes: every lookup below ignores a row only when it has a
-- non-null deleted_at, using to_jsonb(row) ->> 'deleted_at'. That works
-- whether or not the column exists yet (see
-- 20261006100000_content_soft_delete_columns.sql).
--
-- BLUEPRINT PREREQUISITE: the per-topic counts live in
-- public.quizzes.configured_question_count (patch 20261008; the app also
-- accepts the alternative column names listed in
-- mock_board_configured_count below). Without them the app cannot generate a
-- board and this function rejects every submission with "blueprint is not
-- configured" - apply 20261008 and set the counts first.
--
-- PREREQUISITES (verified against supabase/migrations):
--   * public.quiz_attempts(student_id, score, attempted_at, answer, summary,
--     no_of_attempt) exists - 20260607000000 / 20261002000000 guard it.
--   * public.subjects / quizzes / questions / choices exist.
--   * It replaces the two leaderboard functions created in 20261001001000,
--     so apply it AFTER that migration. Independent of the other patches.
--
-- Before running: check existing duplicates, otherwise the numbering index is
-- skipped (a WARNING is raised, nothing fails):
--   select student_id, no_of_attempt, count(*) from public.quiz_attempts
--   where no_of_attempt is not null
--   group by 1, 2 having count(*) > 1;
--
-- Review, then run it as a single reviewed statement in staging first.

begin;
set local lock_timeout = '5s';

-- ---------------------------------------------------------------------------
-- 1. quiz_attempts: trust markers, idempotency key, numbering backstop
-- ---------------------------------------------------------------------------
alter table public.quiz_attempts
  add column if not exists client_attempt_id uuid,
  add column if not exists server_graded boolean not null default false,
  add column if not exists time_verified boolean not null default false,
  add column if not exists started_at timestamptz;

create unique index if not exists quiz_attempts_student_client_attempt_uidx
  on public.quiz_attempts (student_id, client_attempt_id)
  where client_attempt_id is not null;

do $$ begin
  if exists (
    select 1 from public.quiz_attempts
    where no_of_attempt is not null
    group by student_id, no_of_attempt
    having count(*) > 1
  ) then
    raise warning 'quiz_attempts has duplicate (student_id, no_of_attempt) '
      'rows; unique numbering index skipped - repair them, then create '
      'quiz_attempts_student_attempt_uidx by hand';
  else
    create unique index if not exists quiz_attempts_student_attempt_uidx
      on public.quiz_attempts (student_id, no_of_attempt)
      where no_of_attempt is not null;
  end if;
end $$;

-- Phase A: no client update/delete, and clients can no longer write the trust
-- columns. Table-level INSERT is replaced by a column-level grant on exactly
-- the columns the shipped app version writes, so those versions keep working
-- (rows they write have server_graded = false and never rank).
-- History stays readable (select policy and privilege are untouched).
drop policy if exists "Users can update their own quiz attempts"
  on public.quiz_attempts;
drop policy if exists "Users can delete their own quiz attempts"
  on public.quiz_attempts;
revoke insert, update, delete on public.quiz_attempts from anon, authenticated;
grant insert (quiz_id, student_id, score, attempted_at, answer, no_of_attempt, summary)
  on public.quiz_attempts to authenticated;

-- ---------------------------------------------------------------------------
-- 2. Server-recorded start of a board + limit configuration
-- ---------------------------------------------------------------------------
create table if not exists public.mock_board_sessions (
  user_id uuid not null references auth.users(id) on delete cascade,
  client_attempt_id uuid not null,
  started_at timestamptz not null default now(),
  primary key (user_id, client_attempt_id)
);
alter table public.mock_board_sessions enable row level security;
revoke all on public.mock_board_sessions from anon, authenticated;

create table if not exists public.mock_board_settings (
  singleton boolean primary key default true check (singleton),
  -- NULL = limit not enforced yet (decision pending, see header).
  per_subject_minutes integer check (per_subject_minutes > 0),
  grace_minutes integer not null default 15 check (grace_minutes >= 0)
);
alter table public.mock_board_settings enable row level security;
revoke all on public.mock_board_settings from anon, authenticated;
insert into public.mock_board_settings (singleton, per_subject_minutes)
  values (true, 120)
  on conflict do nothing;

create or replace function public.start_mock_board_attempt(
  p_client_attempt_id uuid
) returns timestamptz
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_started timestamptz;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if p_client_attempt_id is null then
    raise exception 'client attempt id is required' using errcode = '22023';
  end if;

  -- Housekeeping: abandoned boards do not accumulate.
  delete from public.mock_board_sessions
  where user_id = v_uid and started_at < now() - interval '7 days';

  -- The first start wins; calling again never moves the clock.
  insert into public.mock_board_sessions (user_id, client_attempt_id)
  values (v_uid, p_client_attempt_id)
  on conflict (user_id, client_attempt_id) do nothing;

  select started_at into v_started
  from public.mock_board_sessions
  where user_id = v_uid and client_attempt_id = p_client_attempt_id;
  return v_started;
end;
$$;

revoke all on function public.start_mock_board_attempt(uuid) from public, anon;
grant execute on function public.start_mock_board_attempt(uuid)
  to authenticated;

-- ---------------------------------------------------------------------------
-- 3. Section <-> subject mapping (mirror of mockBoardSectionSpecs in
--    lib/core/utils/questions_helpers.dart; keep both in sync)
-- ---------------------------------------------------------------------------
create or replace function public.mock_board_normalize_title(p_title text)
returns text
language sql
immutable
set search_path = public
as $$
  select btrim(regexp_replace(
    regexp_replace(
      lower(replace(replace(coalesce(p_title, ''), '&', ' and '), '/', ' ')),
      '[^a-z0-9]+', ' ', 'g'),
    '\s+', ' ', 'g'));
$$;

create or replace function public.mock_board_section_matches(
  p_section integer,
  p_title text
) returns boolean
language plpgsql
immutable
set search_path = public
as $$
declare
  v_title text := public.mock_board_normalize_title(p_title);
  v_matchers text[];
  v_matcher text;
begin
  v_matchers := case p_section
    when 1 then array['clinical chemistry']
    when 2 then array[
      'microbiology parasitology', 'microbiology and parasitology',
      'bacteriology', 'parasitology', 'mycology', 'virology']
    when 3 then array['clinical microscopy']
    when 4 then array['hematology']
    when 5 then array[
      'blood banking serology', 'blood banking and serology',
      'blood banking', 'immunology serology', 'immunology and serology',
      'serology', 'immunohematology']
    when 6 then array[
      'histopathology medical technology laws ethics',
      'histopathology medical technology laws and ethics',
      'histopathology', 'histopath', 'medtech laws',
      'medical technology laws', 'medical technology laws ethics',
      'medical technology laws and ethics', 'laws ethics']
    else null
  end;
  if v_matchers is null then
    return false;
  end if;
  -- Immunohematology belongs to Blood Banking, not to Hematology.
  if p_section = 4 and position('immunohematology' in v_title) > 0 then
    return false;
  end if;
  foreach v_matcher in array v_matchers loop
    if position(v_matcher in v_title) > 0 then
      return true;
    end if;
  end loop;
  return false;
end;
$$;

-- Mirror of _readConfiguredQuestionCount in questions_helpers.dart: the first
-- of these keys holding a whole number wins. Works on to_jsonb(quizzes row),
-- so it does not matter which of the columns exist.
create or replace function public.mock_board_configured_count(p_quiz jsonb)
returns integer
language plpgsql
immutable
set search_path = public
as $$
declare
  v_key text;
  v_value text;
begin
  foreach v_key in array array[
    'configured_question_count', 'configuredQuestionCount',
    'question_count', 'questionCount',
    'mock_board_question_count', 'mockBoardQuestionCount',
    'number_of_questions', 'numberOfQuestions'
  ] loop
    v_value := btrim(coalesce(p_quiz ->> v_key, ''));
    if v_value ~ '^[0-9]{1,9}$' then
      return v_value::integer;
    end if;
  end loop;
  return null;
end;
$$;

revoke all on function public.mock_board_configured_count(jsonb)
  from public, anon;
revoke all on function public.mock_board_normalize_title(text)
  from public, anon;
revoke all on function public.mock_board_section_matches(integer, text)
  from public, anon;

-- ---------------------------------------------------------------------------
-- 4. Grading
-- ---------------------------------------------------------------------------
-- p_items = [{"section": 1..6, "question_id": int,
--             "selected_choice_id": int | null}, ...]   (exactly 600 items,
--             100 per section, 600 different questions)
-- Question/choice correctness, scores and the GWA are computed here; any other
-- client supplied field is ignored. Returns the attempt number.
create or replace function public.save_mock_board_attempt(
  p_client_attempt_id uuid,
  p_items jsonb
) returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  c_sections constant integer := 6;
  c_per_section constant integer := 100;
  c_total constant integer := 600;
  c_titles constant text[] := array[
    'Clinical Chemistry',
    'Microbiology and Parasitology',
    'Clinical Microscopy',
    'Hematology',
    'Blood Banking and Serology',
    'Histopathology and Medical Technology Laws/Ethics'
  ];
  c_weights constant integer[] := array[20, 20, 10, 20, 20, 10];
  v_uid uuid := auth.uid();
  v_existing integer;
  v_distinct integer;
  v_good_sections integer;
  v_missing integer;
  v_wrong_section integer;
  v_bad_pick integer;
  v_ungradable integer;
  v_unconfigured integer;
  v_composition integer;
  v_answer jsonb;
  v_gwa numeric;
  v_no integer;
  v_started timestamptz;
  v_limit integer;
  v_grace integer;
  v_time_ok boolean;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if p_client_attempt_id is null then
    raise exception 'client attempt id is required' using errcode = '22023';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception 'items must be a json array' using errcode = '22023';
  end if;
  if jsonb_array_length(p_items) <> c_total then
    raise exception 'a completed mock board has exactly % items', c_total
      using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_items) as i
    where jsonb_typeof(i) is distinct from 'object'
       or jsonb_typeof(i -> 'section') is distinct from 'number'
       or jsonb_typeof(i -> 'question_id') is distinct from 'number'
       or coalesce(jsonb_typeof(i -> 'selected_choice_id'), 'null')
            not in ('number', 'null')
  ) then
    raise exception 'malformed item' using errcode = '22023';
  end if;

  -- Serialize this user's submissions: numbering and the retry check below
  -- are race free, and a double tap cannot create two attempts.
  perform pg_advisory_xact_lock(
    hashtextextended('mock_board_attempt:' || v_uid::text, 0));

  select no_of_attempt into v_existing
  from public.quiz_attempts
  where student_id = v_uid and client_attempt_id = p_client_attempt_id;
  if found then
    return v_existing;
  end if;

  with req as (
    select
      (i ->> 'section')::integer as section,
      (i ->> 'question_id')::integer as question_id,
      nullif(i ->> 'selected_choice_id', '')::integer as selected_choice_id
    from jsonb_array_elements(p_items) as i
  ),
  res as (
    select
      r.section,
      r.question_id,
      r.selected_choice_id,
      exists (
        select 1 from public.questions q
        where q.id = r.question_id
          and (to_jsonb(q) ->> 'deleted_at') is null
      ) as q_exists,
      -- the question's subject must be the one mapped to this section
      exists (
        select 1
        from public.questions q
        join public.quizzes z on z.id = q.quiz_id
        join public.subjects s on s.id = z.subject_id
        where q.id = r.question_id
          and (to_jsonb(q) ->> 'deleted_at') is null
          and (to_jsonb(z) ->> 'deleted_at') is null
          and (to_jsonb(s) ->> 'deleted_at') is null
          and public.mock_board_section_matches(r.section, s.title)
      ) as in_section,
      (select count(*) from public.choices c
        where c.question_id = r.question_id
          and (to_jsonb(c) ->> 'deleted_at') is null) as n_choices,
      (select count(*) from public.choices c
        where c.question_id = r.question_id and c.is_correct
          and (to_jsonb(c) ->> 'deleted_at') is null) as n_correct,
      -- null when the pick is not a live choice of exactly this question
      (select c.is_correct from public.choices c
        where c.id = r.selected_choice_id
          and c.question_id = r.question_id
          and (to_jsonb(c) ->> 'deleted_at') is null) as picked_correct
    from req r
  ),
  per_section as (
    select
      section,
      count(*) as n,
      count(*) filter (where picked_correct is true) as correct
    from res
    group by section
  )
  select
    (select count(distinct question_id) from req),
    (select count(*) from per_section
      where section between 1 and c_sections and n = c_per_section),
    (select count(*) from res where not q_exists),
    (select count(*) from res where q_exists and not in_section),
    (select count(*) from res
      where selected_choice_id is not null and picked_correct is null),
    (select count(*) from res
      where q_exists and (n_choices < 2 or n_correct <> 1)),
    (select coalesce(jsonb_agg(
              jsonb_build_object(
                'is_correct', s.correct > 0,
                'name', c_titles[s.section],
                'score', round(s.correct * 100.0 / c_per_section, 2))
              order by s.section), '[]'::jsonb)
       from per_section s where s.section between 1 and c_sections)
  into v_distinct, v_good_sections, v_missing, v_wrong_section, v_bad_pick,
       v_ungradable, v_answer;

  if v_distinct <> c_total then
    raise exception 'duplicate question in mock board' using errcode = '22023';
  end if;
  if v_good_sections <> c_sections then
    raise exception 'each of the % sections needs exactly % questions',
      c_sections, c_per_section using errcode = '22023';
  end if;
  if v_missing > 0 then
    raise exception 'every question must exist' using errcode = '22023';
  end if;
  if v_wrong_section > 0 then
    raise exception 'a question does not belong to its section'
      using errcode = '22023';
  end if;
  if v_bad_pick > 0 then
    raise exception 'selected choice does not belong to its question'
      using errcode = '22023';
  end if;
  if v_ungradable > 0 then
    raise exception 'a question has no single correct choice'
      using errcode = '22023';
  end if;

  -- Composition: the board must be exactly the blueprint. A blueprint unit is
  -- a topic ('q<quiz id>', its configured count) or, for a subject with
  -- mock_board_pool_count set (20261008100000), the whole subject
  -- ('s<subject id>', the pool count, from any of its topics). Per section
  -- every unit must have a count and the counts must add up to 100; then
  -- every unit must contribute exactly its number.
  with sec as (
    select generate_series(1, c_sections) as section
  ),
  topics as (
    select sec.section, s.id as subject_id, z.id as quiz_id,
           nullif(to_jsonb(s) ->> 'mock_board_pool_count', '')::integer
             as pool_cnt,
           public.mock_board_configured_count(to_jsonb(z)) as cnt
    from sec
    join public.subjects s
      on public.mock_board_section_matches(sec.section, s.title)
     and (to_jsonb(s) ->> 'deleted_at') is null
    join public.quizzes z
      on z.subject_id = s.id and (to_jsonb(z) ->> 'deleted_at') is null
  ),
  blueprint as (
    select section, 'q' || quiz_id as unit, cnt
    from topics where pool_cnt is null
    union
    select section, 's' || subject_id, pool_cnt
    from topics where pool_cnt is not null
  ),
  submitted as (
    select (i ->> 'section')::integer as section,
           case
             when nullif(to_jsonb(s) ->> 'mock_board_pool_count', '')
                  is not null
               then 's' || s.id
             else 'q' || q.quiz_id
           end as unit,
           count(*) as n
    from jsonb_array_elements(p_items) as i
    join public.questions q on q.id = (i ->> 'question_id')::integer
    left join public.quizzes z on z.id = q.quiz_id
    left join public.subjects s on s.id = z.subject_id
    group by 1, 2
  )
  select
    (select count(*) from sec
      where exists (select 1 from blueprint b
                    where b.section = sec.section and b.cnt is null)
         or coalesce((select sum(b.cnt) from blueprint b
                      where b.section = sec.section), 0) <> c_per_section),
    (select count(*) from (
       select coalesce(b.cnt, 0) as expected, coalesce(s.n, 0) as actual
       from blueprint b
       full join submitted s
         on s.section = b.section and s.unit = b.unit
     ) d where d.expected <> d.actual)
  into v_unconfigured, v_composition;

  if v_unconfigured > 0 then
    raise exception 'the mock board blueprint is not configured'
      using errcode = '55000';
  end if;
  if v_composition > 0 then
    raise exception 'submitted questions do not match the board blueprint'
      using errcode = '22023';
  end if;

  select round(sum((t.x ->> 'score')::numeric * c_weights[t.ord::integer])
               / 100, 2)
  into v_gwa
  from jsonb_array_elements(v_answer) with ordinality as t(x, ord);

  -- Time: trusted only when the server saw the board start and, if a limit is
  -- configured, the submission arrived inside it. Late or unstarted boards
  -- are still saved (the user keeps the result in their history) but never
  -- rank.
  select started_at into v_started
  from public.mock_board_sessions
  where user_id = v_uid and client_attempt_id = p_client_attempt_id;
  select per_subject_minutes, grace_minutes into v_limit, v_grace
  from public.mock_board_settings limit 1;
  v_time_ok := v_started is not null
    and (v_limit is null
         or now() - v_started
              <= make_interval(mins => v_limit * c_sections
                                       + coalesce(v_grace, 0)));

  select coalesce(max(no_of_attempt), 0) + 1 into v_no
  from public.quiz_attempts
  where student_id = v_uid;

  insert into public.quiz_attempts (
    student_id, score, attempted_at, answer, summary,
    no_of_attempt, client_attempt_id, server_graded, time_verified,
    started_at
  ) values (
    v_uid, v_gwa, now(), v_answer, v_answer,
    v_no, p_client_attempt_id, true, v_time_ok, v_started
  );

  return v_no;
end;
$$;

revoke all on function public.save_mock_board_attempt(uuid, jsonb)
  from public, anon;
grant execute on function public.save_mock_board_attempt(uuid, jsonb)
  to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Leaderboards: same output as 20261001001000, but only trusted attempts
--    (server graded AND time verified) can rank. History is untouched.
-- ---------------------------------------------------------------------------
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
    where qa.server_graded and qa.time_verified
      and qa.attempted_at >= (date_trunc('week', timezone('Asia/Manila', now())) at time zone 'Asia/Manila')
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
    where qa.server_graded and qa.time_verified
      and qa.attempted_at >= (date_trunc('month', timezone('Asia/Manila', now())) at time zone 'Asia/Manila')
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

-- Rollback (only if the app version that calls the RPC is withdrawn):
--   create policy "Users can insert their own quiz attempts"
--     on public.quiz_attempts for insert to authenticated
--     with check ((select auth.uid()) = student_id);
--   grant insert on public.quiz_attempts to authenticated;
--   -- restore the two leaderboard functions from 20261001001000.
--   drop function public.save_mock_board_attempt(uuid, jsonb);
--   drop function public.start_mock_board_attempt(uuid);
-- A tested script is in
-- supabase/reconciliation/rollback_mock_board_server_grading_20261013.sql
