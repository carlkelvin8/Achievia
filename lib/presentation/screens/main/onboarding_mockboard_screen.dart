import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/constants/widget_paddings.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/cards/mockboard_card.dart';
import 'package:achievia/presentation/widgets/cards/mockboard_dynamic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingMockboardScreen extends ConsumerStatefulWidget {
  final String title;
  const OnboardingMockboardScreen({required this.title, super.key});

  @override
  ConsumerState<OnboardingMockboardScreen> createState() =>
      _OnboardingMockboardScreenState();
}

class _OnboardingMockboardScreenState
    extends ConsumerState<OnboardingMockboardScreen> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(timerProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mock Boards',
          style: GoogleFonts.poppins(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: level1_widget,
        child: SingleChildScrollView(
          child: Column(
            children: [
              MockboardCard(
                isOne: false,
                label: 'Exam Duration and Subject Order',
                labels: [
                  'Each subject has a 2-hour (120-minute) time limit. Once time is up, the exam will automatically proceed to the next subject whether you finish or not.',
                ],
              ),
              const SizedBox(height: 12),
              MockboardDynamicCard(label: 'Subject Sequence'),
              const SizedBox(height: 12),
              MockboardCard(
                isOne: true,
                label: 'Answering Reminders',
                labels: assets,
              ),
              const SizedBox(height: 12),
              MockboardCard(
                label: 'Important Reminder',
                labels: assets2,
                isOne: true,
              ),
              const SizedBox(height: 12),
              MockboardCard(
                isOne: false,
                label: 'Exam Duration and Subject Order',
                labels: [
                  'Do not take the mock board exam yet if you do not have equal and enough preparation in each subject. Taking it too early may negatively affect your overall score and may not reflect your true potential. Take the exam seriously so you can accurately assess your progress. Answer smart, stay focused, and trust your preparation',
                ],
              ),
            ],
          ),
        ),
      ),
      persistentFooterAlignment: AlignmentDirectional.bottomCenter,
      persistentFooterDecoration: BoxDecoration(),
      persistentFooterButtons: [
        ReusableButton(
          title: 'START EXAM',
          onPressed: () {
            notifier.start();
            context.push(RouteConstants.examScreen);
          },
          width: 300,
          height: 50,
        ),
      ],
    );
  }
}
