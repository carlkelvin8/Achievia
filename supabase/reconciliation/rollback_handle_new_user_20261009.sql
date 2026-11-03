-- MANUAL ROLLBACK for 20261009000000_harden_handle_new_user.sql. Not a
-- migration: it lives here so `supabase db push` never runs it. Run it by hand
-- only if the new trigger misbehaves in production.
--
-- Restores the exact function body from 20261001000000_production_security.sql.
-- Changes no table, row, grant or policy. Profiles created while the new
-- trigger was active stay valid and need no cleanup. The mantra column added
-- by the migration (if it was missing) is left in place on purpose; it is
-- harmless and is part of the schema the app expects.
begin;
set local lock_timeout = '5s';

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, first_name, middle_name, last_name, bio,
    age, username, email, role, status, profile_image, course_id,
    university, purpose, mantra, date_of_examination)
  values (new.id, new.raw_user_meta_data ->> 'first_name',
    new.raw_user_meta_data ->> 'middle_name', new.raw_user_meta_data ->> 'last_name',
    new.raw_user_meta_data ->> 'bio',
    nullif(new.raw_user_meta_data ->> 'age', '')::integer,
    new.raw_user_meta_data ->> 'username', new.email, 'USER', 'active',
    new.raw_user_meta_data ->> 'profile_image',
    nullif(new.raw_user_meta_data ->> 'courseId', '')::integer,
    new.raw_user_meta_data ->> 'university', new.raw_user_meta_data ->> 'purpose',
    new.raw_user_meta_data ->> 'mantra',
    nullif(new.raw_user_meta_data ->> 'date_of_examination', '')::timestamptz);
  return new;
end;
$$;

-- The trigger itself is unchanged by the migration when it was already healthy;
-- this makes sure it still exists, is enabled and points at the function.
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
