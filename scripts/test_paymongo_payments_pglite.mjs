// Local-only test of supabase/proposed/20261014000000_paymongo_payments.sql
// (and its rollback) on PGlite, a WASM build of PostgreSQL. Use it when Docker
// is not available; scripts/test_paymongo_payments.py is the container
// equivalent (it also runs the parallel-delivery case, which a single
// connection cannot).
//
//   npm install --no-save @electric-sql/pglite
//   node scripts/test_paymongo_payments_pglite.mjs
//
import { PGlite } from '@electric-sql/pglite';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('..', import.meta.url));

const patch = readFileSync(
  root + 'supabase/proposed/20261014000000_paymongo_payments.sql',
  'utf8',
);
const U1 = '00000000-0000-0000-0000-000000000001';
const U2 = '00000000-0000-0000-0000-000000000002';

const db = new PGlite();
await db.exec(`
create schema auth;
create role anon nologin; create role authenticated nologin; create role service_role nologin;
create table auth.users(id uuid primary key, email text);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid; $$;
grant usage on schema public, auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
insert into auth.users values ('${U1}','a@example.test'),('${U2}','b@example.test');
`);
await db.exec(patch);
await db.exec(patch); // idempotent re-run
const trialPatch = readFileSync(
  root + 'supabase/proposed/20261014100000_free_trial.sql',
  'utf8',
);
await db.exec(trialPatch);
await db.exec(trialPatch);

let passed = 0;
const ok = (m) => { passed++; console.log('VERIFIED:', m); };

async function as(role, sub, sql) {
  await db.exec(`set role ${role};`);
  if (sub) await db.exec(`select set_config('request.jwt.claim.sub','${sub}',false);`);
  try {
    const res = await db.query(sql);
    return res.rows;
  } finally {
    await db.exec('reset role;');
  }
}
const sv = (sql) => as('service_role', null, sql);
const scalar = async (rows) => Object.values(rows[0] ?? {})[0] ?? null;
async function fails(promise, fragment) {
  try { await promise; } catch (e) {
    assert.ok(String(e.message).toLowerCase().includes(fragment.toLowerCase()),
      `expected "${fragment}", got "${e.message}"`);
    return;
  }
  assert.fail(`expected failure containing "${fragment}"`);
}
const fulfill = (event, session, ref, o = {}) => sv(
  `select public.fulfill_payment('${event}','checkout_session.payment.paid',` +
  `${o.livemode ?? 'false'},'${session}','${ref}','${o.payment ?? 'pay_1'}',` +
  `${o.amount ?? 59900},'${o.currency ?? 'PHP'}','${o.status ?? 'paid'}','gcash')->>'outcome' as o`);
async function newOrder(user, plan, session, mode = 'test') {
  const r = await sv(`select (public.create_payment_order('${user}','${plan}','${mode}')).id as id`);
  const id = r[0].id;
  if (session) await sv(`select public.attach_checkout_session('${id}','${session}','https://c.example.test/${session}')`);
  return id;
}

// 1 catalogue
let rows = await db.query(`select string_agg(code||'='||amount_centavos, ',' order by sort_order) s from public.billing_plans where kind='subscription'`);
assert.equal(rows.rows[0].s, 'sub_1m=29900,sub_3m=59900,sub_6m=99900,sub_12m=169900');
await fails(sv(`select public.create_payment_order('${U1}','mother_notes','test')`), 'plan_unavailable');
await fails(sv(`select public.create_payment_order('${U1}','nope','test')`), 'plan_unavailable');
ok('plans are integer centavos; Mother Notes not purchasable without a price; unknown plan refused');

// 2 order snapshot + reuse
const o1 = await newOrder(U1, 'sub_3m', 'cs_1');
rows = await db.query(`select amount_centavos,currency,status,mode,duration_months from public.payment_orders where id='${o1}'`);
assert.deepEqual(rows.rows[0], { amount_centavos: 59900, currency: 'PHP', status: 'pending', mode: 'test', duration_months: 3 });
assert.equal((await sv(`select (public.create_payment_order('${U1}','sub_3m','test')).id as id`))[0].id, o1);
ok('order snapshots the catalogue price; open order is reused');

// 3 unpaid grants nothing
assert.equal((await db.query('select count(*)::int c from public.user_subscriptions')).rows[0].c, 0);
assert.equal((await as('authenticated', U1, `select (public.get_my_access())->>'subscription_active' a`))[0].a, 'false');
ok('an unpaid order grants no access');

// 4 verified paid grants 3 months
assert.equal((await fulfill('evt_1', 'cs_1', o1))[0].o, 'granted');
rows = await db.query(`select extract(epoch from (expires_at - now()))/86400 d from public.user_subscriptions where user_id='${U1}'`);
assert.ok(rows.rows[0].d > 88 && rows.rows[0].d < 93, rows.rows[0].d);
assert.equal((await as('authenticated', U1, `select (public.get_my_access())->>'subscription_active' a`))[0].a, 'true');
ok('verified paid event grants 3 months');

// 5 duplicates
const before = (await db.query(`select expires_at from public.user_subscriptions where user_id='${U1}'`)).rows[0].expires_at.toISOString();
assert.equal((await fulfill('evt_1', 'cs_1', o1))[0].o, 'duplicate_event');
assert.equal((await fulfill('evt_1b', 'cs_1', o1))[0].o, 'already_paid');
const after = (await db.query(`select expires_at from public.user_subscriptions where user_id='${U1}'`)).rows[0].expires_at.toISOString();
assert.equal(before, after);
assert.equal((await db.query(`select count(*)::int c from public.subscription_grants where order_id='${o1}'`)).rows[0].c, 1);
ok('duplicate delivery and second event for same order never extend twice');

// 6 mismatches
const cases = [
  [{ amount: 100 }, 'rejected_amount_mismatch'],
  [{ currency: 'USD' }, 'rejected_currency_mismatch'],
  [{ livemode: 'true' }, 'rejected_mode_mismatch'],
  [{ status: 'failed' }, 'rejected_not_paid'],
];
for (const [i, [extra, expected]] of cases.entries()) {
  const order = await newOrder(U2, 'sub_1m', `cs_bad_${i}`);
  const got = (await fulfill(`evt_bad_${i}`, `cs_bad_${i}`, order, { amount: 29900, ...extra }))[0].o;
  assert.equal(got, expected);
  await db.exec(`update public.payment_orders set status='cancelled' where id='${order}'`);
}
await newOrder(U2, 'sub_1m', 'cs_ref');
assert.equal((await fulfill('evt_ref', 'cs_ref', U1, { amount: 29900 }))[0].o, 'rejected_reference_mismatch');
assert.equal((await fulfill('evt_unknown', 'cs_missing', U1, { amount: 29900 }))[0].o, 'unknown_order');
await db.exec(`update public.payment_orders set status='cancelled' where checkout_session_id='cs_ref'`);
assert.equal((await db.query(`select count(*)::int c from public.user_subscriptions where user_id='${U2}'`)).rows[0].c, 0);
ok('wrong amount/currency/mode/reference/unpaid/unknown session rejected, nothing granted');

// 7 stacking
const o2 = await newOrder(U1, 'sub_1m', 'cs_2');
const prev = (await db.query(`select expires_at from public.user_subscriptions where user_id='${U1}'`)).rows[0].expires_at;
assert.equal((await fulfill('evt_2', 'cs_2', o2, { amount: 29900, payment: 'pay_2' }))[0].o, 'granted');
const next = (await db.query(`select expires_at from public.user_subscriptions where user_id='${U1}'`)).rows[0].expires_at;
const gap = (next - prev) / 86400000;
assert.ok(gap > 27 && gap < 32, gap);
ok('renewing while active extends from the current expiry');

// 8 mother notes lifetime
await db.exec(`update public.billing_plans set amount_centavos=49900,is_active=true where code='mother_notes'`);
const mn = await newOrder(U1, 'mother_notes', 'cs_mn');
assert.equal((await fulfill('evt_mn', 'cs_mn', mn, { amount: 49900, payment: 'pay_mn' }))[0].o, 'granted');
await db.exec(`update public.user_subscriptions set expires_at = now() - interval '1 day' where user_id='${U1}'`);
const access = (await as('authenticated', U1, `select public.get_my_access() a`))[0].a;
assert.equal(access.subscription_active, false);
assert.equal(access.mother_notes_owned, true);
await fails(sv(`select public.create_payment_order('${U1}','mother_notes','test')`), 'already_owned');
ok('Mother Notes is a separate lifetime entitlement that survives subscription expiry; not buyable twice');

// 9 failures
const of = await newOrder(U2, 'sub_6m', 'cs_fail');
assert.equal((await sv(`select public.record_payment_failure('evt_f1','payment.failed',false,'${of}','card_declined')->>'outcome' o`))[0].o, 'failure_recorded');
assert.equal((await sv(`select public.record_payment_failure('evt_f1','payment.failed',false,'${of}','card_declined')->>'outcome' o`))[0].o, 'duplicate_event');
const fr = (await db.query(`select status,last_failure,failed_attempts from public.payment_orders where id='${of}'`)).rows[0];
assert.deepEqual(fr, { status: 'pending', last_failure: 'card_declined', failed_attempts: 1 });
assert.equal((await db.query(`select count(*)::int c from public.user_subscriptions where user_id='${U2}'`)).rows[0].c, 0);
ok('failed payment recorded, never grants, idempotent');

// 10 expiry and late paid
const oe = await newOrder(U2, 'sub_1m', 'cs_exp');
await db.exec(`update public.payment_orders set expires_at = now() - interval '1 hour' where id='${oe}'`);
assert.equal((await as('authenticated', U2, `select (public.get_my_payment_order('${oe}'))->>'status' s`))[0].s, 'expired');
assert.equal((await fulfill('evt_late', 'cs_exp', oe, { amount: 29900, payment: 'pay_late' }))[0].o, 'granted');
assert.equal((await db.query(`select paid_after_expiry p from public.payment_orders where id='${oe}'`)).rows[0].p, true);
ok('expired reads as expired; late verified payment is granted and flagged');

// 11 cancel
const oc = await newOrder(U1, 'sub_12m', 'cs_cancel');
assert.equal((await as('authenticated', U2, `select public.cancel_my_payment_order('${oc}') s`))[0].s, null);
assert.equal((await as('authenticated', U1, `select public.cancel_my_payment_order('${oc}') s`))[0].s, 'cancelled');
assert.equal((await as('authenticated', U2, `select public.get_my_payment_order('${oc}') s`))[0].s, null);
ok('cancel is owner-only and pending-only; others cannot read the order');

// 12 privileges
await fails(as('authenticated', U1, `insert into public.payment_orders(user_id,plan_code,kind,amount_centavos,mode) values ('${U1}','sub_1m','subscription',1,'test')`), 'permission denied');
await fails(as('authenticated', U1, `update public.user_subscriptions set expires_at = now() + interval '10 years'`), 'permission denied');
await fails(as('authenticated', U2, `insert into public.user_entitlements(user_id,kind,source_order_id) values ('${U2}','mother_notes','${o1}')`), 'permission denied');
await fails(as('authenticated', U1, `select public.fulfill_payment('evt_hack','x',false,'cs_1','${o1}','p',59900,'PHP','paid','x')`), 'permission denied');
await fails(as('authenticated', U1, `select public.create_payment_order('${U1}','sub_1m','test')`), 'permission denied');
await fails(as('authenticated', U1, `select * from public.payment_webhook_events`), 'permission denied');
await fails(as('anon', null, `select public.get_my_access()`), 'permission denied');
const seen = (await as('authenticated', U2, `select count(*)::int c from public.payment_orders`))[0].c;
const mine = (await db.query(`select count(*)::int c from public.payment_orders where user_id='${U2}'`)).rows[0].c;
assert.equal(seen, mine);
ok('clients cannot write, fulfil, create orders, read ledger, or see others; anon denied');

// 13 many different events for one order (sequential: PGlite is single-connection)
const op = await newOrder(U2, 'sub_3m', 'cs_race');
const results = [];
for (let i = 0; i < 8; i++) results.push((await fulfill(`evt_race_${i}`, 'cs_race', op, { amount: 59900, payment: 'pay_race' }))[0].o);
const ob = await newOrder(U1, 'sub_6m', 'cs_reuse');
assert.equal((await fulfill('evt_reuse', 'cs_reuse', ob, { amount: 99900, payment: 'pay_race' }))[0].o, 'rejected_payment_reused');
assert.equal((await db.query(`select count(*)::int c from public.subscription_grants where order_id='${ob}'`)).rows[0].c, 0);
assert.equal(results.filter((r) => r === 'granted').length, 1);
assert.equal(results.filter((r) => r === 'already_paid').length, 7);
assert.equal((await db.query(`select count(*)::int c from public.subscription_grants where order_id='${op}'`)).rows[0].c, 1);
ok('8 different events for one order grant exactly once');

// 14 free trial
const U3 = '00000000-0000-0000-0000-000000000003';
await db.exec(`insert into auth.users values ('${U3}','c@example.test')`);
let acc = (await as('authenticated', U3, `select public.get_my_access() a`))[0].a;
assert.equal(acc.trial_used, false);
assert.equal(acc.trial_active, false);
const started = (await as('authenticated', U3, `select public.claim_free_trial() r`))[0].r;
assert.equal(started.status, 'started');
const days = (new Date(started.ends_at) - Date.now()) / 86400000;
assert.ok(days > 6.99 && days <= 7.001, days);
acc = (await as('authenticated', U3, `select public.get_my_access() a`))[0].a;
assert.equal(acc.trial_active, true);
assert.equal(acc.trial_used, true);
const again = (await as('authenticated', U3, `select public.claim_free_trial() r`))[0].r;
assert.equal(again.status, 'already_used');
assert.equal(again.ends_at, started.ends_at);
ok('a trial lasts 7 days, starts once, and claiming again never extends it');

await db.exec(`update public.user_trials set ends_at = now() - interval '1 hour', started_at = now() - interval '8 days' where user_id='${U3}'`);
acc = (await as('authenticated', U3, `select public.get_my_access() a`))[0].a;
assert.equal(acc.trial_active, false);
assert.equal(acc.trial_used, true);
assert.equal((await as('authenticated', U3, `select public.claim_free_trial() r`))[0].r.status, 'already_used');
ok('an ended trial is inactive and cannot be restarted');

// U1 has a paid subscription with entitlements from the earlier checks
await db.exec(`insert into public.user_subscriptions(user_id, expires_at) values ('${U2}', now() + interval '10 days') on conflict (user_id) do update set expires_at = excluded.expires_at`);
assert.equal((await as('authenticated', U2, `select public.claim_free_trial() r`))[0].r.status, 'subscribed');
assert.equal((await db.query(`select count(*)::int c from public.user_trials where user_id='${U2}'`)).rows[0].c, 0);
ok('an active subscriber does not consume a trial');

await fails(as('authenticated', U1, `insert into public.user_trials(user_id, ends_at) values ('${U1}', now() + interval '3650 days')`), 'permission denied');
await fails(as('authenticated', U3, `update public.user_trials set ends_at = now() + interval '3650 days'`), 'permission denied');
await fails(as('anon', null, `select public.claim_free_trial()`), 'permission denied');
assert.equal((await as('authenticated', U1, `select count(*)::int c from public.user_trials`))[0].c, 0);
ok('clients cannot write or extend trials, anon denied, trials are private');

// trial rollback restores the previous get_my_access and keeps the table
const trialRollback = readFileSync(root + 'supabase/reconciliation/rollback_free_trial_20261014.sql', 'utf8');
await db.exec(trialRollback);
await db.exec(trialRollback);
acc = (await as('authenticated', U3, `select public.get_my_access() a`))[0].a;
assert.equal('trial_used' in acc, false);
assert.equal((await db.query('select count(*)::int c from public.user_trials')).rows[0].c, 1);
await db.exec(trialPatch);
ok('trial rollback is idempotent, keeps data, and can be re-applied');

// 15 rollback removes the functions and keeps the payment data
const rollback = readFileSync(root + 'supabase/reconciliation/rollback_paymongo_payments_20261014.sql','utf8');
await db.exec(rollback);
await db.exec(rollback);
const fns = (await db.query(`select count(*)::int c from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname in ('fulfill_payment','create_payment_order','get_my_access')`)).rows[0].c;
assert.equal(fns, 0);
assert.ok((await db.query('select count(*)::int c from public.payment_orders')).rows[0].c > 0);
ok('rollback removes the functions, is idempotent, and keeps the payment data');

console.log(`\n${passed} checks passed`);
