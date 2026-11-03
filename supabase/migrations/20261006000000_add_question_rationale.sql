begin;

-- Authoritative explanation shown after a Question of the Day or Study Mode
-- answer. Nullable with no default: existing questions simply have no
-- rationale yet and the app shows "No rationale available." Content must be
-- populated externally; nothing is generated or backfilled here.
alter table public.questions
  add column if not exists rationale text;

notify pgrst, 'reload schema';
commit;
