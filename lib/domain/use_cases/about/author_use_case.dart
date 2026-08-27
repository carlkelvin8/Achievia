import 'package:achievia/data/repositoryImpl/about/author_repository_impl.dart';
import 'package:achievia/domain/entities/widgets/author_entity.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthorUseCase {
  final AuthorRepositoryImpl repository;

  AuthorUseCase(this.repository);

  Future<List<AuthorEntity>> getAuthors() => repository.getAuthors();
}
