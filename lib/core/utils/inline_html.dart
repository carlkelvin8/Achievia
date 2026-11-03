import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// [base] with [fontStyle] / [fontWeight] applied using the matching font
/// face. The theme's Poppins is registered one face per weight and style
/// (e.g. `Poppins_regular`), so only changing `fontStyle` would still draw
/// the upright glyphs; this picks the real italic / bold face instead.
TextStyle withFontFace(
  TextStyle base, {
  FontStyle? fontStyle,
  FontWeight? fontWeight,
}) {
  final styled = base.copyWith(fontStyle: fontStyle, fontWeight: fontWeight);
  if (!(base.fontFamily ?? '').startsWith('Poppins')) return styled;
  return GoogleFonts.poppins(textStyle: styled);
}

/// Minimal inline HTML for short labels (abbreviations, mnemonic titles,
/// procedure names): `<em>`/`<i>` italic, `<strong>`/`<b>` bold, `<u>`,
/// `<sub>`/`<sup>`, `<br>`, and the common character entities. Any other tag
/// is dropped and its text kept, so a tag is never shown as plain text.
///
/// This is the same result the Question Bank gets from its HTML renderer,
/// without a full HTML widget inside every list row.
class InlineHtml {
  const InlineHtml._();

  static final _tag = RegExp(
    r'<\s*(/)?\s*([a-zA-Z][a-zA-Z0-9]*)\b[^>]*?(/)?\s*>',
  );

  static const _named = {
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
    'ndash': '–',
    'mdash': '—',
    'alpha': 'α',
    'beta': 'β',
    'gamma': 'γ',
    'delta': 'δ',
    'epsilon': 'ε',
    'kappa': 'κ',
    'lambda': 'λ',
    'mu': 'μ',
    'micro': 'µ',
    'omega': 'ω',
    'sigma': 'σ',
    'plusmn': '±',
    'deg': '°',
    'times': '×',
    'le': '≤',
    'ge': '≥',
    'rarr': '→',
    'larr': '←',
    'hellip': '…',
    'ouml': 'ö',
    'Ouml': 'Ö',
    'auml': 'ä',
    'Auml': 'Ä',
    'uuml': 'ü',
    'Uuml': 'Ü',
    'eacute': 'é',
    'Eacute': 'É',
    'egrave': 'è',
    'aacute': 'á',
    'agrave': 'à',
    'iacute': 'í',
    'oacute': 'ó',
    'uacute': 'ú',
    'ntilde': 'ñ',
    'Ntilde': 'Ñ',
    'ccedil': 'ç',
    'szlig': 'ß',
    'oslash': 'ø',
    'aring': 'å',
    'copy': '©',
    'reg': '®',
    'trade': '™',
    'prime': '′',
    'infin': '∞',
    'ne': '≠',
    'asymp': '≈',
    'minus': '−',
    'middot': '·',
    'bull': '•',
    'acute': '´',
    'grave': '`',
    'lsquo': '‘',
    'rsquo': '’',
    'ldquo': '“',
    'rdquo': '”',
    'sup1': '¹',
    'sup2': '²',
    'sup3': '³',
    'frac12': '½',
    'frac14': '¼',
    'harr': '↔',
    'uarr': '↑',
    'darr': '↓',
    'Delta': 'Δ',
    'Omega': 'Ω',
    'Sigma': 'Σ',
    'Alpha': 'Α',
    'Beta': 'Β',
    'thinsp': ' ',
    'ensp': ' ',
    'emsp': ' ',
  };

  /// Decodes `&beta;`, `&amp;`, `&#946;`, `&#x3b2;`. Unknown entities stay.
  static String decodeEntities(String text) {
    return text.replaceAllMapped(
      RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z][a-zA-Z0-9]*);'),
      (m) {
        final body = m.group(1)!;
        if (body.startsWith('#x') || body.startsWith('#X')) {
          final code = int.tryParse(body.substring(2), radix: 16);
          return code == null ? m.group(0)! : String.fromCharCode(code);
        }
        if (body.startsWith('#')) {
          final code = int.tryParse(body.substring(1));
          return code == null ? m.group(0)! : String.fromCharCode(code);
        }
        return _named[body] ?? _named[body.toLowerCase()] ?? m.group(0)!;
      },
    );
  }

  /// The visible text with every tag removed (for search and semantics).
  static String plain(String html) {
    final withBreaks = html.replaceAll(
      RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false),
      '\n',
    );
    return decodeEntities(withBreaks.replaceAll(_tag, '')).trim();
  }

  /// Rich text for [html], on top of [base].
  ///
  /// With [selectable] true no widgets are emitted (selectable text cannot
  /// hold them), so sub / sup fall back to plain text.
  /// With [ignoreBold] `<strong>` / `<b>` keep the regular weight (study
  /// content: questions, choices, rationales).
  static TextSpan span(
    String html,
    TextStyle? base, {
    bool selectable = false,
    bool ignoreBold = false,
  }) {
    var italic = 0, bold = 0, underline = 0, sub = 0, sup = 0;
    final children = <InlineSpan>[];

    TextStyle? current() {
      var style = base ?? const TextStyle();
      final isBold = bold > 0 && !ignoreBold;
      if (italic > 0 || isBold) {
        style = withFontFace(
          style,
          fontStyle: italic > 0 ? FontStyle.italic : null,
          fontWeight: isBold ? FontWeight.w800 : null,
        );
      }
      if (underline > 0) {
        style = style.copyWith(decoration: TextDecoration.underline);
      }
      return style;
    }

    void add(String text) {
      if (text.isEmpty) return;
      final decoded = decodeEntities(text);
      if (!selectable && (sub > 0 || sup > 0)) {
        children.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Transform.translate(
              offset: Offset(0, sup > 0 ? -4 : 3),
              child: Text(
                decoded,
                textScaler: const TextScaler.linear(0.75),
                style: current(),
              ),
            ),
          ),
        );
      } else {
        children.add(TextSpan(text: decoded, style: current()));
      }
    }

    var last = 0;
    for (final m in _tag.allMatches(html)) {
      add(html.substring(last, m.start));
      last = m.end;
      final closing = m.group(1) != null;
      final name = m.group(2)!.toLowerCase();
      final delta = closing ? -1 : 1;
      switch (name) {
        case 'em':
        case 'i':
          italic = (italic + delta).clamp(0, 99);
        case 'strong':
        case 'b':
          bold = (bold + delta).clamp(0, 99);
        case 'u':
          underline = (underline + delta).clamp(0, 99);
        case 'sub':
          sub = (sub + delta).clamp(0, 99);
        case 'sup':
          sup = (sup + delta).clamp(0, 99);
        case 'br':
          add('\n');
      }
    }
    add(html.substring(last));
    return TextSpan(style: base, children: children);
  }
}

/// A [Text] that understands the inline tags above.
class InlineHtmlText extends StatelessWidget {
  final String html;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  /// See [InlineHtml.span].
  final bool ignoreBold;

  const InlineHtmlText(
    this.html, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.ignoreBold = false,
  });

  @override
  Widget build(BuildContext context) {
    // Plain labels (the large majority) stay an ordinary Text.
    if (!html.contains('<') && !html.contains('&')) {
      return Text(
        html,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }
    final base = DefaultTextStyle.of(context).style.merge(style);
    return Semantics(
      label: InlineHtml.plain(html),
      excludeSemantics: true,
      child: Text.rich(
        InlineHtml.span(html, base, ignoreBold: ignoreBold),
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}
