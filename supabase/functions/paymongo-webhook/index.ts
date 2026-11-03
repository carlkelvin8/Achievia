// POST /functions/v1/paymongo-webhook   (called by PayMongo, not by the app)
//
// Verifies the Paymongo-Signature header on the RAW body, then applies
// `checkout_session.payment.paid` through public.fulfill_payment, which
// matches the stored order and is idempotent. This is the only place that
// can grant access.
//
// PayMongo does not send a Supabase JWT, so JWT verification must be OFF:
//   supabase functions deploy paymongo-webhook --no-verify-jwt
// and register https://<project>.supabase.co/functions/v1/paymongo-webhook as
// the webhook endpoint (subscribe to checkout_session.payment.paid and
// payment.failed), once in test mode and once in live mode.

import { createClient } from 'npm:@supabase/supabase-js@2';
import { loadPaymentConfig } from '../_shared/config.ts';
import { handlePaymongoWebhook } from '../_shared/paymongo.ts';

Deno.serve(async (request: Request) => {
  let config;
  try {
    config = loadPaymentConfig((name) => Deno.env.get(name));
  } catch (error) {
    console.error('payment configuration error', String(error));
    return json(500, { error: 'not_configured' });
  }

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  );

  // Read the body exactly once, as text: the signature covers these bytes.
  const rawBody = await request.text();

  const result = await handlePaymongoWebhook(
    {
      method: request.method,
      rawBody,
      signature: request.headers.get('Paymongo-Signature'),
    },
    {
      mode: config.mode,
      secret: config.webhookSecret,
      nowSeconds: Math.floor(Date.now() / 1000),
      toleranceSeconds: config.toleranceSeconds,
      log: (message) => console.log(message),
      async fulfill(args) {
        const { data, error } = await admin.rpc('fulfill_payment', {
          p_event_id: args.eventId,
          p_event_type: args.eventType,
          p_livemode: args.livemode,
          p_session_id: args.sessionId,
          p_reference: args.reference,
          p_payment_id: args.paymentId,
          p_amount: args.amount,
          p_currency: args.currency,
          p_payment_status: args.paymentStatus,
          p_payment_method: args.paymentMethod,
        });
        if (error) throw new Error(error.message);
        return String(data?.outcome ?? 'unknown');
      },
      async recordFailure(args) {
        const { data, error } = await admin.rpc('record_payment_failure', {
          p_event_id: args.eventId,
          p_event_type: args.eventType,
          p_livemode: args.livemode,
          p_reference: args.reference,
          p_reason: args.reason,
        });
        if (error) throw new Error(error.message);
        return String(data?.outcome ?? 'unknown');
      },
    },
  );
  return json(result.status, result.body);
});

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
