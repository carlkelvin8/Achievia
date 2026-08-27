import 'package:achievia/core/di/injection.dart';
import 'package:achievia/domain/entities/widgets/notification_entity.dart';
import 'package:achievia/domain/use_cases/notifications/notification_use_case.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationUseCaseProvider = Provider<NotificationUseCase>((ref) {
  return sl<NotificationUseCase>();
});

class NotificationsNotifier extends AsyncNotifier<List<NotificationEntity>> {
  @override
  Future<List<NotificationEntity>> build() {
    return ref.read(notificationUseCaseProvider).getNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    await ref.read(notificationUseCaseProvider).markRead(notificationId);
    ref.invalidateSelf();
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationUseCaseProvider).markAllRead();
    ref.invalidateSelf();
  }

  Future<void> deleteNotification(String notificationId) async {
    await ref.read(notificationUseCaseProvider).delete(notificationId);
    ref.invalidateSelf();
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationEntity>>(
      NotificationsNotifier.new,
    );

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications =
      ref.watch(notificationsProvider).value ?? const [];
  return notifications.where((notification) => !notification.isRead).length;
});

final recentNotificationsProvider = Provider<List<NotificationEntity>>((ref) {
  final notifications =
      ref.watch(notificationsProvider).value ?? const [];
  return notifications.take(5).toList();
});
