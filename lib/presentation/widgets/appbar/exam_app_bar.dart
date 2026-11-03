// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/presentation/provider/pomodoro/pomodoro_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mock Boards exam header: back, the subject title, and a submit check that
/// appears once every question of the subject is answered; below it the
/// subject clock, the question position and the answered progress.
class ExamAppBar extends StatelessWidget implements PreferredSizeWidget {
  static const double height = 132;

  final String title;

  /// "Question 3 of 100".
  final String questionLabel;

  /// Answered share of the current subject, 0..1.
  final double progress;
  final VoidCallback onBack;

  /// Submits the subject; null hides the check (not every question answered).
  final VoidCallback? onSubmit;

  /// Whether the question on screen is marked to revisit.
  final bool isMarked;

  /// Marks or unmarks the question on screen; null disables the button.
  final VoidCallback? onToggleMark;

  const ExamAppBar({
    super.key,
    required this.title,
    required this.questionLabel,
    required this.progress,
    required this.onBack,
    this.onSubmit,
    this.isMarked = false,
    this.onToggleMark,
  });

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: height,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  key: const ValueKey('exam-back'),
                  tooltip: 'Leave exam',
                  onPressed: onBack,
                  icon: Icon(Icons.arrow_back, color: primary),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Mockboards',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Same width either way so the title stays centered.
                SizedBox(
                  width: 48,
                  child: onSubmit == null
                      ? null
                      : IconButton(
                          key: const ValueKey('exam-submit-subject'),
                          tooltip: 'Submit subject',
                          onPressed: onSubmit,
                          icon: Icon(
                            Icons.check_circle_outline,
                            color: primary,
                            size: 28,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: _boxDecoration(primary),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              color: primary,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            const _SubjectClock(),
                            const SizedBox(width: 10),
                            Container(
                              width: 1,
                              height: 18,
                              color: primary.withValues(alpha: 0.3),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                questionLabel,
                                key: const ValueKey('exam-question-label'),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _MarkButton(isMarked: isMarked, onPressed: onToggleMark),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  key: const ValueKey('exam-progress'),
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: primary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _boxDecoration(Color color) => BoxDecoration(
  color: color.withValues(alpha: 0.08),
  borderRadius: BorderRadius.circular(10),
  border: Border.all(color: color.withValues(alpha: 0.25)),
);

/// "Mark" / "Unmark": bookmarks the question on screen. Red while marked,
/// matching its number in the question navigator.
class _MarkButton extends StatelessWidget {
  const _MarkButton({required this.isMarked, required this.onPressed});

  final bool isMarked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final color = isMarked ? Colors.red : Theme.of(context).colorScheme.primary;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const ValueKey('exam-mark'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: _boxDecoration(color),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMarked ? Icons.bookmark : Icons.bookmark_border,
                color: color,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                isMarked ? 'Unmark' : 'Mark',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "119:23": total minutes and seconds left on the subject.
class _SubjectClock extends ConsumerWidget {
  const _SubjectClock();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remaining = ref.watch(timerProvider).remaining;
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return Text(
      '$minutes:$seconds',
      key: const ValueKey('exam-clock'),
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
