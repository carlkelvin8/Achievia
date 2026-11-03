"""Local-only check of the supabase/proposed/*.sql patches against the real
migration history. Never connects to hosted Supabase.

Builds a fixture schema, replays the question-bank migrations
(20260814, 20261004, 20261005) and then applies each proposed patch to verify
that it executes, does what its header claims, and which prerequisites it
silently depends on.

    python scripts/test_proposed_patches.py

Requires a running Docker daemon (image postgres:16-alpine).
"""
from pathlib import Path
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
NAME = 'achievia-patches-test-' + str(time.time_ns())
DB = 'postgres'
U1 = '00000000-0000-0000-0000-000000000001'


def run(args, **kwargs):
    return subprocess.run(args, text=True, capture_output=True,
                          encoding='utf-8', **kwargs)


def sql(text, user_sub=None, role=None, db=None):
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


def fails(statement, fragment, **kwargs):
    try:
        sql(statement, **kwargs)
    except RuntimeError as error:
        assert fragment.lower() in str(error).lower(), (fragment, str(error))
        return
    raise AssertionError(f'expected failure containing "{fragment}"')


def read(path):
    return (ROOT / path).read_text(encoding='utf-8')


BOOTSTRAP = """
create extension if not exists pgcrypto;
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

create table public.profiles(id uuid primary key, email varchar(255) unique);
create table public.subjects(id int primary key, title text);
create table public.quizzes(id int primary key, subject_id int references public.subjects(id),
  title text);
create table public.questions(id int primary key, quiz_id int references public.quizzes(id),
  question_text text);
create table public.choices(id int primary key, question_id int references public.questions(id),
  choice_text text, is_correct boolean);
alter table public.choices enable row level security;
create policy "Authenticated users can read choices" on public.choices
  for select to authenticated using (true);
alter table public.questions enable row level security;
create policy "read questions" on public.questions for select to authenticated using (true);
alter table public.quizzes enable row level security;
create policy "read quizzes" on public.quizzes for select to authenticated using (true);
alter table public.subjects enable row level security;
create policy "read subjects" on public.subjects for select to authenticated using (true);

-- shape of the deployed table (database-baseline-catalog.json)
create table public.qotd_answers(
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id int not null references public.questions(id) on delete cascade,
  quiz_id int not null references public.quizzes(id) on delete cascade,
  choice_id int not null references public.choices(id) on delete cascade,
  is_correct boolean not null,
  answered_at timestamptz not null default now());
alter table public.qotd_answers enable row level security;
create policy "Users can read their own QOTD answers" on public.qotd_answers
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users can insert their own QOTD answers" on public.qotd_answers
  for insert to authenticated with check ((select auth.uid()) = user_id);

insert into auth.users values ('00000000-0000-0000-0000-000000000001','old@example.test');
insert into public.profiles values ('00000000-0000-0000-0000-000000000001','old@example.test');
insert into public.subjects values (1, 'Subject');
insert into public.quizzes values (1, 1, 'Topic');
insert into public.questions select n, 1, 'Q' || n from generate_series(1,100) n;
insert into public.choices select n*10 + k, n, 'C' || k, k = 1
  from generate_series(1,100) n, generate_series(1,4) k;

create function public.exam_items() returns jsonb language sql as $$
  select jsonb_agg(jsonb_build_object(
    'position', n, 'question_id', n, 'selected_choice_id', n*10 + 1,
    'choice_order', jsonb_build_array(n*10+1, n*10+2, n*10+3, n*10+4))
    order by n) from generate_series(1,100) n;
$$;
"""


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
        global DB
        sql('create database patches_db', db='postgres')
        DB = 'patches_db'
        sql(BOOTSTRAP)
        for migration in ['20260814000000_add_question_bank_attempts.sql',
                          '20261004000000_question_bank_subject_exams.sql',
                          '20261005000000_subject_exam_attempt_items.sql']:
            sql(read('supabase/migrations/' + migration))
        print('VERIFIED: question-bank migrations 20260814 -> 20261005 replay on the fixture')

        # ---- 20261008: configured_question_count ------------------------
        assert sql("select count(*) from information_schema.columns "
                   "where table_name='quizzes' "
                   "and column_name='configured_question_count'") == '0'
        patch = read('supabase/proposed/20261008000000_mock_board_question_counts.sql')
        sql(patch)
        sql(patch)  # idempotent
        assert sql("select count(*) from information_schema.columns "
                   "where table_name='quizzes' "
                   "and column_name='configured_question_count'") == '1'
        print('VERIFIED: 20261008 adds the column and is idempotent '
              '(20261002 schema guard needs it first if production lacks it)')

        # ---- 20261010: profile email sync -------------------------------
        sql(read('supabase/proposed/20261010000000_sync_profile_email.sql'))
        sql(f"update auth.users set email = 'new@example.test' where id = '{U1}';")
        assert sql(f"select email from public.profiles where id = '{U1}'") \
            == 'new@example.test'
        print('VERIFIED: 20261010 keeps profiles.email in step with auth.users')

        # ---- 20261011: QOTD answer integrity ----------------------------
        sql(read('supabase/proposed/20261011000000_qotd_answer_integrity.sql'))
        sql("insert into public.qotd_answers(user_id, question_id, quiz_id, "
            "choice_id, is_correct) values "
            f"('{U1}', 1, 1, 12, true);", user_sub=U1, role='authenticated')
        assert sql("select is_correct from public.qotd_answers") == 'f'
        fails("insert into public.qotd_answers(user_id, question_id, quiz_id, "
              f"choice_id, is_correct) values ('{U1}', 2, 1, 11, true);",
              'does not belong', user_sub=U1, role='authenticated')
        fails("insert into public.qotd_answers(user_id, question_id, quiz_id, "
              f"choice_id, is_correct) values ('{U1}', 1, 1, 11, true);",
              'duplicate key', user_sub=U1, role='authenticated')
        print('VERIFIED: 20261011 derives is_correct server side, rejects foreign '
              'choices and a second answer for the same day (23505)')

        # ---- 20261012: exam attempts server-authoritative ---------------
        forged = ("insert into public.question_bank_attempts(user_id, subject_id, "
                  "quiz_id, attempt_type, correct_answers, total_questions, score) "
                  f"values ('{U1}', 1, null, 'subject_exam', 100, 100, 100);")
        sql(forged, user_sub=U1, role='authenticated')  # baseline hole
        sql('delete from public.question_bank_attempts')
        print('VERIFIED (baseline): a client can insert a forged subject_exam row')
        sql(read('supabase/proposed/20261012000000_exam_attempts_server_authoritative.sql'))
        fails(forged, 'row-level security', user_sub=U1, role='authenticated')
        sql("insert into public.question_bank_attempts(user_id, subject_id, quiz_id, "
            "attempt_type, correct_answers, total_questions, score) "
            f"values ('{U1}', 1, 1, 'practice', 5, 10, 50);",
            user_sub=U1, role='authenticated')
        client = '11111111-1111-1111-1111-111111111111'
        attempt = sql(f"select public.save_subject_exam_attempt(1, '{client}', "
                      "public.exam_items());", user_sub=U1, role='authenticated')
        assert len(attempt) == 36
        assert sql("select correct_answers, score from "
                   "public.question_bank_attempts where attempt_type = "
                   "'subject_exam'") == '100|100.00'
        fails("insert into public.question_bank_attempt_items(attempt_id, "
              "position, question_text, choices_snapshot, correct_index, "
              f"is_correct) values ('{attempt}', 1, 'x', '[]', 0, false);",
              'row-level security', user_sub=U1, role='authenticated')
        print('VERIFIED: 20261012 blocks forged exam rows/items, keeps practice '
              'inserts, and the RPC still saves a graded exam')

        # ---- 20261007: soft delete (prerequisite check) -----------------
        fails(read('supabase/proposed/20261007000000_exam_rpc_respect_soft_delete.sql'),
              'Prerequisite missing')
        sql("select public.save_subject_exam_attempt(1, "
            "'22222222-2222-2222-2222-222222222222', public.exam_items());",
            user_sub=U1, role='authenticated')
        print('VERIFIED (BLOCKER): 20261007 refuses to apply because the '
              'deleted_at columns it needs do not exist; the exam RPC is left intact')
        # The prepared prerequisite adds the columns; then the order must be
        # prerequisite -> 20261007 -> 20261012.
        prereq = read('supabase/proposed/20261006100000_content_soft_delete_columns.sql')
        sql(prereq)
        sql(prereq)  # idempotent
        assert sql("select count(*) from information_schema.columns where "
                   "table_schema='public' and column_name='deleted_at' and "
                   "table_name in ('subjects','quizzes','questions','choices')"
                   ) == '4'
        sql(read('supabase/proposed/20261007000000_exam_rpc_respect_soft_delete.sql'))
        fails("select public.save_subject_exam_attempt(1, "
              "'33333333-3333-3333-3333-333333333333', public.exam_items());",
              'row-level security', user_sub=U1, role='authenticated')
        sql(read('supabase/proposed/20261012000000_exam_attempts_server_authoritative.sql'))
        sql("select public.save_subject_exam_attempt(1, "
            "'33333333-3333-3333-3333-333333333333', public.exam_items());",
            user_sub=U1, role='authenticated')
        print('VERIFIED: prerequisite is idempotent; order is prerequisite -> '
              '20261007 -> 20261012 (20261007 re-creates the function with '
              'invoker rights)')
        # And the patch now really excludes a soft-deleted question.
        sql("update public.questions set deleted_at = now() where id = 5;")
        fails("select public.save_subject_exam_attempt(1, "
              "'44444444-4444-4444-4444-444444444444', public.exam_items());",
              'every question must exist', user_sub=U1, role='authenticated')
        print('VERIFIED: with the columns in place, 20261007 rejects a '
              'soft-deleted question')
    finally:
        run(['docker', 'rm', '-f', NAME])


if __name__ == '__main__':
    main()
