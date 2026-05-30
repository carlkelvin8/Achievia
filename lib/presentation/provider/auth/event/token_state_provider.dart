import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final tokenStream = StreamProvider<String?>((ref) async* {
  final auth = Supabase.instance.client.auth;

  yield auth.currentSession?.accessToken;
  await for (final state in auth.onAuthStateChange) {
    yield state.session?.accessToken;
  }
});
