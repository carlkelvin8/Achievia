-- Read-only metadata export; run with a catalog-readable role. Contains no
-- user rows or credentials. Save outputs securely with the schema-only dump.
begin transaction read only;
select version();
select table_name, column_name, udt_schema, udt_name, is_nullable,
  column_default, is_identity, identity_generation
from information_schema.columns where table_schema='public'
order by table_name, ordinal_position;
select c.relname, c.relrowsecurity, c.relforcerowsecurity
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind in ('r','p') order by c.relname;
select conrelid::regclass as relation, conname, contype, convalidated,
  pg_get_constraintdef(oid) as definition
from pg_constraint where connamespace='public'::regnamespace order by 1,2;
select schemaname, tablename, indexname, indexdef from pg_indexes
where schemaname='public' order by tablename,indexname;
select n.nspname, t.typname, e.enumlabel, e.enumsortorder
from pg_type t join pg_enum e on e.enumtypid=t.oid
join pg_namespace n on n.oid=t.typnamespace order by 1,2,4;
select * from pg_policies where schemaname in ('public','realtime') order by schemaname,tablename,policyname;
select table_name, grantee, privilege_type from information_schema.table_privileges
where table_schema='public' order by 1,2,3;
select table_name, column_name, grantee, privilege_type from information_schema.column_privileges
where table_schema='public' order by 1,2,3,4;
select p.oid::regprocedure as signature, pg_get_function_result(p.oid) as result,
  p.prosecdef, p.proconfig, p.proacl, pg_get_functiondef(p.oid) as definition
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.prokind in ('f','p') order by 1;
select c.oid::regclass as view, c.reloptions, pg_get_viewdef(c.oid) as definition
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind in ('v','m');
select tgrelid::regclass as relation, tgname, pg_get_triggerdef(oid)
from pg_trigger where not tgisinternal and tgrelid in
  (select oid from pg_class where relnamespace in ('public'::regnamespace,'auth'::regnamespace));
select * from pg_publication_tables where schemaname='public';
-- Ledger is deliberately separate: its presence is not proof DDL matches.
select to_regclass('supabase_migrations.schema_migrations') as migration_ledger;
-- If present, also export: SELECT * FROM supabase_migrations.schema_migrations ORDER BY version;
commit;
