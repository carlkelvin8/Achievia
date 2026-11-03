-- Rollback of supabase/proposed/20261014000000_paymongo_payments.sql
--
-- Removes the payment functions so nothing can create orders or grant access
-- through them any more. The tables are KEPT on purpose: they hold real
-- payment records (orders, grants, entitlements) that must never be lost
-- because of a code rollback. Undo the Edge Functions separately:
--   supabase functions delete create-checkout
--   supabase functions delete paymongo-webhook
--
-- Run the table drops at the bottom ONLY when you are sure there is no paid
-- order you still need (they are commented out).

begin;
set local lock_timeout = '5s';

drop function if exists public.cancel_my_payment_order(uuid);
drop function if exists public.get_my_payment_order(uuid);
drop function if exists public.get_my_access();
drop function if exists public.record_payment_failure(
  text, text, boolean, text, text);
drop function if exists public.fulfill_payment(
  text, text, boolean, text, text, text, integer, text, text, text);
drop function if exists public.attach_checkout_session(uuid, text, text);
drop function if exists public.create_payment_order(uuid, text, text);

notify pgrst, 'reload schema';
commit;

-- Destructive, only after exporting the data:
--   drop table public.user_entitlements;
--   drop table public.user_subscriptions;
--   drop table public.subscription_grants;
--   drop table public.payment_webhook_events;
--   drop table public.payment_orders;
--   drop table public.billing_plans;
