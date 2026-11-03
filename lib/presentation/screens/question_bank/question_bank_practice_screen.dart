import 'package:achievia/core/utils/answer_feedback.dart';
import 'dart:async';

import 'package:achievia/core/constants/routers/route_constants.dart';
import 'package:achievia/core/utils/question_bank_helpers.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/provider/reviewer/question_bank_practice_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/cards/questions_content.dart';
import 'package:achievia/presentation/widgets/question_bank/question_bank_status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Subtopic practice, or a timed Take an Exam session when
/// [selection] has no topic (questions are then supplied via [examQuestions]).
class QuestionBankPracticeScreen extends ConsumerStatefulWidget {
  final QuestionBankSelection selection;
  final List<QuestionItemEntity>? examQuestions;

  const QuestionBankPracticeScreen({
    super.key,
    required this.selection,
    this.examQuestions,
  });

  @override
  ConsumerState<QuestionBankPracticeScreen> createState() =>
      _QuestionBankPracticeScreenState();
}

class _QuestionBankPracticeScreenState
    extends ConsumerState<QuestionBankPracticeScreen>
    with WidgetsBindingObserver {
  static const _leaveExamWarning =
      'Are you sure you want to leave the exam?\n\n'
      'Your current progress will not be saved, and a new set of questions '
      'will be generated next time.';

  bool _sessionInitializationScheduled = false;
  bool _allowPop = false;
  bool _finishing = false;
  bool _quitDialogOpen = false;
  BuildContext? _dialogContext;
  Timer? _ticker;
  final _remaining = ValueNotifier<Duration>(subjectExamDuration);

  bool get _isExam => widget.selection.isSubjectExam;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _remaining.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Time keeps running in the background; recompute from the deadline.
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _startTicker() {
    if (!_isExam || _ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    final endsAt = ref.read(questionBankSessionProvider).endsAt;
    if (!mounted || endsAt == null) return;
    final left = remainingUntil(endsAt, ref.read(questionBankClockProvider)());
    _remaining.value = left;
    if (left == Duration.zero) {
      _ticker?.cancel();
      _finish();
    }
  }

  Future<void> _confirmQuit() async {
    if (_finishing || _quitDialogOpen) return;
    _quitDialogOpen = true;
    var answered = false;
    try {
      final shouldQuit = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          _dialogContext = dialogContext;
          return AlertDialog(
            title: Text(_isExam ? 'Leave Exam' : 'Leave practice?'),
            content: Text(
              _isExam
                  ? _leaveExamWarning
                  : 'Your answers in this session will be discarded.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  if (answered) return;
                  answered = true;
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () {
                  if (answered) return;
                  answered = true;
                  Navigator.of(dialogContext).pop(true);
                },
                child: Text(_isExam ? 'Leave Exam' : 'Leave'),
              ),
            ],
          );
        },
      );
      _dialogContext = null;
      if (shouldQuit == true && mounted) {
        _ticker?.cancel();
        setState(() => _allowPop = true);
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.of(context).pop();
      }
    } finally {
      _quitDialogOpen = false;
    }
  }

  Future<void> _advanceOrComplete() async {
    final notifier = ref.read(questionBankSessionProvider.notifier);
    final state = ref.read(questionBankSessionProvider);
    if (_isExam) {
      if (notifier.advance()) await _finish();
      return;
    }
    if (state.currentIndex < state.questions.length - 1) {
      notifier.next();
      return;
    }
    await _finish();
  }

  /// Finalizes once, whether from the last answer or the timer expiring.
  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    _ticker?.cancel();
    final dialogContext = _dialogContext;
    if (dialogContext != null && dialogContext.mounted) {
      Navigator.of(dialogContext).pop(false);
    }
    final QuestionBankCompletion completion;
    try {
      completion = await ref
          .read(questionBankSessionProvider.notifier)
          .complete();
    } catch (error) {
      debugPrint('Question Bank completion failed: $error');
      _finishing = false;
      return;
    }
    if (!mounted) return;
    context.pushReplacement(
      RouteConstants.questionBankResults,
      extra: QuestionBankResultArgs(
        selection: widget.selection,
        attempt: completion.attempt,
        isSaved: completion.isSaved,
        snapshot: completion.snapshot,
      ),
    );
  }

  AsyncValue<List<QuestionItemEntity>> _questions() {
    if (_isExam) return AsyncData(widget.examQuestions ?? const []);
    return ref.watch(questionBankQuestionsProvider(widget.selection.topic!.id));
  }

  bool _isCurrentSession(QuestionBankSessionState session) {
    final current = session.selection;
    return current != null &&
        current.subject.id == widget.selection.subject.id &&
        current.topic?.id == widget.selection.topic?.id &&
        session.questions.isNotEmpty;
  }

  String _formatRemaining(Duration d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.inMinutes)}:${two(d.inSeconds.remainder(60))}';
  }

  /// The countdown shown in the app bar, at the very top of the screen. Only
  /// this label listens to the clock, so the page does not rebuild every
  /// second.
  Widget _timerTitle() {
    return ValueListenableBuilder<Duration>(
      valueListenable: _remaining,
      builder: (context, left, _) {
        final low = left.inMinutes < 5;
        final color = low
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurface;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 24, color: color),
            const SizedBox(width: 8),
            Text(
              _formatRemaining(left),
              key: const ValueKey('exam-timer'),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: color,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Skip button, centered at a comfortable size. It is removed (not
  /// disabled) once the question is answered.
  Widget _examControls(QuestionBankSessionState session, bool answered) {
    final canSkip =
        !answered &&
        !session.closed &&
        !session.isSubmitting &&
        !(session.inReview && session.skippedCount <= 1);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (session.inReview && !answered)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('Reviewing skipped', style: TextStyle(fontSize: 12)),
            ),
          if (canSkip)
            Center(
              child: SizedBox(
                width: 150,
                height: 42,
                child: OutlinedButton(
                  key: const ValueKey('exam-skip'),
                  onPressed: ref
                      .read(questionBankSessionProvider.notifier)
                      .skip,
                  child: const Text('SKIP'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _indicators(QuestionBankSessionState session) {
    Widget item(String label, int value, Key key) => Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '$value',
              key: key,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
      child: IntrinsicHeight(
        child: Row(
          children: [
            item('Remaining', session.remaining, const ValueKey('remaining')),
            const VerticalDivider(width: 1, thickness: 1),
            item('Skipped', session.skippedCount, const ValueKey('skipped')),
            const VerticalDivider(width: 1, thickness: 1),
            item('Score', session.score, const ValueKey('score')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _questions();
    final title = _isExam
        ? '${widget.selection.subject.title} Exam'
        : widget.selection.topic!.title;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: title,
          // Take an Exam: the countdown sits at the very top of the screen.
          titleWidget: _isExam ? _timerTitle() : null,
          centerTitle: true,
          onBackPressed: _confirmQuit,
        ),
        body: questions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => QuestionBankStatusView(
            icon: Icons.cloud_off_outlined,
            message: 'We could not load questions for this topic.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(
              questionBankQuestionsProvider(widget.selection.topic!.id),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return QuestionBankStatusView(
                icon: Icons.quiz_outlined,
                message: _isExam
                    ? 'This exam does not have usable questions yet.'
                    : 'This topic does not have usable questions yet.',
              );
            }

            final session = ref.watch(questionBankSessionProvider);
            if (!_isCurrentSession(session)) {
              if (!_sessionInitializationScheduled) {
                _sessionInitializationScheduled = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ref
                      .read(questionBankSessionProvider.notifier)
                      .start(
                        selection: widget.selection,
                        questions: items,
                        timeLimit: _isExam ? subjectExamDuration : null,
                      );
                  _startTicker();
                });
              }
              return const Center(child: CircularProgressIndicator());
            }

            final question = session.questions[session.currentIndex];
            final selectedIndex = session.selectedAnswers[question.id];
            final isLast = session.currentIndex == session.questions.length - 1;
            final progress =
                (session.currentIndex + 1) / session.questions.length;

            return Column(
              children: [
                LinearProgressIndicator(value: progress),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.selection.subject.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${session.currentIndex + 1} / ${session.questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: QuestionsContent(
                      key: ValueKey('question-bank-question-${question.id}'),
                      questionText:
                          '${session.currentIndex + 1}. ${question.questionText}',
                      choices: question.choices,
                      imagePath: question.imagePath,
                      selectedIndex: selectedIndex,
                      logoFeedback: _isExam,
                      onSelect: (index) {
                        if (index != null) {
                          // Feedback only for the first, registered answer.
                          final registers =
                              selectedIndex == null &&
                              !session.closed &&
                              index >= 0 &&
                              index < question.choices.length;
                          ref
                              .read(questionBankSessionProvider.notifier)
                              .answer(index);
                          if (registers) {
                            ref
                                .read(answerFeedbackProvider.notifier)
                                .onAnswered(
                                  correct: question.choices[index].isCorrect,
                                );
                          }
                        }
                      },
                    ),
                  ),
                ),
                if (_isExam) _examControls(session, selectedIndex != null),
                if (!_isExam || selectedIndex != null)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                      child: ReusableButton(
                        // View Result only when nothing is left unanswered.
                        title: _isExam
                            ? (session.remaining == 0 ? 'VIEW RESULT' : 'NEXT')
                            : (isLast ? 'VIEW RESULTS' : 'NEXT'),
                        onPressed:
                            selectedIndex == null ||
                                session.isSubmitting ||
                                session.closed && _isExam
                            ? null
                            : _advanceOrComplete,
                        width: 280,
                        height: 50,
                        isLoading: session.isSubmitting,
                      ),
                    ),
                  ),
                if (_isExam && selectedIndex == null) _indicators(session),
              ],
            );
          },
        ),
      ),
    );
  }
}
