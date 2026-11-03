import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/constants/widget_paddings.dart';
import 'package:achievia/core/utils/helpers.dart';
import 'package:achievia/core/utils/mock_board_progress.dart';
import 'package:achievia/core/utils/snack_bar_utils.dart';
import 'package:achievia/data/data_source/home/pre_board_remote_datasource.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/provider/questions/mock_board_resume.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/cards/mockboard_card.dart';
import 'package:achievia/presentation/widgets/cards/mockboard_dynamic_card.dart';
import 'package:achievia/presentation/widgets/dialogs/ranking_unavailable_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingMockboardScreen extends ConsumerStatefulWidget {
  final String title;

  /// Pre Boards: the same exam as a Mock Board, but taken once. Starting it
  /// claims the one take on the server first.
  final bool isPreBoard;
  const OnboardingMockboardScreen({
    required this.title,
    this.isPreBoard = false,
    super.key,
  });

  @override
  ConsumerState<OnboardingMockboardScreen> createState() =>
      _OnboardingMockboardScreenState();
}

class _OnboardingMockboardScreenState
    extends ConsumerState<OnboardingMockboardScreen> {
  bool _starting = false;

  /// Records the start on the server first. If that is not possible the user
  /// is told, before the exam begins, that the attempt will not rank.
  Future<void> _startExam() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      if (widget.isPreBoard) {
        try {
          await ref.read(preBoardRemoteProvider).claim();
        } catch (error) {
          if (mounted) {
            AppToast.showError(context, preBoardErrorMessage(error));
          }
          return;
        }
        if (!mounted) return;
      }
      final proceed = await confirmExamStart(
        context,
        () => ref.read(getQuestions).startMockBoardAttempt(),
      );
      if (!proceed || !mounted) return;
      final timer = ref.read(timerProvider.notifier);
      timer.reset();
      await ref
          .read(mockBoardResumeProvider)
          .beginExam(isPreBoard: widget.isPreBoard);
      if (!mounted) return;
      timer.start();
      context.push(RouteConstants.examScreen);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// Returns to the exact subject and question that were left, with every
  /// answer and the time that was left on that subject's clock.
  void _continueExam(MockBoardProgress pending) {
    ref.read(activeMockBoardIsPreBoardProvider.notifier).state =
        widget.isPreBoard;
    final timer = ref.read(timerProvider.notifier);
    timer.restore(pending.remaining);
    timer.start();
    context.push(RouteConstants.examScreen);
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingMockBoardProvider);
    final canContinue =
        pending != null && pending.isPreBoard == widget.isPreBoard;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isPreBoard ? 'Pre Boards' : 'Mock Boards',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: level1Widget,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.isPreBoard) ...[
                MockboardCard(
                  isOne: false,
                  label: 'One-Take Exam',
                  labels: const [
                    'Pre Boards can only be taken once. Pressing START EXAM uses your only attempt, even if you leave the exam before finishing.',
                  ],
                ),
                const SizedBox(height: 12),
              ],
              MockboardCard(
                isOne: false,
                label: 'Exam Duration and Subject Order',
                labels: [
                  'Each subject has a ${_formatLimit(mockBoardSubjectMinutes)} time limit. Once time is up, the exam will automatically proceed to the next subject whether you finish or not.',
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
                footer: assets2Footer,
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
          key: ValueKey(canContinue ? 'continue-exam' : 'start-exam'),
          title: canContinue ? 'CONTINUE EXAM' : 'START EXAM',
          isLoading: _starting,
          onPressed: canContinue ? () => _continueExam(pending) : _startExam,
          width: 300,
          height: 50,
        ),
      ],
    );
  }
}

/// "1-hr (60-min)" / "90-min": always derived from the enforced limit so the
/// intro text can never disagree with the timer.
String _formatLimit(int minutes) {
  if (minutes % 60 == 0) {
    final hours = minutes ~/ 60;
    return '$hours-hr ($minutes-min)';
  }
  return '$minutes-min';
}
