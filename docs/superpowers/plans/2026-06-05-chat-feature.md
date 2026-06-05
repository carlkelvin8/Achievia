# Chat Feature Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the mock Messages tab with persisted Supabase chat using Postgres for history and Supabase Realtime Broadcast for live delivery.

**Architecture:** Follow the existing Achievia layers: Supabase migration, data source, DTOs, domain entities, repository, use case, Riverpod providers, and presentation widgets/screens. Postgres is the source of truth; Broadcast is only the realtime delivery path for active thread screens.

**Tech Stack:** Flutter, Riverpod 3, injectable/get_it, Supabase Flutter, Supabase Postgres RLS, Supabase Realtime Broadcast, GoRouter.

---

## File Structure

- Create `supabase/migrations/20260605000000_add_chat_tables.sql`: chat tables, indexes, triggers, and RLS policies.
- Create `lib/domain/entities/api/chat/chat_conversation_entity.dart`: app-facing conversation object.
- Create `lib/domain/entities/api/chat/chat_message_entity.dart`: app-facing message object.
- Create `lib/data/models/chat/chat_conversation_dto.dart`: Supabase row mapping for conversations.
- Create `lib/data/models/chat/chat_message_dto.dart`: Supabase row mapping for messages.
- Create `lib/data/data_source/chat/chat_remote_datasource.dart`: Supabase queries, inserts, and Broadcast subscription/send.
- Create `lib/domain/repository/chat/chat_repository.dart`: chat repository contract.
- Create `lib/data/repositoryImpl/chat/chat_repository_impl.dart`: repository implementation.
- Create `lib/domain/use_cases/chat/chat_use_case.dart`: thin application layer.
- Create `lib/presentation/provider/chat/chat_provider.dart`: inbox and thread state.
- Create `lib/presentation/screens/main/chat_thread_screen.dart`: active conversation route.
- Modify `lib/presentation/screens/main/messages_screen.dart`: replace mock list with provider-backed inbox.
- Modify `lib/presentation/widgets/list_items/message_list_item.dart`: accept typed conversations and navigate to thread.
- Create `lib/presentation/widgets/chat/chat_bubble.dart`: message bubble.
- Create `lib/presentation/widgets/chat/chat_composer.dart`: bottom message composer.
- Modify `lib/core/constants/routers/route_constants.dart`: add thread route.
- Modify `lib/core/constants/routers/app_router.dart`: add thread route builder.
- Modify `lib/core/di/injection.config.dart`: regenerate with build_runner after adding injectable classes.
- Create tests under `test/data/models/chat/` and `test/presentation/provider/chat/`.

---

### Task 1: Add Chat Database Schema

**Files:**
- Create: `supabase/migrations/20260605000000_add_chat_tables.sql`

- [ ] **Step 1: Create migration**

Add:

```sql
create extension if not exists "pgcrypto";

create table if not exists public.chat_conversations (
  id uuid primary key default gen_random_uuid(),
  type text not null check (type in ('group', 'direct')),
  title text,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_message_at timestamptz
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

create index if not exists chat_members_conversation_id_idx
  on public.chat_members(conversation_id);

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
```

- [ ] **Step 2: Add membership helper function**

Append:

```sql
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
```

- [ ] **Step 3: Add RLS policies**

Append:

```sql
drop policy if exists "Members can read conversations" on public.chat_conversations;
drop policy if exists "Users can create conversations" on public.chat_conversations;
drop policy if exists "Members can update conversations" on public.chat_conversations;
drop policy if exists "Members can read chat members" on public.chat_members;
drop policy if exists "Users can add themselves as members" on public.chat_members;
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

create policy "Users can add themselves as members"
  on public.chat_members
  for insert
  to authenticated
  with check (profile_id = (select auth.uid()));

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
```

- [ ] **Step 4: Review migration**

Run:

```powershell
Get-Content -Path supabase/migrations/20260605000000_add_chat_tables.sql
```

Expected: the migration contains the three tables, five indexes, helper function, and policies above.

---

### Task 2: Add Domain Entities And DTOs

**Files:**
- Create: `lib/domain/entities/api/chat/chat_conversation_entity.dart`
- Create: `lib/domain/entities/api/chat/chat_message_entity.dart`
- Create: `lib/data/models/chat/chat_conversation_dto.dart`
- Create: `lib/data/models/chat/chat_message_dto.dart`
- Test: `test/data/models/chat/chat_dto_test.dart`

- [ ] **Step 1: Write DTO tests**

Create `test/data/models/chat/chat_dto_test.dart`:

```dart
import 'package:achievia/data/models/chat/chat_conversation_dto.dart';
import 'package:achievia/data/models/chat/chat_message_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps chat conversation row to entity', () {
    final dto = ChatConversationDto.fromJson({
      'id': 'conversation-1',
      'type': 'group',
      'title': 'Achievian RMT',
      'created_by': 'user-1',
      'created_at': '2026-06-05T01:00:00.000Z',
      'updated_at': '2026-06-05T01:05:00.000Z',
      'last_message_at': '2026-06-05T01:06:00.000Z',
      'latest_message': 'Hello',
    });

    final entity = dto.toEntity();

    expect(entity.id, 'conversation-1');
    expect(entity.type, ChatConversationType.group);
    expect(entity.title, 'Achievian RMT');
    expect(entity.latestMessage, 'Hello');
  });

  test('maps chat message row to entity', () {
    final dto = ChatMessageDto.fromJson({
      'id': 'message-1',
      'conversation_id': 'conversation-1',
      'sender_id': 'user-1',
      'body': 'Hello',
      'created_at': '2026-06-05T01:00:00.000Z',
    });

    final entity = dto.toEntity();

    expect(entity.id, 'message-1');
    expect(entity.conversationId, 'conversation-1');
    expect(entity.senderId, 'user-1');
    expect(entity.body, 'Hello');
  });
}
```

- [ ] **Step 2: Run tests and verify failure**

Run:

```powershell
flutter test test/data/models/chat/chat_dto_test.dart
```

Expected: fails because chat DTO/entity files do not exist.

- [ ] **Step 3: Add entities**

Create `lib/domain/entities/api/chat/chat_conversation_entity.dart`:

```dart
enum ChatConversationType { group, direct }

class ChatConversationEntity {
  final String id;
  final ChatConversationType type;
  final String title;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? latestMessage;

  const ChatConversationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.lastMessageAt,
    this.latestMessage,
  });
}
```

Create `lib/domain/entities/api/chat/chat_message_entity.dart`:

```dart
class ChatMessageEntity {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  const ChatMessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });
}
```

- [ ] **Step 4: Add DTOs**

Create `lib/data/models/chat/chat_conversation_dto.dart`:

```dart
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';

class ChatConversationDto {
  final String id;
  final String type;
  final String? title;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final String? latestMessage;

  const ChatConversationDto({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.createdBy,
    this.lastMessageAt,
    this.latestMessage,
  });

  factory ChatConversationDto.fromJson(Map<String, dynamic> json) {
    return ChatConversationDto(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      latestMessage: json['latest_message'] as String?,
    );
  }

  ChatConversationEntity toEntity() {
    return ChatConversationEntity(
      id: id,
      type: type == 'direct'
          ? ChatConversationType.direct
          : ChatConversationType.group,
      title: title?.trim().isNotEmpty == true ? title! : 'Conversation',
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastMessageAt: lastMessageAt,
      latestMessage: latestMessage,
    );
  }
}
```

Create `lib/data/models/chat/chat_message_dto.dart`:

```dart
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';

class ChatMessageDto {
  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  const ChatMessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  factory ChatMessageDto.fromJson(Map<String, dynamic> json) {
    return ChatMessageDto(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'body': body,
    };
  }

  ChatMessageEntity toEntity() {
    return ChatMessageEntity(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      body: body,
      createdAt: createdAt,
    );
  }
}
```

- [ ] **Step 5: Run tests**

Run:

```powershell
flutter test test/data/models/chat/chat_dto_test.dart
```

Expected: tests pass.

---

### Task 3: Add Data Source, Repository, And Use Case

**Files:**
- Create: `lib/data/data_source/chat/chat_remote_datasource.dart`
- Create: `lib/domain/repository/chat/chat_repository.dart`
- Create: `lib/data/repositoryImpl/chat/chat_repository_impl.dart`
- Create: `lib/domain/use_cases/chat/chat_use_case.dart`

- [ ] **Step 1: Add repository contract**

Create `lib/domain/repository/chat/chat_repository.dart`:

```dart
import 'dart:async';

import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';

abstract class ChatRepository {
  Future<List<ChatConversationEntity>> getConversations();
  Future<List<ChatMessageEntity>> getMessages(String conversationId);
  Future<ChatMessageEntity> sendMessage(String conversationId, String body);
  Stream<ChatMessageEntity> subscribeToMessages(String conversationId);
}
```

- [ ] **Step 2: Add Supabase data source**

Create `lib/data/data_source/chat/chat_remote_datasource.dart`:

```dart
import 'dart:async';

import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/chat/chat_conversation_dto.dart';
import 'package:achievia/data/models/chat/chat_message_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatDataSource {
  Future<List<ChatConversationDto>> getConversations();
  Future<List<ChatMessageDto>> getMessages(String conversationId);
  Future<ChatMessageDto> sendMessage(String conversationId, String body);
  Stream<ChatMessageDto> subscribeToMessages(String conversationId);
}

@lazySingleton
@injectable
class ChatRemoteDatasource implements ChatDataSource {
  final SupabaseUserContext userContext;

  ChatRemoteDatasource({this.userContext = const SupabaseUserContext()});

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<List<ChatConversationDto>> getConversations() async {
    final userId = await userContext.currentUserId();
    final memberships = await _supabase
        .from('chat_members')
        .select('conversation_id')
        .eq('profile_id', userId);

    final conversationIds = memberships
        .map((row) => row['conversation_id'] as String)
        .toList();

    if (conversationIds.isEmpty) {
      return [];
    }

    final conversations = await _supabase
        .from('chat_conversations')
        .select('id, type, title, created_by, created_at, updated_at, last_message_at')
        .inFilter('id', conversationIds)
        .order('last_message_at', ascending: false, nullsFirst: false);

    final latestMessages = await _latestMessagesFor(conversationIds);

    return conversations.map((row) {
      final json = Map<String, dynamic>.from(row);
      json['latest_message'] = latestMessages[json['id']];
      return ChatConversationDto.fromJson(json);
    }).toList();
  }

  Future<Map<String, String>> _latestMessagesFor(List<String> conversationIds) async {
    final rows = await _supabase
        .from('chat_messages')
        .select('conversation_id, body, created_at')
        .inFilter('conversation_id', conversationIds)
        .order('created_at', ascending: false);

    final latest = <String, String>{};
    for (final row in rows) {
      final conversationId = row['conversation_id'] as String;
      latest.putIfAbsent(conversationId, () => row['body'] as String);
    }
    return latest;
  }

  @override
  Future<List<ChatMessageDto>> getMessages(String conversationId) async {
    final rows = await _supabase
        .from('chat_messages')
        .select('id, conversation_id, sender_id, body, created_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(100);

    return rows
        .map((row) => ChatMessageDto.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<ChatMessageDto> sendMessage(String conversationId, String body) async {
    final senderId = await userContext.currentUserId();
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw Exception('Message cannot be empty');
    }

    final row = await _supabase
        .from('chat_messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'body': trimmed,
        })
        .select('id, conversation_id, sender_id, body, created_at')
        .single();

    await _supabase
        .from('chat_conversations')
        .update({'last_message_at': row['created_at']})
        .eq('id', conversationId);

    final dto = ChatMessageDto.fromJson(Map<String, dynamic>.from(row));
    await _supabase.channel('chat:$conversationId').sendBroadcastMessage(
      event: 'message.created',
      payload: {
        'id': dto.id,
        'conversation_id': dto.conversationId,
        'sender_id': dto.senderId,
        'body': dto.body,
        'created_at': dto.createdAt.toUtc().toIso8601String(),
      },
    );
    return dto;
  }

  @override
  Stream<ChatMessageDto> subscribeToMessages(String conversationId) {
    final controller = StreamController<ChatMessageDto>();
    final channel = _supabase.channel('chat:$conversationId');

    channel.onBroadcast(event: 'message.created', callback: (payload) {
      controller.add(ChatMessageDto.fromJson(Map<String, dynamic>.from(payload)));
    }).subscribe();

    controller.onCancel = () async {
      await _supabase.removeChannel(channel);
    };

    return controller.stream;
  }
}
```

- [ ] **Step 3: Add repository implementation**

Create `lib/data/repositoryImpl/chat/chat_repository_impl.dart`:

```dart
import 'dart:async';

import 'package:achievia/data/data_source/chat/chat_remote_datasource.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:achievia/domain/repository/chat/chat_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
@lazySingleton
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource datasource;

  ChatRepositoryImpl({required this.datasource});

  @override
  Future<List<ChatConversationEntity>> getConversations() async {
    final rows = await datasource.getConversations();
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<List<ChatMessageEntity>> getMessages(String conversationId) async {
    final rows = await datasource.getMessages(conversationId);
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<ChatMessageEntity> sendMessage(String conversationId, String body) async {
    final row = await datasource.sendMessage(conversationId, body);
    return row.toEntity();
  }

  @override
  Stream<ChatMessageEntity> subscribeToMessages(String conversationId) {
    return datasource
        .subscribeToMessages(conversationId)
        .map((row) => row.toEntity());
  }
}
```

- [ ] **Step 4: Add use case**

Create `lib/domain/use_cases/chat/chat_use_case.dart`:

```dart
import 'dart:async';

import 'package:achievia/data/repositoryImpl/chat/chat_repository_impl.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:injectable/injectable.dart';

@injectable
class ChatUseCase {
  final ChatRepositoryImpl impl;

  ChatUseCase({required this.impl});

  Future<List<ChatConversationEntity>> getConversations() {
    return impl.getConversations();
  }

  Future<List<ChatMessageEntity>> getMessages(String conversationId) {
    return impl.getMessages(conversationId);
  }

  Future<ChatMessageEntity> sendMessage(String conversationId, String body) {
    return impl.sendMessage(conversationId, body);
  }

  Stream<ChatMessageEntity> subscribeToMessages(String conversationId) {
    return impl.subscribeToMessages(conversationId);
  }
}
```

- [ ] **Step 5: Regenerate DI**

Run:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

Expected: `lib/core/di/injection.config.dart` includes `ChatRemoteDatasource`, `ChatRepositoryImpl`, and `ChatUseCase`.

---

### Task 4: Add Chat Providers

**Files:**
- Create: `lib/presentation/provider/chat/chat_provider.dart`
- Test: `test/presentation/provider/chat/chat_thread_state_test.dart`

- [ ] **Step 1: Write state unit test**

Create `test/presentation/provider/chat/chat_thread_state_test.dart`:

```dart
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('appendMessage ignores duplicate message ids', () {
    final state = ChatThreadState(
      messages: [
        ChatMessageEntity(
          id: 'm1',
          conversationId: 'c1',
          senderId: 'u1',
          body: 'Hello',
          createdAt: DateTime.utc(2026, 6, 5),
        ),
      ],
    );

    final next = state.appendMessage(
      ChatMessageEntity(
        id: 'm1',
        conversationId: 'c1',
        senderId: 'u1',
        body: 'Hello',
        createdAt: DateTime.utc(2026, 6, 5),
      ),
    );

    expect(next.messages, hasLength(1));
  });
}
```

- [ ] **Step 2: Run test and verify failure**

Run:

```powershell
flutter test test/presentation/provider/chat/chat_thread_state_test.dart
```

Expected: fails because `chat_provider.dart` does not exist.

- [ ] **Step 3: Add provider**

Create `lib/presentation/provider/chat/chat_provider.dart`:

```dart
import 'dart:async';

import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:achievia/domain/use_cases/chat/chat_use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatUseCaseProvider = Provider<ChatUseCase>((ref) => sl<ChatUseCase>());

final chatConversationsProvider =
    FutureProvider<List<ChatConversationEntity>>((ref) {
  return ref.read(chatUseCaseProvider).getConversations();
});

class ChatThreadState {
  final bool isLoading;
  final bool isSending;
  final String? errorMessage;
  final List<ChatMessageEntity> messages;

  const ChatThreadState({
    this.isLoading = false,
    this.isSending = false,
    this.errorMessage,
    this.messages = const [],
  });

  ChatThreadState copyWith({
    bool? isLoading,
    bool? isSending,
    String? errorMessage,
    List<ChatMessageEntity>? messages,
  }) {
    return ChatThreadState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      messages: messages ?? this.messages,
    );
  }

  ChatThreadState appendMessage(ChatMessageEntity message) {
    if (messages.any((item) => item.id == message.id)) {
      return this;
    }

    final nextMessages = [...messages, message]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return copyWith(messages: nextMessages, errorMessage: null);
  }
}

final chatThreadProvider = NotifierProvider.autoDispose
    .family<ChatThreadNotifier, ChatThreadState, String>(
  ChatThreadNotifier.new,
);

class ChatThreadNotifier extends AutoDisposeFamilyNotifier<ChatThreadState, String> {
  late final TextEditingController composerController;
  StreamSubscription<ChatMessageEntity>? _subscription;

  @override
  ChatThreadState build(String arg) {
    composerController = TextEditingController();
    ref.onDispose(() {
      composerController.dispose();
      _subscription?.cancel();
    });

    Future.microtask(load);
    _subscribe();
    return const ChatThreadState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await AsyncValue.guard(
      () => ref.read(chatUseCaseProvider).getMessages(arg),
    );

    result.when(
      data: (messages) {
        state = state.copyWith(isLoading: false, messages: messages);
      },
      error: (error, _) {
        state = state.copyWith(isLoading: false, errorMessage: error.toString());
      },
      loading: () {},
    );
  }

  void _subscribe() {
    _subscription = ref
        .read(chatUseCaseProvider)
        .subscribeToMessages(arg)
        .listen((message) {
      state = state.appendMessage(message);
      ref.invalidate(chatConversationsProvider);
    });
  }

  Future<void> send() async {
    final body = composerController.text.trim();
    if (body.isEmpty) return;

    state = state.copyWith(isSending: true, errorMessage: null);
    final result = await AsyncValue.guard(
      () => ref.read(chatUseCaseProvider).sendMessage(arg, body),
    );

    result.when(
      data: (message) {
        composerController.clear();
        state = state.appendMessage(message).copyWith(isSending: false);
        ref.invalidate(chatConversationsProvider);
      },
      error: (error, _) {
        state = state.copyWith(isSending: false, errorMessage: error.toString());
      },
      loading: () {},
    );
  }
}
```

- [ ] **Step 4: Run provider test**

Run:

```powershell
flutter test test/presentation/provider/chat/chat_thread_state_test.dart
```

Expected: test passes.

---

### Task 5: Add Routes And Thread UI

**Files:**
- Modify: `lib/core/constants/routers/route_constants.dart`
- Modify: `lib/core/constants/routers/app_router.dart`
- Create: `lib/presentation/screens/main/chat_thread_screen.dart`
- Create: `lib/presentation/widgets/chat/chat_bubble.dart`
- Create: `lib/presentation/widgets/chat/chat_composer.dart`

- [ ] **Step 1: Add route constant**

Modify `RouteConstants`:

```dart
static const String chatThread = '/chat-thread';
```

- [ ] **Step 2: Add GoRoute**

In `app_router.dart`, import:

```dart
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/presentation/screens/main/chat_thread_screen.dart';
```

Add a route:

```dart
GoRoute(
  path: RouteConstants.chatThread,
  builder: (_, state) {
    return ChatThreadScreen(
      conversation: state.extra as ChatConversationEntity,
    );
  },
),
```

- [ ] **Step 3: Add chat bubble widget**

Create `lib/presentation/widgets/chat/chat_bubble.dart`:

```dart
import 'package:achievia/domain/entities/api/chat/chat_message_entity.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageEntity message;
  final bool isMine;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isMine
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHighest;
    final textColor = isMine
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.74,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(message.body, style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
              const SizedBox(height: 4),
              Text(
                DateFormat('h:mm a').format(message.createdAt.toLocal()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor.withOpacity(0.72),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Add composer widget**

Create `lib/presentation/widgets/chat/chat_composer.dart`:

```dart
import 'package:flutter/material.dart';

class ChatComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Message',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: isSending ? null : onSend,
              icon: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Add thread screen**

Create `lib/presentation/screens/main/chat_thread_screen.dart`:

```dart
import 'package:achievia/const.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:achievia/presentation/widgets/chat/chat_bubble.dart';
import 'package:achievia/presentation/widgets/chat/chat_composer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatThreadScreen extends ConsumerWidget {
  final ChatConversationEntity conversation;

  const ChatThreadScreen({
    super.key,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatThreadProvider(conversation.id));
    final notifier = ref.read(chatThreadProvider(conversation.id).notifier);
    final currentUserId = supabaseAuth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(title: Text(conversation.title)),
      body: Column(
        children: [
          if (state.errorMessage != null)
            MaterialBanner(
              content: Text(state.errorMessage!),
              actions: [
                TextButton(onPressed: notifier.load, child: const Text('Retry')),
              ],
            ),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : state.messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          return ChatBubble(
                            message: message,
                            isMine: message.senderId == currentUserId,
                          );
                        },
                      ),
          ),
          ChatComposer(
            controller: notifier.composerController,
            isSending: state.isSending,
            onSend: notifier.send,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Analyze route/thread files**

Run:

```powershell
dart analyze lib/core/constants/routers/route_constants.dart lib/core/constants/routers/app_router.dart lib/presentation/screens/main/chat_thread_screen.dart lib/presentation/widgets/chat/chat_bubble.dart lib/presentation/widgets/chat/chat_composer.dart
```

Expected: no issues.

---

### Task 6: Replace Mock Messages Inbox

**Files:**
- Modify: `lib/presentation/screens/main/messages_screen.dart`
- Modify: `lib/presentation/widgets/list_items/message_list_item.dart`

- [ ] **Step 1: Update list item widget**

Replace `MessageListItem` with a typed version:

```dart
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class MessageListItem extends StatelessWidget {
  final List<ChatConversationEntity> conversations;

  const MessageListItem({
    super.key,
    required this.conversations,
  });

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return const Center(child: Text('No conversations yet'));
    }

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final title = conversation.title;
        final time = conversation.lastMessageAt == null
            ? ''
            : DateFormat('MMM d').format(conversation.lastMessageAt!.toLocal());

        return ListTile(
          leading: CircleAvatar(
            backgroundColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.1),
            child: Text(
              title.isEmpty ? '?' : title[0].toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          subtitle: Text(
            conversation.latestMessage ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(time),
          onTap: () {
            context.push(RouteConstants.chatThread, extra: conversation);
          },
        );
      },
    );
  }
}
```

- [ ] **Step 2: Update MessagesScreen**

Replace mock `messages` usage with `chatConversationsProvider`:

```dart
import 'package:achievia/domain/entities/api/chat/chat_conversation_entity.dart';
import 'package:achievia/presentation/provider/chat/chat_provider.dart';
import 'package:achievia/presentation/provider/tabs/event/tab_event.dart';
import 'package:achievia/presentation/widgets/list_items/message_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabNotifier = ref.read(tabProvider.notifier);
    final controller = ref.watch(tabProvider);
    final conversations = ref.watch(chatConversationsProvider);

    if (controller == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        tabNotifier.createController(this, 3);
      });
      return const SizedBox();
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor:
                      theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            TabBar(
              controller: controller,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Groups'),
                Tab(text: 'Personal Message'),
              ],
            ),
            Expanded(
              child: conversations.when(
                data: (items) {
                  final groups = items
                      .where((item) => item.type == ChatConversationType.group)
                      .toList();
                  final direct = items
                      .where((item) => item.type == ChatConversationType.direct)
                      .toList();

                  return TabBarView(
                    controller: controller,
                    children: [
                      MessageListItem(conversations: items),
                      MessageListItem(conversations: groups),
                      MessageListItem(conversations: direct),
                    ],
                  );
                },
                error: (error, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(chatConversationsProvider),
                    child: Text('Retry: $error'),
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Analyze inbox files**

Run:

```powershell
dart analyze lib/presentation/screens/main/messages_screen.dart lib/presentation/widgets/list_items/message_list_item.dart
```

Expected: no issues.

---

### Task 7: Final Verification

**Files:**
- All created/modified chat files.

- [ ] **Step 1: Run unit tests**

Run:

```powershell
flutter test test/data/models/chat/chat_dto_test.dart test/presentation/provider/chat/chat_thread_state_test.dart
```

Expected: both chat test files pass.

- [ ] **Step 2: Run analyzer**

Run:

```powershell
dart analyze lib/domain/entities/api/chat lib/data/models/chat lib/data/data_source/chat lib/domain/repository/chat lib/data/repositoryImpl/chat lib/domain/use_cases/chat lib/presentation/provider/chat lib/presentation/screens/main/messages_screen.dart lib/presentation/screens/main/chat_thread_screen.dart lib/presentation/widgets/list_items/message_list_item.dart lib/presentation/widgets/chat lib/core/constants/routers/app_router.dart lib/core/constants/routers/route_constants.dart
```

Expected: no issues in chat-related files.

- [ ] **Step 3: Manual Supabase verification**

Use two authenticated users that are both members of the same `chat_conversations` row.

Verify:

- User A sees only conversations where User A has a `chat_members` row.
- User B sees only conversations where User B has a `chat_members` row.
- User A sends a message in the thread.
- User B receives the message through Broadcast without refreshing.
- Both users still see the message after closing and reopening the app.
- A user who is not in `chat_members` cannot query or insert messages for that conversation.

- [ ] **Step 4: Commit implementation**

Run:

```powershell
git status --short
git add supabase/migrations/20260605000000_add_chat_tables.sql lib/domain/entities/api/chat lib/data/models/chat lib/data/data_source/chat lib/domain/repository/chat lib/data/repositoryImpl/chat lib/domain/use_cases/chat lib/presentation/provider/chat lib/presentation/screens/main/messages_screen.dart lib/presentation/screens/main/chat_thread_screen.dart lib/presentation/widgets/list_items/message_list_item.dart lib/presentation/widgets/chat lib/core/constants/routers/app_router.dart lib/core/constants/routers/route_constants.dart test/data/models/chat test/presentation/provider/chat lib/core/di/injection.config.dart
git commit -m "feat: add supabase broadcast chat"
```

Expected: commit succeeds with only chat-related changes staged.

---

## Self-Review Notes

- Spec coverage: schema, RLS, Broadcast delivery, inbox, thread, send flow, duplicate suppression, and verification are covered.
- Scope control: attachments, typing indicators, read receipts, reactions, push notifications, moderation, and message editing remain out of scope.
- Type consistency: conversation and message IDs are strings in Dart because Supabase UUIDs are returned as strings.
- Verification risk: existing non-chat tests may fail if unrelated password-reset tests are stale; the required chat-specific test and analyzer commands are scoped to chat files.
