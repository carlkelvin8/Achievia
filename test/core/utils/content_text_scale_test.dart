import 'package:achievia/core/utils/content_text_scale.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('contentTextScaleFor', () {
    test('the default slider value keeps the existing size exactly', () {
      expect(contentTextScaleFor(0.5), 1.0);
    });

    test('minimum is smaller and maximum is larger than the default', () {
      expect(contentTextScaleFor(0.0), kContentScaleMin);
      expect(contentTextScaleFor(1.0), kContentScaleMax);
      expect(kContentScaleMin, lessThan(1.0));
      expect(kContentScaleMax, greaterThan(1.0));
    });

    test('grows steadily with the slider', () {
      var previous = contentTextScaleFor(0.0);
      for (var step = 1; step <= 20; step++) {
        final next = contentTextScaleFor(step / 20);
        expect(next, greaterThanOrEqualTo(previous));
        previous = next;
      }
    });

    test('out-of-range and invalid values are clamped', () {
      expect(contentTextScaleFor(-3), kContentScaleMin);
      expect(contentTextScaleFor(7), kContentScaleMax);
      expect(contentTextScaleFor(double.nan), 1.0);
    });
  });

  group('ComposedTextScaler', () {
    test('multiplies with the system accessibility scale', () {
      const system = TextScaler.linear(1.3);
      const composed = ComposedTextScaler(system, 1.5);
      expect(composed.scale(10), closeTo(10 * 1.3 * 1.5, 1e-9));
    });

    test('with the system at 1.0 it is just the app factor', () {
      const composed = ComposedTextScaler(TextScaler.noScaling, 0.85);
      expect(composed.scale(20), closeTo(17, 1e-9));
    });

    test('equal inputs are equal', () {
      const a = ComposedTextScaler(TextScaler.linear(1.1), 1.2);
      const b = ComposedTextScaler(TextScaler.linear(1.1), 1.2);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('scaleInlineFontSizes', () {
    test('multiplies absolute inline sizes and leaves the rest alone', () {
      expect(
        scaleInlineFontSizes(
          '<span style="font-size: 20px">a</span>'
          '<span style="color:red; font-size:12pt">b</span>'
          '<span style="font-size: 1.5em">c</span>',
          1.5,
        ),
        '<span style="font-size: 30px">a</span>'
        '<span style="color:red; font-size: 18pt">b</span>'
        '<span style="font-size: 1.5em">c</span>',
      );
    });

    test('no change at the default size or without inline sizes', () {
      const html = '<p style="font-size: 20px">x</p>';
      expect(scaleInlineFontSizes(html, 1.0), html);
      expect(scaleInlineFontSizes('<p>plain</p>', 1.5), '<p>plain</p>');
    });
  });
}
