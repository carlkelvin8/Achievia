class ExaminationConfig {
  final int numberOfItems;
  final int durationMinutes;
  final bool isDefault;

  const ExaminationConfig({
    required this.numberOfItems,
    required this.durationMinutes,
    this.isDefault = false,
  });

  ExaminationConfig copyWith({
    int? numberOfItems,
    int? durationMinutes,
    bool? isDefault,
  }) {
    return ExaminationConfig(
      numberOfItems: numberOfItems ?? this.numberOfItems,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  // Default configuration
  static const ExaminationConfig defaultConfig = ExaminationConfig(
    numberOfItems: 100,
    durationMinutes: 60,
    isDefault: true,
  );

  // Common duration options in minutes
  static const List<int> durationOptions = [30, 45, 60, 90, 120, 180];

  // Common number of items options
  static const List<int> itemOptions = [25, 50, 75, 100, 150, 200];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExaminationConfig &&
        other.numberOfItems == numberOfItems &&
        other.durationMinutes == durationMinutes &&
        other.isDefault == isDefault;
  }

  @override
  int get hashCode {
    return numberOfItems.hashCode ^
        durationMinutes.hashCode ^
        isDefault.hashCode;
  }

  @override
  String toString() {
    return 'ExaminationConfig(numberOfItems: $numberOfItems, durationMinutes: $durationMinutes, isDefault: $isDefault)';
  }
}
