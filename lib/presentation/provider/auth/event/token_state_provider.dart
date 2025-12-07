import 'package:achievia/core/di/injection.dart';
import 'package:achievia/core/di/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenStream = StreamProvider<String?>((ref) {
  final storage = sl<LocalStorageService>();
  return storage.tokenStream;
});

