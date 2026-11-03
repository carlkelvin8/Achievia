// Run with:  node --test supabase/functions/tests/paymongo.test.ts
// (Node 22+, type stripping). No network, no Supabase, no PayMongo.
import assert from 'node:assert/strict';
import { createHmac } from 'node:crypto';
import { test } from 'node:test';

import { loadPaymentConfig, withOrder } from '../_shared/config.ts';
import {
  buildCheckoutSessionBody,
  extractPaidCheckout,
  handleCreateCheckout,
  handlePaymongoWebhook,
  parseSignatureHeader,
  parseWebhookEvent,
  verifyWebhookSignature,
} from '../_shared/paymongo.ts';

const SECRET = 'whsk_test_secret';
const NOW = 1_800_000_000;
const ORDER_ID = '11111111-2222-4333-8444-555555555555';

function sign(body: string, mode: 'test' | 'live', t = NOW, secret = SECRET) {
  const digest = createHmac('sha256', secret)
    .update(`${t}.${body}`)
    .digest('hex');
  return mode === 'test'
    ? `t=${t},te=${digest},li=`
    : `t=${t},te=,li=${digest}`;
}

function paidEvent(overrides: Record<string, unknown> = {}, livemode = false) {
  return JSON.stringify({
    data: {
      id: 'evt_paid_1',
      type: 'event',
      attributes: {
        type: 'checkout_session.payment.paid',
        livemode,
        created_at: NOW,
        data: {
          id: 'cs_abc',
          type: 'checkout_session',
          attributes: {
            reference_number: ORDER_ID,
            metadata: { order_id: ORDER_ID },
            payments: [
              {
                id: 'pay_1',
                attributes: {
                  amount: 59900,
                  currency: 'PHP',
                  status: 'paid',
                  source: { type: 'gcash' },
                },
              },
            ],
            ...overrides,
          },
        },
      },
    },
  });
}

function webhookDeps(calls: Record<string, unknown[]>, extra = {}) {
  return {
    mode: 'test' as const,
    secret: SECRET,
    nowSeconds: NOW,
    toleranceSeconds: 86400,
    async fulfill(args: unknown) {
      calls.fulfill.push(args);
      return 'granted';
    },
    async recordFailure(args: unknown) {
      calls.fail.push(args);
      return 'failure_recorded';
    },
    ...extra,
  };
}

const newCalls = () => ({ fulfill: [] as unknown[], fail: [] as unknown[] });

// --- signature -------------------------------------------------------------

test('parses the Paymongo-Signature header', () => {
  assert.deepEqual(parseSignatureHeader('t=1,te=abc,li='), {
    t: '1',
    te: 'abc',
    li: '',
  });
  assert.equal(parseSignatureHeader(''), null);
  assert.equal(parseSignatureHeader('te=abc'), null);
});

test('accepts a valid test and a valid live signature', async () => {
  const body = paidEvent();
  const test = await verifyWebhookSignature({
    rawBody: body,
    header: sign(body, 'test'),
    secret: SECRET,
    nowSeconds: NOW,
    toleranceSeconds: 0,
  });
  assert.deepEqual(test, { ok: true, mode: 'test' });
  const live = await verifyWebhookSignature({
    rawBody: body,
    header: sign(body, 'live'),
    secret: SECRET,
    nowSeconds: NOW,
    toleranceSeconds: 0,
  });
  assert.deepEqual(live, { ok: true, mode: 'live' });
});

test('rejects wrong secret, tampered body, empty fields and stale timestamps',
  async () => {
    const body = paidEvent();
    const check = (rawBody: string, header: string | null, secret = SECRET,
      tolerance = 300) =>
      verifyWebhookSignature({
        rawBody,
        header,
        secret,
        nowSeconds: NOW,
        toleranceSeconds: tolerance,
      });
    assert.equal((await check(body, sign(body, 'test', NOW, 'other'))).ok,
      false);
    assert.equal((await check(body + ' ', sign(body, 'test'))).ok, false);
    assert.equal((await check(body, null)).ok, false);
    assert.equal((await check(body, 't=1800000000,te=,li=')).ok, false);
    assert.equal((await check(body, sign(body, 'test', NOW - 10_000))).ok,
      false);
    assert.equal((await check(body, sign(body, 'test'), '')).ok, false);
  });

// --- webhook handler ---------------------------------------------------------

test('a signed paid event is fulfilled with the verified payment values',
  async () => {
    const calls = newCalls();
    const body = paidEvent();
    const result = await handlePaymongoWebhook(
      { method: 'POST', rawBody: body, signature: sign(body, 'test') },
      webhookDeps(calls),
    );
    assert.equal(result.status, 200);
    assert.deepEqual(result.body, { outcome: 'granted' });
    assert.deepEqual(calls.fulfill, [{
      eventId: 'evt_paid_1',
      eventType: 'checkout_session.payment.paid',
      livemode: false,
      sessionId: 'cs_abc',
      reference: ORDER_ID,
      paymentId: 'pay_1',
      amount: 59900,
      currency: 'PHP',
      paymentStatus: 'paid',
      paymentMethod: 'gcash',
    }]);
  });

test('an unsigned or forged event never reaches fulfilment', async () => {
  for (const signature of [null, 't=1,te=deadbeef,li=', sign('x', 'test')]) {
    const calls = newCalls();
    const result = await handlePaymongoWebhook(
      { method: 'POST', rawBody: paidEvent(), signature },
      webhookDeps(calls),
    );
    assert.equal(result.status, 401);
    assert.equal(calls.fulfill.length, 0);
  }
});

test('a live event on a test deployment (and vice versa) is ignored',
  async () => {
    const calls = newCalls();
    const liveBody = paidEvent({}, true);
    const result = await handlePaymongoWebhook(
      { method: 'POST', rawBody: liveBody, signature: sign(liveBody, 'live') },
      webhookDeps(calls),
    );
    assert.equal(result.status, 200);
    assert.equal(result.body.outcome, 'ignored_mode_mismatch');
    assert.equal(calls.fulfill.length, 0);

    // Signed with the test field but claiming livemode=true is also refused.
    const mixed = paidEvent({}, true);
    const mixedResult = await handlePaymongoWebhook(
      { method: 'POST', rawBody: mixed, signature: sign(mixed, 'test') },
      webhookDeps(calls),
    );
    assert.equal(mixedResult.body.outcome, 'ignored_mode_mismatch');
    assert.equal(calls.fulfill.length, 0);
  });

test('a database error answers 500 so PayMongo retries', async () => {
  const body = paidEvent();
  const result = await handlePaymongoWebhook(
    { method: 'POST', rawBody: body, signature: sign(body, 'test') },
    webhookDeps(newCalls(), {
      async fulfill() {
        throw new Error('connection reset');
      },
    }),
  );
  assert.equal(result.status, 500);
});

test('duplicate deliveries are passed through to the idempotent function',
  async () => {
    const seen = new Set<string>();
    const body = paidEvent();
    const deps = webhookDeps(newCalls(), {
      async fulfill(args: { eventId: string }) {
        const duplicate = seen.has(args.eventId);
        seen.add(args.eventId);
        return duplicate ? 'duplicate_event' : 'granted';
      },
    });
    const first = await handlePaymongoWebhook(
      { method: 'POST', rawBody: body, signature: sign(body, 'test') }, deps);
    const second = await handlePaymongoWebhook(
      { method: 'POST', rawBody: body, signature: sign(body, 'test') }, deps);
    assert.equal(first.body.outcome, 'granted');
    assert.equal(second.body.outcome, 'duplicate_event');
    assert.equal(second.status, 200);
  });

test('failed payments and unrelated events never fulfil', async () => {
  const calls = newCalls();
  const failed = JSON.stringify({
    data: {
      id: 'evt_f',
      attributes: {
        type: 'payment.failed',
        livemode: false,
        data: {
          id: 'pay_x',
          attributes: {
            status: 'failed',
            metadata: { order_id: ORDER_ID },
            failed_code: 'processor_blocked',
          },
        },
      },
    },
  });
  const result = await handlePaymongoWebhook(
    { method: 'POST', rawBody: failed, signature: sign(failed, 'test') },
    webhookDeps(calls),
  );
  assert.equal(result.status, 200);
  assert.equal(calls.fulfill.length, 0);
  assert.deepEqual(calls.fail, [{
    eventId: 'evt_f',
    eventType: 'payment.failed',
    livemode: false,
    reference: ORDER_ID,
    reason: 'processor_blocked',
  }]);

  const other = JSON.stringify({
    data: { id: 'evt_o', attributes: { type: 'refund.succeeded',
      livemode: false, data: { id: 'ref_1' } } },
  });
  const ignored = await handlePaymongoWebhook(
    { method: 'POST', rawBody: other, signature: sign(other, 'test') },
    webhookDeps(calls),
  );
  assert.equal(ignored.body.outcome, 'ignored_event_type');
  assert.equal(calls.fulfill.length, 0);
});

test('an unusable paid payload is rejected without fulfilment', async () => {
  const calls = newCalls();
  const body = paidEvent({ payments: [] });
  const result = await handlePaymongoWebhook(
    { method: 'POST', rawBody: body, signature: sign(body, 'test') },
    webhookDeps(calls),
  );
  assert.equal(result.body.outcome, 'rejected_unusable_payload');
  assert.equal(calls.fulfill.length, 0);
});

test('only POST is accepted and a missing secret fails closed', async () => {
  const get = await handlePaymongoWebhook(
    { method: 'GET', rawBody: '', signature: null }, webhookDeps(newCalls()));
  assert.equal(get.status, 405);
  const body = paidEvent();
  const noSecret = await handlePaymongoWebhook(
    { method: 'POST', rawBody: body, signature: sign(body, 'test') },
    webhookDeps(newCalls(), { secret: '' }),
  );
  assert.equal(noSecret.status, 500);
});

test('event parsing is defensive', () => {
  assert.equal(parseWebhookEvent('not json'), null);
  assert.equal(parseWebhookEvent('{}'), null);
  const event = parseWebhookEvent(paidEvent())!;
  assert.equal(extractPaidCheckout(event)?.amount, 59900);
  assert.equal(
    extractPaidCheckout({ ...event, resource: { id: 'pi_1' } }), null);
});

// --- checkout creation -------------------------------------------------------

function checkoutDeps(log: string[], extra = {}) {
  return {
    mode: 'test' as const,
    paymentMethodTypes: ['gcash', 'card'],
    successUrl: (id: string) => withOrder('achievia://callback?payment=success', id),
    cancelUrl: (id: string) => withOrder('achievia://callback?payment=cancelled', id),
    async authenticate(token: string) {
      return token === 'good' ? 'user-1' : null;
    },
    async createOrder(userId: string, planCode: string) {
      log.push(`order:${userId}:${planCode}`);
      return {
        id: ORDER_ID,
        user_id: userId,
        plan_code: planCode,
        kind: 'subscription',
        amount_centavos: 59900, // authoritative, from the database
        currency: 'PHP',
        checkout_url: null,
      };
    },
    async planTitle() {
      return '3 Months';
    },
    async createSession(body: unknown, key: string) {
      log.push(`session:${key}:${JSON.stringify(body)}`);
      return { id: 'cs_new', checkoutUrl: 'https://pm.link/cs_new' };
    },
    async attachSession(orderId: string, sessionId: string) {
      log.push(`attach:${orderId}:${sessionId}`);
    },
    ...extra,
  };
}

test('checkout uses the database price and ignores client amounts',
  async () => {
    const log: string[] = [];
    const result = await handleCreateCheckout(
      {
        method: 'POST',
        authorization: 'Bearer good',
        body: { plan_code: 'sub_3m', amount: 1, amount_centavos: 1 },
      },
      checkoutDeps(log),
    );
    assert.equal(result.status, 200);
    assert.equal(result.body.amount_centavos, 59900);
    assert.equal(result.body.checkout_url, 'https://pm.link/cs_new');
    const sent = JSON.parse(log.find((l) => l.startsWith('session:'))!
      .replace(/^session:[^:]+:/, ''));
    const attributes = sent.data.attributes;
    assert.equal(attributes.line_items[0].amount, 59900);
    assert.equal(attributes.line_items[0].currency, 'PHP');
    assert.equal(attributes.line_items[0].quantity, 1);
    assert.deepEqual(attributes.payment_method_types, ['gcash', 'card']);
    assert.equal(attributes.reference_number, ORDER_ID);
    assert.equal(attributes.metadata.order_id, ORDER_ID);
    assert.equal(attributes.success_url,
      `achievia://callback?payment=success&order=${ORDER_ID}`);
    assert.ok(log.includes(`attach:${ORDER_ID}:cs_new`));
    assert.ok(log.some((l) => l.startsWith(`session:${ORDER_ID}:`)),
      'order id is the idempotency key');
  });

test('checkout rejects anonymous callers and bad plan codes', async () => {
  const log: string[] = [];
  const anon = await handleCreateCheckout(
    { method: 'POST', authorization: null, body: { plan_code: 'sub_1m' } },
    checkoutDeps(log));
  assert.equal(anon.status, 401);
  const badToken = await handleCreateCheckout(
    { method: 'POST', authorization: 'Bearer nope',
      body: { plan_code: 'sub_1m' } }, checkoutDeps(log));
  assert.equal(badToken.status, 401);
  for (const body of [{}, { plan_code: 5 }, { plan_code: 'sub; drop' }]) {
    const result = await handleCreateCheckout(
      { method: 'POST', authorization: 'Bearer good', body },
      checkoutDeps(log));
    assert.equal(result.status, 400);
  }
  assert.equal(log.length, 0, 'no order is created for invalid requests');
});

test('checkout maps business errors and hides gateway details', async () => {
  const unavailable = await handleCreateCheckout(
    { method: 'POST', authorization: 'Bearer good',
      body: { plan_code: 'mother_notes' } },
    checkoutDeps([], {
      async createOrder() {
        throw new Error('plan_unavailable');
      },
    }));
  assert.equal(unavailable.status, 404);
  const owned = await handleCreateCheckout(
    { method: 'POST', authorization: 'Bearer good',
      body: { plan_code: 'mother_notes' } },
    checkoutDeps([], {
      async createOrder() {
        throw new Error('already_owned');
      },
    }));
  assert.equal(owned.status, 409);
  const gateway = await handleCreateCheckout(
    { method: 'POST', authorization: 'Bearer good',
      body: { plan_code: 'sub_1m' } },
    checkoutDeps([], {
      async createSession() {
        throw new Error('paymongo 400: secret sk_test_leak');
      },
    }));
  assert.equal(gateway.status, 502);
  assert.equal(JSON.stringify(gateway.body).includes('sk_test'), false);
});

test('an open order with a checkout page is reused, not recreated',
  async () => {
    const log: string[] = [];
    const result = await handleCreateCheckout(
      { method: 'POST', authorization: 'Bearer good',
        body: { plan_code: 'sub_3m' } },
      checkoutDeps(log, {
        async createOrder(userId: string, planCode: string) {
          return {
            id: ORDER_ID, user_id: userId, plan_code: planCode,
            kind: 'subscription', amount_centavos: 59900, currency: 'PHP',
            checkout_url: 'https://pm.link/existing',
          };
        },
      }));
    assert.equal(result.body.checkout_url, 'https://pm.link/existing');
    assert.equal(result.body.reused, true);
    assert.equal(log.some((l) => l.startsWith('session:')), false);
  });

test('payment methods must be configured explicitly', async () => {
  const result = await handleCreateCheckout(
    { method: 'POST', authorization: 'Bearer good',
      body: { plan_code: 'sub_1m' } },
    checkoutDeps([], { paymentMethodTypes: [] }));
  assert.equal(result.status, 503);
});

test('session body only accepts positive integer centavos', () => {
  const base = {
    id: ORDER_ID, user_id: 'u', plan_code: 'sub_1m', kind: 'subscription',
    currency: 'PHP', checkout_url: null,
  };
  for (const amount of [299.5, 0, -1, Number.NaN]) {
    assert.throws(() => buildCheckoutSessionBody({
      order: { ...base, amount_centavos: amount },
      title: 'x', paymentMethodTypes: ['card'], successUrl: 's', cancelUrl: 'c',
    }));
  }
});

// --- configuration -------------------------------------------------------------

test('mode must be explicit and keys must match it', () => {
  const env = (values: Record<string, string>) => (name: string) =>
    values[name];
  assert.throws(() => loadPaymentConfig(env({})));
  assert.throws(() => loadPaymentConfig(env({ PAYMONGO_MODE: 'prod' })));
  assert.throws(() => loadPaymentConfig(env({
    PAYMONGO_MODE: 'test',
    PAYMONGO_SECRET_KEY_TEST: 'sk_live_wrongmode',
  })));
  const config = loadPaymentConfig(env({
    PAYMONGO_MODE: 'live',
    PAYMONGO_SECRET_KEY_LIVE: 'sk_live_abc',
    PAYMONGO_SECRET_KEY_TEST: 'sk_test_abc',
    PAYMONGO_WEBHOOK_SECRET_LIVE: 'whsk_live',
    PAYMONGO_WEBHOOK_SECRET_TEST: 'whsk_test',
    PAYMONGO_PAYMENT_METHOD_TYPES: 'gcash, card ,',
  }));
  assert.equal(config.secretKey, 'sk_live_abc');
  assert.equal(config.webhookSecret, 'whsk_live');
  assert.deepEqual(config.paymentMethodTypes, ['gcash', 'card']);
});
