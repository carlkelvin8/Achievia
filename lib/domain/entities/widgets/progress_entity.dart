class ProgressEntity {
  final double currentScore;
  final String level;
  final String message;
  final StrengthWeakness strengthWeakness;
  final List<ScoreData> scoreHistory;
  final ScreentimeData screentimeData;
  final CalendarData calendarData;

  const ProgressEntity({
    required this.currentScore,
    required this.level,
    required this.message,
    required this.strengthWeakness,
    required this.scoreHistory,
    required this.screentimeData,
    required this.calendarData,
  });

  ProgressEntity copyWith({
    double? currentScore,
    String? level,
    String? message,
    StrengthWeakness? strengthWeakness,
    List<ScoreData>? scoreHistory,
    ScreentimeData? screentimeData,
    CalendarData? calendarData,
  }) {
    return ProgressEntity(
      currentScore: currentScore ?? this.currentScore,
      level: level ?? this.level,
      message: message ?? this.message,
      strengthWeakness: strengthWeakness ?? this.strengthWeakness,
      scoreHistory: scoreHistory ?? this.scoreHistory,
      screentimeData: screentimeData ?? this.screentimeData,
      calendarData: calendarData ?? this.calendarData,
    );
  }
}

class StrengthWeakness {
  final String bestSubject;
  final double bestAverage;
  final String weakestSubject;
  final double weakestAverage;

  const StrengthWeakness({
    required this.bestSubject,
    required this.bestAverage,
    required this.weakestSubject,
    required this.weakestAverage,
  });

  StrengthWeakness copyWith({
    String? bestSubject,
    double? bestAverage,
    String? weakestSubject,
    double? weakestAverage,
  }) {
    return StrengthWeakness(
      bestSubject: bestSubject ?? this.bestSubject,
      bestAverage: bestAverage ?? this.bestAverage,
      weakestSubject: weakestSubject ?? this.weakestSubject,
      weakestAverage: weakestAverage ?? this.weakestAverage,
    );
  }
}

class ScoreData {
  final DateTime date;
  final double score;

  const ScoreData({required this.date, required this.score});

  ScoreData copyWith({DateTime? date, double? score}) {
    return ScoreData(date: date ?? this.date, score: score ?? this.score);
  }
}

class ScreentimeData {
  final int dailyAverage; // in minutes
  final int longestScreentime; // in minutes
  final int shortestScreentime; // in minutes
  final List<DailyScreentime> dailyBreakdown;

  const ScreentimeData({
    required this.dailyAverage,
    required this.longestScreentime,
    required this.shortestScreentime,
    required this.dailyBreakdown,
  });

  ScreentimeData copyWith({
    int? dailyAverage,
    int? longestScreentime,
    int? shortestScreentime,
    List<DailyScreentime>? dailyBreakdown,
  }) {
    return ScreentimeData(
      dailyAverage: dailyAverage ?? this.dailyAverage,
      longestScreentime: longestScreentime ?? this.longestScreentime,
      shortestScreentime: shortestScreentime ?? this.shortestScreentime,
      dailyBreakdown: dailyBreakdown ?? this.dailyBreakdown,
    );
  }
}

class DailyScreentime {
  final DateTime date;
  final int minutes;

  const DailyScreentime({required this.date, required this.minutes});

  DailyScreentime copyWith({DateTime? date, int? minutes}) {
    return DailyScreentime(
      date: date ?? this.date,
      minutes: minutes ?? this.minutes,
    );
  }
}

class GradingBracket {
  final String scoreRange;
  final String level;
  final String message;

  const GradingBracket({
    required this.scoreRange,
    required this.level,
    required this.message,
  });
}

class CalendarData {
  final DateTime currentMonth;
  final int thisMonthStreak;
  final int longestStreak;
  final List<CalendarDay> days;

  const CalendarData({
    required this.currentMonth,
    required this.thisMonthStreak,
    required this.longestStreak,
    required this.days,
  });

  CalendarData copyWith({
    DateTime? currentMonth,
    int? thisMonthStreak,
    int? longestStreak,
    List<CalendarDay>? days,
  }) {
    return CalendarData(
      currentMonth: currentMonth ?? this.currentMonth,
      thisMonthStreak: thisMonthStreak ?? this.thisMonthStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      days: days ?? this.days,
    );
  }
}

class CalendarDay {
  final DateTime date;
  final DayStatus status;

  const CalendarDay({required this.date, required this.status});

  CalendarDay copyWith({DateTime? date, DayStatus? status}) {
    return CalendarDay(date: date ?? this.date, status: status ?? this.status);
  }
}

enum DayStatus {
  completed, // Dark blue with white AX
  current, // White with light blue AX
  upcoming, // White with light blue AX
  inactive, // Light gray
  blank, // Padding / out-of-account-range
}
