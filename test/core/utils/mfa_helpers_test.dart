import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/mfa_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('totp code', () {
    test('accepts exactly six digits, with or without a space', () {
      expect(isValidTotpCode('123456'), isTrue);
      expect(isValidTotpCode('123 456'), isTrue);
      expect(isValidTotpCode(' 123456 '), isTrue);
      expect(normalizeTotpCode('123 456'), '123456');
    });

    test('rejects everything else', () {
      for (final bad in [
        '',
        '12345',
        '1234567',
        'abcdef',
        '12a456',
        '12-456',
      ]) {
        expect(isValidTotpCode(bad), isFalse, reason: bad);
      }
    });

    test('secret is grouped in fours for manual entry', () {
      expect(formatTotpSecret('JBSWY3DPEHPK3PXP'), 'JBSW Y3DP EHPK 3PXP');
      expect(formatTotpSecret('ABCDEF'), 'ABCD EF');
      expect(formatTotpSecret(''), '');
    });
  });

  group('qr code', () {
    test('strips the data uri prefix Supabase adds', () {
      expect(
        qrSvgFromEnrollment('data:image/svg+xml;utf-8,<svg xmlns="x"></svg>'),
        '<svg xmlns="x"></svg>',
      );
      expect(qrSvgFromEnrollment('<svg></svg>'), '<svg></svg>');
    });

    test('reads a percent-encoded svg and refuses non-svg values', () {
      expect(
        qrSvgFromEnrollment(
          'data:image/svg+xml;utf-8,%3Csvg%20a%3D%221%22%3E%3C%2Fsvg%3E',
        ),
        '<svg a="1"></svg>',
      );
      expect(qrSvgFromEnrollment('javascript:alert(1)'), isNull);
      expect(qrSvgFromEnrollment(''), isNull);
    });
  });

  group('mfaRedirect', () {
    test('a signed-out user is never sent to the code screen', () {
      expect(
        mfaRedirect(
          isLoggedIn: false,
          challengeRequired: true,
          location: RouteConstants.main,
        ),
        isNull,
      );
    });

    test('a pending challenge blocks every other route', () {
      for (final location in [
        RouteConstants.main,
        RouteConstants.subscription,
        RouteConstants.settings,
        '/anything',
      ]) {
        expect(
          mfaRedirect(
            isLoggedIn: true,
            challengeRequired: true,
            location: location,
          ),
          RouteConstants.mfaVerify,
          reason: location,
        );
      }
      expect(
        mfaRedirect(
          isLoggedIn: true,
          challengeRequired: true,
          location: RouteConstants.mfaVerify,
        ),
        isNull,
      );
    });

    test('without a challenge the code screen is not reachable', () {
      expect(
        mfaRedirect(
          isLoggedIn: true,
          challengeRequired: false,
          location: RouteConstants.mfaVerify,
        ),
        RouteConstants.main,
      );
      expect(
        mfaRedirect(
          isLoggedIn: true,
          challengeRequired: false,
          location: RouteConstants.main,
        ),
        isNull,
      );
    });
  });

  group('challengeRequiredFor', () {
    test('only aal1 with aal2 available needs the second factor', () {
      expect(
        challengeRequiredFor(currentLevel: 'aal1', nextLevel: 'aal2'),
        isTrue,
      );
      expect(
        challengeRequiredFor(currentLevel: 'aal2', nextLevel: 'aal2'),
        isFalse,
      );
      expect(
        challengeRequiredFor(currentLevel: 'aal1', nextLevel: 'aal1'),
        isFalse,
      );
      expect(
        challengeRequiredFor(currentLevel: null, nextLevel: null),
        isFalse,
      );
    });
  });
}
