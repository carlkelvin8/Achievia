-- PROPOSED PATCH - NOT APPLIED, deliberately kept out of supabase/migrations.
--
-- Makes qotd_answers server-authoritative:
--   * is_correct is derived from the stored choice, never trusted from the
--     client, and the choice must belong to the answered question;
--   * one answer per user, question and (Asia/Manila) calendar day. The app
--     already treats a 23505 unique violation as "already answered".
--
-- Before running: check for existing duplicates, otherwise the index fails:
--   select user_id, question_id, (answered_at at time zone 'Asia/Manila')::date,
--          count(*) from public.qotd_answers group by 1,2,3 having count(*) > 1;
-- Review, then run it as a single reviewed statement.
-- Move to supabase/migrations/ only once approved.

begin;

create or replace function public.qotd_answers_set_correctness()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_correct boolean;
begin
  select c.is_correct into v_correct
  from public.choices c
  where c.id = new.choice_id and c.question_id = new.question_id;

  if not found then
    raise exception 'choice % does not belong to question %',
      new.choice_id, new.question_id using errcode = '23514';
  end if;

  new.is_correct := coalesce(v_correct, false);
  return new;
end;
$$;

drop trigger if exists qotd_answers_set_correctness on public.qotd_answers;
create trigger qotd_answers_set_correctness
  before insert on public.qotd_answers
  for each row execute function public.qotd_answers_set_correctness();

create unique index if not exists qotd_answers_user_question_day_uidx
  on public.qotd_answers (
    user_id, question_id, ((answered_at at time zone 'Asia/Manila')::date)
  );

commit;
