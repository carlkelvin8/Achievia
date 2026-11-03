# PayMongo payments - setup and test plan

Nothing here is deployed. All files are local and uncommitted for review.

## What was built

| Piece | File |
|---|---|
| Database (prices, orders, ledger, grants, entitlements, RPCs) | `supabase/proposed/20261014000000_paymongo_payments.sql` |
| Rollback (keeps payment data) | `supabase/reconciliation/rollback_paymongo_payments_20261014.sql` |
| Create checkout (Edge Function) | `supabase/functions/create-checkout/index.ts` |
| Webhook (Edge Function) | `supabase/functions/paymongo-webhook/index.ts` |
| Shared logic: signature, parsing, handlers | `supabase/functions/_shared/paymongo.ts`, `_shared/config.ts` |
| App: plans, checkout, "Payment processing" status | `lib/presentation/screens/billing/*`, `lib/presentation/provider/billing/*`, `lib/data/data_source/billing/*` |
| Local tests | `supabase/functions/tests/paymongo.test.ts`, `scripts/test_paymongo_payments.py`, `test/**/billing*` |

## Rules the implementation enforces

* Prices are integer centavos in `billing_plans` (₱299 = 29900, ₱599 = 59900,
  ₱999 = 99900, ₱1,699 = 169900). The app sends only a plan code; the Edge
  Function reads the amount from the database.
* One-time payment, time-limited access. No recurring billing anywhere.
* Only `fulfill_payment()` grants access, and only the signature-verified
  webhook calls it. The success redirect (`achievia://callback?payment=...`)
  just opens a status screen that reads the order from the backend.
* `fulfill_payment()` matches the stored order: mode, reference number, amount,
  currency and `paid` status. Any mismatch is recorded and grants nothing.
* Idempotent per webhook event id and per order (`subscription_grants` has the
  order id as its primary key); a second payment id cannot reuse an order.
* Renewing while active extends from the current expiry.
* Mother Notes is a separate row in `user_entitlements` with no expiry, so
  subscription expiry never touches it. It is seeded **inactive and without a
  price**; `create_payment_order` refuses it until you set one.
* Secrets (secret key, webhook secret) exist only as Edge Function secrets.
  Test and live have separate variables and `PAYMONGO_MODE` is explicit.

## Configuration (Edge Function secrets)

```
supabase secrets set \
  PAYMONGO_MODE=test \
  PAYMONGO_SECRET_KEY_TEST=sk_test_... \
  PAYMONGO_WEBHOOK_SECRET_TEST=whsk_... \
  PAYMONGO_PAYMENT_METHOD_TYPES=gcash,paymaya,card
```

`PAYMONGO_PAYMENT_METHOD_TYPES` must list only methods enabled on the merchant
account (Dashboard > Settings > Payment Methods); checkout refuses to start
without it. For live use `PAYMONGO_MODE=live` with the `_LIVE` variables on a
separate deployment/secret set. A `sk_live_` key in test mode (or the reverse)
is a configuration error and the functions refuse to run.

Optional: `PAYMENT_SUCCESS_URL`, `PAYMENT_CANCEL_URL` (default
`achievia://callback?payment=success|cancelled`; `&order=<id>` is appended),
`PAYMONGO_WEBHOOK_TOLERANCE_SECONDS` (default 86400, `0` disables).

## Deploy order

1. Apply `20261014000000_paymongo_payments.sql` (staging first).
2. `supabase functions deploy create-checkout`
3. `supabase functions deploy paymongo-webhook --no-verify-jwt`
   (PayMongo does not send a Supabase JWT.)
4. In PayMongo (test mode) register
   `https://<project>.supabase.co/functions/v1/paymongo-webhook`, subscribe to
   `checkout_session.payment.paid` and `payment.failed`, and copy the signing
   secret into `PAYMONGO_WEBHOOK_SECRET_TEST`.
5. Ship the app build that contains the Subscription screen.

## Facts verified against the PayMongo docs (2026-10-12)

* Checkout Session: `POST /v2/checkout_sessions`, Basic auth (secret key as
  username, empty password); `line_items`, `payment_method_types`,
  `success_url`, `cancel_url`, `reference_number`, `metadata`; response
  `data.id`, `data.attributes.checkout_url`.
* Webhook signature: header `Paymongo-Signature: t=...,te=...,li=...`; HMAC
  SHA-256 over `<t>.<raw body>` with the webhook secret; compare `te` for test
  and `li` for live events. Event `checkout_session.payment.paid` for a paid
  session; `payment.failed` for a failed attempt. 2xx within 30 s; retried up
  to 12 times with exponential backoff.

## Things the docs did not settle - confirm in test mode

1. **Amount unit.** The docs never state centavos explicitly. The code sends
   integer centavos; confirm PHP 299 shows as PHP 299.00 on the PayMongo page.
2. **Exact `checkout_session.payment.paid` payload.** The handler reads the
   session `id`, `attributes.reference_number`, and
   `attributes.payments[].attributes.{amount,currency,status,source.type}`.
   Fire one test event and compare; adjust `extractPaidCheckout` if the shape
   differs. If it cannot be read, the event is rejected and nothing is granted
   (fail closed).
3. **Signature format.** The Setup & Management page and the Best Practices
   example disagree (timestamp included vs not). The code follows Setup &
   Management. The first real test webhook must verify; if it returns 401,
   check this first.
4. **Checkout expiry / cancel events.** No documented webhook for an expired
   or cancelled checkout. Orders expire locally 24 h after creation and the
   app reports them as expired; a payment that still arrives later and is
   verified is granted and flagged `paid_after_expiry` (money was received).
5. **`payment.failed` payload.** It is mapped to an order on a best-effort
   basis (`metadata.order_id`, `external_reference_number`,
   `reference_number`); if no order can be matched it is only logged. It never
   changes access either way.
6. **Custom-scheme return URL.** `success_url`/`cancel_url` use
   `achievia://callback?...`. If PayMongo refuses a non-https URL, host a small
   https page that redirects to the app and set `PAYMENT_SUCCESS_URL` /
   `PAYMENT_CANCEL_URL`. The status screen works without any redirect: it
   follows the order id returned by `create-checkout`.

## Test-mode checklist (needs a PayMongo test account - not run here)

1. Subscription purchase: 1 month, then 3 months while active; check expiry.
2. Mother Notes: set a price, buy, confirm `get_my_access().mother_notes_owned`;
   let a subscription expire and confirm it stays owned.
3. Failed payment: use a PayMongo failing test card/outcome; status screen
   shows "did not go through", no access.
4. Delayed webhook: pause the endpoint (or return 500 once); app shows
   "Payment processing" until PayMongo's retry lands.
5. Duplicate delivery: dashboard "Resend" of the same event; expiry must not
   move again.
6. Abandon/expire: start a checkout, close it; no access, order reads expired
   after 24 h.

## Not covered (out of scope or needs a decision)

* **Enforcing Mother Notes content access.** The entitlement exists and the app
  can read it (`accessStatusProvider`), but existing `modules` RLS still lets
  any signed-in user read them. Gating files by entitlement needs a product
  decision (which modules are "Mother Notes", free vs paid) and a storage /
  RLS change.
* **Subscription gating of other features.** Same: the entitlement is exposed,
  features are not yet gated by it.
* **Refunds / disputes.** No `refund.succeeded` or dispute handling; access is
  not revoked automatically.
* **Mother Notes price.** Not set (inactive). See the end of the migration.
