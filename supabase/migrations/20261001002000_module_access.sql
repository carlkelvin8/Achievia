begin;
-- Casting the enum to text works across deployments using either published
-- or active labels. Filter before pagination, not after downloading drafts.
drop policy if exists "Authenticated users can read active modules" on public.modules;
create policy "Authenticated users can read active modules" on public.modules
for select to authenticated using (
  lower(status::text) in ('published', 'active') or (
    user_id = (select auth.uid()) and exists (
      select 1 from public.profiles p where p.id = (select auth.uid())
      and p.role in ('ADMIN', 'TEACHER') and p.status = 'active')));
create policy "Unpublished modules are private" on public.modules
as restrictive for select to authenticated
using (lower(status::text) in ('published', 'active') or (
    user_id = (select auth.uid()) and exists (
      select 1 from public.profiles p where p.id = (select auth.uid())
      and p.role in ('ADMIN', 'TEACHER') and p.status = 'active')));
create policy "Only staff may insert modules" on public.modules
as restrictive for insert to authenticated with check (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.id = (select auth.uid())
    and p.role in ('ADMIN', 'TEACHER') and p.status = 'active'));
create policy "Only staff may update modules" on public.modules
as restrictive for update to authenticated using (
  user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.id = (select auth.uid())
    and p.role in ('ADMIN', 'TEACHER') and p.status = 'active'))
with check (user_id = (select auth.uid()) and exists (
    select 1 from public.profiles p where p.id = (select auth.uid())
    and p.role in ('ADMIN', 'TEACHER') and p.status = 'active'));
-- Keep the student-facing list published-only even for a signed-in author.
-- security_invoker retains underlying RLS rather than using the view owner.
create or replace view public.published_modules with (security_invoker = true)
as select * from public.modules
where lower(status::text) in ('published', 'active');
revoke all on public.published_modules from anon;
grant select on public.published_modules to authenticated;
notify pgrst, 'reload schema';
commit;
