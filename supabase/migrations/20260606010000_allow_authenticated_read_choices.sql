do $$
begin
  if to_regclass('public.choices') is not null then
    alter table public.choices enable row level security;

    drop policy if exists "Authenticated users can read choices" on public.choices;

    create policy "Authenticated users can read choices"
      on public.choices
      for select
      to authenticated
      using (true);
  end if;
end;
$$;
