"""Database-only compatibility regressions, called by audit_database.py."""
from pathlib import Path
import json
from build_database_baseline import build

ROOT = Path(__file__).resolve().parents[1]
FORWARD = ROOT / 'supabase/migrations/20261002000000_schema_consistency.sql'


def run_compatibility(sql, use_database, bootstrap, prefix):
    def create(suffix, template=None):
        name = prefix + '_' + suffix
        use_database('postgres')
        sql('create database ' + name + (' template ' + template if template else ''))
        use_database(name)
        return name

    def reject(statement, message):
        try:
            sql(statement)
        except RuntimeError as error:
            assert message in str(error), str(error)
        else:
            raise AssertionError('Expected rejection: ' + message)

    forward = FORWARD.read_text(encoding='utf-8')
    base = create('baseline')
    sql(bootstrap)
    sql(build())
    print('VERIFIED: separate empty-install baseline reaches application-derived schema')
    # Parse all explicitly selected columns and preserve FK-backed nested selects.
    sql("""
      select id,title,course_id,description,image,day_subject,created_at from subjects limit 0;
      select id,title,subject_id,description,configured_question_count,created_at from quizzes limit 0;
      select id,quiz_id,question_text from questions limit 0;
      select id,question_id,choice_text,is_correct from choices limit 0;
      select id,title,description,user_id,created_at,file,image,status,subject_id from published_modules limit 0;
      select id,subject_id,title,file_path,description,deleted_at from mnemonics limit 0;
      select id,subject_id,short_form,full_form,deleted_at from abbreviations limit 0;
      select id,subject_id,title,file_path,deleted_at from procedures limit 0;
      select id,task_name,description,user_id,is_done,deadline,created_at from tasks limit 0;
      select id,user_id,quiz_id,current_page,created_at,updated_at from mockboards_paused limit 0;
      select id,student_id,score,answer,summary,attempted_at,no_of_attempt,quiz_id from quiz_attempts limit 0;
      select id,user_id,subject_id,quiz_id,correct_answers,total_questions,score,completed_at from question_bank_attempts limit 0;
      select id,user_id,activity_date,is_active,created_at from progress_days limit 0;
      select id,user_id,goal_date,title,details,is_checked,updated_at from goals limit 0;
      select id,user_id,title,message,notification_type,image_url,data,is_read,created_at from notifications limit 0;
      select id,user_id,started_at,ended_at,duration_minutes,session_type from study_sessions limit 0;
      select id,name,university,achievement,greeting,message,image_url,is_active,sort_order from authors limit 0;
      select id,type,title,created_by,created_at,updated_at,last_message_at,latest_message from chat_conversations limit 0;
      select conversation_id,profile_id,role,joined_at,last_read_at from chat_members limit 0;
      select id,conversation_id,sender_id,body,created_at from chat_messages limit 0;
      do $$ begin
        assert (select count(*)=2 from pg_constraint where conrelid='question_bank_attempts'::regclass
          and contype='f' and confrelid in ('subjects'::regclass,'quizzes'::regclass)), 'embedded select FKs';
        assert not exists(select 1 from pg_class where relnamespace='public'::regnamespace
          and relkind='r' and not relrowsecurity), 'table missing RLS';
        assert to_regprocedure('public.is_username_available(text)') is not null;
        assert to_regprocedure('public.search_profiles_for_chat(text,integer)') is not null;
        assert to_regprocedure('public.chat_profile_summaries(uuid[])') is not null;
        assert to_regprocedure('public.get_or_create_direct_chat(uuid)') is not null;
        assert to_regprocedure('public.get_weekly_mockboard_achievians(integer)') is not null;
        assert to_regprocedure('public.get_monthly_streak_achievians(integer)') is not null;
      end $$;
    """)
    # Capture actual baseline catalog for the schema dependency report.
    catalog = json.loads(sql("""
      select json_agg(t) from (select c.relname as table_name,
        c.relrowsecurity as rls,
        (select json_agg(json_build_object('name',a.attname,'type',format_type(a.atttypid,a.atttypmod),
          'not_null',a.attnotnull) order by a.attnum) from pg_attribute a
          where a.attrelid=c.oid and a.attnum>0 and not a.attisdropped) as columns,
        (select json_agg(pg_get_constraintdef(k.oid) order by k.conname)
          from pg_constraint k where k.conrelid=c.oid) as constraints
      from pg_class c where c.relnamespace='public'::regnamespace and c.relkind in ('r','v')
      order by c.relname) t;
    """))
    evidence = ROOT / 'docs/audit-evidence/database-baseline-catalog.json'
    evidence.write_text(json.dumps(catalog, indent=2) + '\n', encoding='utf-8')
    print('VERIFIED: application column projections, nested-select foreign keys, RPC signatures and RLS presence')

    create('compatible', base)
    sql("""
      insert into auth.users values ('00000000-0000-0000-0000-000000000010','schema@example.test','{}');
      update profiles set mantra='preserve me' where email='schema@example.test';
      insert into mockboards_paused(user_id,quiz_id,current_page)
        values ('00000000-0000-0000-0000-000000000010',7,1.5);
      insert into tasks(task_name,user_id,deadline)
        values ('preserve task','00000000-0000-0000-0000-000000000010',now());
    """)
    before = sql("select json_agg(t order by id) from mockboards_paused t; select json_agg(t order by id) from tasks t;")
    sql(forward)
    sql(forward)
    assert before == sql("select json_agg(t order by id) from mockboards_paused t; select json_agg(t order by id) from tasks t;")
    assert sql("select mantra from profiles where email='schema@example.test'").strip() == 'preserve me'
    reject(build(), 'Baseline refuses non-empty')
    print('VERIFIED: compatible forward migration reentrant; seeded rows/mantra preserved; baseline refuses reuse')

    create('uuid_empty', base)
    # Deliberate test-only drift fixtures. These never run outside this container.
    sql('alter table mockboards_paused alter column quiz_id type uuid using null::uuid;')
    sql(forward)
    sql("""do $$ begin
      assert (select udt_name='int4' from information_schema.columns
        where table_name='mockboards_paused' and column_name='quiz_id');
      assert (select udt_name='uuid' from information_schema.columns
        where table_name='mockboards_paused' and column_name='quiz_id_legacy');
    end $$;""")
    print('VERIFIED: empty UUID paused quiz column upgraded while retaining legacy column')

    create('uuid_populated', base)
    sql("""
      alter table mockboards_paused alter column quiz_id type uuid using null::uuid;
      alter table mockboards_paused alter column current_page type integer using current_page::integer;
      alter table mockboards_paused drop constraint mockboards_paused_user_id_fkey;
      insert into auth.users values ('00000000-0000-0000-0000-000000000010','schema@example.test','{}');
      insert into mockboards_paused(user_id,quiz_id,current_page) values
        ('00000000-0000-0000-0000-000000000010','00000000-0000-0000-0000-000000000099',3);
    """)
    original = sql('select to_jsonb(p) from mockboards_paused p')
    reject(forward, 'UUID quiz_id rows need')
    assert original == sql('select to_jsonb(p) from mockboards_paused p')
    sql((ROOT / 'supabase/reconciliation/prepare_paused_mapping.sql').read_text(encoding='utf-8'))
    reject(forward, 'mapping is incomplete')
    sql("insert into achievia_reconciliation.paused_quiz_map values ('00000000-0000-0000-0000-000000000099',7,'isolated fixture mapping');")
    sql(forward)
    sql(forward)
    after = json.loads(sql('select to_jsonb(p) from mockboards_paused p'))
    old = json.loads(original)
    assert after.pop('quiz_id_legacy') == old['quiz_id']
    assert after.pop('quiz_id') == 7
    old.pop('quiz_id')
    assert after == old, (after, old)
    print('VERIFIED: unmapped/incomplete UUID upgrades fail atomically; mapped upgrade preserves every row and original UUID')

    for suffix, drift, error in [
        ('bad_mantra', 'alter table profiles alter column mantra type integer using null::integer', 'profiles.mantra has type'),
        ('bad_id', 'alter table mockboards_paused alter column id drop default; alter table mockboards_paused alter column id type integer using null::integer', 'mockboards_paused.id is'),
        ('missing_content', 'alter table mnemonics rename to retained_mnemonics', 'missing public.mnemonics'),
        ('bad_content_type', 'alter table choices alter column is_correct drop default; alter table choices alter column is_correct type text using is_correct::text', 'choices.is_correct type'),
        ('missing_column', 'alter table quizzes rename column created_at to retained_created_at', 'quizzes.created_at type'),
        ('missing_nested_fk', 'alter table question_bank_attempts drop constraint question_bank_attempts_subject_id_fkey', 'nested selects require'),
    ]:
        create(suffix, base)
        sql(drift)
        reject(forward, error)
    print('VERIFIED: incompatible mantra/paused IDs/content types, missing columns/tables/nested FKs fail explicitly')
