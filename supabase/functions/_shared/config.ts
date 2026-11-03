// Environment configuration for the payment Edge Functions (Deno runtime).
//
// Test and live credentials are separate variables and the active mode is
// explicit, so a deployment can never silently use live keys:
//
//   PAYMONGO_MODE                      'test' | 'live'  (required, no default)
//   PAYMONGO_SECRET_KEY_TEST           sk_test_...
//   PAYMONGO_SECRET_KEY_LIVE           sk_live_...
//   PAYMONGO_WEBHOOK_SECRET_TEST       whsk_... of the test-mode webhook
//   PAYMONGO_WEBHOOK_SECRET_LIVE       whsk_... of the live-mode webhook
//   PAYMONGO_PAYMENT_METHOD_TYPES      comma list enabled on the merchant
//                                      account, e.g. "gcash,paymaya,card"
//   PAYMENT_SUCCESS_URL / PAYMENT_CANCEL_URL   optional return URLs
//   PAYMONGO_WEBHOOK_TOLERANCE_SECONDS         optional, default 86400
//
// Secrets are read only here, on the backend. SUPABASE_URL and
// SUPABASE_SERVICE_ROLE_KEY are provided by the Supabase runtime.

import type { PaymongoMode } from './paymongo.ts';

export interface PaymentConfig {
  mode: PaymongoMode;
  secretKey: string;
  webhookSecret: string;
  paymentMethodTypes: string[];
  successUrlBase: string;
  cancelUrlBase: string;
  toleranceSeconds: number;
}

export function loadPaymentConfig(
  env: (name: string) => string | undefined,
): PaymentConfig {
  const mode = env('PAYMONGO_MODE');
  if (mode !== 'test' && mode !== 'live') {
    throw new Error('PAYMONGO_MODE must be "test" or "live"');
  }
  const suffix = mode === 'live' ? 'LIVE' : 'TEST';
  const secretKey = env(`PAYMONGO_SECRET_KEY_${suffix}`) ?? '';
  const webhookSecret = env(`PAYMONGO_WEBHOOK_SECRET_${suffix}`) ?? '';
  // A key of the wrong mode is a configuration error, not a fallback.
  if (secretKey && !secretKey.startsWith(`sk_${mode}_`)) {
    throw new Error(`PAYMONGO_SECRET_KEY_${suffix} is not a ${mode} key`);
  }
  const tolerance = Number(env('PAYMONGO_WEBHOOK_TOLERANCE_SECONDS') ?? '');
  return {
    mode,
    secretKey,
    webhookSecret,
    paymentMethodTypes: (env('PAYMONGO_PAYMENT_METHOD_TYPES') ?? '')
      .split(',')
      .map((value) => value.trim())
      .filter((value) => value.length > 0),
    successUrlBase: env('PAYMENT_SUCCESS_URL') ??
      'achievia://callback?payment=success',
    cancelUrlBase: env('PAYMENT_CANCEL_URL') ??
      'achievia://callback?payment=cancelled',
    toleranceSeconds: Number.isFinite(tolerance) && tolerance >= 0 &&
        env('PAYMONGO_WEBHOOK_TOLERANCE_SECONDS') !== undefined
      ? tolerance
      : 86400,
  };
}

/** Appends the order id to a return URL base. */
export function withOrder(base: string, orderId: string): string {
  const separator = base.includes('?') ? '&' : '?';
  return `${base}${separator}order=${encodeURIComponent(orderId)}`;
}
