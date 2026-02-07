import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final localStorageProvider =
    Provider<LocalStorageService>((ref) => sl<LocalStorageService>());

final tokenStreamProvider = StreamProvider<String?>((ref) async* {
  final storage = ref.watch(localStorageProvider);

  yield storage.token;

  yield* storage.tokenStream;
});
