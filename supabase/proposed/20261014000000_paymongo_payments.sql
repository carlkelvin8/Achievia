-- PROPOSED PATCH - NOT APPLIED, deliberately kept out of supabase/migrations.
--
-- PayMongo payments for Achievia: one-time, time-limited subscriptions
-- (1 / 3 / 6 / 12 months, no automatic renewal) and a separate lifetime
-- "Mother Notes" purchase.
--
-- Trust model
--   * Prices live here, in integer centavos (billing_plans). The client only
--     sends a plan code; the amount sent to PayMongo is read from this table by
--     the Edge Function.
--   * Access is granted ONLY by fulfill_payment(), which the paymongo-webhook
--     Edge Function calls with the service role after verifying the webhook
--     signature. The checkout success redirect never grants anything.
--   * fulfill_payment() re-checks the stored order (mode, reference, amount,
--     currency, paid status) and is idempotent per webhook event id AND per
--     order, so a retried or duplicated event can never extend a subscription
--     twice.
--   * Clients can read their own orders/subscription/entitlements and nothing
--     else; they cannot write to any of these tables.
--
-- Mother Notes: billing_plans.mother_notes is seeded INACTIVE with no price.
-- Set it once the price is final (see the end of this file).
--
-- Rollback: supabase/reconciliation/rollback_paymongo_payments_20261014.sql

begin;
set local lock_timeout = '5s';

-- ---------------------------------------------------------------------------
-- 1. Catalogue
-- ---------------------------------------------------------------------------
create table if not exists public.billing_plans (
  code text primary key,
  kind text not null check (kind in ('subscription', 'mother_notes')),
  title text not null,
  amount_centavos integer check (amount_centavos > 0),
  currency text not null default 'PHP' check (currency = 'PHP'),
  duration_months integer check (duration_months > 0),
  is_active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  check (
    (kind = 'subscription'
       and duration_months is not null and amount_centavos is not null)
    or (kind = 'mother_notes' and duration_months is null)
  ),
  -- A plan can only be offered once it has a price.
  check (not is_active or amount_centavos is not null)
);

insert into public.billing_plans
  (code, kind, title, amount_centavos, duration_months, is_active, sort_order)
values
  ('sub_1m',  'subscription', '1 Month',   29900,  1,  true, 10),
  ('sub_3m',  'subscription', '3 Months',  59900,  3,  true, 20),
  ('sub_6m',  'subscription', '6 Months',  99900,  6,  true, 30),
  ('sub_12m', 'subscription', '12 Months', 169900, 12, true, 40)
on conflict (code) do nothing;

insert into public.billing_plans
  (code, kind, title, amount_centavos, duration_months, is_active, sort_order)
values
  ('mother_notes', 'mother_notes', 'Mother Notes (lifetime)', null, null,
   false, 50)
on conflict (code) do nothing;

-- ---------------------------------------------------------------------------
-- 2. Orders, webhook ledger, grants
-- ---------------------------------------------------------------------------
create table if not exists public.payment_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id),
  plan_code text not null references public.billing_plans(code),
  kind text not null check (kind in ('subscription', 'mother_notes')),
  -- Snapshots taken at order time: later price changes never alter an order.
  amount_centavos integer not null check (amount_centavos > 0),
  currency text not null default 'PHP' check (currency = 'PHP'),
  duration_months integer check (duration_months > 0),
  mode text not null check (mode in ('test', 'live')),
  status text not null default 'pending'
    check (status in ('pending', 'paid', 'cancelled', 'expired')),
  checkout_session_id text unique,
  checkout_url text,
  paymongo_payment_id text unique,
  payment_method text,
  last_failure text,
  failed_attempts integer not null default 0,
  paid_after_expiry boolean not null default false,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '24 hours',
  paid_at timestamptz,
  check (status <> 'paid' or paid_at is not null)
);

create index if not exists payment_orders_user_idx
  on public.payment_orders (user_id, created_at desc);

create table if not exists public.payment_webhook_events (
  event_id text primary key,
  event_type text not null,
  livemode boolean,
  order_id uuid references public.payment_orders(id),
  outcome text not null,
  received_at timestamptz not null default now()
);

-- One row per order that extended a subscription. The primary key is the
-- second line of defence against granting the same payment twice.
create table if not exists public.subscription_grants (
  order_id uuid primary key references public.payment_orders(id),
  user_id uuid not null references auth.users(id),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  months integer not null check (months > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.user_subscriptions (
  user_id uuid primary key references auth.users(id),
  expires_at timestamptz not null,
  updated_at timestamptz not null default now()
);

-- Lifetime entitlements. Deliberately has NO expiry column and is never
-- touched by subscription expiry.
create table if not exists public.user_entitlements (
  user_id uuid not null references auth.users(id),
  kind text not null check (kind in ('mother_notes')),
  source_order_id uuid not null unique references public.payment_orders(id),
  granted_at timestamptz not null default now(),
  primary key (user_id, kind)
);

-- ---------------------------------------------------------------------------
-- 3. Row level security: read-only for clients
-- ---------------------------------------------------------------------------
alter table public.billing_plans enable row level security;
alter table public.payment_orders enable row level security;
alter table public.payment_webhook_events enable row level security;
alter table public.subscription_grants enable row level security;
alter table public.user_subscriptions enable row level security;
alter table public.user_entitlements enable row level security;

revoke all on public.billing_plans, public.payment_orders,
  public.payment_webhook_events, public.subscription_grants,
  public.user_subscriptions, public.user_entitlements
  from public, anon, authenticated;

grant select (code, kind, title, amount_centavos, currency, duration_months,
              sort_order)
  on public.billing_plans to authenticated;
grant select (id, plan_code, kind, amount_centavos, currency, status,
              last_failure, failed_attempts, created_at, expires_at, paid_at)
  on public.payment_orders to authenticated;
grant select on public.user_subscriptions to authenticated;
grant select on public.user_entitlements to authenticated;

drop policy if exists "Active plans are readable" on public.billing_plans;
create policy "Active plans are readable" on public.billing_plans
  for select to authenticated using (is_active);

drop policy if exists "Users read their own orders" on public.payment_orders;
create policy "Users read their own orders" on public.payment_orders
  for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "Users read their own subscription"
  on public.user_subscriptions;
create policy "Users read their own subscription" on public.user_subscriptions
  for select to authenticated using (user_id = (select auth.uid()));

drop policy if exists "Users read their own entitlements"
  on public.user_entitlements;
create policy "Users read their own entitlements" on public.user_entitlements
  for select to authenticated using (user_id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- 4. Server-side functions (service role only unless stated)
-- ---------------------------------------------------------------------------

-- Creates (or returns the still-open) pending order for a user and plan. The
-- amount is read from billing_plans here; callers cannot supply it.
create or replace function public.create_payment_order(
  p_user_id uuid,
  p_plan_code text,
  p_mode text
) returns public.payment_orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_plan public.billing_plans;
  v_order public.payment_orders;
begin
  if p_user_id is null then
    raise exception 'user is required' using errcode = '22023';
  end if;
  if p_mode not in ('test', 'live') then
    raise exception 'invalid mode' using errcode = '22023';
  end if;

  select * into v_plan from public.billing_plans where code = p_plan_code;
  if not found or not v_plan.is_active or v_plan.amount_centavos is null then
    raise exception 'plan_unavailable' using errcode = 'P0002';
  end if;

  if v_plan.kind = 'mother_notes' and exists (
    select 1 from public.user_entitlements
    where user_id = p_user_id and kind = 'mother_notes'
  ) then
    raise exception 'already_owned' using errcode = '23505';
  end if;

  -- Reuse an open order (same user, plan, mode, amount) that already has a
  -- checkout page, so repeated taps do not create a pile of sessions.
  select * into v_order
  from public.payment_orders
  where user_id = p_user_id and plan_code = p_plan_code and mode = p_mode
    and status = 'pending' and expires_at > now()
    and amount_centavos = v_plan.amount_centavos
    and checkout_url is not null
  order by created_at desc
  limit 1;
  if found then
    return v_order;
  end if;

  insert into public.payment_orders (
    user_id, plan_code, kind, amount_centavos, currency, duration_months, mode
  ) values (
    p_user_id, v_plan.code, v_plan.kind, v_plan.amount_centavos,
    v_plan.currency, v_plan.duration_months, p_mode
  ) returning * into v_order;
  return v_order;
end;
$$;

create or replace function public.attach_checkout_session(
  p_order_id uuid,
  p_session_id text,
  p_checkout_url text
) returns void
language sql
security definer
set search_path = ''
as $$
  update public.payment_orders
  set checkout_session_id = p_session_id, checkout_url = p_checkout_url
  where id = p_order_id and status = 'pending'
    and checkout_session_id is null;
$$;

-- Applies one verified PayMongo "paid" event. Returns {"outcome": ...}.
-- Everything happens in a single transaction: the event row, the order update
-- and the grant commit together or not at all.
create or replace function public.fulfill_payment(
  p_event_id text,
  p_event_type text,
  p_livemode boolean,
  p_session_id text,
  p_reference text,
  p_payment_id text,
  p_amount integer,
  p_currency text,
  p_payment_status text,
  p_payment_method text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order public.payment_orders;
  v_outcome text;
  v_current timestamptz;
  v_starts timestamptz;
  v_ends timestamptz;
begin
  if p_event_id is null or btrim(p_event_id) = '' then
    raise exception 'event id is required' using errcode = '22023';
  end if;

  -- Idempotency: a delivery we have already processed is acknowledged and
  -- does nothing (PayMongo retries on timeouts and non-2xx answers).
  insert into public.payment_webhook_events
    (event_id, event_type, livemode, outcome)
  values (p_event_id, p_event_type, p_livemode, 'processing')
  on conflict (event_id) do nothing;
  if not found then
    return jsonb_build_object('outcome', 'duplicate_event');
  end if;

  select * into v_order
  from public.payment_orders
  where checkout_session_id = p_session_id
  for update;

  if not found then
    v_outcome := 'unknown_order';
  elsif v_order.mode is distinct from (case when p_livemode then 'live'
                                            else 'test' end) then
    v_outcome := 'rejected_mode_mismatch';
  elsif p_reference is distinct from v_order.id::text then
    v_outcome := 'rejected_reference_mismatch';
  elsif p_amount is distinct from v_order.amount_centavos then
    v_outcome := 'rejected_amount_mismatch';
  elsif upper(coalesce(p_currency, '')) <> v_order.currency then
    v_outcome := 'rejected_currency_mismatch';
  elsif lower(coalesce(p_payment_status, '')) <> 'paid' then
    v_outcome := 'rejected_not_paid';
  elsif v_order.status = 'paid' then
    v_outcome := 'already_paid';
  elsif p_payment_id is not null and exists (
    select 1 from public.payment_orders
    where paymongo_payment_id = p_payment_id and id <> v_order.id
  ) then
    -- One PayMongo payment can only ever pay for one order.
    v_outcome := 'rejected_payment_reused';
  else
    update public.payment_orders
    set status = 'paid',
        paid_at = now(),
        paymongo_payment_id = coalesce(p_payment_id, paymongo_payment_id),
        payment_method = p_payment_method,
        paid_after_expiry = (status = 'expired' or expires_at < now())
    where id = v_order.id;

    if v_order.kind = 'subscription' then
      select expires_at into v_current
      from public.user_subscriptions
      where user_id = v_order.user_id
      for update;

      v_starts := greatest(coalesce(v_current, now()), now());
      v_ends := v_starts + make_interval(months => v_order.duration_months);

      -- The primary key makes a second grant for the same order impossible.
      insert into public.subscription_grants
        (order_id, user_id, starts_at, ends_at, months)
      values (v_order.id, v_order.user_id, v_starts, v_ends,
              v_order.duration_months);

      insert into public.user_subscriptions (user_id, expires_at)
      values (v_order.user_id, v_ends)
      on conflict (user_id) do update
        set expires_at = excluded.expires_at, updated_at = now();
    else
      insert into public.user_entitlements (user_id, kind, source_order_id)
      values (v_order.user_id, v_order.kind, v_order.id)
      on conflict do nothing;
    end if;
    v_outcome := 'granted';
  end if;

  update public.payment_webhook_events
  set outcome = v_outcome, order_id = v_order.id
  where event_id = p_event_id;

  return jsonb_build_object('outcome', v_outcome, 'order_id', v_order.id);
end;
$$;

-- Records a failed payment attempt. It never changes access, and it keeps the
-- order pending because the customer can retry inside the same checkout.
create or replace function public.record_payment_failure(
  p_event_id text,
  p_event_type text,
  p_livemode boolean,
  p_reference text,
  p_reason text
) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order_id uuid;
  v_recorded boolean;
begin
  insert into public.payment_webhook_events
    (event_id, event_type, livemode, outcome)
  values (p_event_id, p_event_type, p_livemode, 'processing')
  on conflict (event_id) do nothing;
  if not found then
    return jsonb_build_object('outcome', 'duplicate_event');
  end if;

  begin
    v_order_id := p_reference::uuid;
  exception when others then
    v_order_id := null;
  end;

  update public.payment_orders
  set last_failure = left(coalesce(nullif(btrim(p_reason), ''), 'failed'), 200),
      failed_attempts = failed_attempts + 1
  where id = v_order_id and status = 'pending'
    and mode = (case when p_livemode then 'live' else 'test' end);
  v_recorded := found;

  update public.payment_webhook_events
  set outcome = case when v_recorded then 'failure_recorded'
                     else 'unknown_order' end,
      order_id = case when v_recorded then v_order_id else null end
  where event_id = p_event_id;
  return jsonb_build_object('outcome',
    case when v_recorded then 'failure_recorded' else 'unknown_order' end);
end;
$$;

revoke all on function public.create_payment_order(uuid, text, text)
  from public, anon, authenticated;
revoke all on function public.attach_checkout_session(uuid, text, text)
  from public, anon, authenticated;
revoke all on function public.fulfill_payment(
  text, text, boolean, text, text, text, integer, text, text, text)
  from public, anon, authenticated;
revoke all on function public.record_payment_failure(
  text, text, boolean, text, text)
  from public, anon, authenticated;
grant execute on function public.create_payment_order(uuid, text, text)
  to service_role;
grant execute on function public.attach_checkout_session(uuid, text, text)
  to service_role;
grant execute on function public.fulfill_payment(
  text, text, boolean, text, text, text, integer, text, text, text)
  to service_role;
grant execute on function public.record_payment_failure(
  text, text, boolean, text, text)
  to service_role;

-- ---------------------------------------------------------------------------
-- 5. Client-facing functions (authenticated, always scoped to auth.uid())
-- ---------------------------------------------------------------------------

-- Current access of the signed-in user.
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

-- Status of one of the caller's own orders. A pending order past its expiry
-- is reported as 'expired'. This is what the "Payment processing" screen polls.
create or replace function public.get_my_payment_order(p_order_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', o.id,
    'plan_code', o.plan_code,
    'kind', o.kind,
    'amount_centavos', o.amount_centavos,
    'currency', o.currency,
    'status', case when o.status = 'pending' and o.expires_at <= now()
                   then 'expired' else o.status end,
    'last_failure', o.last_failure,
    'paid_at', o.paid_at
  )
  from public.payment_orders o
  where o.id = p_order_id and o.user_id = (select auth.uid());
$$;

-- The customer came back through the cancel link. Only a still-pending order
-- can be cancelled; a payment that really completed is still honoured by the
-- webhook (the money was received).
create or replace function public.cancel_my_payment_order(p_order_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_status text;
begin
  update public.payment_orders
  set status = 'cancelled'
  where id = p_order_id and user_id = (select auth.uid())
    and status = 'pending'
  returning status into v_status;
  return coalesce(v_status, (
    select status from public.payment_orders
    where id = p_order_id and user_id = (select auth.uid())));
end;
$$;

revoke all on function public.get_my_access() from public, anon;
revoke all on function public.get_my_payment_order(uuid) from public, anon;
revoke all on function public.cancel_my_payment_order(uuid)
  from public, anon;
grant execute on function public.get_my_access() to authenticated;
grant execute on function public.get_my_payment_order(uuid) to authenticated;
grant execute on function public.cancel_my_payment_order(uuid)
  to authenticated;

notify pgrst, 'reload schema';
commit;

-- ---------------------------------------------------------------------------
-- Mother Notes price (run once the price is final; example amount only):
--   update public.billing_plans
--   set amount_centavos = 49900, is_active = true
--   where code = 'mother_notes';
-- ---------------------------------------------------------------------------
