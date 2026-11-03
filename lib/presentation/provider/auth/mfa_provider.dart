import 'package:achievia/data/data_source/auth/mfa_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final mfaRepositoryProvider = Provider<MfaRepository>(
  (ref) => SupabaseMfaRepository(Supabase.instance.client),
);

String mfaFailureMessage(MfaFailure failure) {
  switch (failure) {
    case MfaFailure.invalidCode:
      return 'That code is not correct or has expired. Enter the current '
          '6-digit code from your authenticator app.';
    case MfaFailure.rateLimited:
      return 'Too many attempts. Please wait a moment and try again.';
    case MfaFailure.recentLoginRequired:
      return 'For your security, log out and sign in again with your '
          'authenticator code, then try again.';
    case MfaFailure.network:
      return 'We could not reach the server. Check your connection and try '
          'again.';
    case MfaFailure.unknown:
      return 'Something went wrong. Please try again.';
  }
}
