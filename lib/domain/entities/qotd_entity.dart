class QotdEntity {
  final String id;
  final String question;
  final List<String> options;
  final int? selectedIndex;

  const QotdEntity({
    required this.id,
    required this.question,
    required this.options,
    this.selectedIndex,
  });

  QotdEntity copyWith({
    String? id,
    String? question,
    List<String>? options,
    int? selectedIndex,
    bool clearSelection = false,
  }) {
    return QotdEntity(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      selectedIndex: clearSelection
          ? null
          : (selectedIndex ?? this.selectedIndex),
    );
  }
}
