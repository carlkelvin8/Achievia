-- READ-ONLY single query (the Supabase SQL Editor shows only the last result
-- set, so everything is one UNION). Creates nothing; returns no passwords,
-- tokens or user values - only counts and schema facts.
-- Read the "verdict" column: anything starting with PROBLEM or STALE needs action.
-- The last block reads supabase_migrations.schema_migrations; if that schema
-- does not exist in your project, delete that block.
select * from (

-- 1. Which handle_new_user is deployed?
select 1 as ord, 'function' as section, p.oid::regprocedure::text as item,
  case
    when p.prosecdef is not true then 'PROBLEM: not security definer'
    when p.proconfig is null or p.proconfig::text not ilike '%search_path%'
      then 'PROBLEM: search_path not pinned'
    when pg_get_functiondef(p.oid) not ilike '%mantra%'
      then 'PROBLEM: old body (writes no mantra column)'
    when pg_get_functiondef(p.oid) not ilike '%handle_new_user failed%'
      then 'STALE: pre-20261009 body (unsafe casts, no diagnostics)'
    else 'OK: 20261009 body'
  end as verdict,
  'owner=' || p.proowner::regrole::text || ' config=' || coalesce(p.proconfig::text, '-') as detail
from pg_proc p
where p.pronamespace = 'public'::regnamespace and p.proname = 'handle_new_user'

union all
select 1, 'function', 'handle_new_user()', 'PROBLEM: function does not exist', '-'
where not exists (select 1 from pg_proc
  where pronamespace = 'public'::regnamespace and proname = 'handle_new_user')

-- 2. Trigger on auth.users present and enabled?
union all
select 2, 'trigger', t.tgname,
  case when t.tgenabled <> 'O' then 'PROBLEM: tgenabled=' || t.tgenabled::text
       when t.tgfoid <> 'public.handle_new_user()'::regprocedure
         then 'PROBLEM: fires ' || t.tgfoid::regproc::text || ' instead of handle_new_user'
       else 'OK: enabled, fires handle_new_user' end,
  pg_get_triggerdef(t.oid)
from pg_trigger t
where t.tgrelid = 'auth.users'::regclass and not t.tgisinternal
union all
select 2, 'trigger', 'on_auth_user_created', 'PROBLEM: missing on auth.users', '-'
where not exists (select 1 from pg_trigger
  where tgrelid = 'auth.users'::regclass and tgname = 'on_auth_user_created')

-- 3. Other triggers firing on profiles during signup.
union all
select 3, 'profiles-trigger', tgname, 'REVIEW: runs on profiles', pg_get_triggerdef(oid)
from pg_trigger where tgrelid = 'public.profiles'::regclass and not tgisinternal

-- 4. Columns the trigger writes.
union all
select 4, 'column', w.col,
  case when c.column_name is null then 'PROBLEM: column missing'
       when c.character_maximum_length is not null
        and c.character_maximum_length < w.need
         then 'PROBLEM: limit ' || c.character_maximum_length || ' < ' || w.need || ' the trigger truncates to'
       else 'OK' end,
  coalesce(c.data_type || coalesce('(' || c.character_maximum_length || ')', ''), '-')
    || ' nullable=' || coalesce(c.is_nullable, '-')
from (values ('id',0),('first_name',100),('middle_name',100),('last_name',255),
  ('bio',0),('age',0),('username',100),('email',255),('role',0),('status',0),
  ('profile_image',255),('course_id',0),('university',255),('purpose',255),
  ('mantra',0),('date_of_examination',0)) as w(col, need)
left join information_schema.columns c
  on c.table_schema = 'public' and c.table_name = 'profiles' and c.column_name = w.col

-- 5. Columns the trigger does NOT set but that are NOT NULL without default.
union all
select 5, 'not-null-no-default', column_name,
  'PROBLEM: trigger leaves this NULL and the column rejects NULL', data_type
from information_schema.columns
where table_schema = 'public' and table_name = 'profiles'
  and is_nullable = 'NO' and column_default is null
  and column_name not in ('id','first_name','middle_name','last_name','bio',
    'age','username','email','role','status','profile_image','course_id',
    'university','purpose','mantra','date_of_examination')

-- 6. Constraints vs. the fixed values the trigger writes ('USER' / 'active').
union all
select 6, 'constraint', conname,
  case
    when conname = 'profiles_role_check' and pg_get_constraintdef(oid) not ilike '%USER%'
      then 'PROBLEM: role check rejects USER'
    when conname = 'profiles_status_check' and pg_get_constraintdef(oid) not ilike '%active%'
      then 'PROBLEM: status check rejects active'
    when not convalidated then 'REVIEW: not validated'
    else 'OK' end,
  pg_get_constraintdef(oid)
from pg_constraint where conrelid = 'public.profiles'::regclass

-- 7. Existing data that makes a new signup collide (counts only).
union all
select 7, 'dup-username-case-insensitive', 'profiles',
  case when count(*) = 0 then 'OK' else 'REVIEW: ' || count(*) || ' duplicate groups' end, '-'
from (select 1 from public.profiles where username is not null
      group by lower(btrim(username)) having count(*) > 1) d
union all
select 7, 'profile-email-stale', 'profiles vs auth.users',
  case when count(*) = 0 then 'OK'
       else 'PROBLEM: ' || count(*) || ' profiles keep an email their auth user no longer has; '
         || 'a new signup with that email fails on profiles_email_key' end, '-'
from public.profiles p join auth.users u on u.id = p.id
where p.email is distinct from u.email
union all
select 7, 'orphan-profiles', 'profiles',
  case when count(*) = 0 then 'OK' else 'REVIEW: ' || count(*) || ' rows without auth user' end, '-'
from public.profiles p where not exists (select 1 from auth.users u where u.id = p.id)

-- 7b. Username hygiene (counts only).
union all
select 7, 'username-blank-or-padded', 'profiles',
  case when count(*) = 0 then 'OK'
       else 'REVIEW: ' || count(*) || ' rows with NULL/blank/padded username' end, '-'
from public.profiles
where username is null or btrim(username) = '' or username <> btrim(username)

-- 7c. Drift: was 20261001 (production_security) applied? It removed INSERT on
-- profiles from the API roles and pinned the trigger function.
union all
select 7, 'drift-profiles-insert-grant', 'authenticated/anon',
  case when count(*) = 0 then 'OK: INSERT revoked (20261001 applied)'
       else 'DRIFT: ' || string_agg(grantee, ',') || ' still have INSERT rights on profiles (20261001 not applied?)' end, '-'
from information_schema.role_table_grants
where table_schema = 'public' and table_name = 'profiles'
  and privilege_type = 'INSERT' and grantee in ('anon', 'authenticated')
union all
select 7, 'drift-username-rpc', 'is_username_available(text)',
  case when to_regprocedure('public.is_username_available(text)') is not null
       then 'OK: exists' else 'DRIFT: 20260829 not applied (app falls back to the DB constraint)' end, '-'

-- 8. Migration ledger (delete this block if the schema does not exist).
union all
select 8, 'ledger', version::text,
  case when version = '20261009000000' then 'OK: hardening migration recorded' else 'listed' end,
  coalesce(name, '-')
from supabase_migrations.schema_migrations where version >= '20261001000000'
union all
select 8, 'ledger', '20261001000000', 'DRIFT: production_security not in ledger (may have been applied by hand; compare sections 1 and 7c)', '-'
where not exists (select 1 from supabase_migrations.schema_migrations where version = '20261001000000')

) q order by ord, section, item;
