"""Local-only PostgreSQL test for supabase/proposed/20261014000000_paymongo_payments.sql

Starts a throw-away, network-isolated postgres container, applies the patch to
a minimal fixture schema and executes the assertions below as service_role /
authenticated / anon. It never connects to hosted Supabase and accepts no URL
or credentials.

    python scripts/test_paymongo_payments.py

Requires a running Docker daemon (image postgres:16-alpine).
"""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
NAME = 'achievia-payments-test-' + str(time.time_ns())
DB = 'postgres'

U1 = '00000000-0000-0000-0000-000000000001'
U2 = '00000000-0000-0000-0000-000000000002'


def run(args, **kwargs):
    return subprocess.run(args, text=True, capture_output=True,
                          encoding='utf-8', **kwargs)


def sql(text, user_sub=None, role=None):
    prefix = ''
    if role:
        prefix += f'set role {role};\n'
    if user_sub:
        prefix += f"set request.jwt.claim.sub = '{user_sub}';\n"
    result = run(['docker', 'exec', '-i', NAME, 'psql', '-U', 'postgres',
                  '-d', DB, '-v', 'ON_ERROR_STOP=1', '-X', '-q', '-t', '-A'],
                 input=prefix + text)
    if result.returncode:
        raise RuntimeError(result.stderr.strip())
    return result.stdout.strip()


def expect_error(statement, fragment, **kwargs):
    try:
        sql(statement, **kwargs)
    except RuntimeError as error:
        if fragment.lower() not in str(error).lower():
            raise AssertionError(f'expected "{fragment}", got: {error}')
        return
    raise AssertionError(f'expected failure containing "{fragment}"')


BOOTSTRAP = """
create schema auth;
create role anon nologin;
create role authenticated nologin;
create role service_role nologin;
create table auth.users(id uuid primary key, email text);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
grant usage on schema public, auth to anon, authenticated, service_role;
grant execute on function auth.uid() to anon, authenticated, service_role;
insert into auth.users values
 ('00000000-0000-0000-0000-000000000001','a@example.test'),
 ('00000000-0000-0000-0000-000000000002','b@example.test');
"""


def fulfill(event, session, reference, amount=59900, currency='PHP',
            livemode='false', status='paid', payment='pay_1', method='gcash'):
    return (
        "select public.fulfill_payment("
        f"'{event}', 'checkout_session.payment.paid', {livemode}, "
        f"'{session}', '{reference}', '{payment}', {amount}, '{currency}', "
        f"'{status}', '{method}')->>'outcome';")


def new_order(user, plan, mode='test', session=None):
    """Creates an order as service_role; optionally attaches a session."""
    order = sql("select (public.create_payment_order("
                f"'{user}', '{plan}', '{mode}')).id;", role='service_role')
    if session:
        sql(f"select public.attach_checkout_session('{order}', '{session}', "
            f"'https://checkout.example.test/{session}');", role='service_role')
    return order


def main():
    started = run(['docker', 'run', '--detach', '--name', NAME, '--network',
                   'none', '-e', 'POSTGRES_HOST_AUTH_METHOD=trust',
                   'postgres:16-alpine'])
    if started.returncode:
        sys.exit(started.stderr)
    passed = 0

    def ok(message):
        nonlocal passed
        passed += 1
        print('VERIFIED:', message)

    try:
        for _ in range(60):
            if run(['docker', 'exec', NAME, 'pg_isready', '-U',
                    'postgres']).returncode == 0:
                break
            time.sleep(1)
        time.sleep(2)
        sql(BOOTSTRAP)
        patch = (ROOT / 'supabase/proposed/'
                 '20261014000000_paymongo_payments.sql').read_text(
                     encoding='utf-8')
        sql(patch)
        sql(patch)  # idempotent re-run
        sv = dict(role='service_role')
        u1 = dict(user_sub=U1, role='authenticated')
        u2 = dict(user_sub=U2, role='authenticated')

        # 1. catalogue in integer centavos; Mother Notes not for sale yet
        prices = sql("select string_agg(code || '=' || amount_centavos, ',' "
                     "order by sort_order) from public.billing_plans "
                     "where kind = 'subscription';")
        assert prices == 'sub_1m=29900,sub_3m=59900,sub_6m=99900,'\
                         'sub_12m=169900', prices
        assert sql("select is_active::text || coalesce(amount_centavos::text,"
                   "'-') from public.billing_plans "
                   "where code = 'mother_notes';") == 'false-'
        expect_error("select public.create_payment_order("
                     f"'{U1}', 'mother_notes', 'test');",
                     'plan_unavailable', **sv)
        expect_error("select public.create_payment_order("
                     f"'{U1}', 'no_such_plan', 'test');",
                     'plan_unavailable', **sv)
        ok('plans are stored in integer centavos; Mother Notes is not '
           'purchasable until it has a price; unknown plans are refused')

        # 2. order amount comes from the catalogue, not from the caller
        o1 = new_order(U1, 'sub_3m', session='cs_1')
        row = sql("select amount_centavos, currency, status, mode, "
                  f"duration_months from public.payment_orders where id = '{o1}';")
        assert row == '59900|PHP|pending|test|3', row
        again = sql("select (public.create_payment_order("
                    f"'{U1}', 'sub_3m', 'test')).id;", **sv)
        assert again == o1, 'open order with a checkout page is reused'
        ok('order snapshots the authoritative price; an open order is reused')

        # 3. nothing is granted before a verified paid event
        assert sql("select count(*) from public.user_subscriptions;") == '0'
        assert sql("select (public.get_my_access())->>'subscription_active';",
                   **u1) == 'false'
        ok('an unpaid order grants no access')

        # 4. a verified paid event grants exactly the purchased duration
        assert sql(fulfill('evt_1', 'cs_1', o1), **sv) == 'granted'
        months = sql("select round(extract(epoch from (expires_at - now())) "
                     "/ 86400) from public.user_subscriptions "
                     f"where user_id = '{U1}';")
        assert 88 <= int(float(months)) <= 93, months  # ~3 calendar months
        assert sql(f"select status from public.payment_orders where id='{o1}';"
                   ) == 'paid'
        assert sql("select (public.get_my_access())->>'subscription_active';",
                   **u1) == 'true'
        ok('a verified paid event grants the subscription for 3 months')

        # 5. duplicates and retries never extend it twice
        before = sql("select expires_at from public.user_subscriptions "
                     f"where user_id = '{U1}';")
        assert sql(fulfill('evt_1', 'cs_1', o1), **sv) == 'duplicate_event'
        assert sql(fulfill('evt_1b', 'cs_1', o1, payment='pay_1'),
                   **sv) == 'already_paid'
        after = sql("select expires_at from public.user_subscriptions "
                    f"where user_id = '{U1}';")
        assert before == after, (before, after)
        assert sql("select count(*) from public.subscription_grants "
                   f"where order_id = '{o1}';") == '1'
        ok('duplicate delivery and a second event for the same order do not '
           'extend the subscription')

        # 6. every mismatch is rejected and grants nothing
        cases = [
            ('amount', dict(amount=100), 'rejected_amount_mismatch'),
            ('currency', dict(currency='USD'), 'rejected_currency_mismatch'),
            ('mode', dict(livemode='true'), 'rejected_mode_mismatch'),
            ('status', dict(status='failed'), 'rejected_not_paid'),
        ]
        for index, (label, extra, expected) in enumerate(cases):
            order = new_order(U2, 'sub_1m', session=f'cs_bad_{index}')
            amount = extra.pop('amount', 29900)
            got = sql(fulfill(f'evt_bad_{index}', f'cs_bad_{index}', order,
                              amount=amount, **extra), **sv)
            assert got == expected, (label, got)
            # make the next order for the same plan distinct
            sql(f"update public.payment_orders set status = 'cancelled' "
                f"where id = '{order}';")
        ref_order = new_order(U2, 'sub_1m', session='cs_ref')
        assert sql(fulfill('evt_ref', 'cs_ref', U1, amount=29900),
                   **sv) == 'rejected_reference_mismatch'
        assert sql(fulfill('evt_unknown', 'cs_missing', U1, amount=29900),
                   **sv) == 'unknown_order'
        assert sql("select count(*) from public.user_subscriptions "
                   f"where user_id = '{U2}';") == '0'
        ok('wrong amount / currency / mode / reference / unpaid status / '
           'unknown session are all rejected and grant nothing')

        # 7. a second purchase stacks on the remaining time
        o2 = new_order(U1, 'sub_1m', session='cs_2')
        prev = sql("select expires_at from public.user_subscriptions "
                   f"where user_id = '{U1}';")
        assert sql(fulfill('evt_2', 'cs_2', o2, amount=29900,
                           payment='pay_2'), **sv) == 'granted'
        gap = sql("select round(extract(epoch from (u.expires_at - "
                  f"'{prev}'::timestamptz)) / 86400) "
                  f"from public.user_subscriptions u where u.user_id='{U1}';")
        assert 28 <= int(float(gap)) <= 31, gap
        ok('renewing while active extends from the current expiry')

        # 8. Mother Notes: priced, bought once, lifetime
        sql("update public.billing_plans set amount_centavos = 49900, "
            "is_active = true where code = 'mother_notes';")
        mn = new_order(U1, 'mother_notes', session='cs_mn')
        assert sql(fulfill('evt_mn', 'cs_mn', mn, amount=49900,
                           payment='pay_mn'), **sv) == 'granted'
        assert sql("select (public.get_my_access())->>'mother_notes_owned';",
                   **u1) == 'true'
        # the subscription ends; the entitlement must not
        sql("update public.user_subscriptions set expires_at = "
            f"now() - interval '1 day' where user_id = '{U1}';")
        access = sql("select (public.get_my_access())->>'subscription_active'"
                     " || ',' || (public.get_my_access())->>"
                     "'mother_notes_owned';", **u1)
        assert access == 'false,true', access
        expect_error("select public.create_payment_order("
                     f"'{U1}', 'mother_notes', 'test');", 'already_owned', **sv)
        assert sql(f"select count(*) from public.user_entitlements "
                   f"where user_id = '{U1}';") == '1'
        ok('Mother Notes is a separate lifetime entitlement that survives '
           'subscription expiry and cannot be bought twice')

        # 9. failed payment attempts never grant access
        of = new_order(U2, 'sub_6m', session='cs_fail')
        out = sql("select public.record_payment_failure('evt_f1', "
                  f"'payment.failed', false, '{of}', "
                  "'card_declined')->>'outcome';", **sv)
        assert out == 'failure_recorded', out
        assert sql("select public.record_payment_failure('evt_f1', "
                   f"'payment.failed', false, '{of}', "
                   "'card_declined')->>'outcome';", **sv) == 'duplicate_event'
        row = sql("select status, last_failure, failed_attempts from "
                  f"public.payment_orders where id = '{of}';")
        assert row == 'pending|card_declined|1', row
        assert sql("select count(*) from public.user_subscriptions "
                   f"where user_id = '{U2}';") == '0'
        ok('a failed payment is recorded, never grants, and is idempotent')

        # 10. expired orders are reported as expired; a paid-late webhook
        # (money was received) is still honoured and flagged
        oe = new_order(U2, 'sub_1m', session='cs_exp')
        sql("update public.payment_orders set expires_at = now() - "
            f"interval '1 hour' where id = '{oe}';")
        got = sql(f"select (public.get_my_payment_order('{oe}'))->>'status';",
                  **u2)
        assert got == 'expired', got
        assert sql(fulfill('evt_late', 'cs_exp', oe, amount=29900,
                           payment='pay_late'), **sv) == 'granted'
        assert sql("select paid_after_expiry::text from public.payment_orders "
                   f"where id = '{oe}';") == 'true'
        ok('expired orders read as expired; a late but verified payment is '
           'granted and flagged for review')

        # 11. cancel only affects a pending order, and only your own
        oc = new_order(U1, 'sub_12m', session='cs_cancel')
        assert sql(f"select public.cancel_my_payment_order('{oc}');",
                   **u2) in ('', None)
        assert sql(f"select public.cancel_my_payment_order('{oc}');",
                   **u1) == 'cancelled'
        assert sql(f"select (public.get_my_payment_order('{oc}'))->>'status';",
                   **u1) == 'cancelled'
        assert sql(f"select (public.get_my_payment_order('{oc}'))->>'status';",
                   **u2) == ''
        ok('cancel is owner-only and only applies to pending orders; '
           'other users cannot read an order')

        # 12. privileges: clients cannot write or fulfil
        expect_error("insert into public.payment_orders(user_id, plan_code, "
                     "kind, amount_centavos, mode) values "
                     f"('{U1}', 'sub_1m', 'subscription', 1, 'test');",
                     'permission denied', **u1)
        expect_error("update public.user_subscriptions set expires_at = "
                     "now() + interval '10 years';", 'permission denied', **u1)
        expect_error("insert into public.user_entitlements(user_id, kind, "
                     f"source_order_id) values ('{U2}', 'mother_notes', "
                     f"'{o1}');", 'permission denied', **u2)
        expect_error(fulfill('evt_hack', 'cs_1', o1), 'permission denied',
                     **u1)
        expect_error("select public.create_payment_order("
                     f"'{U1}', 'sub_1m', 'test');", 'permission denied', **u1)
        expect_error("select * from public.payment_webhook_events;",
                     'permission denied', **u1)
        expect_error("select public.get_my_access();", 'permission denied',
                     role='anon')
        seen = sql("select count(*) from public.payment_orders;", **u2)
        mine = sql(f"select count(*) from public.payment_orders "
                   f"where user_id = '{U2}';")
        assert seen == mine, (seen, mine)
        ok('clients cannot write orders/grants, call fulfil/create, read '
           'the webhook ledger, or see other users orders; anon denied')

        # 13. parallel deliveries of different events for one order grant once
        op = new_order(U2, 'sub_1m', session='cs_race')

        def deliver(i):
            return sql(fulfill(f'evt_race_{i}', 'cs_race', op, amount=29900,
                               payment='pay_race'), **sv)

        with ThreadPoolExecutor(8) as pool:
            results = list(pool.map(deliver, range(8)))
        assert results.count('granted') == 1, results
        assert results.count('already_paid') == 7, results
        assert sql("select count(*) from public.subscription_grants "
                   f"where order_id = '{op}';") == '1'
        # one PayMongo payment can never pay for a second order
        reuse = new_order(U1, 'sub_6m', session='cs_reuse')
        assert sql(fulfill('evt_reuse', 'cs_reuse', reuse, amount=99900,
                           payment='pay_race'), **sv) ==             'rejected_payment_reused'
        with ThreadPoolExecutor(8) as pool:
            same = list(pool.map(
                lambda _: sql(fulfill('evt_same', 'cs_race', op, amount=29900),
                              **sv), range(8)))
        assert set(same) == {'duplicate_event'}, same
        ok('8 parallel deliveries of one order grant exactly once; 8 '
           'identical retries are all duplicates')

        print(f'\n{passed} checks passed')
    finally:
        run(['docker', 'rm', '-f', NAME])


if __name__ == '__main__':
    main()
