// PayMongo helpers shared by the Edge Functions.
//
// Pure logic only (Web Crypto + plain objects, no Deno or Node globals beyond
// `crypto`), so the same file runs in the Supabase Edge runtime and in the
// local node tests (supabase/functions/tests).
//
// Verified against the PayMongo documentation on 2026-10-12:
//   * Webhook signature: header `Paymongo-Signature: t=<unix>,te=<hex>,li=<hex>`;
//     signed string is `<t>.<raw request body>`; HMAC-SHA256 with the webhook
//     secret; compare `te` for test-mode events and `li` for live-mode events
//     (docs.paymongo.com "Setup & Management" / "Best Practices").
//   * Checkout Session: POST https://api.paymongo.com/v2/checkout_sessions,
//     HTTP Basic auth with the secret key as username and an empty password;
//     body { data: { attributes: { line_items, payment_method_types,
//     success_url, cancel_url, reference_number, metadata, ... } } };
//     response data.id and data.attributes.checkout_url. Paid sessions fire
//     the `checkout_session.payment.paid` webhook event.
// The docs do not spell out the amount unit; this code sends integer
// centavos as the requirement states. Confirm with the first test-mode
// checkout (PHP 299 must show as PHP 299.00 on the PayMongo page).

export type PaymongoMode = 'test' | 'live';

export interface SignatureHeader {
  t: string;
  te: string;
  li: string;
}

export function parseSignatureHeader(
  header: string | null | undefined,
): SignatureHeader | null {
  if (!header) return null;
  const parts: Record<string, string> = {};
  for (const piece of header.split(',')) {
    const index = piece.indexOf('=');
    if (index < 0) continue;
    parts[piece.slice(0, index).trim()] = piece.slice(index + 1).trim();
  }
  if (!parts.t) return null;
  return { t: parts.t, te: parts.te ?? '', li: parts.li ?? '' };
}

async function hmacSha256Hex(secret: string, message: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(message),
  );
  return Array.from(new Uint8Array(signature))
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');
}

/** Constant-time comparison for equal-length hex strings. */
export function timingSafeEqualHex(a: string, b: string): boolean {
  if (a.length !== b.length || a.length === 0) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

export type SignatureResult =
  | { ok: true; mode: PaymongoMode }
  | { ok: false; reason: string };

export async function verifyWebhookSignature(options: {
  rawBody: string;
  header: string | null | undefined;
  secret: string;
  nowSeconds: number;
  /** 0 disables the age check (event-id idempotency already stops replays). */
  toleranceSeconds: number;
}): Promise<SignatureResult> {
  const { rawBody, header, secret, nowSeconds, toleranceSeconds } = options;
  if (!secret) return { ok: false, reason: 'missing_secret' };
  const parsed = parseSignatureHeader(header);
  if (!parsed) return { ok: false, reason: 'missing_or_malformed_header' };

  const timestamp = Number(parsed.t);
  if (!Number.isFinite(timestamp)) {
    return { ok: false, reason: 'malformed_timestamp' };
  }
  if (
    toleranceSeconds > 0 &&
    Math.abs(nowSeconds - timestamp) > toleranceSeconds
  ) {
    return { ok: false, reason: 'timestamp_out_of_tolerance' };
  }

  const expected = await hmacSha256Hex(secret, `${parsed.t}.${rawBody}`);
  // Evaluate both so timing does not reveal which field matched.
  const isTest = timingSafeEqualHex(expected, parsed.te);
  const isLive = timingSafeEqualHex(expected, parsed.li);
  if (isTest) return { ok: true, mode: 'test' };
  if (isLive) return { ok: true, mode: 'live' };
  return { ok: false, reason: 'signature_mismatch' };
}

// ---------------------------------------------------------------------------
// Event parsing
// ---------------------------------------------------------------------------

// deno-lint-ignore no-explicit-any
type Json = any;

export interface WebhookEvent {
  eventId: string;
  type: string;
  livemode: boolean;
  resource: Json;
}

export function parseWebhookEvent(rawBody: string): WebhookEvent | null {
  let body: Json;
  try {
    body = JSON.parse(rawBody);
  } catch (_) {
    return null;
  }
  const data = body?.data;
  const attributes = data?.attributes;
  if (
    typeof data?.id !== 'string' ||
    typeof attributes?.type !== 'string' ||
    typeof attributes?.livemode !== 'boolean'
  ) {
    return null;
  }
  return {
    eventId: data.id,
    type: attributes.type,
    livemode: attributes.livemode,
    resource: attributes.data ?? null,
  };
}

export interface PaidCheckout {
  sessionId: string;
  referenceNumber: string | null;
  paymentId: string | null;
  amount: number;
  currency: string;
  paymentStatus: string;
  paymentMethod: string | null;
}

/** Reads a `checkout_session.payment.paid` resource. Null = unusable payload. */
export function extractPaidCheckout(event: WebhookEvent): PaidCheckout | null {
  const session = event.resource;
  const sessionId = session?.id;
  if (typeof sessionId !== 'string' || !sessionId.startsWith('cs_')) {
    return null;
  }
  const attributes = session.attributes ?? {};
  const payments: Json[] = Array.isArray(attributes.payments)
    ? attributes.payments
    : [];
  // The payment that completed the session.
  const payment =
    payments.find((p) => p?.attributes?.status === 'paid') ?? payments[0];
  const paymentAttributes = payment?.attributes;
  if (!paymentAttributes) return null;

  const amount = paymentAttributes.amount;
  if (!Number.isInteger(amount)) return null;

  const reference = attributes.reference_number ??
    attributes.metadata?.order_id ?? null;
  const source = paymentAttributes.source;
  return {
    sessionId,
    referenceNumber: typeof reference === 'string' ? reference : null,
    paymentId: typeof payment.id === 'string' ? payment.id : null,
    amount,
    currency: String(paymentAttributes.currency ?? '').toUpperCase(),
    paymentStatus: String(paymentAttributes.status ?? ''),
    paymentMethod: typeof source?.type === 'string' ? source.type : null,
  };
}

export interface FailedPayment {
  reference: string | null;
  reason: string;
}

/** Best-effort read of a `payment.failed` resource (never grants anything). */
export function extractFailedPayment(event: WebhookEvent): FailedPayment {
  const attributes = event.resource?.attributes ?? {};
  const candidates = [
    attributes.metadata?.order_id,
    attributes.external_reference_number,
    attributes.reference_number,
  ];
  const reference = candidates.find((value) =>
    typeof value === 'string' && value.length > 0
  );
  const reason = attributes.failed_code ?? attributes.failed_message ??
    attributes.status ?? 'failed';
  return {
    reference: reference ?? null,
    reason: String(reason).slice(0, 200),
  };
}

// ---------------------------------------------------------------------------
// Webhook handler (framework independent)
// ---------------------------------------------------------------------------

export interface FulfillArgs {
  eventId: string;
  eventType: string;
  livemode: boolean;
  sessionId: string;
  reference: string | null;
  paymentId: string | null;
  amount: number;
  currency: string;
  paymentStatus: string;
  paymentMethod: string | null;
}

export interface WebhookDeps {
  /** Mode this deployment is configured for and its endpoint secret. */
  mode: PaymongoMode;
  secret: string;
  nowSeconds: number;
  toleranceSeconds: number;
  /** Calls public.fulfill_payment; resolves to its `outcome`. */
  fulfill(args: FulfillArgs): Promise<string>;
  /** Calls public.record_payment_failure; resolves to its `outcome`. */
  recordFailure(args: {
    eventId: string;
    eventType: string;
    livemode: boolean;
    reference: string | null;
    reason: string;
  }): Promise<string>;
  log?(message: string): void;
}

export interface HandlerResponse {
  status: number;
  body: Record<string, unknown>;
}

export async function handlePaymongoWebhook(
  request: { method: string; rawBody: string; signature: string | null },
  deps: WebhookDeps,
): Promise<HandlerResponse> {
  const log = deps.log ?? (() => {});
  if (request.method !== 'POST') {
    return { status: 405, body: { error: 'method_not_allowed' } };
  }
  if (!deps.secret) {
    log('webhook secret is not configured');
    return { status: 500, body: { error: 'not_configured' } };
  }

  // 1. Signature first, on the raw body, before anything is parsed.
  const verified = await verifyWebhookSignature({
    rawBody: request.rawBody,
    header: request.signature,
    secret: deps.secret,
    nowSeconds: deps.nowSeconds,
    toleranceSeconds: deps.toleranceSeconds,
  });
  if (!verified.ok) {
    log(`signature rejected: ${verified.reason}`);
    return { status: 401, body: { error: 'invalid_signature' } };
  }

  const event = parseWebhookEvent(request.rawBody);
  if (!event) {
    return { status: 400, body: { error: 'malformed_event' } };
  }

  // 2. The signature field that matched, the event's own livemode flag and
  //    this deployment's mode must all agree.
  const eventMode: PaymongoMode = event.livemode ? 'live' : 'test';
  if (verified.mode !== eventMode || eventMode !== deps.mode) {
    log(`event ${event.eventId} ignored: mode mismatch`);
    return { status: 200, body: { outcome: 'ignored_mode_mismatch' } };
  }

  // 3. Dispatch. Anything that is not an explicit success event grants nothing.
  try {
    if (event.type === 'checkout_session.payment.paid') {
      const paid = extractPaidCheckout(event);
      if (!paid) {
        log(`event ${event.eventId}: unusable paid payload`);
        return { status: 200, body: { outcome: 'rejected_unusable_payload' } };
      }
      const outcome = await deps.fulfill({
        eventId: event.eventId,
        eventType: event.type,
        livemode: event.livemode,
        sessionId: paid.sessionId,
        reference: paid.referenceNumber,
        paymentId: paid.paymentId,
        amount: paid.amount,
        currency: paid.currency,
        paymentStatus: paid.paymentStatus,
        paymentMethod: paid.paymentMethod,
      });
      log(`event ${event.eventId}: ${outcome}`);
      return { status: 200, body: { outcome } };
    }

    if (event.type === 'payment.failed') {
      const failed = extractFailedPayment(event);
      const outcome = await deps.recordFailure({
        eventId: event.eventId,
        eventType: event.type,
        livemode: event.livemode,
        reference: failed.reference,
        reason: failed.reason,
      });
      return { status: 200, body: { outcome } };
    }
  } catch (error) {
    // A database/transient failure: answer non-2xx so PayMongo retries.
    log(`event ${event.eventId}: processing error ${String(error)}`);
    return { status: 500, body: { error: 'processing_failed' } };
  }

  return { status: 200, body: { outcome: 'ignored_event_type' } };
}

// ---------------------------------------------------------------------------
// Checkout creation (framework independent)
// ---------------------------------------------------------------------------

export interface OrderRow {
  id: string;
  user_id: string;
  plan_code: string;
  kind: string;
  amount_centavos: number;
  currency: string;
  checkout_url: string | null;
}

export interface CheckoutDeps {
  mode: PaymongoMode;
  /** Resolves a bearer token to a user id, or null when it is not valid. */
  authenticate(token: string): Promise<string | null>;
  /** public.create_payment_order; throws 'plan_unavailable' / 'already_owned'. */
  createOrder(
    userId: string,
    planCode: string,
    mode: PaymongoMode,
  ): Promise<OrderRow>;
  planTitle(planCode: string): Promise<string>;
  createSession(
    body: Json,
    idempotencyKey: string,
  ): Promise<{ id: string; checkoutUrl: string }>;
  attachSession(orderId: string, sessionId: string, url: string): Promise<void>;
  paymentMethodTypes: string[];
  successUrl(orderId: string): string;
  cancelUrl(orderId: string): string;
  log?(message: string): void;
}

export function buildCheckoutSessionBody(options: {
  order: OrderRow;
  title: string;
  paymentMethodTypes: string[];
  successUrl: string;
  cancelUrl: string;
}): Json {
  const { order } = options;
  if (!Number.isInteger(order.amount_centavos) || order.amount_centavos <= 0) {
    throw new Error('invalid_amount');
  }
  return {
    data: {
      attributes: {
        line_items: [
          {
            name: options.title,
            quantity: 1,
            amount: order.amount_centavos, // integer centavos
            currency: order.currency,
          },
        ],
        payment_method_types: options.paymentMethodTypes,
        success_url: options.successUrl,
        cancel_url: options.cancelUrl,
        reference_number: order.id,
        description: `Achievia - ${options.title}`,
        send_email_receipt: false,
        show_description: true,
        show_line_items: true,
        metadata: {
          order_id: order.id,
          user_id: order.user_id,
          plan_code: order.plan_code,
          kind: order.kind,
        },
      },
    },
  };
}

const PLAN_CODE = /^[a-z0-9_]{1,32}$/;

export async function handleCreateCheckout(
  request: { method: string; authorization: string | null; body: Json },
  deps: CheckoutDeps,
): Promise<HandlerResponse> {
  const log = deps.log ?? (() => {});
  if (request.method !== 'POST') {
    return { status: 405, body: { error: 'method_not_allowed' } };
  }
  const token = /^Bearer\s+(.+)$/i.exec(request.authorization ?? '')?.[1];
  const userId = token ? await deps.authenticate(token) : null;
  if (!userId) {
    return { status: 401, body: { error: 'unauthorized' } };
  }
  const planCode = request.body?.plan_code;
  if (typeof planCode !== 'string' || !PLAN_CODE.test(planCode)) {
    return { status: 400, body: { error: 'invalid_plan' } };
  }
  if (deps.paymentMethodTypes.length === 0) {
    log('PAYMONGO_PAYMENT_METHOD_TYPES is not configured');
    return { status: 503, body: { error: 'payments_not_configured' } };
  }

  let order: OrderRow;
  try {
    // The amount comes from the database; nothing in the request body can
    // influence it.
    order = await deps.createOrder(userId, planCode, deps.mode);
  } catch (error) {
    const message = String((error as Error)?.message ?? error);
    if (message.includes('plan_unavailable')) {
      return { status: 404, body: { error: 'plan_unavailable' } };
    }
    if (message.includes('already_owned')) {
      return { status: 409, body: { error: 'already_owned' } };
    }
    log(`create order failed: ${message}`);
    return { status: 500, body: { error: 'order_failed' } };
  }

  if (order.checkout_url) {
    return {
      status: 200,
      body: {
        order_id: order.id,
        checkout_url: order.checkout_url,
        amount_centavos: order.amount_centavos,
        reused: true,
      },
    };
  }

  try {
    const body = buildCheckoutSessionBody({
      order,
      title: await deps.planTitle(order.plan_code),
      paymentMethodTypes: deps.paymentMethodTypes,
      successUrl: deps.successUrl(order.id),
      cancelUrl: deps.cancelUrl(order.id),
    });
    const session = await deps.createSession(body, order.id);
    await deps.attachSession(order.id, session.id, session.checkoutUrl);
    return {
      status: 200,
      body: {
        order_id: order.id,
        checkout_url: session.checkoutUrl,
        amount_centavos: order.amount_centavos,
        reused: false,
      },
    };
  } catch (error) {
    // Never forward gateway details to the client.
    log(`checkout session failed: ${String(error)}`);
    return { status: 502, body: { error: 'gateway_error' } };
  }
}
