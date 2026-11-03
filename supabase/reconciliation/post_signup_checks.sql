-- READ-ONLY. Run after ONE controlled signup. Replace the email below with the
-- exact address used for the test (it is the only place the value appears).
-- Shows the auth user, the resulting profile row (no password/token columns),
-- and whether any orphan exists. Nothing is created or changed.
with t as (select lower(btrim('REPLACE_WITH_TEST_EMAIL@example.com')) as email)
select * from (
  select 1 as ord, 'auth.users' as check_name,
    case when count(*) = 1 then 'OK: 1 row' else 'PROBLEM: ' || count(*) || ' rows' end as verdict,
    coalesce(string_agg('id=' || u.id || ' created=' || u.created_at
      || ' confirmed=' || coalesce(u.email_confirmed_at::text, 'no (email pending)'), '; '), '-') as detail
  from auth.users u, t where lower(u.email) = t.email
  union all
  select 2, 'profile row',
    case when count(*) = 1 then 'OK: 1 row' else 'PROBLEM: ' || count(*) || ' rows (expected 1)' end,
    coalesce(string_agg('username=' || coalesce(p.username, 'NULL') || ' email=' || coalesce(p.email, 'NULL')
      || ' role=' || p.role || ' status=' || p.status || ' first=' || coalesce(p.first_name, 'NULL')
      || ' university=' || coalesce(p.university, 'NULL') || ' purpose=' || coalesce(p.purpose, 'NULL'), '; '), '-')
  from public.profiles p join auth.users u on u.id = p.id, t where lower(u.email) = t.email
  union all
  select 3, 'role/status/email values',
    case when count(*) = 1 then 'OK: role=USER, status=active, email matches' else 'PROBLEM: unexpected values' end, '-'
  from public.profiles p join auth.users u on u.id = p.id, t
  where lower(u.email) = t.email and p.role = 'USER' and p.status = 'active' and p.email = u.email
  union all
  select 4, 'orphan auth users (last 24h, no profile)',
    case when count(*) = 0 then 'OK: none' else 'PROBLEM: ' || count(*) end,
    coalesce(string_agg(u.id::text, ', '), '-')
  from auth.users u
  where u.created_at > now() - interval '24 hours'
    and not exists (select 1 from public.profiles p where p.id = u.id)
  union all
  select 5, 'orphan profiles (no auth user)',
    case when count(*) = 0 then 'OK: none' else 'PROBLEM: ' || count(*) end, '-'
  from public.profiles p where not exists (select 1 from auth.users u where u.id = p.id)
) q order by ord;
