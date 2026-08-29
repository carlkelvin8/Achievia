-- Let the unauthenticated signup form check the public username namespace
-- before auth.users invokes the profile trigger.
create or replace function public.is_username_available(p_username text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select nullif(trim(p_username), '') is not null
    and not exists (
      select 1
      from public.profiles
      where lower(trim(username)) = lower(trim(p_username))
    );
$$;

revoke all on function public.is_username_available(text) from public;
grant execute on function public.is_username_available(text) to anon;
grant execute on function public.is_username_available(text) to authenticated;
