import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/core/utils/pre_board_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Server calls for Pre Boards (see supabase/proposed/20261019100000).
class PreBoardRemoteDatasource {
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<PreBoardStatus> status() async {
    final result = await _supabase.rpc<dynamic>('get_pre_board_status');
    final row = result is List
        ? (result.isEmpty ? null : result.first)
        : result;
    if (row is! Map) {
      throw StateError('Pre Boards status is unavailable');
    }
    return PreBoardStatus.fromJson(Map<String, dynamic>.from(row));
  }

  /// Marks Pre Boards as taken. Throws a [PostgrestException] whose message is
  /// one of `pre_board_locked`, `pre_board_no_exam_date`, `pre_board_passed`
  /// or `pre_board_already_taken` when the server refuses.
  Future<void> claim() async {
    await _supabase.rpc<dynamic>('claim_pre_board_attempt');
  }
}

/// A safe message for a failed Pre Boards call.
String preBoardErrorMessage(Object error) {
  if (error is PostgrestException) {
    final text = error.message;
    if (text.contains('pre_board_already_taken')) {
      return 'You have already taken your Pre Boards.';
    }
    if (text.contains('pre_board_no_exam_date')) {
      return 'Set your board exam date in your profile to unlock Pre Boards.';
    }
    if (text.contains('pre_board_locked')) {
      return 'Pre Boards are not open yet. They unlock two weeks before your '
          'board exam.';
    }
    if (text.contains('pre_board_passed')) {
      return 'Your board exam date has passed, so Pre Boards are closed.';
    }
    if (error.code == 'PGRST202') {
      return 'Pre Boards is not available yet. Please try again later.';
    }
  }
  return 'Unable to open Pre Boards. ${userFacingError(error)}';
}

final preBoardRemoteProvider = Provider<PreBoardRemoteDatasource>(
  (ref) => PreBoardRemoteDatasource(),
);
