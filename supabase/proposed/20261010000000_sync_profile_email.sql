-- PROPOSED, NOT APPLIED. Decide before promoting to supabase/migrations/.
--
-- Problem: public.profiles.email is a copy written once by handle_new_user().
-- Nothing updates it when auth.users.email changes (Dashboard edit, admin API,
-- or a future in-app email change). The old address then stays in profiles,
-- GoTrue considers it free, and a new signup with it fails on
-- profiles_email_key ("Database error saving new user").
--
-- This keeps the copy in step going forward. It does NOT rewrite any existing
-- row: existing mismatches are listed by the "profile-email-stale" row of
-- supabase/reconciliation/diagnose_signup_trigger.sql and must be reviewed and
-- fixed by hand (see the commented query at the bottom).
--
-- It adds a trigger on auth.users, so apply in staging first. A failure here
-- never blocks an email change: it only logs a warning.
begin;
set local lock_timeout = '5s';

create or replace function public.sync_profile_email()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  -- Fast path: GoTrue rewrites auth.users on every login, so do nothing (and
  -- open no subtransaction) unless the email really changed.
  if new.email is not distinct from old.email then
    return new;
  end if;
  begin
    update public.profiles set email = left(new.email, 255) where id = new.id;
  exception when others then
    raise warning 'sync_profile_email skipped: sqlstate=% message=%', sqlstate, sqlerrm;
  end;
  return new;
end;
$$;

drop trigger if exists on_auth_user_email_changed on auth.users;
create trigger on_auth_user_email_changed
  after update of email on auth.users
  for each row execute function public.sync_profile_email();

commit;

-- Manual reconciliation of EXISTING drift (review the list first, then run):
-- update public.profiles p set email = left(u.email, 255)
-- from auth.users u
-- where u.id = p.id and p.email is distinct from u.email
--   and not exists (select 1 from public.profiles o
--                   where o.email = u.email and o.id <> p.id);
