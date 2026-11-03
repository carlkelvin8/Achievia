/// Icon asset for a Question Bank subject, matched on the subject title so
/// it works with the titles stored in the database ("Histopath",
/// "Immunology & Serology", ...). Returns null for an unknown subject.
String? subjectIconAsset(String title) {
  final t = title.toLowerCase();
  const base = 'assets/icons/subjects/';
  // Order matters: "immunohematology" must win over "hematology".
  const rules = <(String, String)>[
    ('immunohematology', 'immunohematology'),
    ('blood bank', 'immunohematology'),
    ('hematology', 'hematology'),
    ('serology', 'immunology_and_serology'),
    ('immunology', 'immunology_and_serology'),
    ('bacteriology', 'bacteriology'),
    ('chemistry', 'clinical_chemistry'),
    ('microscopy', 'clinical_microscopy'),
    ('histopath', 'histopathology'),
    ('law', 'medtech_laws_and_ethics'),
    ('ethics', 'medtech_laws_and_ethics'),
    ('molecular', 'molecular_biology'),
    ('mycology', 'mycology'),
    ('parasitology', 'parasitology'),
    ('virology', 'virology'),
  ];
  for (final (keyword, file) in rules) {
    if (t.contains(keyword)) return '$base$file.png';
  }
  return null;
}
