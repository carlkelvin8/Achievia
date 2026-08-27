import 'package:achievia/domain/entities/widgets/notification_entity.dart';

abstract class NotificationRepository {
  Future<List<NotificationEntity>> getNotifications();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> delete(String id);
}
