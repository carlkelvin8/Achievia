import 'package:achievia/domain/entities/widgets/progress_entity.dart';
import 'package:achievia/presentation/widgets/charts/progress/score_line_chart.dart';
import 'package:flutter/material.dart';

class ScoreGraphCard extends StatefulWidget {
  final ProgressEntity progress;

  const ScoreGraphCard({super.key, required this.progress});

  @override
  State<ScoreGraphCard> createState() => _ScoreGraphCardState();
}

/// Subject Performance Graph: one subject at a time, switched with the
/// previous / next arrows. The data is `progress.subjectHistory`, which is
/// built only from completed Take an Exam subject exams (never practice, Mock
/// Board, Question of the Day or Study Mode), one point per exam.
class _ScoreGraphCardState extends State<ScoreGraphCard> {
  String? _subject;

  /// Subjects in a stable alphabetical order.
  List<String> get _subjects =>
      widget.progress.subjectHistory.keys.toList()..sort();

  /// The selected subject, falling back to the first when the previous
  /// selection no longer exists (for example after a refresh).
  String? _selected(List<String> subjects) {
    if (subjects.isEmpty) return null;
    return subjects.contains(_subject) ? _subject : subjects.first;
  }

  /// Arrows wrap around, so with two or more subjects both are always usable.
  void _step(int delta) {
    final subjects = _subjects;
    if (subjects.length < 2) return;
    final current = subjects.indexOf(_selected(subjects)!);
    final next = (current + delta) % subjects.length;
    setState(
      () => _subject = subjects[next < 0 ? next + subjects.length : next],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjects = _subjects;
    final selected = _selected(subjects);
    final history = selected == null
        ? const <ScoreData>[]
        : widget.progress.subjectHistory[selected]!;
    final average = history.isEmpty
        ? null
        : history.map((item) => item.score).reduce((a, b) => a + b) /
              history.length;
    final canStep = subjects.length > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject performance',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          if (selected != null)
            Row(
              children: [
                IconButton(
                  key: const ValueKey('graph-prev'),
                  tooltip: 'Previous subject',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: canStep ? () => _step(-1) : null,
                ),
                Expanded(
                  child: Text(
                    selected,
                    key: const ValueKey('graph-subject'),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  key: const ValueKey('graph-next'),
                  tooltip: 'Next subject',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: canStep ? () => _step(1) : null,
                ),
              ],
            ),
          const SizedBox(height: 8),
          Text(
            average == null
                ? 'No completed subject exams yet'
                : 'Average Score: ${average.toStringAsFixed(2)}%',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Score percentage',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: history.isEmpty ? 80 : 220,
            child: ScoreLineChart(
              key: ValueKey(selected),
              data: history,
              emptyMessage:
                  'Complete a Take an Exam subject exam to see your scores.',
            ),
          ),
        ],
      ),
    );
  }
}
