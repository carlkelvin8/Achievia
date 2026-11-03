import 'package:flutter/material.dart';

class PdfBadge extends StatefulWidget {
  final String text;
  final String tabType;
  final String? imageUrl;
  final VoidCallback? callback;
  const PdfBadge({
    super.key,
    required this.text,
    required this.tabType,
    this.imageUrl,
    this.callback,
  });

  @override
  State<PdfBadge> createState() => _PdfBadgeState();
}

class _PdfBadgeState extends State<PdfBadge> {
  final bool _isExpanded = false;

  /// A word longer than the tile is wide would break in the middle
  /// ("Immunohematol-ogy"), so very long words get a slightly smaller size.
  TextStyle? _titleStyle(TextStyle? base, Color color) {
    final longest = widget.text
        .split(RegExp(r'\s+'))
        .fold<int>(0, (max, word) => word.length > max ? word.length : max);
    const fits = 12;
    final scale = longest > fits ? (fits / longest).clamp(0.7, 1.0) : 1.0;
    final size = base?.fontSize;
    return base?.copyWith(
      color: color,
      fontSize: size == null ? null : size * scale,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme.labelSmall;

    return GestureDetector(
      onTap: widget.callback,
      child: Container(
        padding: const EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: themeColor.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: widget.imageUrl != null
                    ? Image.network(
                        widget.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          widget.tabType == 'mother notes'
                              ? Icons.picture_as_pdf
                              : Icons.file_copy,
                          size: 60,
                          color: themeColor.primary,
                        ),
                      )
                    : Icon(
                        widget.tabType == 'mother notes'
                            ? Icons.picture_as_pdf
                            : Icons.file_copy,
                        size: 60,
                        color: themeColor.primary,
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              flex: 2,
              child: AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                firstChild: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  style: _titleStyle(textTheme, themeColor.primary),
                ),
                secondChild: SingleChildScrollView(
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: _titleStyle(textTheme, themeColor.primary),
                  ),
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
