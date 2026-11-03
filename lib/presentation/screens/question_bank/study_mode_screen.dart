import 'dart:async';
import 'package:achievia/core/utils/answer_feedback.dart';
import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/presentation/widgets/question_bank/question_image.dart';
import 'package:achievia/domain/entities/api/reviewer/question_bank_entity.dart';
import 'package:achievia/domain/entities/api/reviewer/quiz_entity.dart';
import 'package:achievia/domain/entities/widgets/pomodoro_state_entity.dart';
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:achievia/presentation/provider/reviewer/study_mode_provider.dart';
import 'package:achievia/presentation/widgets/appbar/custom_app_bar.dart';
import 'package:achievia/presentation/widgets/question_bank/question_bank_status_view.dart';
import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:achievia/presentation/widgets/inputs/content_text_scale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html_unescape/html_unescape.dart';

/// Subtopic Study Mode: a per-user, per-subtopic deck with a Pomodoro timer.
/// Completely separate from Take an Exam (no score, no attempts, no results).
class StudyModeScreen extends ConsumerStatefulWidget {
  final QuestionBankSubject subject;
  final QuestionBankTopic topic;

  const StudyModeScreen({
    super.key,
    required this.subject,
    required this.topic,
  });

  @override
  ConsumerState<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends ConsumerState<StudyModeScreen> {
  bool _pomodoroStarted = false;

  /// "Take a breather!" prompt shown when an answer is attempted during a
  /// break. Lives in the root overlay so it dims the whole screen.
  OverlayEntry? _breakPrompt;
  Timer? _breakPromptTimer;
  static const _breakPromptDuration = Duration(seconds: 5);

  /// True once the saved Pomodoro settings are loaded. The timer is neither
  /// shown nor started before that, so it never runs with the 25-minute
  /// default and then jumps to the user's values.
  bool _settingsReady = false;

  @override
  void initState() {
    super.initState();
    ref.read(pomodoroSettingsProvider.notifier).ready.then((_) {
      if (mounted) setState(() => _settingsReady = true);
    });
  }

  @override
  void dispose() {
    _dismissBreakPrompt();
    super.dispose();
  }

  StudyModeKey get _key =>
      (subjectId: widget.subject.id, quizId: widget.topic.id);

  /// Every attempt to answer during a break shows the prompt (again) for
  /// five seconds. It never touches the timer or the deck.
  void _showBreakPrompt() {
    if (!mounted) return;
    _breakPromptTimer?.cancel();
    if (_breakPrompt == null) {
      final entry = OverlayEntry(
        builder: (_) => _BreakPrompt(onDismiss: _dismissBreakPrompt),
      );
      Overlay.of(context, rootOverlay: true).insert(entry);
      _breakPrompt = entry;
    }
    _breakPromptTimer = Timer(_breakPromptDuration, _dismissBreakPrompt);
  }

  void _dismissBreakPrompt() {
    _breakPromptTimer?.cancel();
    _breakPromptTimer = null;
    final entry = _breakPrompt;
    _breakPrompt = null;
    if (entry != null) {
      entry.remove();
      entry.dispose();
    }
  }

  /// Pomodoro starts once per screen visit, and only for a deck that is
  /// actually studyable (not empty, not failed, not already complete).
  void _autoStartPomodoro(StudyModeState state) {
    if (!_settingsReady ||
        _pomodoroStarted ||
        state.isEmpty ||
        state.isComplete) {
      return;
    }
    _pomodoroStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final timer = ref.read(pomodoroProvider.notifier);
      // No-op when already in sync; corrects a timer created before the saved
      // settings were available.
      timer.syncWithSettings();
      timer.start();
    });
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset deck?'),
        content: const Text(
          'This clears Already Know, Repeat and Done for this topic and '
          'starts the deck over.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('study-reset-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(studyModeProvider(_key).notifier).resetDeck();
    }
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final s = ref.watch(studyModeProvider(_key)).value;
          final notifier = ref.read(studyModeProvider(_key).notifier);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  key: const ValueKey('study-shuffle-questions'),
                  title: const Text('Shuffle Questions'),
                  value: s?.progress.shuffleQuestions ?? false,
                  onChanged: s == null ? null : notifier.setShuffleQuestions,
                ),
                SwitchListTile(
                  key: const ValueKey('study-shuffle-choices'),
                  title: const Text('Shuffle Choices'),
                  value: s?.progress.shuffleChoices ?? false,
                  onChanged: s == null ? null : notifier.setShuffleChoices,
                ),
                ListTile(
                  key: const ValueKey('study-reset-deck'),
                  leading: const Icon(Icons.restart_alt),
                  title: const Text('Reset Deck'),
                  enabled: s != null && !s.isEmpty,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _confirmReset();
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(studyModeProvider(_key));
    // Back to a Focus session: answering is allowed again, so the prompt goes.
    // Only once the saved settings are loaded: listening creates the timer,
    // and it must be created with the user's durations, not the defaults.
    if (_settingsReady) {
      ref.listen(pomodoroProvider.select((p) => p.phase), (previous, next) {
        if (next == PomodoroPhase.focus) _dismissBreakPrompt();
      });
    }
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.topic.title,
        centerTitle: true,
        actions: [
          IconButton(
            key: const ValueKey('study-settings'),
            tooltip: 'Study settings',
            icon: const Icon(Icons.tune),
            onPressed: async.hasValue ? _openSettings : null,
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => QuestionBankStatusView(
          icon: Icons.cloud_off_outlined,
          message: 'We could not load the questions for this topic.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(studyModeProvider(_key)),
        ),
        data: (state) {
          if (state.isEmpty) {
            return const QuestionBankStatusView(
              key: ValueKey('study-empty'),
              icon: Icons.quiz_outlined,
              message: 'This topic does not have questions to study yet.',
            );
          }
          _autoStartPomodoro(state);
          return Column(
            children: [
              if (_settingsReady) const _PomodoroBar(),
              Expanded(
                child: state.isComplete
                    ? _CompleteView(onReset: _confirmReset)
                    : _QuestionView(
                        stateKey: _key,
                        onBreakAttempt: _showBreakPrompt,
                      ),
              ),
              _Footer(stateKey: _key),
            ],
          );
        },
      ),
    );
  }
}

/// Only this widget listens to the clock, so a tick never rebuilds the
/// question tree.
///
/// Layout: a prominent countdown, Pause / Reset buttons and a progress line
/// for the elapsed time. Breaks start on their own when a Focus session ends.
class _PomodoroBar extends ConsumerWidget {
  const _PomodoroBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final pomodoro = ref.watch(pomodoroProvider);
    final notifier = ref.read(pomodoroProvider.notifier);
    final total = notifier.durationOf(pomodoro.phase);
    final elapsed = total.inSeconds <= 0
        ? 0.0
        : (1 - pomodoro.remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0);
    // A break reads as a break at a glance: coffee icon and red timer.
    final onBreak = pomodoro.phase != PomodoroPhase.focus;
    final accent = onBreak ? theme.colorScheme.error : null;
    final caption = switch (pomodoro.phase) {
      PomodoroPhase.focus => 'Focus session',
      PomodoroPhase.shortBreak => 'Short break',
      PomodoroPhase.longBreak => 'Long break',
    };

    // The timer is interface chrome, not study content: it stays compact at
    // the largest system text sizes so the question keeps its room.
    return MediaQuery.withClampedTextScaling(
      minScaleFactor: 1,
      maxScaleFactor: 1.2,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.4),
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  pomodoro.phase == PomodoroPhase.focus
                      ? Icons.timer_outlined
                      : Icons.free_breakfast_outlined,
                  size: 30,
                  color: accent ?? theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          notifier.formatDuration(pomodoro.remaining),
                          key: const ValueKey('study-pomodoro-time'),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: accent ?? theme.colorScheme.onSurface,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Text(
                        caption,
                        key: const ValueKey('study-pomodoro-caption'),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  key: const ValueKey('study-pomodoro-toggle'),
                  onPressed: pomodoro.isRunning
                      ? notifier.pause
                      : notifier.start,
                  icon: Icon(
                    pomodoro.isRunning ? Icons.pause : Icons.play_arrow,
                    size: 18,
                  ),
                  label: Text(pomodoro.isRunning ? 'Pause' : 'Resume'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(96, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  key: const ValueKey('study-pomodoro-reset'),
                  tooltip: 'Reset',
                  onPressed: notifier.reset,
                  icon: const Icon(Icons.refresh, size: 20),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                key: const ValueKey('study-pomodoro-progress'),
                value: elapsed,
                minHeight: 5,
                color: accent,
                backgroundColor: (accent ?? theme.colorScheme.primary)
                    .withValues(alpha: 0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionView extends ConsumerWidget {
  final StudyModeKey stateKey;

  /// Called instead of answering when the timer is in a break.
  final VoidCallback onBreakAttempt;

  const _QuestionView({required this.stateKey, required this.onBreakAttempt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(studyModeProvider(stateKey)).requireValue;
    final question = s.current;
    if (question == null) return const SizedBox.shrink();
    final unescape = HtmlUnescape();
    final notifier = ref.read(studyModeProvider(stateKey).notifier);
    return SingleChildScrollView(
      key: ValueKey('study-question-${question.id}'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentTextScale(
            child: ScaledHtml(data: unescape.convert(question.questionText)),
          ),
          const SizedBox(height: 8),
          if (question.imagePath.trim().isNotEmpty) ...[
            QuestionImage(imagePath: question.imagePath),
            const SizedBox(height: 12),
          ],
          for (final choice in s.currentChoices)
            _ChoiceTile(
              choice: choice,
              selectedId: s.selectedChoiceId,
              onTap: () {
                // Locked for the whole of a Short or Long Break.
                if (ref.read(pomodoroProvider).phase != PomodoroPhase.focus) {
                  onBreakAttempt();
                  return;
                }
                notifier.answer(choice.id);
                // One registered answer: sound / vibration per the settings.
                ref
                    .read(answerFeedbackProvider.notifier)
                    .onAnswered(correct: choice.isCorrect);
              },
            ),
          // One box, one position: the disclaimer (notes) by default, and the
          // rationale in its place while the Rationale button is toggled on.
          // A question without a disclaimer shows the box only for the
          // rationale. Moving to another question resets it to the disclaimer.
          if ((s.answered && s.rationaleOpen) || question.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoBox(
              child: s.answered && s.rationaleOpen
                  ? _RationaleContent(rationale: question.rationale)
                  : _NotesContent(notes: question.notes),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final ChoiceEntity choice;
  final int? selectedId;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.choice,
    required this.selectedId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unescape = HtmlUnescape();
    final answered = selectedId != null;
    final selected = selectedId == choice.id;

    // Green / red color coding plus the Achievia check or X; no text label.
    Color? color;
    String? logoLabel;
    if (answered) {
      if (choice.isCorrect) {
        color = Colors.green.shade700;
        logoLabel = 'Correct answer';
      } else if (selected) {
        color = Colors.red.shade700;
        logoLabel = 'Incorrect answer';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: color?.withValues(alpha: 0.10) ?? Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: color ?? theme.dividerColor.withValues(alpha: 0.5),
            width: color == null ? 1 : 1.5,
          ),
        ),
        child: InkWell(
          key: ValueKey('study-choice-${choice.id}'),
          borderRadius: BorderRadius.circular(10),
          // Locked after the first answer: no handler at all.
          onTap: answered ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Answered: all choices reserve the same icon slot, so the
                // four choices stay perfectly aligned.
                if (answered)
                  SizedBox(
                    width: 46,
                    height: 36,
                    child: color == null
                        ? null
                        : Align(
                            alignment: Alignment.centerLeft,
                            child: InlineStyleSvg(
                              key: ValueKey('study-logo-${choice.id}'),
                              assetPath: logoLabel == 'Incorrect answer'
                                  ? incorrectAnswerIcon
                                  : correctAnswerIcon,
                              width: 36,
                              height: 36,
                              semanticsLabel: logoLabel,
                            ),
                          ),
                  ),
                Expanded(
                  child: ContentTextScale(
                    child: ScaledHtml(
                      data: unescape.convert(choice.choiceText),
                      style: {'*': Style(margin: Margins.zero, color: color)},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The single gray box under the last answer choice. The disclaimer and the
/// rationale share it, so the design, color and alignment never change when
/// the student toggles between them.
class _InfoBox extends StatelessWidget {
  final Widget child;

  const _InfoBox({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('study-info-box'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

/// Disclaimer / notes text (the admin's `notes`), no label.
class _NotesContent extends StatelessWidget {
  final String notes;

  const _NotesContent({required this.notes});

  @override
  Widget build(BuildContext context) {
    return ContentTextScale(
      key: const ValueKey('study-notes-panel'),
      child: ScaledHtml(data: HtmlUnescape().convert(notes)),
    );
  }
}

class _RationaleContent extends StatelessWidget {
  final String rationale;

  const _RationaleContent({required this.rationale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const ValueKey('study-rationale-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rationale',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        if (rationale.trim().isEmpty)
          const ContentTextScale(
            child: Text(
              'No rationale available.',
              key: ValueKey('study-no-rationale'),
            ),
          )
        else
          ContentTextScale(
            child: ScaledHtml(data: HtmlUnescape().convert(rationale)),
          ),
      ],
    );
  }
}

class _CompleteView extends StatelessWidget {
  final VoidCallback onReset;

  const _CompleteView({required this.onReset});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      key: const ValueKey('study-complete'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Deck complete',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You marked every question in this topic as Already Know.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('study-reset-deck-complete'),
              onPressed: onReset,
              child: const Text('Reset Deck'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Post-answer actions (only after a locked answer) and the deck counters.
class _Footer extends ConsumerWidget {
  final StudyModeKey stateKey;

  const _Footer({required this.stateKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final s = ref.watch(studyModeProvider(stateKey)).requireValue;
    final notifier = ref.read(studyModeProvider(stateKey).notifier);

    // Equal shares that scale down instead of overflowing at large text.
    Widget counter(String label, int value, String key) => Expanded(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(
              '$value',
              key: ValueKey(key),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (s.persistFailed)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Progress could not be saved on this device.',
                  key: const ValueKey('study-persist-failed'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            if (s.answered && !s.isComplete)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  spacing: 28,
                  runSpacing: 12,
                  children: [
                    _StudyActionButton(
                      key: const ValueKey('study-again'),
                      asset: studyAgainIcon,
                      label: 'Study again',
                      onPressed: notifier.studyAgain,
                    ),
                    _StudyActionButton(
                      key: const ValueKey('study-rationale'),
                      asset: rationaleIcon,
                      label: 'Rationale',
                      onPressed: notifier.toggleRationale,
                    ),
                    _StudyActionButton(
                      key: const ValueKey('study-already-know'),
                      asset: alreadyKnowIcon,
                      label: 'Already know',
                      onPressed: notifier.alreadyKnow,
                    ),
                  ],
                ),
              )
            else
              // Progress counters are for choosing; once answered the three
              // action buttons take their place.
              IntrinsicHeight(
                child: Row(
                  children: [
                    counter('Remaining', s.remaining, 'study-remaining'),
                    const VerticalDivider(width: 1, thickness: 1),
                    counter('Repeat', s.repeat, 'study-repeat'),
                    const VerticalDivider(width: 1, thickness: 1),
                    counter('Done', s.done, 'study-done'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One of the three Study Deck actions: the Achievia logo icon with its label.
class _StudyActionButton extends StatelessWidget {
  final String asset;
  final String label;
  final VoidCallback onPressed;

  const _StudyActionButton({
    super.key,
    required this.asset,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 84,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InlineStyleSvg(assetPath: asset, width: 56, height: 56),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The break reminder: a dimmed screen with a centered card. Tapping the dim
/// area dismisses it at once (and is not passed to the screen below); the
/// card itself ignores taps.
class _BreakPrompt extends StatelessWidget {
  final VoidCallback onDismiss;

  const _BreakPrompt({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      key: const ValueKey('study-break-prompt'),
      fit: StackFit.expand,
      children: [
        GestureDetector(
          key: const ValueKey('study-break-backdrop'),
          behavior: HitTestBehavior.opaque,
          onTap: onDismiss,
          child: const ColoredBox(color: Color(0x99424242)),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Material(
              color: theme.colorScheme.surface,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Take a breather!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rest up for the next focus session.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
