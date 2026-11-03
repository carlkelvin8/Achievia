-- NOTE: The modules table uses a PostgreSQL enum type for the status column.
-- The CREATE TABLE below is for documentation purposes only.
-- The table was created manually in the Supabase dashboard.
-- Run only the RLS section below if the table already exists.

-- Ensure RLS is enabled and policies are correct for authenticated read access.

alter table public.modules enable row level security;

-- All authenticated users can read all modules (RLS handles access control).
drop policy if exists "Authenticated users can read active modules" on public.modules;
create policy "Authenticated users can read active modules"
  on public.modules
  for select
  to authenticated
  using (true);

-- Only authors can insert their own modules.
drop policy if exists "Authors can insert their own modules" on public.modules;
create policy "Authors can insert their own modules"
  on public.modules
  for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

-- Authors can update their own modules.
drop policy if exists "Authors can update their own modules" on public.modules;
create policy "Authors can update their own modules"
  on public.modules
  for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
