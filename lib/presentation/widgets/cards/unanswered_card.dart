// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:achievia/core/constants/app_assets.dart';
import 'package:achievia/core/constants/app_colors.dart';
import 'package:achievia/presentation/widgets/builders/inline_style_svg.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The Mock Boards question navigator: every question number of the subject,
/// answered ones dark. It is only as tall as its content, and scrolls on a
/// short screen.
class UnansweredCard extends StatelessWidget {
  final int itemCount;
  final Widget? Function(BuildContext, int) itemBuilder;
  final VoidCallback isShown;

  /// Answered questions.
  final int totalItems;

  /// All questions of the subject.
  final int currentItems;
  const UnansweredCard({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.isShown,
    required this.totalItems,
    required this.currentItems,
  });

  @override
  Widget build(BuildContext context) {
    final left = currentItems - totalItems;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 32, 12, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            key: const ValueKey('question-navigator'),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 17, 44, 131),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const InlineStyleSvg(
                      assetPath: logo,
                      width: 30,
                      height: 30,
                      semanticsLabel: 'Achievia',
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Mock Boards',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('navigator-close'),
                      tooltip: 'Close',
                      onPressed: isShown,
                      // Flush with the grid's right edge, like the logo on the left.
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerRight,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                Text(
                  left == 0
                      ? 'You have answered every question, Achievian. Review '
                            'or submit when you are ready!'
                      : 'You have $left questions left to answer, Achievian. '
                            'Stay focused, you got this!',
                  style: GoogleFonts.poppins(
                    color: LightColors.secondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: itemCount,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 10,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemBuilder: itemBuilder,
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
