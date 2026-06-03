create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles
  add column if not exists first_name varchar(100),
  add column if not exists middle_name varchar(100),
  add column if not exists last_name varchar(255),
  add column if not exists bio text,
  add column if not exists age integer,
  add column if not exists trial integer,
  add column if not exists username varchar(100),
  add column if not exists email varchar(255),
  add column if not exists role varchar(50) not null default 'USER',
  add column if not exists status varchar(50) not null default 'active',
  add column if not exists profile_image varchar(255),
  add column if not exists course_id integer,
  add column if not exists university varchar(255),
  add column if not exists purpose varchar(255),
  add column if not exists mantra text,
  add column if not exists date_of_examination timestamptz,
  add column if not exists updated_at timestamptz not null default now();

update public.profiles
set
  role = coalesce(nullif(role, ''), 'USER'),
  status = coalesce(nullif(status, ''), 'active'),
  updated_at = coalesce(updated_at, now());

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_username_key'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles add constraint profiles_username_key unique (username);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_email_key'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles add constraint profiles_email_key unique (email);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_role_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_role_check
      check (role in ('USER', 'ADMIN', 'TEACHER'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_status_check'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_status_check
      check (status in ('active', 'inactive'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_id_fkey'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_id_fkey
      foreign key (id)
      references auth.users(id)
      on delete cascade;
  end if;
end;
$$;

create index if not exists profiles_course_id_idx on public.profiles(course_id);
create index if not exists profiles_username_idx on public.profiles(username);
create index if not exists profiles_email_idx on public.profiles(email);

alter table public.profiles enable row level security;

drop policy if exists "Users can read their own profile" on public.profiles;
drop policy if exists "Users can insert their own profile" on public.profiles;
drop policy if exists "Users can update their own profile" on public.profiles;
drop policy if exists "Users can delete their own profile" on public.profiles;

create policy "Users can read their own profile"
  on public.profiles
  for select
  to authenticated
  using ((select auth.uid()) = id);

create policy "Users can insert their own profile"
  on public.profiles
  for insert
  to authenticated
  with check ((select auth.uid()) = id);

create policy "Users can update their own profile"
  on public.profiles
  for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create policy "Users can delete their own profile"
  on public.profiles
  for delete
  to authenticated
  using ((select auth.uid()) = id);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    first_name,
    middle_name,
    last_name,
    bio,
    age,
    trial,
    username,
    email,
    role,
    status,
    profile_image,
    course_id,
    university,
    purpose,
    mantra,
    date_of_examination
  )
  values (
    new.id,
    new.raw_user_meta_data ->> 'first_name',
    new.raw_user_meta_data ->> 'middle_name',
    new.raw_user_meta_data ->> 'last_name',
    new.raw_user_meta_data ->> 'bio',
    nullif(new.raw_user_meta_data ->> 'age', '')::integer,
    nullif(new.raw_user_meta_data ->> 'trial', '')::integer,
    new.raw_user_meta_data ->> 'username',
    new.email,
    coalesce(nullif(new.raw_user_meta_data ->> 'role', ''), 'USER'),
    coalesce(nullif(new.raw_user_meta_data ->> 'status', ''), 'active'),
    new.raw_user_meta_data ->> 'profile_image',
    nullif(new.raw_user_meta_data ->> 'courseId', '')::integer,
    new.raw_user_meta_data ->> 'university',
    new.raw_user_meta_data ->> 'purpose',
    new.raw_user_meta_data ->> 'mantra',
    nullif(new.raw_user_meta_data ->> 'date_of_examination', '')::timestamptz
  )
  on conflict (id) do update set
    first_name = excluded.first_name,
    middle_name = excluded.middle_name,
    last_name = excluded.last_name,
    bio = excluded.bio,
    age = excluded.age,
    trial = excluded.trial,
    username = excluded.username,
    email = excluded.email,
    role = excluded.role,
    status = excluded.status,
    profile_image = excluded.profile_image,
    course_id = excluded.course_id,
    university = excluded.university,
    purpose = excluded.purpose,
    mantra = excluded.mantra,
    date_of_examination = excluded.date_of_examination;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
