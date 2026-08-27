import 'package:achievia/domain/entities/widgets/author_entity.dart';

abstract class AuthorRepository {
  Future<List<AuthorEntity>> getAuthors();
}
