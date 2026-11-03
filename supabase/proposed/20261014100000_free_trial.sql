-- PROPOSED PATCH - NOT APPLIED, deliberately kept out of supabase/migrations.
--
-- 7-day free trial. Apply AFTER 20261014000000_paymongo_payments.sql (it
-- replaces get_my_access() from that patch).
--
-- Rules
--   * One trial per account, started explicitly by claim_free_trial().
--     The start and end time are written by the server; the client cannot
--     choose or extend them (no client write access to user_trials).
--   * A user with an active paid subscription does not consume a trial.
--   * The trial is never granted by a payment and never touches paid
--     subscriptions or the lifetime Mother Notes entitlement.
--   * Limits: one trial per ACCOUNT. Someone who registers new accounts can
--     get more trials; closing that needs phone or payment-method checks.
--
-- Rollback: supabase/reconciliation/rollback_free_trial_20261014.sql

begin;
set local lock_timeout = '5s';

create table if not exists public.user_trials (
  user_id uuid primary key references auth.users(id),
  started_at timestamptz not null default now(),
  ends_at timestamptz not null,
  check (ends_at > started_at)
);

alter table public.user_trials enable row level security;
revoke all on public.user_trials from public, anon, authenticated;
grant select on public.user_trials to authenticated;

drop policy if exists "Users read their own trial" on public.user_trials;
create policy "Users read their own trial" on public.user_trials
  for select to authenticated using (user_id = (select auth.uid()));

-- Starts the caller's free trial. Idempotent: calling it again never restarts
-- or extends it.
--   {"status": "started" | "already_used" | "subscribed", "ends_at": ...}
create or replace function public.claim_free_trial()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  c_trial_days constant integer := 7;
  v_uid uuid := auth.uid();
  v_ends timestamptz;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;

  -- Someone who already pays does not need (and does not burn) a trial.
  if exists (
    select 1 from public.user_subscriptions s
    where s.user_id = v_uid and s.expires_at > now()
  ) then
    return jsonb_build_object('status', 'subscribed');
  end if;

  select ends_at into v_ends from public.user_trials where user_id = v_uid;
  if found then
    return jsonb_build_object('status', 'already_used', 'ends_at', v_ends);
  end if;

  insert into public.user_trials (user_id, started_at, ends_at)
  values (v_uid, now(), now() + make_interval(days => c_trial_days))
  on conflict (user_id) do nothing
  returning ends_at into v_ends;

  if v_ends is null then
    -- A concurrent call won the race.
    select ends_at into v_ends from public.user_trials where user_id = v_uid;
    return jsonb_build_object('status', 'already_used', 'ends_at', v_ends);
  end if;
  return jsonb_build_object('status', 'started', 'ends_at', v_ends);
end;
$$;

-- Current access of the signed-in user, now including the trial.
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
                and e.kind = 'mother_notes'),
    'trial_used',
      exists (select 1 from public.user_trials t
              where t.user_id = (select auth.uid())),
    'trial_active',
      coalesce((select t.ends_at > now() from public.user_trials t
                where t.user_id = (select auth.uid())), false),
    'trial_ends_at',
      (select t.ends_at from public.user_trials t
       where t.user_id = (select auth.uid()))
  );
$$;

revoke all on function public.claim_free_trial() from public, anon;
revoke all on function public.get_my_access() from public, anon;
grant execute on function public.claim_free_trial() to authenticated;
grant execute on function public.get_my_access() to authenticated;

notify pgrst, 'reload schema';
commit;
