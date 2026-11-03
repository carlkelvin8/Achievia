import 'package:flutter/widgets.dart';

/// The app's custom Text Size preference is a slider value in `0.0..1.0`
/// (default `0.5`). It only scales study content: questions, answer choices,
/// rationales and notes in Study Deck, Take an Exam and Mock Boards.
///
/// The default maps to exactly 1.0, so the existing default sizes are
/// untouched; the ends of the slider give a smaller and a larger size.
const double kTextSizeDefault = 0.5;
const double kContentScaleMin = 0.85;
const double kContentScaleMax = 1.5;

/// Multiplier applied to study content for a slider [value].
double contentTextScaleFor(double value) {
  final v = value.isNaN ? kTextSizeDefault : value.clamp(0.0, 1.0);
  if (v <= kTextSizeDefault) {
    final t = v / kTextSizeDefault;
    return kContentScaleMin + (1.0 - kContentScaleMin) * t;
  }
  final t = (v - kTextSizeDefault) / (1.0 - kTextSizeDefault);
  return 1.0 + (kContentScaleMax - 1.0) * t;
}

/// Applies [factor] on top of whatever scaler the operating system already
/// gave the app, so native accessibility text scaling keeps working (the two
/// multiply) instead of being replaced.
class ComposedTextScaler extends TextScaler {
  final TextScaler base;
  final double factor;

  const ComposedTextScaler(this.base, this.factor);

  @override
  double scale(double fontSize) => base.scale(fontSize * factor);

  @override
  double get textScaleFactor => base.scale(1.0) * factor;

  @override
  bool operator ==(Object other) =>
      other is ComposedTextScaler &&
      other.base == base &&
      other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

final _inlineFontSize = RegExp(
  r'font-size\s*:\s*(\d+(?:\.\d+)?)\s*(px|pt)',
  caseSensitive: false,
);

/// Scales absolute `font-size: NNpx|pt` values written inline in [html] so
/// content that carries its own sizes follows the Text Size setting too.
/// Relative units (em, %, keywords) already follow the base size.
String scaleInlineFontSizes(String html, double factor) {
  if (factor == 1.0 || !html.contains('font-size')) return html;
  return html.replaceAllMapped(_inlineFontSize, (match) {
    final value = double.parse(match.group(1)!) * factor;
    final text = value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return 'font-size: $text${match.group(2)}';
  });
}
