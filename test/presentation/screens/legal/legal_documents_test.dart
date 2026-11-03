import 'dart:io';

import 'package:achievia/core/constants/legal_documents.dart';
import 'package:achievia/core/constants/routers/app_router.dart';
import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/presentation/widgets/list_items/legal_policies_section.dart';
import 'package:achievia/presentation/widgets/list_items/mission_vision_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guests and signed-in users can open both legal documents', () {
    for (final location in [
      RouteConstants.privacyPolicy,
      RouteConstants.termsOfService,
    ]) {
      expect(authRedirect(isLoggedIn: false, location: location), isNull);
      expect(authRedirect(isLoggedIn: true, location: location), isNull);
    }
  });

  test('both legal PDFs are bundled', () {
    for (final document in [termsOfService, privacyPolicy]) {
      expect(File(document.asset).existsSync(), isTrue, reason: document.asset);
    }
  });

  testWidgets('About tab shows the renamed header and Legal & Policies', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [MissionVisionSection(), LegalPoliciesSection()],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Our Purpose & Principles'), findsOneWidget);
    expect(find.text('Legal & Policies'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });
}
