-- Forward-only. Makes the signup profile trigger tolerant of optional or
-- malformed metadata and makes its failures diagnosable. Apply in staging
-- first. Does not touch RLS, grants or any existing row. Rollback:
-- supabase/reconciliation/rollback_handle_new_user_20261009.sql
--
-- Why: a failure inside public.handle_new_user() makes GoTrue answer
-- "500: Database error saving new user". The previous body (see
-- 20261001000000_production_security.sql) could fail on:
--   * values longer than the varchar limits (first/middle name and username 100,
--     last name/email/university/purpose/profile_image 255);
--   * non-numeric age / courseId or an unparsable date_of_examination;
--   * a missing username (stored NULL);
-- and the error text did not say which constraint or column was involved.
--
-- Username policy: a username the user typed is NEVER changed. If it is already
-- taken (compared case-insensitively, same rule as is_username_available) the
-- signup fails and the Postgres log names profiles_username_key. A username is
-- generated only when none was supplied.
begin;
set local lock_timeout = '5s';

-- Drift guard: the function below writes this column. Checked first so the
-- ACCESS EXCLUSIVE lock of ALTER TABLE is only taken when it is really missing.
do $$ begin
  if not exists (select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'profiles'
        and column_name = 'mantra') then
    alter table public.profiles add column mantra text;
  end if;
end $$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
  v_username text := left(nullif(btrim(meta ->> 'username'), ''), 100);
  v_age integer;
  v_course integer;
  v_exam timestamptz;
  v_constraint text;
  v_column text;
begin
  -- Optional numeric fields: accept plain digits only, otherwise store NULL.
  if btrim(coalesce(meta ->> 'age', '')) ~ '^[0-9]{1,9}$' then
    v_age := btrim(meta ->> 'age')::integer;
  end if;
  if btrim(coalesce(meta ->> 'courseId', '')) ~ '^[0-9]{1,9}$' then
    v_course := btrim(meta ->> 'courseId')::integer;
  end if;

  -- Optional timestamp: an unparsable value must not block account creation.
  begin
    v_exam := nullif(btrim(meta ->> 'date_of_examination'), '')::timestamptz;
  exception when others then
    v_exam := null;
  end;

  if v_username is null then
    -- No username supplied: derive a unique one from the email.
    v_username := left(
      coalesce(nullif(split_part(coalesce(new.email, ''), '@', 1), ''), 'user'),
      90) || '_' || substr(replace(new.id::text, '-', ''), 1, 6);
  elsif exists (
    select 1 from public.profiles p
    where lower(btrim(p.username)) = lower(v_username) and p.id <> new.id
  ) then
    -- Explicit username is taken: refuse, never rename it.
    raise exception 'username already taken'
      using errcode = '23505', constraint = 'profiles_username_key';
  end if;

  -- role and status are fixed here on purpose: clients must not choose them.
  insert into public.profiles (id, first_name, middle_name, last_name, bio,
    age, username, email, role, status, profile_image, course_id,
    university, purpose, mantra, date_of_examination)
  values (new.id,
    left(meta ->> 'first_name', 100),
    left(meta ->> 'middle_name', 100),
    left(meta ->> 'last_name', 255),
    meta ->> 'bio',
    v_age,
    v_username,
    left(new.email, 255),
    'USER', 'active',
    left(meta ->> 'profile_image', 255),
    v_course,
    left(meta ->> 'university', 255),
    left(meta ->> 'purpose', 255),
    meta ->> 'mantra',
    v_exam);
  return new;
exception when others then
  -- Name the failing constraint/column in the Postgres log. No row values.
  get stacked diagnostics v_constraint = constraint_name, v_column = column_name;
  raise exception
    'handle_new_user failed: sqlstate=% constraint=% column=% message=%',
    sqlstate, coalesce(v_constraint, '-'), coalesce(v_column, '-'), sqlerrm
    using errcode = sqlstate;
end;
$$;

-- Recreate the trigger only if it is missing, disabled or points elsewhere, so
-- a healthy auth.users is not locked or modified at all.
do $$ begin
  if not exists (
    select 1 from pg_trigger t
    where t.tgrelid = 'auth.users'::regclass
      and t.tgname = 'on_auth_user_created'
      and t.tgenabled = 'O'
      and t.tgfoid = 'public.handle_new_user()'::regprocedure
  ) then
    drop trigger if exists on_auth_user_created on auth.users;
    create trigger on_auth_user_created
      after insert on auth.users
      for each row execute function public.handle_new_user();
  end if;
end $$;

commit;
