/// Time durations are shown in the app's short form, with the right singular
/// and plural: "1 min", "45 mins", "1 hr", "2 hrs", "1 hr & 1 min",
/// "2 hrs & 28 mins".
String formatHoursMinutes(int totalMinutes) {
  final minutes = totalMinutes < 0 ? 0 : totalMinutes;
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  final hoursLabel = '$hours ${hours == 1 ? 'hr' : 'hrs'}';
  final restLabel = '$rest ${rest == 1 ? 'min' : 'mins'}';
  if (hours == 0) return restLabel;
  if (rest == 0) return hoursLabel;
  return '$hoursLabel & $restLabel';
}

/// Today's total, shown in hours and minutes. Less than a minute of use reads
/// "Less than 1 min" instead of a misleading "0 mins".
String formatTodayScreenTime(int totalSeconds) {
  final seconds = totalSeconds < 0 ? 0 : totalSeconds;
  if (seconds > 0 && seconds < 60) return 'Less than 1 min';
  return formatHoursMinutes(seconds ~/ 60);
}

/// "1 min" / "30 mins" for a plain minute count (limits, timers).
String formatMinutes(int minutes) => minutes == 1 ? '1 min' : '$minutes mins';
