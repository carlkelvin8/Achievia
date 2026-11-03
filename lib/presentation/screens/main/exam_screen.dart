import 'package:achievia/core/utils/auth_error_utils.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/provider/questions/mock_board_resume.dart';
import 'package:achievia/presentation/provider/questions/questions_provider.dart';
import 'package:achievia/presentation/widgets/appbar/exam_app_bar.dart';
import 'package:achievia/presentation/widgets/badges/unanswered_questions_badge.dart';
import 'package:achievia/presentation/widgets/builders/exam_pageview_builder.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:achievia/presentation/widgets/cards/questions_content.dart';
import 'package:achievia/presentation/widgets/cards/unanswered_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The Mock Boards exam: six subjects in order, each with its own clock.
///
/// Within a subject the student moves freely (Back / Next / the navigator)
/// and may change answers; correctness is never shown. A subject ends when
/// it is submitted from the check icon (all questions answered) or when its
/// clock runs out; the last subject then submits the whole exam.
class ExamScreen extends ConsumerStatefulWidget {
  const ExamScreen({super.key});

  @override
  ConsumerState<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends ConsumerState<ExamScreen> {
  final Map<String, int> selectedAnswers = {};
  AppLifecycleListener? _lifecycle;

  /// Set once the whole exam was submitted: nothing is saved for later then.
  bool _submitted = false;
  bool _advancing = false;

  /// Keeps the exam on the device so it can be continued later. With
  /// [markPending] the intro page switches to CONTINUE EXAM.
  Future<void> _saveProgress({bool markPending = false}) async {
    if (_submitted) return;
    await ref
        .read(mockBoardResumeProvider)
        .saveProgress(
          subjectIndex: ref.read(changeIndexProvider),
          questionIndex: ref.read(changeIndexProviderOuter),
          markPending: markPending,
        );
  }

  /// Back button / system back: leaving keeps everything (answers, subject,
  /// question and the time left) so the exam can be continued later.
  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExamPromptDialog(
        mark: '!',
        title: 'Do you want to leave the exam?',
        message:
            'Your progress will be saved. You can continue where you left off.',
        cancelLabel: 'Cancel',
        confirmLabel: 'Leave',
        cancelKey: ValueKey('leave-exam-cancel'),
        confirmKey: ValueKey('leave-exam-confirm'),
      ),
    );
    if (leave != true || !mounted) return;
    ref.read(timerProvider.notifier).pause();
    await _saveProgress(markPending: true);
    if (mounted) context.pop();
  }

  /// The check icon: review the answers, or submit this subject.
  Future<void> _confirmSubmitSubject() async {
    final submit = await showDialog<bool>(
      context: context,
      builder: (_) => const _ExamPromptDialog(
        mark: '?',
        title: 'Do you want to submit the exam?',
        message: 'Once submitted, you cannot change your answers.',
        cancelLabel: 'Review Answers',
        confirmLabel: 'Submit',
        cancelKey: ValueKey('submit-subject-review'),
        confirmKey: ValueKey('submit-subject-confirm'),
      ),
    );
    if (submit == true && mounted) await _advanceSubject(byTimer: false);
  }

  /// Ends the current subject: moves to the next one (whose clock starts
  /// fresh), or submits the whole exam after the sixth.
  Future<void> _advanceSubject({required bool byTimer}) async {
    if (_advancing) return;
    final quizBatches = ref.read(getGeneratedQuestions).value ?? [];
    if (quizBatches.isEmpty) return;
    _advancing = true;
    final timerNotifier = ref.read(timerProvider.notifier);
    try {
      final safeIndex = ref
          .read(changeIndexProvider)
          .clamp(0, quizBatches.length - 1);
      final isLastBatch = safeIndex >= quizBatches.length - 1;
      timerNotifier.pause();
      // Saved first, so an exam whose submit fails can still be continued.
      await _saveProgress();
      if (!mounted) return;
      final advanced = await ref
          .read(pageController.notifier)
          .next(context, quizBatches.length, safeIndex);
      if (!mounted) return;
      if (!advanced) {
        // A failed submit keeps the answers; a clock that ran out stays at
        // zero so the student retries from the check icon.
        if (!byTimer && ref.read(timerProvider).remaining > Duration.zero) {
          timerNotifier.start();
        }
        return;
      }
      if (isLastBatch) {
        _submitted = true;
        ref.read(answeredQuestionsProvider.notifier).resetState();
        setState(selectedAnswers.clear);
      }
      // Otherwise the subject page changed: see onPageChanged.
    } finally {
      _advancing = false;
    }
  }

  String _answerKey(QuizItemEntity batch, QuestionItemEntity question) =>
      '${batch.id}:${question.id}';

  /// Mark / Unmark: the question stays red in the navigator until unmarked.
  void _toggleMark(String answerKey) {
    ref
        .read(examMarkedQuestionsProvider.notifier)
        .update(
          (marked) => marked.contains(answerKey)
              ? ({...marked}..remove(answerKey))
              : {...marked, answerKey},
        );
    _saveProgress();
  }

  /// Shows question [index] of the current subject once its page is built.
  void _jumpToQuestion(int index) {
    ref.read(changeIndexProviderOuter.notifier).changeIndex(index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(pageControllerOuter);
      if (!mounted || !controller.hasClients) return;
      controller.jumpToPage(index);
    });
  }

  /// Closes the navigator on question [jumpTo] (or the one already shown).
  void _closeNavigator({int? jumpTo}) {
    final int target = jumpTo ?? ref.read(changeIndexProviderOuter);
    ref.read(showModalNotifier.notifier).showModal();
    _jumpToQuestion(target);
  }

  @override
  void initState() {
    super.initState();
    // A continued exam starts with the answers it already had.
    selectedAnswers.addAll(ref.read(examSelectedAnswersProvider));
    // Closing or backgrounding the app keeps the exam too.
    _lifecycle = AppLifecycleListener(
      onHide: () => _saveProgress(markPending: true),
    );
    ref.listenManual(timerProvider, (prev, next) {
      // Only react to a real countdown reaching zero, never to the initial
      // state or to a reset that happens to land on zero.
      if (prev == null) return;
      if (prev.remaining != Duration.zero && next.remaining == Duration.zero) {
        // Time is up: the subject is submitted as it is (unanswered
        // questions count as wrong) and the exam moves on.
        _advanceSubject(byTimer: true);
      }
    });
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncQuestions = ref.watch(getGeneratedQuestions);
    final pageControllers = ref.watch(pageController);
    final pageControllerOuterNotifier = ref.read(pageControllerOuter.notifier);
    final pageControllerOuterState = ref.watch(pageControllerOuter);
    final indexs = ref.watch(changeIndexProvider);
    final indexNotider = ref.read(changeIndexProvider.notifier);
    final indexOuter = ref.read(changeIndexProviderOuter.notifier);
    final indexOuterState = ref.watch(changeIndexProviderOuter);
    final visible = ref.watch(showModalNotifier);
    final isAnswered = ref.read(answeredQuestionsProvider.notifier);
    final isAnsweredWatch = ref.watch(answeredQuestionsProvider);
    final answerQuestion = ref.read(answerQotProvider.notifier);
    final timerNotifier = ref.read(timerProvider.notifier);
    final quizBatches = asyncQuestions.value ?? <QuizItemEntity>[];
    final safeIndex = quizBatches.isEmpty
        ? 0
        : indexs.clamp(0, quizBatches.length - 1);
    final currentBatch = quizBatches.isEmpty ? null : quizBatches[safeIndex];
    final questionCount = currentBatch?.questions.length ?? 0;
    final safeOuterIndex = questionCount == 0
        ? 0
        : indexOuterState.clamp(0, questionCount - 1);
    final currentBatchAnsweredCount = currentBatch == null
        ? 0
        : currentBatch.questions
              .where((question) => isAnsweredWatch.contains(question.id))
              .length;
    final allAnswered =
        questionCount > 0 && currentBatchAnsweredCount == questionCount;
    final marked = ref.watch(examMarkedQuestionsProvider);
    final currentKey = currentBatch == null || questionCount == 0
        ? null
        : _answerKey(currentBatch, currentBatch.questions[safeOuterIndex]);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        appBar: ExamAppBar(
          title: asyncQuestions.when(
            data: (_) => currentBatch?.title ?? 'No questions',
            error: (_, _) => 'Mock Boards',
            loading: () => 'Loading',
          ),
          questionLabel: questionCount == 0
              ? 'Question 0 of 0'
              : 'Question ${safeOuterIndex + 1} of $questionCount',
          progress: questionCount == 0
              ? 0
              : currentBatchAnsweredCount / questionCount,
          onBack: _confirmLeave,
          onSubmit: allAnswered && !visible ? _confirmSubmitSubject : null,
          isMarked: currentKey != null && marked.contains(currentKey),
          onToggleMark: currentKey == null || visible
              ? null
              : () => _toggleMark(currentKey),
        ),
        persistentFooterAlignment: AlignmentDirectional.center,
        body: asyncQuestions.when(
          data: (_) {
            if (quizBatches.isEmpty) {
              return const Center(child: Text('No questions available'));
            }

            return ExamPageviewBuilder(
              visible: visible,
              controller: pageControllers,
              itemCount: quizBatches.length,
              onPageChanged: (batchIndex) {
                // A new subject: first question, a fresh clock.
                indexNotider.changeIndex(batchIndex);
                _jumpToQuestion(0);
                timerNotifier.reset();
                timerNotifier.start();
                _saveProgress();
              },
              itemBuilder: (context, batchIndex) {
                final batch = quizBatches[batchIndex];
                final isActiveBatch = batchIndex == safeIndex;

                return !visible
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: batch.questions.isEmpty
                            ? const Center(
                                child: Text('No questions available'),
                              )
                            : PageView.builder(
                                key: ValueKey('question-page-$batchIndex'),
                                physics: const NeverScrollableScrollPhysics(),
                                controller: isActiveBatch
                                    ? pageControllerOuterState
                                    : null,
                                itemCount: batch.questions.length,
                                onPageChanged: isActiveBatch
                                    ? indexOuter.changeIndex
                                    : null,
                                itemBuilder: (context, questionIndex) {
                                  final question =
                                      batch.questions[questionIndex];
                                  final answerKey = _answerKey(batch, question);

                                  return QuestionsContent(
                                    key: ValueKey(
                                      'question-content-$answerKey',
                                    ),
                                    questionText:
                                        '${questionIndex + 1}. ${question.questionText}',
                                    choices: question.choices,
                                    imagePath: question.imagePath,
                                    selectedIndex: selectedAnswers[answerKey],
                                    // Highlight only; the answer can change.
                                    selectionOnly: true,
                                    onSelect: (v) async {
                                      if (v == null) return;
                                      isAnswered.isAnswered(question.id);
                                      setState(() {
                                        selectedAnswers[answerKey] = v;
                                      });
                                      ref
                                          .read(
                                            examSelectedAnswersProvider
                                                .notifier,
                                          )
                                          .update(
                                            (answers) => {
                                              ...answers,
                                              answerKey: v,
                                            },
                                          );
                                      answerQuestion.recordMockBoardAnswer(
                                        subjectName: batch.title,
                                        isCorrect:
                                            question.choices[v].isCorrect,
                                        questionId: question.id,
                                        choiceId: question.choices[v].id,
                                      );
                                      _saveProgress();
                                    },
                                  );
                                },
                              ),
                      )
                    : UnansweredCard(
                        isShown: _closeNavigator,
                        itemCount: questionCount,
                        itemBuilder: (context, indx) =>
                            UnansweredQuestionsBadge(
                              callback: () => _closeNavigator(jumpTo: indx),
                              content: '${indx + 1}',
                              answered: currentBatch == null
                                  ? false
                                  : isAnsweredWatch.contains(
                                      currentBatch.questions[indx].id,
                                    ),
                              marked:
                                  currentBatch != null &&
                                  marked.contains(
                                    _answerKey(
                                      currentBatch,
                                      currentBatch.questions[indx],
                                    ),
                                  ),
                              index: indx,
                            ),
                        totalItems: currentBatchAnsweredCount,
                        currentItems: questionCount,
                      );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(userFacingError(e))),
        ),
        persistentFooterButtons: visible
            ? null
            : [
                _NavBoxButton(
                  key: const ValueKey('exam-prev'),
                  tooltip: 'Previous question',
                  icon: Icons.arrow_back_ios_new,
                  onPressed: questionCount == 0 || safeOuterIndex == 0
                      ? null
                      : pageControllerOuterNotifier.prev,
                ),
                ReusableButton(
                  key: const ValueKey('exam-navigate'),
                  title: 'NAVIGATE',
                  onPressed: () =>
                      ref.read(showModalNotifier.notifier).showModal(),
                  width: MediaQuery.of(context).size.width == 360 ? 200 : 240,
                  height: 50,
                ),
                _NavBoxButton(
                  key: const ValueKey('exam-next'),
                  tooltip: 'Next question',
                  icon: Icons.arrow_forward_ios,
                  onPressed:
                      questionCount == 0 || safeOuterIndex >= questionCount - 1
                      ? null
                      : () => pageControllerOuterNotifier.nextAsOuter(
                          context,
                          currentBatch?.title ?? '',
                        ),
                ),
              ],
      ),
    );
  }
}

/// Previous / next arrow in its own box, styled like the timer and
/// question-count box in the exam app bar.
class _NavBoxButton extends StatelessWidget {
  const _NavBoxButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: primary.withValues(alpha: 0.25)),
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          icon: Icon(icon, color: primary, size: 20),
        ),
      ),
    );
  }
}

/// The exam prompts (submit, leave): a pale-blue badge with a mark, the
/// message and two equal buttons side by side. Pops `false` for the left
/// button and `true` for the right one.
class _ExamPromptDialog extends StatelessWidget {
  const _ExamPromptDialog({
    required this.mark,
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.cancelKey,
    required this.confirmKey,
  });

  final String mark;
  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final Key cancelKey;
  final Key confirmKey;

  static const _badge = Color(0xFFE4F0FC);
  static const _badgeMark = Color(0xFF3F4D75);
  static const _title = Color(0xFF00002C);
  static const _body = Color(0xFF6E6E78);
  static const _reviewBackground = Color(0xFFE7F3FD);
  static const _blue = Color(0xFF0085FD);

  @override
  Widget build(BuildContext context) {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    );
    const label = TextStyle(fontSize: 13, fontWeight: FontWeight.bold);
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 20, 14, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _badge,
                shape: BoxShape.circle,
              ),
              child: Text(
                mark,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: _badgeMark,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Narrower than the buttons, so the message breaks onto two lines.
            SizedBox(
              width: 200,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _title,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 236,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: _body,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: cancelKey,
                    style: TextButton.styleFrom(
                      backgroundColor: _reviewBackground,
                      foregroundColor: _blue,
                      minimumSize: const Size.fromHeight(41),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: shape,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        cancelLabel,
                        maxLines: 1,
                        softWrap: false,
                        style: label,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    key: confirmKey,
                    style: TextButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(41),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      shape: shape,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirmLabel, style: label),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
