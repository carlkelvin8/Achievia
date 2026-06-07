create extension if not exists "pg_trgm";

create index if not exists profiles_username_trgm_idx
  on public.profiles using gin (lower(coalesce(username, '')) gin_trgm_ops);

create index if not exists profiles_email_trgm_idx
  on public.profiles using gin (lower(coalesce(email, '')) gin_trgm_ops);

create index if not exists profiles_first_name_trgm_idx
  on public.profiles using gin (lower(coalesce(first_name, '')) gin_trgm_ops);

create index if not exists profiles_last_name_trgm_idx
  on public.profiles using gin (lower(coalesce(last_name, '')) gin_trgm_ops);

create or replace function public.search_profiles_for_chat(
  search_query text,
  result_limit integer default 20
)
returns table (
  id uuid,
  first_name varchar,
  last_name varchar,
  username varchar,
  email varchar,
  profile_image varchar
)
language sql
security definer
set search_path = public
as $$
  select
    p.id,
    p.first_name,
    p.last_name,
    p.username,
    p.email,
    p.profile_image
  from public.profiles p
  where (select auth.uid()) is not null
    and p.id <> (select auth.uid())
    and length(trim(search_query)) >= 2
    and (
      lower(coalesce(p.username, '')) like '%' || lower(trim(search_query)) || '%'
      or lower(coalesce(p.email, '')) like '%' || lower(trim(search_query)) || '%'
      or lower(coalesce(p.first_name, '')) like '%' || lower(trim(search_query)) || '%'
      or lower(coalesce(p.last_name, '')) like '%' || lower(trim(search_query)) || '%'
    )
  order by
    case
      when lower(coalesce(p.username, '')) = lower(trim(search_query)) then 0
      when lower(coalesce(p.email, '')) = lower(trim(search_query)) then 1
      when lower(coalesce(p.username, '')) like lower(trim(search_query)) || '%' then 2
      when lower(coalesce(p.first_name, '')) like lower(trim(search_query)) || '%' then 3
      else 4
    end,
    p.first_name nulls last,
    p.last_name nulls last,
    p.username nulls last
  limit least(greatest(coalesce(result_limit, 20), 1), 30);
$$;

revoke all on function public.search_profiles_for_chat(text, integer) from public;
grant execute on function public.search_profiles_for_chat(text, integer) to authenticated;

create or replace function public.chat_profile_summaries(profile_ids uuid[])
returns table (
  id uuid,
  first_name varchar,
  last_name varchar,
  username varchar,
  email varchar,
  profile_image varchar
)
language sql
security definer
set search_path = public
as $$
  select
    p.id,
    p.first_name,
    p.last_name,
    p.username,
    p.email,
    p.profile_image
  from public.profiles p
  where (select auth.uid()) is not null
    and p.id = any(profile_ids)
  limit 50;
$$;

revoke all on function public.chat_profile_summaries(uuid[]) from public;
grant execute on function public.chat_profile_summaries(uuid[]) to authenticated;

drop function if exists public.get_or_create_direct_chat(uuid);

create or replace function public.get_or_create_direct_chat(target_profile_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  current_profile_id uuid := (select auth.uid());
  existing_conversation_id uuid;
  new_conversation_id uuid;
  conversation_row public.chat_conversations%rowtype;
  target_title text;
begin
  if current_profile_id is null then
    raise exception 'User is not authenticated';
  end if;

  if target_profile_id is null or target_profile_id = current_profile_id then
    raise exception 'Target profile is invalid';
  end if;

  if not exists (select 1 from public.profiles p where p.id = target_profile_id) then
    raise exception 'Target profile was not found';
  end if;

  perform pg_advisory_xact_lock(
    hashtext(
      least(current_profile_id::text, target_profile_id::text)
      || ':'
      || greatest(current_profile_id::text, target_profile_id::text)
    )
  );

  select cc.id
  into existing_conversation_id
  from public.chat_conversations cc
  join public.chat_members current_member
    on current_member.conversation_id = cc.id
    and current_member.profile_id = current_profile_id
  join public.chat_members target_member
    on target_member.conversation_id = cc.id
    and target_member.profile_id = target_profile_id
  where cc.type = 'direct'
  limit 1;

  if existing_conversation_id is null then
    insert into public.chat_conversations (type, title, created_by)
    values ('direct', null, current_profile_id)
    returning chat_conversations.id into new_conversation_id;

    insert into public.chat_members (conversation_id, profile_id, role)
    values
      (new_conversation_id, current_profile_id, 'owner'),
      (new_conversation_id, target_profile_id, 'member')
    on conflict (conversation_id, profile_id) do nothing;

    existing_conversation_id := new_conversation_id;
  end if;

  select *
  into conversation_row
  from public.chat_conversations
  where id = existing_conversation_id;

  select coalesce(
    nullif(conversation_row.title, ''),
    nullif(trim(concat_ws(' ', p.first_name, p.last_name)), ''),
    nullif(p.username, ''),
    p.email,
    'Direct message'
  )
  into target_title
  from public.profiles p
  where p.id = target_profile_id;

  return jsonb_build_object(
    'id', conversation_row.id,
    'type', conversation_row.type,
    'title', target_title,
    'created_by', conversation_row.created_by,
    'created_at', conversation_row.created_at,
    'updated_at', conversation_row.updated_at,
    'last_message_at', conversation_row.last_message_at,
    'latest_message', conversation_row.latest_message
  );
end;
$$;

revoke all on function public.get_or_create_direct_chat(uuid) from public;
grant execute on function public.get_or_create_direct_chat(uuid) to authenticated;
