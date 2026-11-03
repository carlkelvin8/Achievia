"""Local-only PostgreSQL test for the Mock Board server grading patches:

  supabase/proposed/20261013000000_mock_board_server_grading.sql   (Phase A)
  supabase/proposed/20261013100000_mock_board_lockdown_legacy_insert.sql (Phase B)
  supabase/reconciliation/rollback_mock_board_server_grading_20261013.sql

Starts a throw-away, network-isolated postgres container, builds a minimal
fixture schema (auth shim, profiles, content tables with a topic blueprint,
quiz_attempts with the legacy client-write policies), applies the patches and
executes the assertions below as the `authenticated` / `anon` roles. It never
connects to hosted Supabase and accepts no URL or credentials.

    python scripts/test_mock_board_grading.py

Requires a running Docker daemon (image postgres:16-alpine).
"""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
NAME = 'achievia-grading-test-' + str(time.time_ns())
DB = 'postgres'

U1 = '00000000-0000-0000-0000-000000000001'
U2 = '00000000-0000-0000-0000-000000000002'
U3 = '00000000-0000-0000-0000-000000000003'

# Titles and the sections each one must map to. Shared with the Dart test
# (test/core/utils/mock_board_section_mapping_test.dart) to keep both
# implementations of the matching in step.
SECTION_TITLES = [
    ('Clinical Chemistry', [1]),
    ('Clinical Chemistry (Advanced)', [1]),
    ('Microbiology & Parasitology', [2]),
    ('Bacteriology', [2]),
    ('Mycology and Virology', [2]),
    ('Clinical Microscopy', [3]),
    ('Hematology', [4]),
    ('Immunohematology', [5]),
    ('Blood Banking / Serology', [5]),
    ('Histopathology', [6]),
    ('Medical Technology Laws/Ethics', [6]),
    ('Anatomy', []),
]


def run(args, **kwargs):
    return subprocess.run(args, text=True, capture_output=True,
                          encoding='utf-8', **kwargs)


def sql(text, db=None, user_sub=None, role=None):
    """Runs SQL in the container; optionally as a role with auth.uid() set."""
    prefix = ''
    if role:
        prefix += f'set role {role};\n'
    if user_sub:
        prefix += f"set request.jwt.claim.sub = '{user_sub}';\n"
    result = run(['docker', 'exec', '-i', NAME, 'psql', '-U', 'postgres',
                  '-d', db or DB, '-v', 'ON_ERROR_STOP=1', '-X', '-q', '-t',
                  '-A'], input=prefix + text)
    if result.returncode:
        raise RuntimeError(result.stderr.strip())
    return result.stdout.strip()


BOOTSTRAP = """
create schema auth;
create role anon nologin;
create role authenticated nologin;
create table auth.users(id uuid primary key, email text);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
grant usage on schema public, auth to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
alter default privileges in schema public grant all on tables to anon, authenticated;

create table public.profiles(
  id uuid primary key, first_name varchar, middle_name varchar,
  last_name varchar, profile_image varchar, university varchar,
  purpose varchar, date_of_examination timestamptz,
  created_at timestamptz default now());
create table public.subjects(id int primary key, title text);
create table public.quizzes(id int primary key, subject_id int, title text,
  configured_question_count int);
create table public.questions(id int primary key, quiz_id int, question_text text);
create table public.choices(id int primary key, question_id int,
  choice_text text, is_correct boolean);

-- Same shape and legacy policies as 20260607000000_fix_quiz_attempts_student_id_rls.sql
create table public.quiz_attempts(
  id bigint generated always as identity primary key,
  quiz_id int, student_id uuid not null references auth.users(id),
  score numeric, attempted_at timestamptz, answer jsonb default '[]',
  no_of_attempt int, summary jsonb default '[]',
  created_at timestamptz default now());
alter table public.quiz_attempts enable row level security;
create policy "Users can read their own quiz attempts" on public.quiz_attempts
  for select to authenticated using ((select auth.uid()) = student_id);
create policy "Users can insert their own quiz attempts" on public.quiz_attempts
  for insert to authenticated with check ((select auth.uid()) = student_id);
create policy "Users can update their own quiz attempts" on public.quiz_attempts
  for update to authenticated using ((select auth.uid()) = student_id)
  with check ((select auth.uid()) = student_id);
create policy "Users can delete their own quiz attempts" on public.quiz_attempts
  for delete to authenticated using ((select auth.uid()) = student_id);

insert into auth.users values
 ('00000000-0000-0000-0000-000000000001','a@example.test'),
 ('00000000-0000-0000-0000-000000000002','b@example.test');
insert into public.profiles(id, first_name) values
 ('00000000-0000-0000-0000-000000000001','Ana'),
 ('00000000-0000-0000-0000-000000000002','Ben');

insert into public.subjects values
 (1,'Clinical Chemistry'), (2,'Microbiology & Parasitology'),
 (3,'Clinical Microscopy'), (4,'Hematology'),
 (5,'Blood Banking / Serology'), (6,'Histopathology'),
 (7,'Anatomy');
-- Blueprint: section 1 has two topics (40 + 60), the others one topic of 100.
insert into public.quizzes values
 (1, 1, 'Topic 1a', 40), (11, 1, 'Topic 1b', 60),
 (2, 2, 'Topic 2', 100), (3, 3, 'Topic 3', 100), (4, 4, 'Topic 4', 100),
 (5, 5, 'Topic 5', 100), (6, 6, 'Topic 6', 100), (7, 7, 'Anatomy', null);
-- 6 sections x 100 questions (ids 1..600), plus 601 (Anatomy), 602 (a
-- Microbiology question) and 603 (a Clinical Chemistry topic 1a spare).
insert into public.questions
  select (s-1)*100 + n,
         case when s = 1 and n > 40 then 11 else s end,
         'Q' || ((s-1)*100 + n)
  from generate_series(1,6) s, generate_series(1,100) n;
insert into public.questions values (601, 7, 'Q601'), (602, 2, 'Q602'),
  (603, 1, 'Q603');
-- 4 choices each; the FIRST choice is correct.
insert into public.choices
  select q*10 + k, q, 'C' || k, k = 1
  from generate_series(1,603) q, generate_series(1,4) k;

-- items for a board: first correct_counts[s] questions of section s are
-- answered correctly, the rest wrongly (choice 2); unanswered => null.
create function public.test_items(correct_counts int[], unanswered_from int default 101)
returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object(
    'section', s, 'question_id', q,
    'selected_choice_id',
      case when n >= unanswered_from then null
           when n <= correct_counts[s] then q*10 + 1 else q*10 + 2 end)
    order by s, n)
  from (select s, n, (s-1)*100 + n as q
        from generate_series(1,6) s, generate_series(1,100) n) t;
$$;
"""


def expect_error(statement, fragment, sub=U1, role='authenticated'):
    try:
        sql(statement, user_sub=sub, role=role)
    except RuntimeError as error:
        if fragment.lower() not in str(error).lower():
            raise AssertionError(f'expected "{fragment}", got: {error}')
        return
    raise AssertionError(f'expected failure containing "{fragment}"')


def swap(item_index, key, value):
    """Items of a valid board with one field replaced."""
    return ("(select jsonb_set(public.test_items(array[1,1,1,1,1,1]), "
            f"'{{{item_index},{key}}}', '{value}'::jsonb))")


def swap_item(item_index, question_id):
    """Replace an item's question and clear its answer (so the pick is valid)."""
    return ("(select jsonb_set(jsonb_set(public.test_items(array[1,1,1,1,1,1]),"
            f" '{{{item_index},question_id}}', '{question_id}'::jsonb),"
            f" '{{{item_index},selected_choice_id}}', 'null'::jsonb))")


def submit_sql(client, items):
    return f"select public.save_mock_board_attempt('{client}', {items});"


def read(path):
    return (ROOT / path).read_text(encoding='utf-8')


def main():
    started = run(['docker', 'run', '--detach', '--name', NAME, '--network',
                   'none', '-e', 'POSTGRES_HOST_AUTH_METHOD=trust',
                   'postgres:16-alpine'])
    if started.returncode:
        sys.exit(started.stderr)
    try:
        for _ in range(60):
            if run(['docker', 'exec', NAME, 'pg_isready', '-U',
                    'postgres']).returncode == 0:
                break
            time.sleep(1)
        time.sleep(2)
        sql('create database fixture_db', db='postgres')
        global DB
        DB = 'fixture_db'
        sql(BOOTSTRAP)
        sql(read('supabase/proposed/20261013000000_mock_board_server_grading.sql'))
        passed = 0

        def ok(message):
            nonlocal passed
            passed += 1
            print('VERIFIED:', message)

        full = "public.test_items(array[90,80,70,60,50,40])"
        cid1 = '11111111-1111-1111-1111-111111111111'
        auth = dict(user_sub=U1, role='authenticated')

        # 1. section <-> subject mapping helper agrees with the app's rules
        for title, sections in SECTION_TITLES:
            matched = [s for s in range(1, 7) if sql(
                "select public.mock_board_section_matches("
                f"{s}, $t${title}$t$);") == 't']
            assert matched == sections, (title, matched, sections)
        ok('section/subject title matching covers every blueprint section '
           '(Immunohematology is Blood Banking, not Hematology)')

        # 2. the server records the start once
        first = sql(f"select public.start_mock_board_attempt('{cid1}');", **auth)
        second = sql(f"select public.start_mock_board_attempt('{cid1}');", **auth)
        assert first and first == second, (first, second)
        ok('start time is recorded by the server and never moves')

        # 3. grading is computed by the server
        number = sql(submit_sql(cid1, full), **auth)
        assert number == '1', number
        row = sql("select score, server_graded, time_verified, no_of_attempt, "
                  "(answer->0->>'name'), (answer->0->>'score')::numeric, "
                  "(answer->5->>'name'), summary = answer, "
                  "attempted_at > now() - interval '1 minute', "
                  "started_at is not null from public.quiz_attempts;")
        assert row == ('67.00|t|t|1|Clinical Chemistry|90.00|'
                       'Histopathology and Medical Technology Laws/Ethics|'
                       't|t|t'), row
        ok('server computes section scores and weighted GWA (67.00), '
           'stamps time and start')

        # 4. idempotent retry
        again = sql(submit_sql(
            cid1, "public.test_items(array[100,100,100,100,100,100])"), **auth)
        assert again == '1', again
        assert sql('select count(*) from public.quiz_attempts') == '1'
        ok('same client_attempt_id returns the first attempt, never overwrites')

        # 5. sequential numbering; unanswered counts as wrong; no session
        number2 = sql(submit_sql(
            '22222222-2222-2222-2222-222222222222',
            "public.test_items(array[100,100,100,100,100,100], 51)"), **auth)
        assert number2 == '2', number2
        assert sql("select score || '|' || time_verified from "
                   "public.quiz_attempts where no_of_attempt = 2") == '50.00|false'
        ok('attempt numbers increase; unanswered questions are not correct; '
           'a board the server never saw start is saved but not time verified')

        # 6. Phase A privileges
        expect_error("update public.quiz_attempts set score = 100;",
                     'permission denied')
        expect_error("delete from public.quiz_attempts;", 'permission denied')
        expect_error("insert into public.quiz_attempts(student_id, score, "
                     f"no_of_attempt, server_graded) values ('{U1}', 100, 98, true);",
                     'permission denied')
        expect_error("insert into public.quiz_attempts(student_id, score, "
                     f"no_of_attempt, time_verified) values ('{U1}', 100, 98, true);",
                     'permission denied')
        expect_error("select * from public.mock_board_sessions;",
                     'permission denied')
        expect_error("update public.mock_board_settings "
                     "set per_subject_minutes = 100000;", 'permission denied')
        ok('Phase A: update/delete denied, trust columns cannot be written, '
           'sessions and settings are server only')

        # 7. composition + eligibility validation on the server
        expect_error(submit_sql('33333333-3333-3333-3333-333333333333',
                                swap(1, 'question_id', 1)),
                     'duplicate question')
        # a question already used by ANOTHER section (cross-section duplicate)
        expect_error(submit_sql('33333333-3333-3333-3333-333333333334',
                                swap_item(0, 101)), 'duplicate question')
        expect_error(submit_sql('44444444-4444-4444-4444-444444444444',
                                swap(0, 'selected_choice_id', 9991)),
                     'does not belong to its question')
        expect_error(submit_sql('44444444-4444-4444-4444-444444444445',
                                swap(0, 'selected_choice_id', 21)),
                     'does not belong to its question')
        expect_error(submit_sql(
            '55555555-5555-5555-5555-555555555555',
            "(select jsonb_agg(x) from jsonb_array_elements("
            "public.test_items(array[1,1,1,1,1,1])) with ordinality "
            "as t(x, o) where o <= 599)"), 'exactly 600')
        expect_error(submit_sql('66666666-6666-6666-6666-666666666666',
                                swap(0, 'section', 2)), 'exactly 100')
        expect_error("select public.save_mock_board_attempt(null, "
                     "public.test_items(array[1,1,1,1,1,1]));", 'required')
        expect_error(submit_sql('77777777-7777-7777-7777-777777777777',
                                swap_item(0, 601)),
                     'does not belong to its section')
        expect_error(submit_sql('77777777-7777-7777-7777-777777777778',
                                swap_item(0, 602)),
                     'does not belong to its section')
        # wrong composition: right section, but topic 1a gets 41 and 1b 59
        expect_error(submit_sql('77777777-7777-7777-7777-777777777779',
                                swap_item(40, 603)),
                     'do not match the board blueprint')
        # blueprint missing or not adding up to 100
        sql('update public.quizzes set configured_question_count = null '
            'where id = 11;')
        expect_error(submit_sql('77777777-7777-7777-7777-77777777777a',
                                "public.test_items(array[1,1,1,1,1,1])"),
                     'blueprint is not configured')
        sql('update public.quizzes set configured_question_count = 60 '
            'where id = 11;')
        sql('update public.quizzes set configured_question_count = 39 '
            'where id = 1;')
        expect_error(submit_sql('77777777-7777-7777-7777-77777777777b',
                                "public.test_items(array[1,1,1,1,1,1])"),
                     'blueprint is not configured')
        sql('update public.quizzes set configured_question_count = 40 '
            'where id = 1;')
        # a question that is not gradable (two correct choices)
        sql('update public.choices set is_correct = true where id = 62;')
        expect_error(submit_sql('88888888-8888-8888-8888-888888888888',
                                "public.test_items(array[1,1,1,1,1,1])"),
                     'no single correct choice')
        sql('update public.choices set is_correct = false where id = 62;')
        sql('delete from public.choices where id in (12, 13, 14);')
        expect_error(submit_sql('88888888-8888-8888-8888-888888888889',
                                "public.test_items(array[1,1,1,1,1,1])"),
                     'no single correct choice')
        sql("insert into public.choices values (12,1,'C2',false),"
            "(13,1,'C3',false),(14,1,'C4',false);")
        assert sql('select count(*) from public.quiz_attempts') == '2'
        ok('duplicate ids (also across sections), wrong section/subject, '
           'wrong topic composition, missing blueprint, foreign choices and '
           'ungradable questions are all rejected; nothing saved')

        # 7b. pooled subject (20261008100000): the subject's count is taken
        # from ANY of its topics, its topics' own counts are ignored. Uses a
        # third user so the attempt numbers of U1/U2 below are unchanged.
        sql(read('supabase/proposed/20261008000000_mock_board_question_counts.sql'))
        sql(read('supabase/proposed/20261008100000_mock_board_topic_pools.sql'))
        sql(f"insert into auth.users values ('{U3}','c@example.test');"
            f"insert into public.profiles(id, first_name) values ('{U3}','Cy');"
            "insert into public.quizzes values (21, 2, 'Topic 2b', null);"
            "update public.questions set quiz_id = 21 "
            "where id between 151 and 200;"
            "update public.subjects set mock_board_pool_count = 100 where id = 2;")
        u3 = dict(user_sub=U3, role='authenticated')
        assert sql(submit_sql('c0c0c0c0-0000-0000-0000-000000000001',
                              "public.test_items(array[1,1,1,1,1,1])"),
                   **u3) == '1'
        # another question of the pool (topic 2) instead of one of topic 2b
        assert sql(submit_sql('c0c0c0c0-0000-0000-0000-000000000002',
                              swap_item(199, 602)), **u3) == '2'
        sql('update public.subjects set mock_board_pool_count = 99 where id = 2;')
        expect_error(submit_sql('c0c0c0c0-0000-0000-0000-000000000003',
                                "public.test_items(array[1,1,1,1,1,1])"),
                     'blueprint is not configured', sub=U3)
        sql('update public.subjects set mock_board_pool_count = null where id = 2;'
            'update public.questions set quiz_id = 2 '
            'where id between 151 and 200;'
            'delete from public.quizzes where id = 21;'
            f"delete from public.quiz_attempts where student_id = '{U3}';")
        ok('a pooled subject takes its count from any of its topics (topic '
           'counts ignored); a pool that breaks the 100 is not configured')

        # 8. the scoring denominator is fixed on the server
        zero = sql(submit_sql(
            'abababab-0000-0000-0000-000000000001',
            "public.test_items(array[100,100,100,100,100,100], 1)"), **auth)
        assert zero == '3', zero
        assert sql("select score || '|' || (answer->0->>'score') || '|' || "
                   "(answer->0->>'is_correct') from public.quiz_attempts "
                   "where no_of_attempt = 3") == '0.00|0.00|false'
        one = sql(submit_sql(
            'abababab-0000-0000-0000-000000000002',
            "public.test_items(array[1,0,0,0,0,0], 2)"), **auth)
        assert one == '4', one
        assert sql("select (answer->0->>'score') || '|' || score from "
                   "public.quiz_attempts where no_of_attempt = 4") == '1.00|0.20'
        ok('score = correct / 100 per section (an unanswered board is 0, '
           'one right answer is 1.00); the client cannot shrink the denominator')

        # 9. ownership: another user is isolated, anon cannot call
        number_b = sql(submit_sql(cid1, full), user_sub=U2, role='authenticated')
        assert number_b == '1', number_b
        assert sql('select count(*) from public.quiz_attempts',
                   user_sub=U2, role='authenticated') == '1'
        expect_error(submit_sql(cid1, full), 'permission denied',
                     sub=U1, role='anon')
        expect_error(f"select public.start_mock_board_attempt('{cid1}');",
                     'permission denied', sub=U1, role='anon')
        ok("results are owned by auth.uid(); users never see/overwrite others; "
           'anon denied')

        # 10. atomic numbering + no duplicate submissions under concurrency
        def submit(client):
            return sql(submit_sql(
                client, 'public.test_items(array[10,10,10,10,10,10])'),
                user_sub=U2, role='authenticated')

        with ThreadPoolExecutor(8) as pool:
            distinct = list(pool.map(
                submit, [f'aaaaaaaa-0000-0000-0000-00000000000{i}' for i in range(8)]))
        assert sorted(map(int, distinct)) == list(range(2, 10)), distinct
        with ThreadPoolExecutor(8) as pool:
            same = set(pool.map(
                submit, ['bbbbbbbb-0000-0000-0000-000000000000'] * 8))
        assert same == {'10'}, same
        assert sql("select count(*) = count(distinct no_of_attempt) from "
                   f"public.quiz_attempts where student_id = '{U2}'") == 't'
        ok('8 parallel submissions get 8 distinct numbers; 8 identical '
           'retries make 1 row')

        # 11. an attempt without a valid server start never ranks
        # (b) started only AFTER it was submitted
        late_start = 'cdcdcdcd-0000-0000-0000-000000000001'
        assert sql(submit_sql(late_start, full), **auth) == '5'
        sql(f"select public.start_mock_board_attempt('{late_start}');", **auth)
        assert sql(submit_sql(late_start, full), **auth) == '5'  # retry
        assert sql("select time_verified from public.quiz_attempts "
                   f"where client_attempt_id = '{late_start}'") == 'f'
        # (c) the start was recorded by ANOTHER user
        foreign = 'cdcdcdcd-0000-0000-0000-000000000002'
        sql(f"select public.start_mock_board_attempt('{foreign}');",
            user_sub=U2, role='authenticated')
        assert sql(submit_sql(foreign, full), **auth) == '6'
        assert sql("select time_verified from public.quiz_attempts "
                   f"where client_attempt_id = '{foreign}'") == 'f'
        # (d) a legacy client insert (still allowed in Phase A) with a perfect
        # score and a "fresh" attempt time
        sql("insert into public.quiz_attempts(student_id, score, attempted_at, "
            f"no_of_attempt) values ('{U1}', 100, now(), 500);", **auth)
        best = sql("select max(best_score) || '|' || count(*) from "
                   "public.get_weekly_mockboard_achievians(10)", **auth)
        assert best == '67.00|1', best  # only U1's properly started board
        assert sql("select count(*) from "
                   "public.get_monthly_streak_achievians(10)", **auth) == '1'
        ok('never-started, started-after-submit, someone-else-started and '
           'legacy client rows are all excluded from both leaderboards')

        # 12. history is preserved for the owner
        history = sql("select count(*) from public.quiz_attempts "
                      f"where student_id = '{U1}'", **auth)
        assert history == '7', history  # 6 graded + the legacy insert
        assert sql("select count(*) from public.quiz_attempts "
                   "where score = 100", **auth) == '1'
        ok('the owner still sees every attempt, including legacy rows')

        # 13. configured limit: late boards are saved but never rank
        sql('update public.mock_board_settings '
            'set per_subject_minutes = 60, grace_minutes = 15;')
        late = '99999999-9999-9999-9999-999999999991'
        sql(f"select public.start_mock_board_attempt('{late}');", **auth)
        sql("update public.mock_board_sessions set started_at = "
            f"now() - interval '8 hours' where client_attempt_id = '{late}';")
        assert sql(submit_sql(late, full), **auth) == '501'
        assert sql("select time_verified from public.quiz_attempts "
                   f"where client_attempt_id = '{late}'") == 'f'
        on_time = '99999999-9999-9999-9999-999999999992'
        sql(f"select public.start_mock_board_attempt('{on_time}');", **auth)
        assert sql(submit_sql(on_time, full), **auth) == '502'
        assert sql("select time_verified from public.quiz_attempts "
                   f"where client_attempt_id = '{on_time}'") == 't'
        counted = sql("select attempts_count from "
                      "public.get_weekly_mockboard_achievians(10)", **auth)
        assert counted == '2', counted  # first board + on-time board
        ok('with a limit configured, a late submission is kept in history '
           'but excluded from rankings; an on-time one ranks')

        # 14. soft-deleted content is not gradable once deleted_at exists
        sql('alter table public.questions add column deleted_at timestamptz;')
        sql('update public.questions set deleted_at = now() where id = 7;')
        expect_error(submit_sql('99999999-9999-9999-9999-999999999993', full),
                     'every question must exist')
        sql('update public.questions set deleted_at = null where id = 7;')
        ok('a soft-deleted question can no longer be submitted '
           '(works with or without the deleted_at column)')

        # 15. Phase B closes the legacy insert
        sql(read('supabase/proposed/20261013100000_mock_board_lockdown_legacy_insert.sql'))
        expect_error("insert into public.quiz_attempts(student_id, score, "
                     f"attempted_at, no_of_attempt) values ('{U1}', 100, now(), 600);",
                     'permission denied')
        assert sql(submit_sql('dededede-0000-0000-0000-000000000001', full),
                   **auth) == '503'
        assert sql("select count(*) from public.quiz_attempts "
                   f"where student_id = '{U1}'", **auth) == '10'
        ok('Phase B: clients cannot insert at all; the RPC still saves and '
           'history is unchanged')

        # 16. rollback restores the previous behaviour without data loss
        before = sql('select count(*) from public.quiz_attempts')
        script = read('supabase/reconciliation/'
                      'rollback_mock_board_server_grading_20261013.sql')
        sql(script)
        sql(script)  # idempotent
        assert sql('select count(*) from public.quiz_attempts') == before
        sql("insert into public.quiz_attempts(student_id, score, attempted_at, "
            f"no_of_attempt) values ('{U1}', 80, now(), 700);", **auth)
        expect_error(submit_sql('efefefef-0000-0000-0000-000000000001', full),
                     'does not exist')
        sql("update public.quiz_attempts set score = 81 where no_of_attempt = 700;",
            **auth)
        assert sql("select max(best_score) from "
                   "public.get_weekly_mockboard_achievians(10)", **auth) == '100'
        ok('rollback: no data lost, direct writes work again, RPC removed, '
           'leaderboards back to the pre-patch ranking')

        print(f'\n{passed} checks passed')
    finally:
        run(['docker', 'rm', '-f', NAME])


if __name__ == '__main__':
    main()
