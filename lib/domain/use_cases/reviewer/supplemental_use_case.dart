import 'package:achievia/data/models/reviewer/supplemental_item_dto.dart';
import 'package:achievia/data/repositoryImpl/reviewer/supplemental_repository_impl.dart';
import 'package:injectable/injectable.dart';

@injectable
class SupplementalUseCase {
  final SupplementalRepositoryImpl repository;

  SupplementalUseCase(this.repository);

  Future<List<SupplementalItemDto>> getItems({int? courseId}) =>
      repository.getItems(courseId: courseId);
}
