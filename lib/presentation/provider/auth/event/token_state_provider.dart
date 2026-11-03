import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Access token of the current session (null when signed out).
///
/// Supabase pushes failed background token refreshes (for example while the
/// device is offline) into `onAuthStateChange` as stream errors. Those must not
/// end this stream: an error thrown out of the loop would leave every provider
/// that waits on it (reminders, goal, progress, screen time) failing until the
/// app restarts, even after the connection is back. Errors are logged and
/// skipped; the next real auth event carries the token again.
final tokenStream = StreamProvider<String?>((ref) {
  final auth = Supabase.instance.client.auth;
  return accessTokens(
    initial: auth.currentSession?.accessToken,
    events: auth.onAuthStateChange,
  );
});

/// Emits [initial], then the access token of every auth event, skipping the
/// errors that Supabase reports on [events].
Stream<String?> accessTokens({
  required String? initial,
  required Stream<AuthState> events,
}) async* {
  yield initial;
  final safe = events.handleError((Object error) {
    debugPrint('Auth state error ignored: ${error.runtimeType}');
  });
  await for (final state in safe) {
    yield state.session?.accessToken;
  }
}
