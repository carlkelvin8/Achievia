"""Local-only PostgreSQL regression harness. Never connects to hosted Supabase.

Requires docker run --detach --name achievia-audit-db --network none
  -e POSTGRES_HOST_AUTH_METHOD=trust postgres:16-alpine
Runs in a disposable database inside that isolated container.
"""
from pathlib import Path
import subprocess
import time
import json
from concurrent.futures import ThreadPoolExecutor

ROOT = Path(__file__).resolve().parents[1]
DATABASE = 'postgres'

# Refuse accidental use of a container with host/network access. No URL,
# environment database credentials, or remote target is accepted by this tool.
container = json.loads(subprocess.check_output(
    ['docker', 'inspect', 'achievia-audit-db'], text=True, encoding='utf-8'))[0]
if container['HostConfig']['NetworkMode'] != 'none':
    raise RuntimeError('Audit container must use --network none')
if container['HostConfig'].get('PortBindings'):
    raise RuntimeError('Audit container must not publish ports')


def sql(text):
    result = subprocess.run(
        ['docker', 'exec', '-i', 'achievia-audit-db', 'psql', '-U', 'postgres',
         '-d', DATABASE, '-v', 'ON_ERROR_STOP=1', '-X', '-q', '-t', '-A'],
        input=text, text=True, capture_output=True, encoding='utf-8')
    if result.returncode:
        raise RuntimeError(result.stderr)
    return result.stdout


def migration(name):
    return (ROOT / 'supabase/migrations' / name).read_text(encoding='utf-8')


bootstrap = """
create schema auth;
do $$ begin
  if not exists(select 1 from pg_roles where rolname='anon') then create role anon nologin; end if;
  if not exists(select 1 from pg_roles where rolname='authenticated') then create role authenticated nologin; end if;
end $$;
create table auth.users(id uuid primary key, email text, raw_user_meta_data jsonb);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid;
$$;
grant usage on schema public, auth to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
alter default privileges in schema public grant all on tables to anon, authenticated;
alter default privileges in schema public grant usage, select on sequences to anon, authenticated;
create schema realtime;
create table realtime.messages(extension text);
alter table realtime.messages enable row level security;
grant usage on schema realtime to authenticated;
grant select, insert on realtime.messages to authenticated;
create function realtime.topic() returns text language sql stable as $$
  select current_setting('realtime.topic', true);
$$;
"""
database_name = 'audit_' + str(time.time_ns())
sql('create database ' + database_name)
DATABASE = database_name
sql(bootstrap)
for filename in [
    '20260601172733_modify_profile.sql',
    '20260605000000_add_chat_tables.sql',
    '20260606000001_add_chat_person_search.sql',
    '20260607000000_fix_quiz_attempts_student_id_rls.sql',
    '20260607001000_make_quiz_attempt_quiz_id_optional.sql',
    '20260607150148_account_that_have_mockboard_ended.sql',
    '20260707002000_weekly_achievements_and_streak_rpc.sql',
]:
    sql(migration(filename))

# Reproduce privilege escalation and cross-account access before the fix.
sql("""
insert into auth.users values
('00000000-0000-0000-0000-000000000001','a@example.test','{"username":"a","role":"ADMIN"}'),
('00000000-0000-0000-0000-000000000002','b@example.test','{"username":"b"}'),
('00000000-0000-0000-0000-000000000003','c@example.test','{"username":"c"}');
do $$ begin
 assert (select role = 'ADMIN' from profiles where username='a'), 'baseline signup exploit absent';
end $$;
insert into mockboards_paused(user_id,quiz_id) values
('00000000-0000-0000-0000-000000000002','00000000-0000-0000-0000-000000000009');
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
update profiles set role='TEACHER' where username='a';
do $$ begin
 assert (select count(*) = 1 from mockboards_paused), 'baseline cross-user exploit absent';
end $$;
reset role;
""")
print('VERIFIED: baseline signup escalation, role update, cross-user paused-exam read')
sql(migration('20261001000000_production_security.sql'))
sql(migration('20261001001000_rpc_privacy_and_streaks.sql'))
sql((ROOT / 'scripts/audit_database_assertions.sql').read_text(encoding='utf-8'))
print('VERIFIED: hardened role, ownership, chat, privacy, input, anonymous and streak assertions')

# The core content schema is not in Git. This enum fixture tests only the
# module-policy delta, not compatibility with an unknown hosted schema.
sql("""
create type module_status as enum ('published', 'draft');
create table public.modules(id int primary key, user_id uuid, status module_status);
""")
sql(migration('20260930000000_create_modules_table.sql'))
sql(migration('20261001002000_module_access.sql'))
sql("""
insert into modules values
(1,'00000000-0000-0000-0000-000000000002','published'),
(2,'00000000-0000-0000-0000-000000000002','draft'),
(4,'00000000-0000-0000-0000-000000000001','draft');
set role authenticated;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000004';
do $$ begin
  assert (select count(*)=1 from modules), 'draft exposed';
  begin
    insert into modules values (3,auth.uid(),'published');
    raise exception 'ordinary user published a module';
  exception when insufficient_privilege then null; end;
end $$;
set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
do $$ begin
  assert (select count(*)=2 from modules), 'staff cannot read own draft';
  assert (select count(*)=1 from published_modules), 'student list exposes own draft';
end $$;
update modules set status='published' where id=4;
do $$ begin
  assert (select count(*)=2 from published_modules), 'staff cannot publish own draft';
end $$;
reset role;
""")
print('VERIFIED: enum-safe module visibility, non-staff write denial, staff draft read/publish')

def create_chat(_):
    return sql("""
      set role authenticated;
      set request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
      select get_or_create_direct_chat('00000000-0000-0000-0000-000000000004')->>'id';
    """).strip()

with ThreadPoolExecutor(max_workers=8) as pool:
    results = list(pool.map(create_chat, range(8)))
assert len(set(results)) == 1, results
print('VERIFIED: eight concurrent direct-chat requests return one conversation')

# Reproduce the actual clean migration replay failure separately, with the
# minimal Supabase auth shim. Stop at the first failure; never mutate history.
replay_name = database_name + '_replay'
sql('create database ' + replay_name)
DATABASE = replay_name
sql(bootstrap)
legacy_replay_failed = False
for file in sorted((ROOT / 'supabase/migrations').glob('*.sql')):
    try:
        sql(file.read_text(encoding='utf-8'))
    except RuntimeError as error:
        legacy_replay_failed = True
        print('FAILED: clean migration replay at', file.name)
        print(str(error).strip())
        break
else:
    print('VERIFIED: clean migration replay')

from database_compatibility import run_compatibility


def use_database(name):
    global DATABASE
    DATABASE = name


run_compatibility(sql, use_database, bootstrap, database_name)
# A green baseline test does not make the historical replay green.
if legacy_replay_failed:
    raise SystemExit(1)
