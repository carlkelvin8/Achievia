import 'package:achievia/core/utils/achievia_grading.dart';
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExaminationResultsCard extends StatefulWidget {
  final List<ExaminationResult>? results;
  final String description;
  final String title;

  /// Results shown before "Show all".
  final int initialCount;

  /// Called when a result that can reopen its summary is tapped. The returned
  /// future completes when the user comes back, which is what guards against
  /// pushing the same screen twice. Null leaves the card non-interactive.
  final Future<void> Function(ExaminationResult result)? onResultTap;
  const ExaminationResultsCard({
    super.key,
    this.results,
    this.onResultTap,
    required this.title,
    this.initialCount = 10,
    this.description =
        'Examination Results is where all your exam scores are logged to track progress and identify improvement over time. It helps monitor growth and guide focused review.',
  });

  @override
  State<ExaminationResultsCard> createState() => _ExaminationResultsCardState();
}

class _ExaminationResultsCardState extends State<ExaminationResultsCard> {
  bool _showAll = false;

  String get title => widget.title;
  String get description => widget.description;
  Future<void> Function(ExaminationResult result)? get onResultTap =>
      widget.onResultTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = widget.results;
    final hidden = (all?.length ?? 0) - widget.initialCount;
    final results = all == null || _showAll || hidden <= 0
        ? all
        : all.take(widget.initialCount).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
          const SizedBox(height: 16),

          // Results or Empty State
          if (results == null || results.isEmpty)
            _buildNoResults(theme)
          else
            _buildResultsList(theme, results),
          if (hidden > 0) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                key: const ValueKey('results-show-all'),
                onPressed: () => setState(() => _showAll = !_showAll),
                child: Text(
                  _showAll ? 'Show less' : 'Show all results (${all!.length})',
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
              fontFamily: GoogleFonts.poppins().fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'No results found.',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
            fontFamily: GoogleFonts.poppins().fontFamily,
          ),
        ),
      ),
    );
  }

  Widget _buildResultsList(
    ThemeData theme,
    List<ExaminationResult> examResults,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: examResults.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final result = examResults[index];
        final passed = isPassing(
          score: result.score,
          passingScore: result.passingScore,
        );

        final passColor = passed
            ? theme.colorScheme.primary
            : theme.colorScheme.error;

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exam Name + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    result.examName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: passColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    passed ? 'PASSED' : 'FAILED',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: passColor,
                      fontFamily: GoogleFonts.poppins().fontFamily,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date + Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  result.date,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  ),
                ),
                Text(
                  'Score: ${result.score.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                    fontFamily: GoogleFonts.poppins().fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: result.score / 100,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(passColor),
                minHeight: 8,
              ),
            ),
          ],
        );
        final onTap = onResultTap;
        if (onTap == null || !result.canOpenSummary) return content;
        return _TappableResult(onTap: () => onTap(result), child: content);
      },
    );
  }
}

/// Makes one result tappable. While the pushed screen is open further taps are
/// ignored, so a rapid double tap can never stack two summary screens.
class _TappableResult extends StatefulWidget {
  final Future<void> Function() onTap;
  final Widget child;

  const _TappableResult({required this.onTap, required this.child});

  @override
  State<_TappableResult> createState() => _TappableResultState();
}

class _TappableResultState extends State<_TappableResult> {
  bool _open = false;

  Future<void> _handleTap() async {
    if (_open) return;
    _open = true;
    try {
      await widget.onTap();
    } finally {
      _open = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: InkWell(
        key: const ValueKey('recent-result-tap'),
        borderRadius: BorderRadius.circular(8),
        onTap: _handleTap,
        child: widget.child,
      ),
    );
  }
}
