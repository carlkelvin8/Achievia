create extension if not exists "pgcrypto";

create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('group', 'direct')),
  title text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_message_at timestamptz,
  latest_message text
);

create table if not exists public.chat_members (
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  profile_id uuid not null references public.profiles(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  last_read_at timestamptz,
  primary key (conversation_id, profile_id)
);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.chat_conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (length(trim(body)) > 0),
  created_at timestamptz not null default now()
);

create index if not exists chat_members_profile_id_idx
  on public.chat_members(profile_id);

create index if not exists chat_messages_conversation_created_idx
  on public.chat_messages(conversation_id, created_at desc);

create index if not exists chat_messages_sender_id_idx
  on public.chat_messages(sender_id);

create index if not exists chat_conversations_last_message_at_idx
  on public.chat_conversations(last_message_at desc);

create or replace function public.set_chat_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_chat_conversations_updated_at on public.chat_conversations;
create trigger set_chat_conversations_updated_at
  before update on public.chat_conversations
  for each row
  execute function public.set_chat_updated_at();

alter table public.chat_conversations enable row level security;
alter table public.chat_members enable row level security;
alter table public.chat_messages enable row level security;

create or replace function public.is_chat_member(target_conversation_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.chat_members cm
    where cm.conversation_id = target_conversation_id
      and cm.profile_id = (select auth.uid())
  );
$$;

drop policy if exists "Members can read conversations" on public.chat_conversations;
drop policy if exists "Users can create conversations" on public.chat_conversations;
drop policy if exists "Members can update conversations" on public.chat_conversations;
drop policy if exists "Members can read chat members" on public.chat_members;
drop policy if exists "Users can add themselves as members" on public.chat_members;
drop policy if exists "Creators can add themselves as members" on public.chat_members;
drop policy if exists "Members can add chat members" on public.chat_members;
drop policy if exists "Members can read messages" on public.chat_messages;
drop policy if exists "Members can send messages" on public.chat_messages;

create policy "Members can read conversations"
  on public.chat_conversations
  for select
  to authenticated
  using ((select public.is_chat_member(id)));

create policy "Users can create conversations"
  on public.chat_conversations
  for insert
  to authenticated
  with check (created_by = (select auth.uid()));

create policy "Members can update conversations"
  on public.chat_conversations
  for update
  to authenticated
  using ((select public.is_chat_member(id)))
  with check ((select public.is_chat_member(id)));

create policy "Members can read chat members"
  on public.chat_members
  for select
  to authenticated
  using ((select public.is_chat_member(conversation_id)));

create policy "Creators can add themselves as members"
  on public.chat_members
  for insert
  to authenticated
  with check (
    profile_id = (select auth.uid())
    and exists (
      select 1
      from public.chat_conversations cc
      where cc.id = conversation_id
        and cc.created_by = (select auth.uid())
    )
  );

create policy "Members can add chat members"
  on public.chat_members
  for insert
  to authenticated
  with check ((select public.is_chat_member(conversation_id)));

create policy "Members can read messages"
  on public.chat_messages
  for select
  to authenticated
  using ((select public.is_chat_member(conversation_id)));

create policy "Members can send messages"
  on public.chat_messages
  for insert
  to authenticated
  with check (
    sender_id = (select auth.uid())
    and (select public.is_chat_member(conversation_id))
  );
