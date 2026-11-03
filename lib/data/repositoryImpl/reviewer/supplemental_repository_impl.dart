import 'package:achievia/data/data_source/reviewer/supplemental_remote_datasource.dart';
import 'package:achievia/data/models/reviewer/supplemental_item_dto.dart';
import 'package:achievia/domain/repository/reviewer/supplemental_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@injectable
class SupplementalRepositoryImpl implements SupplementalRepository {
  final SupplementalRemoteDatasource datasource;

  SupplementalRepositoryImpl(this.datasource);

  @override
  Future<List<SupplementalItemDto>> getItems({int? courseId}) =>
      datasource.getItems(courseId: courseId);

  @override
  Future<Map<int, String>> getSubjectTitles(Iterable<int> subjectIds) =>
      datasource.getSubjectTitles(subjectIds);
}
