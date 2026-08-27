import 'package:achievia/data/data_source/supabase_user_context.dart';
import 'package:achievia/data/models/notifications/notification_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class NotificationDataSource {
  Future<List<NotificationDto>> getNotifications();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> delete(String id);
}

@lazySingleton
@injectable
class NotificationRemoteDatasource implements NotificationDataSource {
  final SupabaseUserContext userContext;

  NotificationRemoteDatasource({
    this.userContext = const SupabaseUserContext(),
  });

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<String> get _userId => userContext.currentUserId();

  @override
  Future<List<NotificationDto>> getNotifications() async {
    final rows = await _supabase
        .from('notifications')
        .select(
          'id, title, message, notification_type, image_url, data, is_read, created_at',
        )
        .eq('user_id', await _userId)
        .order('created_at', ascending: false);
    return rows
        .map((row) => NotificationDto.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  @override
  Future<void> markRead(String id) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', id)
        .eq('user_id', await _userId);
  }

  @override
  Future<void> markAllRead() async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', await _userId)
        .eq('is_read', false);
  }

  @override
  Future<void> delete(String id) async {
    await _supabase
        .from('notifications')
        .delete()
        .eq('id', id)
        .eq('user_id', await _userId);
  }
}
