begin;

create table if not exists public.daily_motivations (
  id uuid primary key default gen_random_uuid(),
  message text not null
    constraint daily_motivations_message_check
    check (btrim(message) <> '' and char_length(message) <= 280),
  is_active boolean not null default true,
  display_order integer not null default 0,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- The same message (ignoring case/whitespace) cannot be stored twice; this
-- also keeps the seed below idempotent.
create unique index if not exists daily_motivations_message_unique
  on public.daily_motivations (lower(btrim(message)));

-- Homepage query: active rows in a stable rotation order.
create index if not exists daily_motivations_active_order_idx
  on public.daily_motivations (display_order, created_at, id)
  where is_active;

drop trigger if exists set_daily_motivations_updated_at on public.daily_motivations;
create trigger set_daily_motivations_updated_at
  before update on public.daily_motivations
  for each row execute function public.set_updated_at();

alter table public.daily_motivations enable row level security;

revoke all on public.daily_motivations from anon;
grant select, insert, update, delete on public.daily_motivations to authenticated;

-- Everyone signed in reads active rows; admins also see inactive ones.
drop policy if exists "Read active daily motivations" on public.daily_motivations;
create policy "Read active daily motivations" on public.daily_motivations
for select to authenticated using (
  is_active or exists (
    select 1 from public.profiles p where p.id = (select auth.uid())
    and p.role = 'ADMIN' and p.status = 'active'));

drop policy if exists "Admins insert daily motivations" on public.daily_motivations;
create policy "Admins insert daily motivations" on public.daily_motivations
for insert to authenticated with check (
  created_by = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.id = (select auth.uid())
    and p.role = 'ADMIN' and p.status = 'active'));

drop policy if exists "Admins update daily motivations" on public.daily_motivations;
create policy "Admins update daily motivations" on public.daily_motivations
for update to authenticated using (exists (
    select 1 from public.profiles p where p.id = (select auth.uid())
    and p.role = 'ADMIN' and p.status = 'active'))
with check (exists (
    select 1 from public.profiles p where p.id = (select auth.uid())
    and p.role = 'ADMIN' and p.status = 'active'));

drop policy if exists "Admins delete daily motivations" on public.daily_motivations;
create policy "Admins delete daily motivations" on public.daily_motivations
for delete to authenticated using (exists (
    select 1 from public.profiles p where p.id = (select auth.uid())
    and p.role = 'ADMIN' and p.status = 'active'));

-- Starter content; rerunning is a no-op thanks to the unique index.
insert into public.daily_motivations (message, display_order) values
  ('You didn''t come this far to only come this far. Every late night, every sacrificed moment, they are all shaping your victory. Keep going.', 1),
  ('Small steps every day add up to the license you are working for.', 2),
  ('Trust your preparation. Future RMT, you are more ready than you think.', 3),
  ('Discipline today is the confidence you will carry into the board exam.', 4),
  ('Rest if you must, but do not quit. Your future patients are counting on you.', 5)
on conflict do nothing;

notify pgrst, 'reload schema';
commit;
