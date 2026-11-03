-- PROPOSED - NOT APPLIED. Review, then run as one reviewed statement.
--
-- Stores the date of birth collected on the Create account screen.
--
--   * adds public.profiles.birth_date (date, nullable);
--   * a small AFTER INSERT trigger copies it from the sign-up metadata
--     (auth.users.raw_user_meta_data ->> 'birth_date'), so the existing
--     public.handle_new_user() body is not touched.
--
-- Until this is applied the app still saves the user's age (profiles.age,
-- derived from the birthday) and keeps the date in the auth user metadata, so
-- nothing is lost. Nothing existing is modified; rows without a birthday stay
-- NULL.
begin;

alter table public.profiles
  add column if not exists birth_date date;

create or replace function public.copy_profile_birth_date()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_raw text;
  v_date date;
begin
  select u.raw_user_meta_data ->> 'birth_date'
    into v_raw
    from auth.users u
   where u.id = new.id;

  begin
    v_date := nullif(btrim(v_raw), '')::date;
  exception when others then
    v_date := null;
  end;

  -- A date in the future or before 1900 is not a birthday: store NULL.
  if v_date is not null and (v_date > current_date or v_date < date '1900-01-01') then
    v_date := null;
  end if;

  if v_date is not null then
    update public.profiles set birth_date = v_date where id = new.id;
  end if;
  return null;
end;
$$;

drop trigger if exists profiles_copy_birth_date on public.profiles;
create trigger profiles_copy_birth_date
  after insert on public.profiles
  for each row execute function public.copy_profile_birth_date();

notify pgrst, 'reload schema';
commit;
