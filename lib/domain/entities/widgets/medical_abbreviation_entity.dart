class MedicalAbbreviation {
  final String abbreviation;
  final String expansion;

  /// Longer explanation shown on the detail page ('' when there is none).
  final String description;

  /// The subject the abbreviation belongs to (drives the subject filter).
  final int? subjectId;

  const MedicalAbbreviation({
    required this.abbreviation,
    required this.expansion,
    this.description = '',
    this.subjectId,
  });
}
