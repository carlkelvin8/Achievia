# Application schema dependency report

This is the tested, application-derived EMPTY-install schema, **not an export of deployed Supabase**. All Dart datasource files were read/scanned, including generic RPC calls and queries outside datasources in questions_helpers/home_provider. Types and constraints below were collected from the isolated PostgreSQL baseline. Extra hosted columns, policies, triggers, defaults and enums must be compared separately.

Eight missing content definitions are provisional for fresh installations. Foreign keys for supplemental subject_id follow its name; the app currently filters it with courseId, so production semantics need confirmation. The baseline uses module_status(draft,published,active); hosted enum name/labels remain unknown. Other enum-like values use CHECK constraints, not PostgreSQL enums.

All exposed base tables require RLS. Views depend on their underlying table policies. Existing policy definitions are reused; no new authentication or scoring behavior was implemented.

## abbreviations

Columns: `id integer NOT NULL`; `subject_id integer`; `short_form text`; `full_form text`; `deleted_at timestamp with time zone`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (subject_id) REFERENCES subjects(id)

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Authenticated read, deleted_at IS NULL.

Application references:
- `lib/data/data_source/reviewer/supplemental_remote_datasource.dart:58`

## authors

Columns: `id bigint NOT NULL`; `name text NOT NULL`; `university text NOT NULL`; `achievement text NOT NULL`; `greeting text NOT NULL`; `message text NOT NULL`; `image_url text`; `sort_order integer NOT NULL`; `is_active boolean NOT NULL`; `created_at timestamp with time zone NOT NULL`; `updated_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: None.

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Authenticated active content read.

Application references:
- `lib/data/data_source/about/author_remote_datasource.dart:17`

## chat_conversations

Columns: `id uuid NOT NULL`; `type text NOT NULL`; `title text`; `created_by uuid`; `created_at timestamp with time zone NOT NULL`; `updated_at timestamp with time zone NOT NULL`; `last_message_at timestamp with time zone`; `latest_message text`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE SET NULL

Other constraints: CHECK ((type = ANY (ARRAY['group'::text, 'direct'::text])))

Enum usage: No native enum.

RLS requirement: Membership read; RPC creates direct chats.

Application references:
- `lib/data/data_source/chat/chat_remote_datasource.dart:44`

## chat_members

Columns: `conversation_id uuid NOT NULL`; `profile_id uuid NOT NULL`; `role text NOT NULL`; `joined_at timestamp with time zone NOT NULL`; `last_read_at timestamp with time zone`.

Primary key: PRIMARY KEY (conversation_id, profile_id)

Foreign keys: FOREIGN KEY (conversation_id) REFERENCES chat_conversations(id) ON DELETE CASCADE; FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE

Other constraints: CHECK ((role = ANY (ARRAY['owner'::text, 'member'::text])))

Enum usage: No native enum.

RLS requirement: Membership read; RPC manages membership.

Application references:
- `lib/data/data_source/chat/chat_remote_datasource.dart:34`
- `lib/data/data_source/chat/chat_remote_datasource.dart:81`

## chat_messages

Columns: `id uuid NOT NULL`; `conversation_id uuid NOT NULL`; `sender_id uuid NOT NULL`; `body text NOT NULL`; `created_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (conversation_id) REFERENCES chat_conversations(id) ON DELETE CASCADE; FOREIGN KEY (sender_id) REFERENCES profiles(id) ON DELETE CASCADE

Other constraints: CHECK ((char_length(body) <= 10000)) NOT VALID; CHECK ((length(TRIM(BOTH FROM body)) > 0))

Enum usage: No native enum.

RLS requirement: Membership read/send.

Application references:
- `lib/data/data_source/chat/chat_remote_datasource.dart:124`
- `lib/data/data_source/chat/chat_remote_datasource.dart:187`

## choices

Columns: `id integer NOT NULL`; `question_id integer NOT NULL`; `choice_text text NOT NULL`; `is_correct boolean NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (question_id) REFERENCES questions(id)

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Authenticated content read.

Application references:
- `lib/core/utils/questions_helpers.dart:361`
- `lib/core/utils/questions_helpers.dart:375`
- `lib/data/data_source/home/questions_remote_datasource.dart:103`
- `lib/data/data_source/reviewer/question_bank_remote_datasource.dart:104`

## goals

Columns: `id uuid NOT NULL`; `user_id uuid NOT NULL`; `goal_date date NOT NULL`; `title text NOT NULL`; `details text NOT NULL`; `is_checked boolean NOT NULL`; `created_at timestamp with time zone NOT NULL`; `updated_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE

Other constraints: UNIQUE (user_id, goal_date)

Enum usage: No native enum.

RLS requirement: Owner-scoped access using the UUID user/student ID; existing operation policies retained.

Application references:
- `lib/data/data_source/home/goal_remote_datasource.dart:33`
- `lib/data/data_source/home/goal_remote_datasource.dart:49`

## mnemonics

Columns: `id integer NOT NULL`; `subject_id integer`; `title text`; `file_path text`; `description text`; `deleted_at timestamp with time zone`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (subject_id) REFERENCES subjects(id)

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Authenticated read, deleted_at IS NULL.

Application references:
- `lib/data/data_source/reviewer/supplemental_remote_datasource.dart:33`

## mockboards_paused

Columns: `id uuid NOT NULL`; `user_id uuid NOT NULL`; `quiz_id integer NOT NULL`; `current_page double precision NOT NULL`; `created_at timestamp with time zone NOT NULL`; `updated_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (user_id) REFERENCES profiles(id)

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Owner-scoped access using the UUID user/student ID; existing operation policies retained.

Application references:
- `lib/data/data_source/home/questions_remote_datasource.dart:246`
- `lib/data/data_source/home/questions_remote_datasource.dart:262`

## modules

Columns: `id integer NOT NULL`; `title text NOT NULL`; `description text`; `user_id uuid`; `created_at timestamp with time zone NOT NULL`; `file text`; `image text`; `status module_status NOT NULL`; `subject_id integer`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (subject_id) REFERENCES subjects(id); FOREIGN KEY (user_id) REFERENCES profiles(id)

Other constraints: None.

Enum usage: module_status; hosted enum may differ.

RLS requirement: Published/active read, staff-owned drafts and writes (existing policies).

Application references:
- `lib/data/data_source/reviewer/module_remote_datasource.dart:44`

## notifications

Columns: `id uuid NOT NULL`; `user_id uuid NOT NULL`; `title text NOT NULL`; `message text NOT NULL`; `notification_type text NOT NULL`; `image_url text`; `data jsonb`; `is_read boolean NOT NULL`; `created_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Owner-scoped access using the UUID user/student ID; existing operation policies retained.

Application references:
- `lib/data/data_source/notifications/notification_remote_datasource.dart:29`
- `lib/data/data_source/notifications/notification_remote_datasource.dart:43`
- `lib/data/data_source/notifications/notification_remote_datasource.dart:52`
- `lib/data/data_source/notifications/notification_remote_datasource.dart:61`

## procedures

Columns: `id integer NOT NULL`; `subject_id integer`; `title text`; `file_path text`; `deleted_at timestamp with time zone`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (subject_id) REFERENCES subjects(id)

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Authenticated read, deleted_at IS NULL.

Application references:
- `lib/data/data_source/reviewer/supplemental_remote_datasource.dart:82`

## profiles

Columns: `id uuid NOT NULL`; `created_at timestamp with time zone NOT NULL`; `updated_at timestamp with time zone NOT NULL`; `first_name character varying(100)`; `middle_name character varying(100)`; `last_name character varying(255)`; `bio text`; `age integer`; `trial integer`; `username character varying(100)`; `email character varying(255)`; `role character varying(50) NOT NULL`; `status character varying(50) NOT NULL`; `profile_image character varying(255)`; `course_id integer`; `university character varying(255)`; `purpose character varying(255)`; `mantra text`; `date_of_examination timestamp with time zone`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE

Other constraints: UNIQUE (email); CHECK (((role)::text = ANY ((ARRAY['USER'::character varying, 'ADMIN'::character varying, 'TEACHER'::character varying])::text[]))); CHECK (((status)::text = ANY ((ARRAY['active'::character varying, 'inactive'::character varying])::text[]))); UNIQUE (username)

Enum usage: No native enum.

RLS requirement: Own profile; existing audit column grants retained.

Application references:
- `lib/data/data_source/profile/profile_remote_datasource.dart:28`
- `lib/data/data_source/profile/profile_remote_datasource.dart:51`
- `lib/data/data_source/profile/profile_remote_datasource.dart:73`
- `lib/data/data_source/supabase_user_context.dart:20`

## progress_days

Columns: `id bigint NOT NULL`; `user_id uuid`; `activity_date date NOT NULL`; `is_active boolean NOT NULL`; `created_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Owner-scoped access using the UUID user/student ID; existing operation policies retained.

Application references:
- `lib/data/data_source/progress/progress_remote_datasource.dart:32`
- `lib/data/data_source/progress/progress_remote_datasource.dart:43`

## published_modules

Columns: `id integer`; `title text`; `description text`; `user_id uuid`; `created_at timestamp with time zone`; `file text`; `image text`; `status module_status`; `subject_id integer`.

Primary key: None (view).

Foreign keys: None.

Other constraints: None.

Enum usage: module_status; hosted enum may differ.

RLS requirement: Invoker-security view; published/active filter over modules RLS.

Application references:
- `lib/data/data_source/reviewer/module_remote_datasource.dart:44`

## qotd_answers

Columns: `id uuid NOT NULL`; `user_id uuid NOT NULL`; `question_id integer NOT NULL`; `quiz_id integer NOT NULL`; `choice_id integer NOT NULL`; `is_correct boolean NOT NULL`; `answered_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (choice_id) REFERENCES choices(id) ON DELETE CASCADE; FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE; FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE; FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Owner-scoped access using the UUID user/student ID; existing operation policies retained.

Application references:
- `lib/data/data_source/home/questions_remote_datasource.dart:126`

## question_bank_attempts

Columns: `id uuid NOT NULL`; `user_id uuid NOT NULL`; `subject_id integer NOT NULL`; `quiz_id integer NOT NULL`; `correct_answers integer NOT NULL`; `total_questions integer NOT NULL`; `score numeric(5,2) NOT NULL`; `completed_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE; FOREIGN KEY (subject_id) REFERENCES subjects(id) ON DELETE CASCADE; FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE

Other constraints: CHECK ((correct_answers <= total_questions)); CHECK ((correct_answers >= 0)); CHECK (((score >= (0)::numeric) AND (score <= (100)::numeric))); CHECK ((total_questions > 0))

Enum usage: No native enum.

RLS requirement: Owner-scoped access using the UUID user/student ID; existing operation policies retained.

Application references:
- `lib/data/data_source/progress/progress_remote_datasource.dart:64`
- `lib/data/data_source/reviewer/question_bank_remote_datasource.dart:132`
- `lib/data/data_source/reviewer/question_bank_remote_datasource.dart:157`

## questions

Columns: `id integer NOT NULL`; `quiz_id integer NOT NULL`; `question_text text NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (quiz_id) REFERENCES quizzes(id)

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Authenticated content read.

Application references:
- `lib/core/utils/questions_helpers.dart:118`
- `lib/data/data_source/home/questions_remote_datasource.dart:67`
- `lib/data/data_source/home/questions_remote_datasource.dart:116`
- `lib/data/data_source/reviewer/question_bank_remote_datasource.dart:90`

## quiz_attempts

Columns: `id bigint NOT NULL`; `quiz_id integer`; `student_id uuid NOT NULL`; `score numeric NOT NULL`; `attempted_at timestamp with time zone NOT NULL`; `answer jsonb NOT NULL`; `no_of_attempt integer NOT NULL`; `summary jsonb NOT NULL`; `created_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (student_id) REFERENCES auth.users(id) ON DELETE CASCADE

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Owner-scoped access using the UUID user/student ID; existing operation policies retained.

Application references:
- `lib/data/data_source/home/questions_remote_datasource.dart:195`
- `lib/data/data_source/home/questions_remote_datasource.dart:216`
- `lib/data/data_source/home/questions_remote_datasource.dart:223`
- `lib/data/data_source/home/questions_remote_datasource.dart:279`
- `lib/data/data_source/progress/progress_remote_datasource.dart:59`

## quizzes

Columns: `id integer NOT NULL`; `subject_id integer`; `title text NOT NULL`; `description text`; `configured_question_count integer`; `created_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (subject_id) REFERENCES subjects(id)

Other constraints: CHECK ((configured_question_count >= 0))

Enum usage: No native enum.

RLS requirement: Authenticated content read.

Application references:
- `lib/core/utils/questions_helpers.dart:103`
- `lib/core/utils/questions_helpers.dart:393`
- `lib/data/data_source/reviewer/question_bank_remote_datasource.dart:66`

## study_sessions

Columns: `id uuid NOT NULL`; `user_id uuid NOT NULL`; `started_at timestamp with time zone NOT NULL`; `ended_at timestamp with time zone NOT NULL`; `duration_minutes integer NOT NULL`; `session_type text NOT NULL`; `created_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE

Other constraints: CHECK ((ended_at > started_at)); CHECK ((duration_minutes > 0))

Enum usage: No native enum.

RLS requirement: Owner-scoped access using the UUID user/student ID; existing operation policies retained.

Application references:
- `lib/data/data_source/progress/study_session_remote_datasource.dart:33`

## subjects

Columns: `id integer NOT NULL`; `title text NOT NULL`; `course_id integer`; `description text`; `image text`; `day_subject text`; `created_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: None.

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Authenticated content read.

Application references:
- `lib/data/data_source/home/questions_remote_datasource.dart:46`
- `lib/data/data_source/home/questions_remote_datasource.dart:150`
- `lib/data/data_source/reviewer/question_bank_remote_datasource.dart:45`
- `lib/data/data_source/reviewer/question_bank_remote_datasource.dart:55`

## supplemental_items

Columns: `id bigint NOT NULL`; `course_id integer`; `kind text NOT NULL`; `title text NOT NULL`; `content text NOT NULL`; `image_url text`; `file_url text`; `sort_order integer NOT NULL`; `is_active boolean NOT NULL`; `created_at timestamp with time zone NOT NULL`; `updated_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: None.

Other constraints: CHECK ((kind = ANY (ARRAY['mnemonic'::text, 'abbreviation'::text, 'procedure'::text])))

Enum usage: No native enum.

RLS requirement: Authenticated active content read; no current datasource.

Application references:
- No direct `.from()` call; retained historical support table/view.

## tasks

Columns: `id uuid NOT NULL`; `task_name text NOT NULL`; `description text NOT NULL`; `user_id uuid NOT NULL`; `is_done boolean NOT NULL`; `deadline timestamp with time zone NOT NULL`; `created_at timestamp with time zone NOT NULL`; `updated_at timestamp with time zone NOT NULL`.

Primary key: PRIMARY KEY (id)

Foreign keys: FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE

Other constraints: None.

Enum usage: No native enum.

RLS requirement: Owner-scoped access using the UUID user/student ID; existing operation policies retained.

Application references:
- `lib/data/data_source/task/task_remote_datasource.dart:26`
- `lib/data/data_source/task/task_remote_datasource.dart:39`
- `lib/data/data_source/task/task_remote_datasource.dart:54`

## RPC contract

| Function | Arguments | Return shape | Application |
|---|---|---|---|
| is_username_available | p_username text | boolean | auth/user_remote_datasource.dart |
| search_profiles_for_chat | search_query text, result_limit integer default 20 | rows: id UUID, name/username/email/profile_image strings | chat/chat_remote_datasource.dart |
| chat_profile_summaries | profile_ids UUID[] | same profile rows | chat/chat_remote_datasource.dart |
| get_or_create_direct_chat | target_profile_id UUID | JSONB conversation object, not a row set | chat/chat_remote_datasource.dart |
| get_weekly_mockboard_achievians | p_limit integer default 10 | profile fields, average_score/best_score numeric, attempts_count bigint | presentation/provider/home/home_provider.dart |
| get_monthly_streak_achievians | p_limit integer default 10 | profile fields, longest_streak/active_days integer | presentation/provider/home/home_provider.dart |

RPC dependencies: profiles + chat_members/chat_conversations for chat; profiles + quiz_attempts for leaderboards; profiles.username for availability. Server-only helper functions (auth trigger, timestamps, is_chat_member) are retained from source migrations.

## Schema ambiguities preserved for review

- mockboards_paused.id must deserialize as String; canonical new IDs are UUID. quiz_id must deserialize as numeric integer. current_page is double in Dart; canonical SQL is double precision. Integer row-ID deployments require a separate reviewed ID and incoming-FK mapping; the forward migration stops rather than replacing IDs.
- Paused quiz_id meaning is not established by an active caller (resumeExam has no call site found). Generated exams also use section IDs 1..6. Do not invent a quizzes FK or convert UUIDs by order/cast. Existing quiz FKs are retained when attached to the legacy column; validate their delete behavior manually.
- Paused maybeSingle() assumes at most one row per user, but history has no such unique constraint. Do not delete duplicate rows to impose uniqueness. The current Flutter write also supplies empty IDs/timestamps; baseline SQL compatibility does not certify that resume flow. Flutter changes are out of scope.
- quiz_attempts.quiz_id stays nullable without a new FK because aggregate attempts omit it. Legacy identity backfills for quiz_attempts.student_id_legacy and progress_days.user_id_legacy require authoritative mappings.
- progress_days requires unique(user_id,activity_date) for upsert; goals has unique(user_id,goal_date). Baseline includes both. Attempt numbers are not uniquely constrained.
- quizzes configured_question_count is the baseline field; app also accepts configuredQuestionCount, question_count, questionCount, mock_board_question_count, mockBoardQuestionCount, number_of_questions, numberOfQuestions. Existing deployment aliases should be inspected before adding/backfilling a canonical field.
- ProfileDto.password is an optional unused decode field, not a required public database column. No password column is added.
- Content/quiz counts and actual study materials require approved data import; schema creation alone cannot populate them. Storage buckets/files and realtime platform behavior are outside this database replay fixture.

## Datasource inspection inventory

- `lib/core/utils/questions_helpers.dart`
- `lib/data/data_source/about/author_remote_datasource.dart`
- `lib/data/data_source/auth/user_remote_datasource.dart`
- `lib/data/data_source/chat/chat_remote_datasource.dart`
- `lib/data/data_source/home/goal_remote_datasource.dart`
- `lib/data/data_source/home/questions_remote_datasource.dart`
- `lib/data/data_source/notifications/notification_remote_datasource.dart`
- `lib/data/data_source/profile/profile_remote_datasource.dart`
- `lib/data/data_source/progress/progress_remote_datasource.dart`
- `lib/data/data_source/progress/study_session_remote_datasource.dart`
- `lib/data/data_source/reviewer/module_remote_datasource.dart`
- `lib/data/data_source/reviewer/question_bank_remote_datasource.dart`
- `lib/data/data_source/reviewer/supplemental_remote_datasource.dart`
- `lib/data/data_source/supabase_user_context.dart`
- `lib/data/data_source/task/task_remote_datasource.dart`
- `lib/presentation/provider/home/home_provider.dart`

DTOs checked for ID/types: mockboards_paused_dto.dart and generated decoder; task_read_dto.dart; profile_dto.dart; questions_dto.dart; module_dto.dart; supplemental_item_dto.dart; question-bank parsing helpers. Full baseline catalog: `docs/audit-evidence/database-baseline-catalog.json`.
