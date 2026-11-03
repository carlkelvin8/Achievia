import 'package:achievia/core/utils/inline_html.dart';
import 'package:achievia/domain/entities/widgets/medical_abbreviation_entity.dart';
import 'package:achievia/domain/entities/widgets/notes_entity.dart';

/// A subject a mnemonic can belong to (name from the `subjects` table).
class SupplementalSubject {
  final int id;
  final String title;

  const SupplementalSubject({required this.id, required this.title});
}

/// Case-insensitive A-Z by title. Equal titles keep their original relative
/// order (the sort is stable), so the list never shuffles between rebuilds.
List<NotesEntity> sortMnemonicsAlphabetically(Iterable<NotesEntity> items) {
  final indexed = items.toList().asMap().entries.toList();
  indexed.sort((a, b) {
    final byTitle = _key(a.value.title).compareTo(_key(b.value.title));
    return byTitle != 0 ? byTitle : a.key.compareTo(b.key);
  });
  return [for (final entry in indexed) entry.value];
}

String _key(String title) => title.trim().toLowerCase();

/// Applies the search text and the subject selection together.
///
/// [query] is matched against the title, case-insensitively. An empty
/// [subjectIds] means "All Subjects" (every mnemonic, including those that
/// belong to no subject); otherwise a mnemonic must belong to any of the
/// selected subjects. The input order is preserved.
List<NotesEntity> filterMnemonics({
  required List<NotesEntity> items,
  required String query,
  required Set<int> subjectIds,
}) {
  final needle = query.trim().toLowerCase();
  return [
    for (final item in items)
      if ((needle.isEmpty || item.title.toLowerCase().contains(needle)) &&
          (subjectIds.isEmpty ||
              (item.subjectId != null && subjectIds.contains(item.subjectId))))
        item,
  ];
}

/// Subjects that at least one mnemonic belongs to, resolved to names and
/// sorted A-Z. Ids without a known name are dropped rather than invented.
List<SupplementalSubject> subjectsForMnemonics({
  required Iterable<NotesEntity> mnemonics,
  required Map<int, String> titlesById,
  Iterable<MedicalAbbreviation> abbreviations = const [],
}) {
  final ids = {
    for (final item in mnemonics)
      if (item.subjectId != null) item.subjectId!,
    for (final item in abbreviations)
      if (item.subjectId != null) item.subjectId!,
  };
  final subjects = [
    for (final id in ids)
      if ((titlesById[id] ?? '').trim().isNotEmpty)
        SupplementalSubject(id: id, title: titlesById[id]!.trim()),
  ];
  subjects.sort((a, b) {
    final byTitle = _key(a.title).compareTo(_key(b.title));
    return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
  });
  return subjects;
}

/// A selection that covers every listed subject is the same as "All Subjects".
Set<int> normalizeSubjectSelection(
  Set<int> selected,
  List<SupplementalSubject> available,
) {
  final known = {for (final subject in available) subject.id};
  final valid = selected.intersection(known);
  if (valid.isEmpty || valid.length == known.length) return const {};
  return valid;
}

/// Abbreviations in A-Z order of the text students read (the full form),
/// case-insensitive and ignoring tags. Ties fall back to the abbreviation and
/// then to the original order, so the list never shuffles between rebuilds.
List<MedicalAbbreviation> sortAbbreviationsAlphabetically(
  Iterable<MedicalAbbreviation> items,
) {
  String key(String text) => InlineHtml.plain(text).toLowerCase();
  final indexed = items.toList().asMap().entries.toList();
  indexed.sort((a, b) {
    final byText = key(a.value.expansion).compareTo(key(b.value.expansion));
    if (byText != 0) return byText;
    final byShort = key(
      a.value.abbreviation,
    ).compareTo(key(b.value.abbreviation));
    return byShort != 0 ? byShort : a.key.compareTo(b.key);
  });
  return [for (final entry in indexed) entry.value];
}

/// Applies the search text and the subject selection together; an empty
/// [subjectIds] is "All Subjects". The input order is preserved.
List<MedicalAbbreviation> filterAbbreviations({
  required List<MedicalAbbreviation> items,
  required String query,
  required Set<int> subjectIds,
}) {
  final needle = query.trim().toLowerCase();
  return [
    for (final item in items)
      if ((needle.isEmpty ||
              InlineHtml.plain(
                item.abbreviation,
              ).toLowerCase().contains(needle) ||
              InlineHtml.plain(
                item.expansion,
              ).toLowerCase().contains(needle)) &&
          (subjectIds.isEmpty ||
              (item.subjectId != null && subjectIds.contains(item.subjectId))))
        item,
  ];
}
