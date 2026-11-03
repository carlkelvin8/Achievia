-- Forward-only, transactional, fail-closed reconciliation of known drift.
-- Never replay the old history on a populated database. Read the database
-- runbook, capture deployed catalog/history, and test on a restored copy first.
begin;
set local lock_timeout = '5s';
set local statement_timeout = '60s';

do $$ declare t text; actual text; begin
  foreach t in array array['profiles','tasks','subjects','quizzes','questions',
    'choices','modules','mnemonics','abbreviations','procedures',
    'mockboards_paused'] loop
    if to_regclass('public.' || t) is null then
      raise exception 'Schema reconciliation blocked: missing public.%; restore/approve content DDL first', t;
    end if;
  end loop;
  -- IF NOT EXISTS alone would conceal wrong types. Validate before adding.
  select udt_name into actual from information_schema.columns
    where table_schema='public' and table_name='profiles' and column_name='mantra';
  if actual is not null and actual not in ('text','varchar') then
    raise exception 'Schema reconciliation blocked: profiles.mantra has type %', actual;
  end if;
end $$;
alter table public.profiles add column if not exists mantra text;

do $$ declare t text; actual text; begin
  foreach t in array array['profiles','tasks','mockboards_paused'] loop
    select udt_name into actual from information_schema.columns
      where table_schema='public' and table_name=t and column_name='id';
    if actual is distinct from 'uuid' then
      raise exception 'Schema reconciliation blocked: %.id is %, requires reviewed ID/dependency mapping to UUID', t, actual;
    end if;
  end loop;
end $$;

-- No UUID-to-integer cast exists that preserves meaning. On populated UUID
-- deployments require an operator-reviewed map. Keep the original column.
do $$ declare actual text; begin
  lock table public.mockboards_paused in access exclusive mode;
  select udt_name into actual from information_schema.columns
    where table_schema='public' and table_name='mockboards_paused' and column_name='quiz_id';
  if actual = 'uuid' then
    if exists (select 1 from information_schema.columns where table_schema='public'
      and table_name='mockboards_paused' and column_name='quiz_id_legacy') then
      raise exception 'Schema reconciliation blocked: quiz_id_legacy already exists; inspect partial reconciliation';
    end if;
    if exists (select 1 from public.mockboards_paused) then
      if to_regclass('achievia_reconciliation.paused_quiz_map') is null then
        raise exception 'Schema reconciliation blocked: UUID quiz_id rows need achievia_reconciliation.paused_quiz_map';
      end if;
      lock table achievia_reconciliation.paused_quiz_map in share mode;
      if exists (select legacy_quiz_id from achievia_reconciliation.paused_quiz_map
        group by legacy_quiz_id having count(*) <> 1) then
        raise exception 'Schema reconciliation blocked: paused quiz mapping has duplicate keys';
      end if;
      if exists (select 1 from public.mockboards_paused p
        left join achievia_reconciliation.paused_quiz_map m on m.legacy_quiz_id=p.quiz_id
        where m.app_quiz_id is null) then
        raise exception 'Schema reconciliation blocked: paused quiz mapping is incomplete';
      end if;
    end if;
    alter table public.mockboards_paused rename column quiz_id to quiz_id_legacy;
    alter table public.mockboards_paused alter column quiz_id_legacy drop not null;
    -- A legacy default must not populate misleading UUIDs on new integer rows.
    alter table public.mockboards_paused alter column quiz_id_legacy drop default;
    alter table public.mockboards_paused add column quiz_id integer;
    if exists (select 1 from public.mockboards_paused) then
      update public.mockboards_paused p set quiz_id=m.app_quiz_id
        from achievia_reconciliation.paused_quiz_map m where p.quiz_id_legacy=m.legacy_quiz_id;
    end if;
    alter table public.mockboards_paused alter column quiz_id set not null;
  elsif actual is distinct from 'int4' then
    raise exception 'Schema reconciliation blocked: mockboards_paused.quiz_id is %', actual;
  end if;
  select udt_name into actual from information_schema.columns
    where table_schema='public' and table_name='mockboards_paused' and column_name='current_page';
  if actual = 'int4' then
    alter table public.mockboards_paused alter column current_page type double precision
      using current_page::double precision;
  elsif actual is distinct from 'float8' then
    raise exception 'Schema reconciliation blocked: mockboards_paused.current_page is %', actual;
  end if;
end $$;
-- Validate the application contract after guarded changes. Missing columns and
-- incompatible types are errors, not silently ignored IF NOT EXISTS notices.
-- Extra deployed columns are retained. Enum names may differ across projects.
do $$ declare r record; actual text; begin
  for r in select * from (values
    ('abbreviations','id',array['int4']),
    ('abbreviations','subject_id',array['int4']),
    ('abbreviations','short_form',array['text','varchar']),
    ('abbreviations','full_form',array['text','varchar']),
    ('abbreviations','deleted_at',array['timestamptz']),
    ('authors','id',array['int8']),
    ('authors','name',array['text','varchar']),
    ('authors','university',array['text','varchar']),
    ('authors','achievement',array['text','varchar']),
    ('authors','greeting',array['text','varchar']),
    ('authors','message',array['text','varchar']),
    ('authors','image_url',array['text','varchar']),
    ('authors','sort_order',array['int4']),
    ('authors','is_active',array['bool']),
    ('authors','created_at',array['timestamptz']),
    ('authors','updated_at',array['timestamptz']),
    ('chat_conversations','id',array['uuid']),
    ('chat_conversations','type',array['text','varchar']),
    ('chat_conversations','title',array['text','varchar']),
    ('chat_conversations','created_by',array['uuid']),
    ('chat_conversations','created_at',array['timestamptz']),
    ('chat_conversations','updated_at',array['timestamptz']),
    ('chat_conversations','last_message_at',array['timestamptz']),
    ('chat_conversations','latest_message',array['text','varchar']),
    ('chat_members','conversation_id',array['uuid']),
    ('chat_members','profile_id',array['uuid']),
    ('chat_members','role',array['text','varchar']),
    ('chat_members','joined_at',array['timestamptz']),
    ('chat_members','last_read_at',array['timestamptz']),
    ('chat_messages','id',array['uuid']),
    ('chat_messages','conversation_id',array['uuid']),
    ('chat_messages','sender_id',array['uuid']),
    ('chat_messages','body',array['text','varchar']),
    ('chat_messages','created_at',array['timestamptz']),
    ('choices','id',array['int4']),
    ('choices','question_id',array['int4']),
    ('choices','choice_text',array['text','varchar']),
    ('choices','is_correct',array['bool']),
    ('goals','id',array['uuid']),
    ('goals','user_id',array['uuid']),
    ('goals','goal_date',array['date']),
    ('goals','title',array['text','varchar']),
    ('goals','details',array['text','varchar']),
    ('goals','is_checked',array['bool']),
    ('goals','created_at',array['timestamptz']),
    ('goals','updated_at',array['timestamptz']),
    ('mnemonics','id',array['int4']),
    ('mnemonics','subject_id',array['int4']),
    ('mnemonics','title',array['text','varchar']),
    ('mnemonics','file_path',array['text','varchar']),
    ('mnemonics','description',array['text','varchar']),
    ('mnemonics','deleted_at',array['timestamptz']),
    ('mockboards_paused','id',array['uuid']),
    ('mockboards_paused','user_id',array['uuid']),
    ('mockboards_paused','quiz_id',array['int4']),
    ('mockboards_paused','current_page',array['float8']),
    ('mockboards_paused','created_at',array['timestamptz']),
    ('mockboards_paused','updated_at',array['timestamptz']),
    ('modules','id',array['int4']),
    ('modules','title',array['text','varchar']),
    ('modules','description',array['text','varchar']),
    ('modules','user_id',array['uuid']),
    ('modules','created_at',array['timestamptz']),
    ('modules','file',array['text','varchar']),
    ('modules','image',array['text','varchar']),
    ('modules','subject_id',array['int4']),
    ('notifications','id',array['uuid']),
    ('notifications','user_id',array['uuid']),
    ('notifications','title',array['text','varchar']),
    ('notifications','message',array['text','varchar']),
    ('notifications','notification_type',array['text','varchar']),
    ('notifications','image_url',array['text','varchar']),
    ('notifications','data',array['jsonb']),
    ('notifications','is_read',array['bool']),
    ('notifications','created_at',array['timestamptz']),
    ('procedures','id',array['int4']),
    ('procedures','subject_id',array['int4']),
    ('procedures','title',array['text','varchar']),
    ('procedures','file_path',array['text','varchar']),
    ('procedures','deleted_at',array['timestamptz']),
    ('profiles','id',array['uuid']),
    ('profiles','created_at',array['timestamptz']),
    ('profiles','updated_at',array['timestamptz']),
    ('profiles','first_name',array['varchar','text']),
    ('profiles','middle_name',array['varchar','text']),
    ('profiles','last_name',array['varchar','text']),
    ('profiles','bio',array['text','varchar']),
    ('profiles','age',array['int4']),
    ('profiles','trial',array['int4']),
    ('profiles','username',array['varchar','text']),
    ('profiles','email',array['varchar','text']),
    ('profiles','role',array['varchar','text']),
    ('profiles','status',array['varchar','text']),
    ('profiles','profile_image',array['varchar','text']),
    ('profiles','course_id',array['int4']),
    ('profiles','university',array['varchar','text']),
    ('profiles','purpose',array['varchar','text']),
    ('profiles','mantra',array['text','varchar']),
    ('profiles','date_of_examination',array['timestamptz']),
    ('progress_days','id',array['int8']),
    ('progress_days','user_id',array['uuid']),
    ('progress_days','activity_date',array['date']),
    ('progress_days','is_active',array['bool']),
    ('progress_days','created_at',array['timestamptz']),
    ('published_modules','id',array['int4']),
    ('published_modules','title',array['text','varchar']),
    ('published_modules','description',array['text','varchar']),
    ('published_modules','user_id',array['uuid']),
    ('published_modules','created_at',array['timestamptz']),
    ('published_modules','file',array['text','varchar']),
    ('published_modules','image',array['text','varchar']),
    ('published_modules','subject_id',array['int4']),
    ('qotd_answers','id',array['uuid']),
    ('qotd_answers','user_id',array['uuid']),
    ('qotd_answers','question_id',array['int4']),
    ('qotd_answers','quiz_id',array['int4']),
    ('qotd_answers','choice_id',array['int4']),
    ('qotd_answers','is_correct',array['bool']),
    ('qotd_answers','answered_at',array['timestamptz']),
    ('question_bank_attempts','id',array['uuid']),
    ('question_bank_attempts','user_id',array['uuid']),
    ('question_bank_attempts','subject_id',array['int4']),
    ('question_bank_attempts','quiz_id',array['int4']),
    ('question_bank_attempts','correct_answers',array['int4']),
    ('question_bank_attempts','total_questions',array['int4']),
    ('question_bank_attempts','score',array['numeric']),
    ('question_bank_attempts','completed_at',array['timestamptz']),
    ('questions','id',array['int4']),
    ('questions','quiz_id',array['int4']),
    ('questions','question_text',array['text','varchar']),
    ('quiz_attempts','id',array['int8']),
    ('quiz_attempts','quiz_id',array['int4']),
    ('quiz_attempts','student_id',array['uuid']),
    ('quiz_attempts','score',array['numeric']),
    ('quiz_attempts','attempted_at',array['timestamptz']),
    ('quiz_attempts','answer',array['jsonb']),
    ('quiz_attempts','no_of_attempt',array['int4']),
    ('quiz_attempts','summary',array['jsonb']),
    ('quiz_attempts','created_at',array['timestamptz']),
    ('quizzes','id',array['int4']),
    ('quizzes','subject_id',array['int4']),
    ('quizzes','title',array['text','varchar']),
    ('quizzes','description',array['text','varchar']),
    ('quizzes','configured_question_count',array['int4']),
    ('quizzes','created_at',array['timestamptz']),
    ('study_sessions','id',array['uuid']),
    ('study_sessions','user_id',array['uuid']),
    ('study_sessions','started_at',array['timestamptz']),
    ('study_sessions','ended_at',array['timestamptz']),
    ('study_sessions','duration_minutes',array['int4']),
    ('study_sessions','session_type',array['text','varchar']),
    ('study_sessions','created_at',array['timestamptz']),
    ('subjects','id',array['int4']),
    ('subjects','title',array['text','varchar']),
    ('subjects','course_id',array['int4']),
    ('subjects','description',array['text','varchar']),
    ('subjects','image',array['text','varchar']),
    ('subjects','day_subject',array['text','varchar']),
    ('subjects','created_at',array['timestamptz']),
    ('tasks','id',array['uuid']),
    ('tasks','task_name',array['text','varchar']),
    ('tasks','description',array['text','varchar']),
    ('tasks','user_id',array['uuid']),
    ('tasks','is_done',array['bool']),
    ('tasks','deadline',array['timestamptz']),
    ('tasks','created_at',array['timestamptz']),
    ('tasks','updated_at',array['timestamptz'])
  ) as expected(table_name,column_name,types) loop
    select udt_name into actual from information_schema.columns c
      where c.table_schema='public' and c.table_name=r.table_name and c.column_name=r.column_name;
    if actual is null or not (actual=any(r.types)) then
      raise exception 'Schema reconciliation blocked: %.% type %, expected %', r.table_name,r.column_name,actual,r.types;
    end if;
  end loop;
  if not exists (select 1 from pg_attribute a join pg_type t on t.oid=a.atttypid
    where a.attrelid='public.modules'::regclass and a.attname='status'
      and (t.typname in ('text','varchar') or (t.typtype='e' and exists
        (select 1 from pg_enum e where e.enumtypid=t.oid and lower(e.enumlabel) in ('published','active'))))) then
    raise exception 'Schema reconciliation blocked: modules.status needs text or an enum with published/active labels';
  end if;
  if not exists (select 1 from pg_constraint where conrelid='public.question_bank_attempts'::regclass
      and contype='f' and confrelid='public.subjects'::regclass)
    or not exists (select 1 from pg_constraint where conrelid='public.question_bank_attempts'::regclass
      and contype='f' and confrelid='public.quizzes'::regclass) then
    raise exception 'Schema reconciliation blocked: question_bank_attempts nested selects require subject/quiz FKs';
  end if;
end $$;
-- The first paused-table definition omitted its owner FK. Add only when there
-- is no owner FK at all; conflicting targets must be inspected, not overwritten.
do $$ declare owner_att smallint; begin
  select attnum into owner_att from pg_attribute
    where attrelid='public.mockboards_paused'::regclass and attname='user_id' and not attisdropped;
  if not exists (select 1 from pg_constraint where conrelid='public.mockboards_paused'::regclass
    and contype='f' and owner_att=any(conkey)) then
    alter table public.mockboards_paused add constraint mockboards_paused_owner_schema_fk
      foreign key (user_id) references public.profiles(id) not valid;
    alter table public.mockboards_paused validate constraint mockboards_paused_owner_schema_fk;
  end if;
end $$;
-- Check keys by participating columns/targets, not by constraint names.
do $$ declare r record; begin
  for r in select * from (values
    ('abbreviations',array['id']),
    ('authors',array['id']),
    ('chat_conversations',array['id']),
    ('chat_members',array['conversation_id','profile_id']),
    ('chat_messages',array['id']),
    ('choices',array['id']),
    ('goals',array['id']),
    ('mnemonics',array['id']),
    ('mockboards_paused',array['id']),
    ('modules',array['id']),
    ('notifications',array['id']),
    ('procedures',array['id']),
    ('profiles',array['id']),
    ('progress_days',array['id']),
    ('qotd_answers',array['id']),
    ('question_bank_attempts',array['id']),
    ('questions',array['id']),
    ('quiz_attempts',array['id']),
    ('quizzes',array['id']),
    ('study_sessions',array['id']),
    ('subjects',array['id']),
    ('tasks',array['id'])
  ) expected(table_name,columns) loop
    if not exists (select 1 from pg_constraint k
      where k.conrelid=to_regclass('public.'||r.table_name) and k.contype='p'
      and (select array_agg(a.attname::text order by x.ordinality)
        from unnest(k.conkey) with ordinality x(attnum,ordinality)
        join pg_attribute a on a.attrelid=k.conrelid and a.attnum=x.attnum)=r.columns) then
      raise exception 'Schema reconciliation blocked: %.% primary key missing/different', r.table_name,r.columns;
    end if;
  end loop;
  for r in select * from (values
    ('abbreviations','subject_id','public.subjects','id'),
    ('chat_conversations','created_by','public.profiles','id'),
    ('chat_members','conversation_id','public.chat_conversations','id'),
    ('chat_members','profile_id','public.profiles','id'),
    ('chat_messages','conversation_id','public.chat_conversations','id'),
    ('chat_messages','sender_id','public.profiles','id'),
    ('choices','question_id','public.questions','id'),
    ('goals','user_id','auth.users','id'),
    ('mnemonics','subject_id','public.subjects','id'),
    ('mockboards_paused','user_id','public.profiles','id'),
    ('modules','subject_id','public.subjects','id'),
    ('modules','user_id','public.profiles','id'),
    ('notifications','user_id','auth.users','id'),
    ('procedures','subject_id','public.subjects','id'),
    ('profiles','id','auth.users','id'),
    ('progress_days','user_id','auth.users','id'),
    ('qotd_answers','choice_id','public.choices','id'),
    ('qotd_answers','question_id','public.questions','id'),
    ('qotd_answers','quiz_id','public.quizzes','id'),
    ('qotd_answers','user_id','auth.users','id'),
    ('question_bank_attempts','quiz_id','public.quizzes','id'),
    ('question_bank_attempts','subject_id','public.subjects','id'),
    ('question_bank_attempts','user_id','public.profiles','id'),
    ('questions','quiz_id','public.quizzes','id'),
    ('quiz_attempts','student_id','auth.users','id'),
    ('quizzes','subject_id','public.subjects','id'),
    ('study_sessions','user_id','auth.users','id'),
    ('tasks','user_id','public.profiles','id')
  ) expected(table_name,column_name,target_table,target_column) loop
    if not exists (select 1 from pg_constraint k
      join pg_attribute a on a.attrelid=k.conrelid and k.conkey=array[a.attnum]
      join pg_attribute b on b.attrelid=k.confrelid and k.confkey=array[b.attnum]
      where k.conrelid=to_regclass('public.'||r.table_name) and k.contype='f'
        and a.attname=r.column_name and k.confrelid=to_regclass(r.target_table)
        and b.attname=r.target_column and k.convalidated) then
      raise exception 'Schema reconciliation blocked: %.% requires validated FK to %.%',
        r.table_name,r.column_name,r.target_table,r.target_column;
    end if;
  end loop;
end $$;
notify pgrst, 'reload schema';
commit;
