alter table public.modules
  alter column user_id type uuid
  using user_id::text::uuid;
