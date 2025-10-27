import 'package:achievia/presentation/provider/auth/event/auth_state_provider.dart';
import 'package:get_it/get_it.dart';

final GetIt sl = GetIt.instance;

void init() {
  sl.registerLazySingleton(() => AuthNotifier());
}
