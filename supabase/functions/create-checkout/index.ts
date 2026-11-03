// POST /functions/v1/create-checkout   { "plan_code": "sub_3m" }
//
// Requires the signed-in user's JWT (verify_jwt stays ON for this function).
// Creates the order from the authoritative price in public.billing_plans and
// a PayMongo Checkout Session for exactly that amount. Returns the hosted
// checkout URL. Access is never granted here; only the webhook does that.
//
// Deploy:  supabase functions deploy create-checkout

import { createClient } from 'npm:@supabase/supabase-js@2';
import { loadPaymentConfig, withOrder } from '../_shared/config.ts';
import { handleCreateCheckout } from '../_shared/paymongo.ts';

const PAYMONGO_API = 'https://api.paymongo.com/v2/checkout_sessions';

Deno.serve(async (request: Request) => {
  let config;
  try {
    config = loadPaymentConfig((name) => Deno.env.get(name));
  } catch (error) {
    console.error('payment configuration error', String(error));
    return json(503, { error: 'payments_not_configured' });
  }
  if (!config.secretKey) {
    console.error('PayMongo secret key is not configured');
    return json(503, { error: 'payments_not_configured' });
  }

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false } },
  );

  let body: unknown = null;
  try {
    body = await request.json();
  } catch (_) {
    body = null;
  }

  const result = await handleCreateCheckout(
    {
      method: request.method,
      authorization: request.headers.get('Authorization'),
      body,
    },
    {
      mode: config.mode,
      paymentMethodTypes: config.paymentMethodTypes,
      successUrl: (orderId) => withOrder(config.successUrlBase, orderId),
      cancelUrl: (orderId) => withOrder(config.cancelUrlBase, orderId),
      log: (message) => console.log(message),
      async authenticate(token) {
        const { data, error } = await admin.auth.getUser(token);
        return error || !data.user ? null : data.user.id;
      },
      async createOrder(userId, planCode, mode) {
        const { data, error } = await admin.rpc('create_payment_order', {
          p_user_id: userId,
          p_plan_code: planCode,
          p_mode: mode,
        });
        if (error) throw new Error(error.message);
        return data;
      },
      async planTitle(planCode) {
        const { data } = await admin
          .from('billing_plans')
          .select('title')
          .eq('code', planCode)
          .maybeSingle();
        return data?.title ?? planCode;
      },
      async createSession(sessionBody, idempotencyKey) {
        const response = await fetch(PAYMONGO_API, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Accept: 'application/json',
            // Secret key as the Basic auth username, empty password.
            Authorization: `Basic ${btoa(`${config.secretKey}:`)}`,
            'Idempotency-Key': idempotencyKey,
          },
          body: JSON.stringify(sessionBody),
        });
        const payload = await response.json().catch(() => null);
        const id = payload?.data?.id;
        const checkoutUrl = payload?.data?.attributes?.checkout_url;
        if (!response.ok || typeof id !== 'string' ||
            typeof checkoutUrl !== 'string') {
          throw new Error(`paymongo ${response.status}`);
        }
        // The gateway reports the mode of the key; it must match ours.
        if (payload?.data?.attributes?.livemode !== (config.mode === 'live')) {
          throw new Error('paymongo mode mismatch');
        }
        return { id, checkoutUrl };
      },
      async attachSession(orderId, sessionId, url) {
        const { error } = await admin.rpc('attach_checkout_session', {
          p_order_id: orderId,
          p_session_id: sessionId,
          p_checkout_url: url,
        });
        if (error) throw new Error(error.message);
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
