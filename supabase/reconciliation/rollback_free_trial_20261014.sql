-- Rollback of supabase/proposed/20261014100000_free_trial.sql
--
-- Removes the trial function and restores get_my_access() to the version from
-- 20261014000000_paymongo_payments.sql. The user_trials table is KEPT so a
-- re-apply cannot hand out a second trial; drop it only deliberately.

begin;
set local lock_timeout = '5s';

drop function if exists public.claim_free_trial();

create or replace function public.get_my_access()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'subscription_active',
      coalesce((select s.expires_at > now()
                from public.user_subscriptions s
                where s.user_id = (select auth.uid())), false),
    'subscription_expires_at',
      (select s.expires_at from public.user_subscriptions s
       where s.user_id = (select auth.uid())),
    'mother_notes_owned',
      exists (select 1 from public.user_entitlements e
              where e.user_id = (select auth.uid())
                and e.kind = 'mother_notes')
  );
$$;

revoke all on function public.get_my_access() from public, anon;
grant execute on function public.get_my_access() to authenticated;

notify pgrst, 'reload schema';
commit;

-- Destructive (re-apply would then give everyone a fresh trial):
--   drop table public.user_trials;
