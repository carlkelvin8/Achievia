# Chat Feature Design

## Goal

Build a real chat feature for Achievia that replaces the current mock messages list with persisted Supabase-backed conversations and live message delivery using Supabase Realtime Broadcast.

## Scope

The first implementation will support:

- Group conversations, used for community or batch rooms.
- Personal one-to-one conversations between two users.
- Conversation inbox filtering by all, group, and personal conversations.
- Chat thread view with message history, realtime incoming messages, and a composer for sending text messages.
- Durable message storage in Postgres so chats survive app restarts.
- Supabase Broadcast for low-latency message delivery while users are inside a thread.

The first implementation will not include attachments, typing indicators, reactions, message editing, read receipts, push notifications, moderation tools, or search across all message bodies. Those can be added after the core chat path is stable.

## Architecture

The implementation will follow the existing app layering:

- Data source: Supabase reads, writes, and realtime broadcast subscription management.
- Data models: JSON serialization for conversation and message rows.
- Domain entities: app-facing immutable chat objects.
- Repository interface and implementation: domain boundary for chat operations.
- Use case: thin application layer consumed by Riverpod providers.
- Riverpod provider: state management for inbox and active thread.
- Screens and widgets: Messages inbox, chat thread, message bubbles, and composer.

This keeps chat consistent with existing features such as profile, task, reviewer, progress, and auth.

## Database Design

The schema will add three tables:

`chat_conversations`

- `id uuid primary key default gen_random_uuid()`
- `type text not null check (type in ('group', 'direct'))`
- `title text`
- `created_by uuid references public.profiles(id) on delete set null`
- `created_at timestamptz not null default now()`
- `updated_at timestamptz not null default now()`
- `last_message_at timestamptz`

`chat_members`

- `conversation_id uuid references public.chat_conversations(id) on delete cascade`
- `profile_id uuid references public.profiles(id) on delete cascade`
- `role text not null default 'member' check (role in ('owner', 'member'))`
- `joined_at timestamptz not null default now()`
- `last_read_at timestamptz`
- primary key on `(conversation_id, profile_id)`

`chat_messages`

- `id uuid primary key default gen_random_uuid()`
- `conversation_id uuid references public.chat_conversations(id) on delete cascade`
- `sender_id uuid references public.profiles(id) on delete cascade`
- `body text not null check (length(trim(body)) > 0)`
- `created_at timestamptz not null default now()`

Indexes will support the actual query paths:

- `chat_members_profile_id_idx` on `chat_members(profile_id)`
- `chat_members_conversation_id_idx` on `chat_members(conversation_id)`
- `chat_messages_conversation_created_idx` on `chat_messages(conversation_id, created_at desc)`
- `chat_messages_sender_id_idx` on `chat_messages(sender_id)`
- `chat_conversations_last_message_at_idx` on `chat_conversations(last_message_at desc)`

## Security And RLS

All chat tables will have RLS enabled.

Access rules:

- A user can read a conversation only if they are a member.
- A user can read conversation members only for conversations they belong to.
- A user can read messages only for conversations they belong to.
- A user can insert messages only into conversations they belong to, and `sender_id` must match `auth.uid()`.
- A user can create a conversation as themselves.
- A user can add themselves as a member during conversation creation.

Policies will use `(select auth.uid())` to avoid per-row `auth.uid()` calls. Membership checks will be backed by indexes on `chat_members`.

## Supabase Broadcast Design

The active chat thread subscribes to one broadcast channel per conversation:

`chat:<conversation_id>`

When sending a message:

1. The app inserts the message row into `chat_messages`.
2. The data source updates `chat_conversations.last_message_at`.
3. The data source broadcasts a `message.created` event to `chat:<conversation_id>` with the saved message payload.
4. The local provider appends the sent message after the insert succeeds.
5. Other active clients append the message when the broadcast event arrives.

Postgres is the source of truth. Broadcast is only the live delivery path. On screen open or refresh, history is loaded from Postgres.

Duplicate handling will use message IDs. If a message is already present locally, the provider ignores the duplicate broadcast.

## Data Flow

Inbox load:

1. `MessagesScreen` watches the inbox provider.
2. Provider calls `ChatUseCase.watchConversations` or `getConversations`.
3. Use case calls repository.
4. Repository calls remote data source.
5. Data source queries conversations where the current profile is a member, including latest message summary.
6. UI renders all, group, and direct tabs from the same state.

Thread load:

1. Chat thread receives a conversation entity.
2. Provider fetches recent messages ordered ascending for display.
3. Provider subscribes to `chat:<conversation_id>`.
4. Broadcast events append messages while the thread is mounted.
5. Provider unsubscribes on dispose.

Send message:

1. User enters text and taps send.
2. Provider validates non-empty text.
3. Provider calls use case.
4. Data source inserts into Supabase and broadcasts the saved message.
5. Provider clears composer after success.
6. Errors are shown in the thread and composer remains intact.

## UI Design

`MessagesScreen` remains the inbox entry point.

It will show:

- Search field.
- Tabs: All, Groups, Personal Message.
- Conversation list rows with avatar, title, latest message preview, and time.
- Empty states for no conversations.
- Loading and error states.

The thread screen will show:

- App bar with conversation title.
- Scrollable message list.
- Right-aligned bubbles for current user messages.
- Left-aligned bubbles for other users.
- Message time below or inside compact bubble metadata.
- Composer pinned to the bottom with text input and send icon button.

The UI should remain work-focused and consistent with the existing app style. No landing page or marketing treatment.

## Error Handling

- If the user is unauthenticated, chat data source throws a clear authentication error.
- If conversation load fails, inbox shows a retry state.
- If message history load fails, thread shows a retry state.
- If message send fails, composer keeps the draft and shows an error.
- If broadcast subscription fails or disconnects, history remains usable because Postgres is the source of truth.

## Testing And Verification

The implementation plan will include:

- Model serialization tests for conversations and messages.
- Provider tests for append, duplicate suppression, and send failure behavior where feasible.
- SQL review with RLS policy checks and indexes.
- `dart analyze` for touched Dart files.
- A manual verification checklist for Supabase local/linked project:
  - user can see only member conversations
  - user can send only to member conversations
  - message persists after reload
  - broadcast delivers message to another active client
  - duplicate broadcast does not duplicate local sent message

## Open Decisions Resolved

- Chat supports both group and direct conversations.
- Supabase Broadcast is required for realtime delivery.
- Postgres remains the durable source of truth.
- Attachments, typing indicators, read receipts, and push notifications are out of scope for the first implementation.
