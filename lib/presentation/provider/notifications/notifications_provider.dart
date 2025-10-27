import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:achievia/domain/entities/notification_entity.dart';

// Mock data for notifications
final List<NotificationEntity> _mockNotifications = [
  NotificationEntity(
    id: '1',
    title: 'New Update is out, Charlesjoven',
    message:
        'The latest version of our app is now live! We\'ve added new features, improvements, and updated content to help you study smarter and level up your review.',
    timestamp: DateTime(2025, 7, 7, 6, 45),
    isRead: false,
    type: NotificationType.update,
    imageUrl: null,
  ),
  NotificationEntity(
    id: '2',
    title: 'Study Reminder',
    message:
        'Don\'t forget to review your flashcards today! You\'re on a 5-day streak.',
    timestamp: DateTime(2025, 7, 6, 14, 30),
    isRead: true,
    type: NotificationType.reminder,
  ),
  NotificationEntity(
    id: '3',
    title: 'Achievement Unlocked!',
    message: 'Congratulations! You\'ve completed 100 practice questions.',
    timestamp: DateTime(2025, 7, 5, 16, 20),
    isRead: true,
    type: NotificationType.achievement,
  ),
  NotificationEntity(
    id: '4',
    title: 'New Message',
    message:
        'You have a new message from your instructor about the upcoming exam.',
    timestamp: DateTime(2025, 7, 4, 10, 15),
    isRead: false,
    type: NotificationType.message,
  ),
  NotificationEntity(
    id: '5',
    title: 'System Maintenance',
    message:
        'We\'ll be performing scheduled maintenance on Sunday from 2-4 AM. The app may be temporarily unavailable.',
    timestamp: DateTime(2025, 7, 3, 9, 0),
    isRead: true,
    type: NotificationType.system,
  ),
];

class NotificationsNotifier extends Notifier<List<NotificationEntity>> {
  @override
  List<NotificationEntity> build() {
    return _mockNotifications;
  }

  void markAsRead(String notificationId) {
    state = state.map((notification) {
      if (notification.id == notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();
  }

  void markAllAsRead() {
    state = state.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();
  }

  void deleteNotification(String notificationId) {
    state = state
        .where((notification) => notification.id != notificationId)
        .toList();
  }

  void addNotification(NotificationEntity notification) {
    state = [notification, ...state];
  }

  void refreshNotifications() {
    // In a real app, this would fetch from an API
    state = [..._mockNotifications];
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<NotificationEntity>>(
      () => NotificationsNotifier(),
    );

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.where((notification) => !notification.isRead).length;
});

final recentNotificationsProvider = Provider<List<NotificationEntity>>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.take(5).toList();
});
