import 'package:achievia/data/data_source/auth/mfa_repository.dart';
import 'package:achievia/presentation/provider/auth/mfa_provider.dart';
import 'package:achievia/presentation/screens/auth/mfa_challenge_screen.dart';
import 'package:achievia/presentation/screens/settings/mfa_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _svg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 10 10">'
    '<rect width="10" height="10"/></svg>';

class FakeMfa implements MfaRepository {
  FakeMfa({this.factor, this.failure});

  String? factor;
  MfaFailure? failure;
  final verifiedCodes = <String>[];
  final confirmed = <String>[];
  final cancelled = <String>[];
  var disabled = 0;
  var enrollments = 0;

  @override
  Future<String?> verifiedFactorId() async => factor;

  @override
  Future<MfaEnrollment> beginEnrollment() async {
    enrollments++;
    return const MfaEnrollment(
      factorId: 'f_new',
      qrSvg: _svg,
      secret: 'JBSWY3DPEHPK3PXP',
    );
  }

  @override
  Future<void> confirmEnrollment({
    required String factorId,
    required String code,
  }) async {
    if (failure != null) throw MfaException(failure!);
    confirmed.add('$factorId:$code');
    factor = factorId;
  }

  @override
  Future<void> cancelEnrollment(String factorId) async =>
      cancelled.add(factorId);

  @override
  Future<void> verifyLogin(String code) async {
    if (failure != null) throw MfaException(failure!);
    verifiedCodes.add(code);
  }

  @override
  Future<void> disable(String factorId) async {
    if (failure != null) throw MfaException(failure!);
    disabled++;
    factor = null;
  }
}

Widget host(FakeMfa mfa, Widget child) => ProviderScope(
  overrides: [mfaRepositoryProvider.overrideWithValue(mfa)],
  child: MaterialApp(home: child),
);

void main() {
  group('MfaChallengeScreen', () {
    testWidgets('a valid code is sent to the backend', (tester) async {
      final mfa = FakeMfa(factor: 'f1');
      await tester.pumpWidget(host(mfa, const MfaChallengeScreen()));
      await tester.enterText(find.byKey(const ValueKey('mfa-code')), '123 456');
      await tester.tap(find.byKey(const ValueKey('mfa-verify')));
      await tester.pumpAndSettle();
      expect(mfa.verifiedCodes, ['123 456']);
    });

    testWidgets('a malformed code never reaches the backend', (tester) async {
      final mfa = FakeMfa(factor: 'f1');
      await tester.pumpWidget(host(mfa, const MfaChallengeScreen()));
      await tester.enterText(find.byKey(const ValueKey('mfa-code')), '12');
      await tester.tap(find.byKey(const ValueKey('mfa-verify')));
      await tester.pumpAndSettle();
      expect(mfa.verifiedCodes, isEmpty);
      expect(find.textContaining('6-digit code'), findsWidgets);
    });

    testWidgets('a wrong code shows a clear error and can be retried', (
      tester,
    ) async {
      final mfa = FakeMfa(factor: 'f1', failure: MfaFailure.invalidCode);
      await tester.pumpWidget(host(mfa, const MfaChallengeScreen()));
      await tester.enterText(find.byKey(const ValueKey('mfa-code')), '000000');
      await tester.tap(find.byKey(const ValueKey('mfa-verify')));
      await tester.pumpAndSettle();
      expect(find.textContaining('not correct or has expired'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('mfa-verify')))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('MfaSettingsScreen', () {
    testWidgets('off state offers to turn it on and shows the QR', (
      tester,
    ) async {
      final mfa = FakeMfa();
      await tester.pumpWidget(host(mfa, const MfaSettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mfa-status-off')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mfa-enable')));
      await tester.pumpAndSettle();
      expect(mfa.enrollments, 1);
      expect(find.byKey(const ValueKey('mfa-qr')), findsOneWidget);
      expect(find.text('JBSW Y3DP EHPK 3PXP'), findsOneWidget);
    });

    testWidgets('confirming with a code turns MFA on', (tester) async {
      final mfa = FakeMfa();
      await tester.pumpWidget(host(mfa, const MfaSettingsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mfa-enable')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('mfa-enroll-code')),
        '654321',
      );
      await tester.tap(find.byKey(const ValueKey('mfa-confirm')));
      await tester.pumpAndSettle();
      expect(mfa.confirmed, ['f_new:654321']);
      expect(find.byKey(const ValueKey('mfa-status-on')), findsOneWidget);
    });

    testWidgets('a wrong enrollment code keeps MFA off', (tester) async {
      final mfa = FakeMfa(failure: MfaFailure.invalidCode);
      await tester.pumpWidget(host(mfa, const MfaSettingsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mfa-enable')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('mfa-enroll-code')),
        '111111',
      );
      await tester.tap(find.byKey(const ValueKey('mfa-confirm')));
      await tester.pumpAndSettle();
      expect(mfa.confirmed, isEmpty);
      expect(find.byKey(const ValueKey('mfa-status-on')), findsNothing);
      expect(find.textContaining('not correct or has expired'), findsOneWidget);
    });

    testWidgets('cancelling removes the unconfirmed factor', (tester) async {
      final mfa = FakeMfa();
      await tester.pumpWidget(host(mfa, const MfaSettingsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mfa-enable')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(mfa.cancelled, ['f_new']);
      expect(find.byKey(const ValueKey('mfa-status-off')), findsOneWidget);
    });

    testWidgets('an enrolled user sees On and can turn it off', (tester) async {
      final mfa = FakeMfa(factor: 'f1');
      await tester.pumpWidget(host(mfa, const MfaSettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mfa-status-on')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mfa-disable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mfa-confirm-disable')));
      await tester.pumpAndSettle();
      expect(mfa.disabled, 1);
      expect(find.byKey(const ValueKey('mfa-status-off')), findsOneWidget);
    });

    testWidgets('a failed turn-off keeps MFA on and explains why', (
      tester,
    ) async {
      final mfa = FakeMfa(
        factor: 'f1',
        failure: MfaFailure.recentLoginRequired,
      );
      await tester.pumpWidget(host(mfa, const MfaSettingsScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mfa-disable')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mfa-confirm-disable')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mfa-status-on')), findsOneWidget);
      expect(find.textContaining('sign in again'), findsOneWidget);
    });
  });
}
