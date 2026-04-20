import 'package:achievia/data/data_source/profile/profile_remote_datasource.dart';
import 'package:achievia/domain/entities/api/profile/profile_entity.dart';
import 'package:achievia/domain/repository/profile/profile_repository.dart';
import 'package:injectable/injectable.dart';

@injectable
@lazySingleton
class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource datasource;

  ProfileRepositoryImpl({required this.datasource});

  @override
  Future<ProfileEntity> getProfile() async {
    return await datasource.getProfile();
  }

  @override
  Future<String> updateMantra(String mantra) async {
    return await datasource.updateMantra(mantra);
  }
}
