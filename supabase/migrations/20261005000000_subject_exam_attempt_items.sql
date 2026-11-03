begin;

-- Persisted, immutable summaries for Take an Exam (attempt_type =
-- 'subject_exam'). Every item stores a snapshot of the question and choices as
-- the user saw them, so later Question Bank edits or deletions never change a
-- completed exam summary.
--
-- Not applied automatically. Subject exam attempts created before this
-- migration have no item rows and cannot be reconstructed.

-- Client-generated id of one exam session. It makes the save idempotent:
-- retrying after an uncertain network response returns the same attempt.
alter table public.question_bank_attempts
  add column if not exists client_attempt_id uuid;

create unique index if not exists question_bank_attempts_client_attempt_uidx
  on public.question_bank_attempts (user_id, client_attempt_id)
  where client_attempt_id is not null;

create table if not exists public.question_bank_attempt_items (
  attempt_id uuid not null
    references public.question_bank_attempts(id) on delete cascade,
  -- 1-based position in the exam, exactly as presented to the user.
  position smallint not null check (position between 1 and 100),
  -- Traceability only. The snapshot below is the source of truth, so deleting
  -- the live question must not delete history.
  question_id integer
    references public.questions(id) on delete set null,
  question_text text not null check (length(btrim(question_text)) > 0),
  -- Ordered array of {"id": int|null, "text": text, "is_correct": bool}.
  choices_snapshot jsonb not null check (jsonb_typeof(choices_snapshot) = 'array'),
  -- Indexes into choices_snapshot. selected_index is null when unanswered.
  selected_index smallint check (selected_index >= 0),
  correct_index smallint not null check (correct_index >= 0),
  -- Live choice ids at exam time; informational, deliberately not foreign keys.
  selected_choice_id integer,
  correct_choice_id integer,
  is_correct boolean not null,
  primary key (attempt_id, position),
  -- An unanswered item can never be correct.
  check (selected_index is not null or is_correct = false)
);

create unique index if not exists question_bank_attempt_items_question_uidx
  on public.question_bank_attempt_items (attempt_id, question_id)
  where question_id is not null;

alter table public.question_bank_attempt_items enable row level security;

drop policy if exists "Users can read their own exam attempt items"
  on public.question_bank_attempt_items;
drop policy if exists "Users can insert their own exam attempt items"
  on public.question_bank_attempt_items;

-- Ownership always comes from the parent attempt. No update or delete policy:
-- a saved summary is immutable (rows only disappear with their parent).
create policy "Users can read their own exam attempt items"
  on public.question_bank_attempt_items
  for select
  to authenticated
  using (
    exists (
      select 1 from public.question_bank_attempts a
      where a.id = attempt_id and a.user_id = (select auth.uid())
    )
  );

create policy "Users can insert their own exam attempt items"
  on public.question_bank_attempt_items
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.question_bank_attempts a
      where a.id = attempt_id and a.user_id = (select auth.uid())
    )
  );

-- Saves a completed subject exam and all of its item snapshots in one
-- transaction and returns the attempt id.
--
-- The server is authoritative. The client only reports what happened in its
-- session; it never says what is correct:
--   p_items = [{"position": 1..100,
--               "question_id": int,
--               "selected_choice_id": int | null,   -- null = unanswered
--               "choice_order": [choice ids in the order displayed]}, ...]
-- Question text, choice text, which choice is correct, is_correct, the score
-- and the correct count are all read or computed here from the Question Bank
-- tables. Any client supplied text, correctness or score fields are ignored.
--
-- SECURITY INVOKER (the default): the caller's RLS applies to every table it
-- touches, and the owner is always auth.uid(), never a client value.
--
-- Idempotency: the same (user, client_attempt_id) always returns the first
-- saved attempt id. A retry with a different payload does NOT overwrite or
-- replace the original attempt; it just returns the original id.
create or replace function public.save_subject_exam_attempt(
  p_subject_id integer,
  p_client_attempt_id uuid,
  p_items jsonb
) returns uuid
language plpgsql
set search_path = public
as $$
declare
  c_expected constant integer := 100;
  v_uid uuid := auth.uid();
  v_total integer;
  v_correct integer;
  v_attempt_id uuid;
  v_rows jsonb;
  v_positions integer;
  v_min integer;
  v_max integer;
  v_dup_question boolean;
  v_dup_choice boolean;
  v_foreign_choice boolean;
  v_choice_mismatch boolean;
  v_no_correct boolean;
  v_bad_selected boolean;
  v_resolved integer;
begin
  if v_uid is null then
    raise exception 'Not authenticated' using errcode = '28000';
  end if;
  if p_subject_id is null or p_client_attempt_id is null then
    raise exception 'subject and client attempt id are required'
      using errcode = '22023';
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception 'items must be a json array' using errcode = '22023';
  end if;

  v_total := jsonb_array_length(p_items);
  if v_total <> c_expected then
    raise exception 'a completed subject exam has exactly % items', c_expected
      using errcode = '22023';
  end if;

  -- Idempotent retry: the same exam session returns the same attempt.
  select id into v_attempt_id
  from public.question_bank_attempts
  where user_id = v_uid and client_attempt_id = p_client_attempt_id;
  if v_attempt_id is not null then
    return v_attempt_id;
  end if;

  -- Resolve every submitted question and choice against the live Question
  -- Bank and validate the submission in one pass.
  with req as (
    select
      (i ->> 'position')::integer as position,
      (i ->> 'question_id')::integer as question_id,
      nullif(i ->> 'selected_choice_id', '')::integer as selected_choice_id,
      i -> 'choice_order' as choice_order
    from jsonb_array_elements(p_items) as i
  ),
  ord as (
    select
      r.position,
      r.question_id,
      e.choice_id_text::integer as choice_id,
      e.ord::integer as ord
    from req r
    cross join lateral jsonb_array_elements_text(r.choice_order)
      with ordinality as e(choice_id_text, ord)
  ),
  ch as (
    select o.position, o.ord, c.id, c.choice_text, c.is_correct
    from ord o
    join public.choices c
      on c.id = o.choice_id and c.question_id = o.question_id
  ),
  per as (
    -- Only questions that exist AND belong to the requested subject survive
    -- this join; anything else makes the resolved count fall short below.
    select
      r.position,
      r.question_id,
      q.question_text,
      r.selected_choice_id,
      (select jsonb_agg(
                jsonb_build_object(
                  'id', ch.id, 'text', ch.choice_text,
                  'is_correct', ch.is_correct)
                order by ch.ord)
         from ch where ch.position = r.position) as snap,
      (select ch.ord - 1 from ch
        where ch.position = r.position and ch.id = r.selected_choice_id)
        as sel_idx,
      (select min(ch.ord) - 1 from ch
        where ch.position = r.position and ch.is_correct) as cor_idx,
      coalesce((select ch.is_correct from ch
        where ch.position = r.position and ch.id = r.selected_choice_id),
        false) as is_correct
    from req r
    join public.questions q on q.id = r.question_id
    join public.quizzes z on z.id = q.quiz_id and z.subject_id = p_subject_id
  )
  select
    (select jsonb_agg(to_jsonb(per) order by per.position) from per),
    (select count(distinct position) from req),
    (select min(position) from req),
    (select max(position) from req),
    (select count(question_id) <> count(distinct question_id) from req),
    (select count(*) from per),
    -- the same choice listed twice for one question
    exists (select 1 from ord group by position, choice_id having count(*) > 1),
    -- a choice id that is not a choice of that exact question
    exists (
      select 1 from ord o
      left join public.choices c
        on c.id = o.choice_id and c.question_id = o.question_id
      where c.id is null
    ),
    -- the submitted order must list every choice of the question exactly once
    exists (
      select 1 from per p
      where (select count(*) from ord o where o.position = p.position)
         <> (select count(*) from public.choices c
             where c.question_id = p.question_id)
    ),
    -- a question needs at least one correct choice to be gradable
    exists (select 1 from per where cor_idx is null),
    -- the selected choice must be one of that question's choices
    exists (
      select 1 from per
      where selected_choice_id is not null and sel_idx is null
    )
  into
    v_rows, v_positions, v_min, v_max, v_dup_question, v_resolved,
    v_dup_choice, v_foreign_choice, v_choice_mismatch, v_no_correct,
    v_bad_selected
  from (select 1) as one;

  if v_positions <> v_total or v_min <> 1 or v_max <> v_total then
    raise exception 'item positions must be exactly 1..%', v_total
      using errcode = '22023';
  end if;
  if v_dup_question then
    raise exception 'duplicate question in exam' using errcode = '22023';
  end if;
  if v_resolved <> v_total then
    raise exception 'every question must exist and belong to the subject'
      using errcode = '22023';
  end if;
  if v_dup_choice or v_foreign_choice or v_choice_mismatch then
    raise exception 'choice order must list each choice of the question once'
      using errcode = '22023';
  end if;
  if v_no_correct then
    raise exception 'a question has no correct choice' using errcode = '22023';
  end if;
  if v_bad_selected then
    raise exception 'selected choice does not belong to its question'
      using errcode = '22023';
  end if;

  select count(*) filter (where (x ->> 'is_correct')::boolean)
  into v_correct
  from jsonb_array_elements(v_rows) as x;

  insert into public.question_bank_attempts (
    user_id, subject_id, quiz_id, attempt_type,
    correct_answers, total_questions, score, client_attempt_id
  ) values (
    v_uid, p_subject_id, null, 'subject_exam',
    v_correct, v_total, round(v_correct * 100.0 / v_total, 2),
    p_client_attempt_id
  )
  on conflict (user_id, client_attempt_id) where client_attempt_id is not null
  do nothing
  returning id into v_attempt_id;

  if v_attempt_id is null then
    -- A concurrent call with the same session id won the race.
    select id into v_attempt_id
    from public.question_bank_attempts
    where user_id = v_uid and client_attempt_id = p_client_attempt_id;
    return v_attempt_id;
  end if;

  insert into public.question_bank_attempt_items (
    attempt_id, position, question_id, question_text, choices_snapshot,
    selected_index, correct_index, selected_choice_id, correct_choice_id,
    is_correct
  )
  select
    v_attempt_id, x.position, x.question_id, x.question_text, x.snap,
    x.sel_idx, x.cor_idx, x.selected_choice_id,
    (x.snap -> x.cor_idx::integer ->> 'id')::integer,
    x.is_correct
  from jsonb_to_recordset(v_rows) as x(
    position smallint,
    question_id integer,
    question_text text,
    selected_choice_id integer,
    snap jsonb,
    sel_idx smallint,
    cor_idx smallint,
    is_correct boolean
  )
  order by x.position;

  return v_attempt_id;
end;
$$;

revoke all on function public.save_subject_exam_attempt(integer, uuid, jsonb)
  from public, anon;
grant execute on function public.save_subject_exam_attempt(integer, uuid, jsonb)
  to authenticated;

notify pgrst, 'reload schema';
commit;
