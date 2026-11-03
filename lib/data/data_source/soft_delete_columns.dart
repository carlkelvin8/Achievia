import 'package:supabase_flutter/supabase_flutter.dart';

/// Content tables (subjects, quizzes, questions, choices) are soft-deleted by
/// the admin with `deleted_at`. Students must never see those rows, so every
/// content read applies `deleted_at IS NULL` through [liveSelect].
///
/// The column is part of the content schema (the soft-delete patches in
/// `supabase/` require it), so it is applied directly with no extra request.
class SoftDeleteColumns {
  const SoftDeleteColumns._();

  /// `from(table).select(columns)` restricted to live rows.
  static Future<PostgrestFilterBuilder<PostgrestList>> liveSelect(
    SupabaseClient client,
    String table,
    String columns,
  ) async {
    return client.from(table).select(columns).isFilter('deleted_at', null);
  }
}
