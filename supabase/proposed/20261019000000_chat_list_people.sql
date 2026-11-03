-- Lets a signed-in student browse every other student with an account (the
-- "New message" list in Messages), so nobody has to guess who has signed up.
-- Same shape and privacy rules as search_profiles_for_chat: the email is never
-- returned and the caller is excluded.
begin;

create or replace function public.list_profiles_for_chat(
  result_limit integer default 50,
  result_offset integer default 0
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
  order by
    lower(coalesce(nullif(trim(p.first_name), ''), p.username, '')),
    lower(coalesce(p.last_name, '')),
    p.id
  limit least(greatest(coalesce(result_limit, 50), 1), 100)
  offset greatest(coalesce(result_offset, 0), 0);
$$;

revoke all on function public.list_profiles_for_chat(integer, integer) from public;
grant execute on function public.list_profiles_for_chat(integer, integer) to authenticated;

commit;
