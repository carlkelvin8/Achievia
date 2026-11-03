-- Exam Summary: keep each question's image and rationale in the saved snapshot
--
-- Why: the Take an Exam summary is a snapshot of the exam (question text and
-- choices as they were shown). The image and rationale were not part of it,
-- so the app looked them up on the live question. A question that is later
-- hard deleted, or hidden from clients once the soft-delete RLS policy of
-- 20261006100000 is enabled, then lost its image and rationale in old
-- summaries.
--
-- What it does:
--   * adds nullable image_path / rationale to question_bank_attempt_items;
--   * a BEFORE INSERT trigger copies them from public.questions, so
--     save_subject_exam_attempt keeps working unchanged (no body change);
--   * backfills the rows saved so far from the questions that still exist.
--
-- The rationale follows the app: the rationale column when it is filled,
-- otherwise the admin panel's correct_description. The app reads the
-- columns when present and falls back to the live question otherwise, so it
-- works before and after this patch.
--
-- Review, then run it as a single statement in staging first.

begin;
set local lock_timeout = '5s';

alter table public.question_bank_attempt_items
  add column if not exists image_path text,
  add column if not exists rationale text;

create or replace function public.question_bank_attempt_item_media()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_question jsonb;
begin
  if new.question_id is null then
    return new;
  end if;
  -- to_jsonb so a missing optional column (rationale / correct_description)
  -- reads as null instead of failing.
  select to_jsonb(q) into v_question
  from public.questions q
  where q.id = new.question_id;
  if v_question is null then
    return new;
  end if;
  new.image_path := coalesce(
    new.image_path,
    nullif(nullif(btrim(v_question ->> 'image_path'), ''), 'null')
  );
  new.rationale := coalesce(
    new.rationale,
    nullif(nullif(btrim(v_question ->> 'rationale'), ''), 'null'),
    nullif(nullif(btrim(v_question ->> 'correct_description'), ''), 'null')
  );
  return new;
end;
$$;

revoke all on function public.question_bank_attempt_item_media() from public;

drop trigger if exists question_bank_attempt_item_media
  on public.question_bank_attempt_items;
create trigger question_bank_attempt_item_media
  before insert on public.question_bank_attempt_items
  for each row execute function public.question_bank_attempt_item_media();

-- Backfill the summaries saved before this patch.
update public.question_bank_attempt_items i
set
  image_path = coalesce(
    i.image_path,
    nullif(nullif(btrim(to_jsonb(q) ->> 'image_path'), ''), 'null')
  ),
  rationale = coalesce(
    i.rationale,
    nullif(nullif(btrim(to_jsonb(q) ->> 'rationale'), ''), 'null'),
    nullif(nullif(btrim(to_jsonb(q) ->> 'correct_description'), ''), 'null')
  )
from public.questions q
where q.id = i.question_id
  and (i.image_path is null or i.rationale is null);

commit;
