import 'package:achievia/const.dart';

Future<Map<String, dynamic>> guardFunction() async {
  final userResponse = await supabaseAuth.getUser();
  final user = userResponse.user;
  final session = supabaseAuth.currentSession;

  if (user == null) {
    throw Exception('Unauthorized user');
  }

  if (user.isAnonymous) {
    throw Exception('Anonymous users are not allowed');
  }

  // Check null before bang — session can be null if the user is not signed in
  if (session == null || session.isExpired) {
    throw Exception('Session expired');
  }

  return {'user_id': user.id};
}

/// Returns the current session token, or null if there is no valid session.
Future<String?> getSession() async {
  final session = supabaseAuth.currentSession;
  if (session == null || session.isExpired) {
    return null;
  }
  return session.accessToken;
}
