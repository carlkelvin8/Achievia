class DailyMotivationEntity {
  final String id;
  final String message;
  final bool isActive;
  final int displayOrder;
  final DateTime? createdAt;

  const DailyMotivationEntity({
    required this.id,
    required this.message,
    this.isActive = true,
    this.displayOrder = 0,
    this.createdAt,
  });

  static const maxMessageLength = 280;

  /// Long enough to fill the homepage banner with a real message.
  static const minMessageLength = 150;

  /// Returns a user-facing validation error, or null when [raw] is valid.
  static String? validateMessage(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return 'Please enter a message.';
    if (text.length < minMessageLength) {
      return 'Message must be at least $minMessageLength characters '
          '(${text.length} so far).';
    }
    if (text.length > maxMessageLength) {
      return 'Message must be $maxMessageLength characters or fewer.';
    }
    return null;
  }

  factory DailyMotivationEntity.fromJson(Map<String, dynamic> json) {
    return DailyMotivationEntity(
      id: json['id'].toString(),
      message: json['message']?.toString().trim() ?? '',
      isActive: json['is_active'] != false,
      displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toCacheJson() => {'id': id, 'message': message};
}

/// Deterministic once-per-calendar-day selection.
class DailyMotivationPicker {
  const DailyMotivationPicker._();

  /// The app targets Philippine students, so the "day" always rolls over at
  /// midnight UTC+8 regardless of the device timezone.
  static const _appUtcOffset = Duration(hours: 8);

  /// yyyy-MM-dd of [now] in the application timezone.
  static String dayKey(DateTime now) {
    final d = now.toUtc().add(_appUtcOffset);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
  }

  static int dayNumber(DateTime now) {
    final d = now.toUtc().add(_appUtcOffset);
    return DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/
        Duration.millisecondsPerDay;
  }

  /// [active] must already be in stable order (display_order, created_at, id).
  static DailyMotivationEntity? pick(
    List<DailyMotivationEntity> active,
    DateTime now,
  ) {
    if (active.isEmpty) return null;
    return active[dayNumber(now) % active.length];
  }
}
