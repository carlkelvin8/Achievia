-- Makes quiz_attempts.attempted_at a real point in time.
--
-- Production has `timestamp without time zone`, while the repo expects
-- timestamptz. Without an offset the app shows UTC values as if they were local
-- (10:59 AM appeared as 02:59), and timezone('Asia/Manila', attempted_at) in the
-- monthly streak converts in the wrong direction.
--
-- The stored values are not all in one zone, and production has no created_at
-- to compare them with. The cutoff comes from production's rows on 2026-11-03:
--   * id <= 23 (July 2026 and earlier): the app wrote local time, Asia/Manila.
--   * id >= 24 (from 2026-10-19): UTC. Inferred from the times of day and from
--     Mock Board 11, which appeared after 11:04 AM with a stored time of 03:19.
--
-- This cutoff is specific to that production database; the script stops if the
-- rows do not match it. Safe to run twice. Old values stay in the backup table.
--
-- Undo:
--   begin;
--   alter table public.quiz_attempts alter column attempted_at
--     type timestamp without time zone using attempted_at at time zone 'UTC';
--   update public.quiz_attempts qa set attempted_at = b.old_attempted_at
--   from public.quiz_attempts_attempted_at_backup_20261103 b where qa.id = b.id;
--   commit;

begin;
set local lock_timeout = '5s';

do $$
declare
  v_type text;
  v_bad integer;
begin
  select data_type into v_type
  from information_schema.columns
  where table_schema = 'public'
    and table_name = 'quiz_attempts'
    and column_name = 'attempted_at';

  if v_type = 'timestamp with time zone' then
    raise notice 'attempted_at is already timestamptz; nothing to do';
    return;
  end if;
  if v_type is distinct from 'timestamp without time zone' then
    raise exception 'unexpected attempted_at type: %', v_type;
  end if;

  select count(*) into v_bad
  from public.quiz_attempts
  where (id <= 23 and attempted_at >= timestamp '2026-08-01')
     or (id >= 24 and attempted_at < timestamp '2026-10-19');
  if v_bad > 0 then
    raise exception '% rows do not match the id 23/24 cutoff', v_bad;
  end if;

  create table public.quiz_attempts_attempted_at_backup_20261103 as
  select id, attempted_at as old_attempted_at, now() as backed_up_at
  from public.quiz_attempts;
  alter table public.quiz_attempts_attempted_at_backup_20261103
    add primary key (id);
  alter table public.quiz_attempts_attempted_at_backup_20261103
    enable row level security;
  revoke all on public.quiz_attempts_attempted_at_backup_20261103
    from public, anon, authenticated;

  alter table public.quiz_attempts
    alter column attempted_at type timestamptz
    using case
      when id <= 23 then attempted_at at time zone 'Asia/Manila'
      else attempted_at at time zone 'UTC'
    end;
end;
$$;

commit;
