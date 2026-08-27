import 'package:achievia/data/data_source/about/author_remote_datasource.dart';
import 'package:achievia/domain/entities/widgets/author_entity.dart';
import 'package:achievia/domain/repository/about/author_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
@injectable
class AuthorRepositoryImpl implements AuthorRepository {
  final AuthorRemoteDatasource datasource;

  AuthorRepositoryImpl(this.datasource);

  @override
  Future<List<AuthorEntity>> getAuthors() async =>
      (await datasource.getAuthors()).map((item) => item.toEntity()).toList();
}
