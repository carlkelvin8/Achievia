import 'package:achievia/core/utils/pomodoro_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('one minute is singular, everything else plural', () {
    expect(formatMinutesLabel(1), '1 min');
    expect(formatMinutesLabel(2), '2 mins');
    expect(formatMinutesLabel(3), '3 mins');
    expect(formatMinutesLabel(25), '25 mins');
    expect(formatMinutesLabel(0), '0 mins');
  });

  test('one session is singular, everything else plural', () {
    expect(formatSessionsLabel(1), '1 session');
    expect(formatSessionsLabel(3), '3 sessions');
    expect(formatSessionsLabel(10), '10 sessions');
  });
}
