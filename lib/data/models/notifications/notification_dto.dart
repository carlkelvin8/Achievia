import 'package:achievia/domain/entities/widgets/notification_entity.dart';

class NotificationDto {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final NotificationType type;
  final String? imageUrl;
  final Map<String, dynamic>? data;

  const NotificationDto({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
    required this.imageUrl,
    required this.data,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    final typeName = json['notification_type']?.toString() ?? '';
    final type = NotificationType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => NotificationType.general,
    );
    final rawData = json['data'];
    return NotificationDto(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at'].toString()),
      isRead: json['is_read'] == true,
      type: type,
      imageUrl: json['image_url']?.toString(),
      data: rawData is Map ? Map<String, dynamic>.from(rawData) : null,
    );
  }

  NotificationEntity toEntity() => NotificationEntity(
    id: id,
    title: title,
    message: message,
    timestamp: createdAt,
    isRead: isRead,
    type: type,
    imageUrl: imageUrl,
    data: data,
  );
}
