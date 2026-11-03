/// Case-insensitive A-Z order for titles shown to students ("anatomy" sits
/// with "Anatomy", not after every capitalised title). Leading/trailing spaces
/// are ignored. Equal titles fall back to [tieBreakA]/[tieBreakB] (usually the
/// id) so the order is stable between loads.
int compareTitlesAlphabetically(
  String a,
  String b, {
  int tieBreakA = 0,
  int tieBreakB = 0,
}) {
  final byTitle = a.trim().toLowerCase().compareTo(b.trim().toLowerCase());
  if (byTitle != 0) return byTitle;
  final exact = a.trim().compareTo(b.trim());
  if (exact != 0) return exact;
  return tieBreakA.compareTo(tieBreakB);
}
