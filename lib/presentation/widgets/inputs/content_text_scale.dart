import 'package:achievia/core/utils/content_text_scale.dart';
import 'package:achievia/core/utils/inline_html.dart';
import 'package:achievia/presentation/provider/settings/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps study content (a question, an answer choice, a rationale, a note) so
/// that it follows the Text Size setting. Headings, buttons, labels, timers
/// and navigation are never wrapped, so they do not change.
///
/// The factor is multiplied with the system text scaler, so the phone's own
/// accessibility font size still applies on top. For HTML content use
/// [ScaledHtml], which applies the same factor through CSS font sizes.
class ContentTextScale extends ConsumerWidget {
  final Widget child;

  const ContentTextScale({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factor = contentTextScaleFor(ref.watch(textSizeProvider));
    if (factor == 1.0) return child;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(
        textScaler: ComposedTextScaler(media.textScaler, factor),
      ),
      child: child,
    );
  }
}

final _inlineFontWeight = RegExp(
  r'font-weight\s*:\s*[^;"]*;?',
  caseSensitive: false,
);

/// Removes `font-weight` declarations from inline `style` attributes, so
/// editor-made bold (`<span style="font-weight: 700">`) is drawn regular too.
String dropInlineFontWeights(String html) =>
    html.replaceAll(_inlineFontWeight, '');

/// `Html` that follows the Text Size setting.
///
/// The HTML renderer lays nested blocks out with its own text scaler, so a
/// [MediaQuery] override does not reach them. Instead the base font size and
/// any inline pixel sizes in the content are multiplied by the factor, which
/// keeps the document's relative sizes (headings, sub/superscripts) intact.
class ScaledHtml extends ConsumerWidget {
  /// Fallback base size (flutter_html's `FontSize.medium`).
  static const double baseFontSize = 14.0;

  final String data;
  final Map<String, Style> style;

  const ScaledHtml({super.key, required this.data, this.style = const {}});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factor = contentTextScaleFor(ref.watch(textSizeProvider));

    // An enclosing ContentTextScale already composed the factor into the text
    // scaler; undo that here so the HTML is not scaled twice.
    final media = MediaQuery.of(context);
    final scaler = media.textScaler;
    final restoreScaler = scaler is ComposedTextScaler;
    // The size this content has at the default setting: whatever the
    // surrounding widget gives it (a list tile title is larger than a plain
    // paragraph), so the default look is preserved and only scaled from there.
    final defaultStyle = DefaultTextStyle.of(context).style;
    final base = defaultStyle.fontSize ?? baseFontSize;

    // `<em>` needs the real Poppins italic face, or the renderer only flags
    // the style and still draws upright glyphs.
    final weight =
        style['p']?.fontWeight ??
        style['*']?.fontWeight ??
        defaultStyle.fontWeight;
    final italicFace = withFontFace(
      defaultStyle.copyWith(fontWeight: weight),
      fontStyle: FontStyle.italic,
    ).fontFamily;
    final faces = {
      for (final tag in const ['em', 'i'])
        tag: Style(fontStyle: FontStyle.italic, fontFamily: italicFace),
      // Study content is drawn in one regular weight: `<strong>` / `<b>` (and
      // headings) keep the surrounding face (italic inside `<em>`) instead of
      // turning bold.
      for (final tag in const [
        'strong',
        'b',
        'h1',
        'h2',
        'h3',
        'h4',
        'h5',
        'h6',
        'th',
      ])
        tag: Style(fontWeight: FontWeight.normal),
    };
    final content = dropInlineFontWeights(data);

    Widget html;
    if (factor == 1.0) {
      html = Html(data: content, style: {...faces, ...style});
    } else {
      html = Html(
        data: scaleInlineFontSizes(content, factor),
        style: {
          ...faces,
          ...style,
          'body': (style['body'] ?? Style()).copyWith(
            fontSize: FontSize(base * factor),
          ),
        },
      );
    }

    if (!restoreScaler) return html;
    return MediaQuery(
      data: media.copyWith(textScaler: scaler.base),
      child: html,
    );
  }
}
