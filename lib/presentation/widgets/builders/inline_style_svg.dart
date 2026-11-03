import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_svg/flutter_svg.dart';

/// Renders an SVG asset whose colors are defined in a `<style>` block of CSS
/// classes (as the official Achievia logo files are exported). flutter_svg
/// ignores `<style>`, which would draw the logo black; the simple
/// `.class { fill: #xxx }` rules are inlined as `fill` attributes first.
///
/// The asset is read once per widget, and the box keeps its final size while
/// loading, so the layout never jumps.
class InlineStyleSvg extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;
  final String? semanticsLabel;

  const InlineStyleSvg({
    super.key,
    required this.assetPath,
    required this.width,
    required this.height,
    this.semanticsLabel,
  });

  @override
  State<InlineStyleSvg> createState() => _InlineStyleSvgState();
}

class _InlineStyleSvgState extends State<InlineStyleSvg> {
  late Future<String> _svg = _load();

  Future<String> _load() async => inlineSimpleFillStyles(
    await services.rootBundle.loadString(widget.assetPath),
  );

  @override
  void didUpdateWidget(covariant InlineStyleSvg oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath) _svg = _load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _svg,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(width: widget.width, height: widget.height);
        }
        return SvgPicture.string(
          snapshot.data!,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.contain,
          semanticsLabel: widget.semanticsLabel,
        );
      },
    );
  }
}

/// Replaces `class="x"` with `fill="#..."` for every `.x { fill: ... }` rule
/// of the SVG's `<style>` block, then removes the block.
String inlineSimpleFillStyles(String svgString) {
  final styleReg = RegExp(
    r'<style[^>]*>([\s\S]*?)<\/style>',
    caseSensitive: false,
  );
  final styleMatch = styleReg.firstMatch(svgString);
  if (styleMatch == null) return svgString;

  final styleBody = styleMatch.group(1)!;
  final classReg = RegExp(
    r'\.([\w-]+)\s*\{[^}]*fill:\s*([^;\s}]+)[^}]*\}',
    caseSensitive: false,
  );

  var normalizedSvg = svgString;
  for (final match in classReg.allMatches(styleBody)) {
    final className = match.group(1)!;
    final fill = match.group(2)!;
    normalizedSvg = normalizedSvg.replaceAll(
      RegExp('class="$className"'),
      'fill="$fill"',
    );
    normalizedSvg = normalizedSvg.replaceAll(
      RegExp("class='$className'"),
      "fill='$fill'",
    );
  }

  return normalizedSvg.replaceFirst(styleReg, '');
}
