import 'package:achievia/data/models/reviewer/supplemental_item_dto.dart';

abstract class SupplementalRepository {
  Future<List<SupplementalItemDto>> getItems({int? courseId});
  Future<Map<int, String>> getSubjectTitles(Iterable<int> subjectIds);
}
