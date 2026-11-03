import 'package:achievia/core/utils/duration_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('minutes below an hour, singular and plural', () {
    expect(formatHoursMinutes(0), '0 mins');
    expect(formatHoursMinutes(1), '1 min');
    expect(formatHoursMinutes(30), '30 mins');
    expect(formatHoursMinutes(45), '45 mins');
    expect(formatHoursMinutes(59), '59 mins');
  });

  test('whole hours use hr / hrs', () {
    expect(formatHoursMinutes(60), '1 hr');
    expect(formatHoursMinutes(120), '2 hrs');
    expect(formatHoursMinutes(600), '10 hrs');
  });

  test('hours and minutes combine with &', () {
    expect(formatHoursMinutes(61), '1 hr & 1 min');
    expect(formatHoursMinutes(75), '1 hr & 15 mins');
    expect(formatHoursMinutes(121), '2 hrs & 1 min');
    expect(formatHoursMinutes(148), '2 hrs & 28 mins');
  });

  test('negative values never go below zero', () {
    expect(formatHoursMinutes(-5), '0 mins');
  });

  test("today's total uses the same short form", () {
    expect(formatTodayScreenTime(0), '0 mins');
    expect(formatTodayScreenTime(30), 'Less than 1 min');
    expect(formatTodayScreenTime(60), '1 min');
    expect(formatTodayScreenTime(252), '4 mins');
    expect(formatTodayScreenTime(148 * 60 + 4), '2 hrs & 28 mins');
    expect(formatTodayScreenTime(3600), '1 hr');
  });

  test('plain minute counts', () {
    expect(formatMinutes(1), '1 min');
    expect(formatMinutes(60), '60 mins');
  });
}
