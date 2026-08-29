-- Enable UUID extension (safe in Supabase)
create extension if not exists "pgcrypto";

-- =========================================
-- PROFILES TABLE (FIXED STRUCTURE)
-- =========================================
create table if not exists public.profiles (
  id uuid primary key default auth.uid(),
  full_name text,
  email text,
  avatar_url text,
  created_at timestamp with time zone default now()
);

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();
drop trigger if exists set_profiles_updated_at on public.profiles;
drop function if exists public.set_updated_at();
drop table if exists public.profiles cascade;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  first_name varchar(100),
  middle_name varchar(100),
  last_name varchar(255),
  bio text,
  age integer,
  trial integer,
  username varchar(100) unique,
  email varchar(255) unique,
  role varchar(50) not null default 'USER',
  status varchar(50) not null default 'active',
  profile_image varchar(255),
  course_id integer,
  university varchar(255),
  purpose varchar(255),
  date_of_examination timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_role_check check (role in ('USER', 'ADMIN', 'TEACHER')),
  constraint profiles_status_check check (status in ('active', 'inactive'))
);

-- =========================================
-- INDEX (optional but recommended)
-- =========================================
create index if not exists profiles_id_idx
on public.profiles(id);
create index profiles_course_id_idx on public.profiles(course_id);
create index profiles_username_idx on public.profiles(username);
create index profiles_email_idx on public.profiles(email);

-- =========================================
-- ROW LEVEL SECURITY
-- =========================================
alter table public.profiles enable row level security;

-- =========================================
-- RLS POLICIES
-- =========================================

-- SELECT own profile only
create policy "Users can read their own profile"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

-- INSERT own profile only
create policy "Users can insert their own profile"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

-- UPDATE own profile only
create policy "Users can update their own profile"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

-- DELETE own profile only
create policy "Users can delete their own profile"
on public.profiles
for delete
to authenticated
using (auth.uid() = id);

create function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_profiles_updated_at
  before update on public.profiles
  for each row
  execute function public.set_updated_at();

create function public.handle_new_user()
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
    date_of_examination = excluded.date_of_examination;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute function public.handle_new_user();
