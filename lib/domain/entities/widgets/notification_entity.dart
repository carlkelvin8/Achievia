class NotificationEntity {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final NotificationType type;
  final String? imageUrl;
  final Map<String, dynamic>? data;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = NotificationType.general,
    this.imageUrl,
    this.data,
  });

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    bool? isRead,
    NotificationType? type,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'NotificationEntity(id: $id, title: $title, isRead: $isRead)';
  }
}

enum NotificationType {
  general,
  update,
  reminder,
  achievement,
  message,
  system,
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.general:
        return 'General';
      case NotificationType.update:
        return 'Update';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.achievement:
        return 'Achievement';
      case NotificationType.message:
        return 'Message';
      case NotificationType.system:
        return 'System';
    }
  }

  String get iconName {
    switch (this) {
      case NotificationType.general:
        return 'notifications';
      case NotificationType.update:
        return 'system_update';
      case NotificationType.reminder:
        return 'schedule';
      case NotificationType.achievement:
        return 'emoji_events';
      case NotificationType.message:
        return 'message';
      case NotificationType.system:
        return 'settings';
    }
  }
}
