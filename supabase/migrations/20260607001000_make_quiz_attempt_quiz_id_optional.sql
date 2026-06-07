do $$
declare
  quiz_id_fk_name text;
begin
  if exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'quiz_attempts'
      and column_name = 'quiz_id'
  ) then
    for quiz_id_fk_name in
      select constraint_record.conname
      from pg_constraint constraint_record
      join pg_class table_record
        on table_record.oid = constraint_record.conrelid
      join pg_namespace schema_record
        on schema_record.oid = table_record.relnamespace
      join unnest(constraint_record.conkey) as constrained_column(attnum)
        on true
      join pg_attribute attribute_record
        on attribute_record.attrelid = table_record.oid
       and attribute_record.attnum = constrained_column.attnum
      where schema_record.nspname = 'public'
        and table_record.relname = 'quiz_attempts'
        and constraint_record.contype = 'f'
        and attribute_record.attname = 'quiz_id'
    loop
      execute format(
        'alter table public.quiz_attempts drop constraint if exists %I',
        quiz_id_fk_name
      );
    end loop;

    alter table public.quiz_attempts
      alter column quiz_id drop not null;
  end if;
end;
$$;
