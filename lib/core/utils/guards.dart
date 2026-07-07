import 'package:achievia/const.dart';

Future<Map<String, dynamic>> guardFunction() async {
  final userResponse = await supabaseAuth.getUser();
  final user = userResponse.user;
  final session = supabaseAuth.currentSession;
  if (user == null) {
    throw Exception("Unauthorized user");
  }

  if (user.isAnonymous) {
    throw Exception('Anonymous users are not allowed');
  }

  if (session!.isExpired) {
    throw Exception("Session expired");
  }
  return {'user_id': user.id};
}

Future<String?> getSession() async {
  final session = supabaseAuth.currentSession;
  if (session!.isExpired || session == null) {
    return "Session not ";
  }
}
