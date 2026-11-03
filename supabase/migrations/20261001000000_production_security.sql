-- Forward-only hardening. Apply in staging first; do not replay historical DDL
-- against an existing deployment.
begin;

-- RLS restricts rows, not columns. Signup owns creation; clients may edit only
-- presentation fields, never identity, role, status, or trial entitlements.
revoke insert, update, delete on public.profiles from anon, authenticated;
grant update (first_name, middle_name, last_name, bio, age, username,
  profile_image, university, purpose, mantra, date_of_examination)
  on public.profiles to authenticated;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, first_name, middle_name, last_name, bio,
    age, username, email, role, status, profile_image, course_id,
    university, purpose, mantra, date_of_examination)
  values (new.id, new.raw_user_meta_data ->> 'first_name',
    new.raw_user_meta_data ->> 'middle_name', new.raw_user_meta_data ->> 'last_name',
    new.raw_user_meta_data ->> 'bio',
    nullif(new.raw_user_meta_data ->> 'age', '')::integer,
    new.raw_user_meta_data ->> 'username', new.email, 'USER', 'active',
    new.raw_user_meta_data ->> 'profile_image',
    nullif(new.raw_user_meta_data ->> 'courseId', '')::integer,
    new.raw_user_meta_data ->> 'university', new.raw_user_meta_data ->> 'purpose',
    new.raw_user_meta_data ->> 'mantra',
    nullif(new.raw_user_meta_data ->> 'date_of_examination', '')::timestamptz);
  return new;
end;
$$;

-- Remove permissive legacy policies: permissive policies combine with OR.
do $$ declare p record; begin
  for p in select policyname from pg_policies
    where schemaname = 'public' and tablename = 'mockboards_paused'
  loop
    execute format('drop policy %I on public.mockboards_paused', p.policyname);
  end loop;
end $$;
alter table public.mockboards_paused enable row level security;
create policy "Owners manage paused exams" on public.mockboards_paused
for all to authenticated using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Direct conversations are created atomically by get_or_create_direct_chat.
-- Members must not add a third party to another member's private conversation,
-- promote themselves to owner, or forge the conversation's message preview.
revoke insert, update, delete on public.chat_members from anon, authenticated;
revoke insert, update, delete on public.chat_conversations from anon, authenticated;

create or replace function public.update_chat_preview()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  update public.chat_conversations
  set latest_message = new.body, last_message_at = new.created_at
  where id = new.conversation_id
    and (last_message_at is null or last_message_at <= new.created_at);
  return new;
end;
$$;
drop trigger if exists update_chat_preview on public.chat_messages;
create trigger update_chat_preview after insert on public.chat_messages
for each row execute function public.update_chat_preview();

-- A supplied timestamp must not reorder messages or pin a forged preview.
create or replace function public.stamp_chat_message()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.created_at := clock_timestamp();
  return new;
end;
$$;
drop trigger if exists stamp_chat_message on public.chat_messages;
create trigger stamp_chat_message before insert on public.chat_messages
for each row execute function public.stamp_chat_message();
alter table public.chat_messages add constraint chat_message_body_limit
  check (char_length(body) <= 10000) not valid;

-- Database changes are filtered by chat_messages RLS; no client broadcasts
-- containing message text are trusted or sent by the updated application.
do $$ begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
    and not exists (select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public'
        and tablename = 'chat_messages') then
    alter publication supabase_realtime add table public.chat_messages;
  end if;
end $$;

-- Typing events use a private channel and reveal no message contents.
do $$ begin
  if to_regclass('realtime.messages') is not null then
    execute $policy$create policy "Chat members receive typing" on realtime.messages
      for select to authenticated using (
        extension = 'broadcast' and exists (
          select 1 from public.chat_members cm
          where cm.profile_id = (select auth.uid())
          and 'chat-typing:' || cm.conversation_id::text = realtime.topic()
        ))$policy$;
    execute $policy$create policy "Chat members send typing" on realtime.messages
      for insert to authenticated with check (
        extension = 'broadcast' and exists (
          select 1 from public.chat_members cm
          where cm.profile_id = (select auth.uid())
          and 'chat-typing:' || cm.conversation_id::text = realtime.topic()
        ))$policy$;
  end if;
end $$;
notify pgrst, 'reload schema';
commit;
