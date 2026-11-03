-- Repairs stored Mock Board scores graded with the wrong MTLE weights.
--
-- Clinical Microscopy was weighted 20% and Blood Banking and Serology 10%; the
-- correct weights are Clinical Microscopy 10%, Histopathology/Laws 10% and the
-- other four subjects 20%. `quiz_attempts.score` feeds Recent Results, Progress
-- and the leaderboards, so it has to be recomputed from the stored section
-- scores.
--
-- Weights are matched by subject name, not position. Only rows with exactly the
-- six board sections and numeric scores are recomputed; older rows that stored
-- topic names (e.g. "Clinical Microscopy Picture-Based Questions") are left
-- untouched. Old scores are kept in the backup table. Safe to run twice.
--
-- Undo:
--   update public.quiz_attempts qa set score = b.old_score
--   from public.quiz_attempts_score_backup_20261103 b
--   where qa.id::text = b.attempt_id;

begin;

create table if not exists public.quiz_attempts_score_backup_20261103 (
  attempt_id text primary key,
  old_score numeric not null,
  backed_up_at timestamptz not null default now()
);
alter table public.quiz_attempts_score_backup_20261103
  enable row level security;
revoke all on public.quiz_attempts_score_backup_20261103
  from public, anon, authenticated;

create temporary table recomputed_scores on commit drop as
select
  qa.id,
  qa.score as old_score,
  round(
    sum(
      case when i.item ->> 'score' ~ '^[0-9]+(\.[0-9]+)?$'
        then (i.item ->> 'score')::numeric else 0 end
      * case
          when lower(i.item ->> 'name') like 'clinical microscopy%'
            or lower(i.item ->> 'name') like 'histopath%' then 10
          else 20
        end
    ) / 100,
    2
  ) as new_score
from public.quiz_attempts qa
cross join lateral jsonb_array_elements(
  case when jsonb_typeof(qa.answer) = 'array' then qa.answer else '[]'::jsonb end
) as i(item)
group by qa.id, qa.score
having count(*) = 6
  and bool_and(coalesce(i.item ->> 'score' ~ '^[0-9]+(\.[0-9]+)?$', false))
  and count(distinct lower(i.item ->> 'name')) filter (
    where lower(i.item ->> 'name') = any (array[
      'clinical chemistry',
      'microbiology and parasitology',
      'clinical microscopy',
      'hematology',
      'blood banking and serology',
      'histopathology and medical technology laws/ethics'
    ])
  ) = 6;

insert into public.quiz_attempts_score_backup_20261103 (attempt_id, old_score)
select id::text, old_score
from recomputed_scores
where new_score is distinct from old_score
on conflict (attempt_id) do nothing;

update public.quiz_attempts qa
set score = r.new_score
from recomputed_scores r
where qa.id = r.id
  and r.new_score is distinct from r.old_score;

commit;
