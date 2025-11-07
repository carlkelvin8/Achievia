import 'package:achievia/domain/entities/examination_results_entity.dart';
import 'package:achievia/domain/entities/pdf_entity.dart';
import 'package:achievia/domain/entities/reminders_entity.dart';
import 'package:flutter/material.dart';
import 'package:achievia/domain/entities/reminder_entity.dart';
import 'package:achievia/domain/entities/author_entity.dart';
import 'package:achievia/domain/entities/progress_entity.dart';

final List<ExaminationResult> results = [
  ExaminationResult(
    examName: 'Mock Test 1',
    date: 'October 15, 2025',
    score: 85.5,
    passingScore: 75.0,
  ),
  ExaminationResult(
    examName: 'Practice Exam 2',
    date: 'October 20, 2025',
    score: 92.0,
    passingScore: 75.0,
  ),
];

final List<RemindersEntity> reminders = [
  RemindersEntity(
    'Today',
    const Icon(Icons.calendar_today_outlined, color: Colors.white),
    '1',
  ),
  RemindersEntity(
    ' Scheduled',
    const Icon(Icons.calendar_month, color: Colors.white),
    '3',
  ),
  RemindersEntity(
    'Completed',
    const Icon(Icons.check_circle, color: Colors.white),
    '2',
  ),
];

final List<Map<String, dynamic>> messages = [
  {
    'name': 'Achievian RMT',
    'message': 'Mga paturo naman kung paano madaliang tandaan yu...',
    'isGroup': true,
  },
  {
    'name': 'Achievian August 2025 Takers',
    'message': 'Lax: goodluck guys, kaya yan. 34 days nalang madami p...',
    'isGroup': true,
  },
  {
    'name': 'Khim Jaen Magtibay',
    'message': 'anong sagot dun sa delta bilirubin something?',
    'isGroup': false,
  },
  {
    'name': 'Jersy Lima Lopez',
    'message': 'tara magsagot ng exam sa clin chem. pataasan tayo!',
    'isGroup': false,
  },
  {
    'name': 'Lei Jossa Lat',
    'message': 'ang toxic sa labi di na naubos ubos ang pasyente aa',
    'isGroup': false,
  },
];

final tabs = const [
  Tab(text: 'Mother Notes'),
  Tab(text: 'Questions'),
  Tab(text: 'Supplementals'),
];

final List<PdfEntity> list = [
  PdfEntity(text: 'Clinical Chemistry'),
  PdfEntity(text: 'Hemathology'),
  PdfEntity(text: 'Microbiology'),
  PdfEntity(text: 'AUBF'),
  PdfEntity(text: 'Immunology'),
  PdfEntity(text: 'Serology'),
  PdfEntity(text: 'Blood Banking'),
  PdfEntity(text: 'Histopathology'),
];

final List<PdfEntity> list2 = [
  PdfEntity(text: 'Clinical Chemistry'),
  PdfEntity(text: 'Hemathology'),
  PdfEntity(text: 'Microbiology'),
];
final List<PdfEntity> list3 = [
  PdfEntity(text: 'Serology'),
  PdfEntity(text: 'Blood Banking'),
  PdfEntity(text: 'Histopathology'),
];

// Demo data for Reminder screen
const List<ReminderEntity> demoReminderItems = [
  ReminderEntity(
    title: 'Hematology topic 1',
    subtitle: 'Page 1 - page 32',
    dueDateLabel: 'July 6, 2025',
    progress: 0.1,
  ),
  ReminderEntity(
    title: 'Parasitology Lecture',
    subtitle: 'Study protozoans until nematodes',
    dueDateLabel: 'July 7, 2025',
    progress: 0.45,
  ),
  ReminderEntity(
    title: 'DAT Procedure',
    subtitle: 'Need to memorize every reagents and measurement',
    dueDateLabel: 'July 9, 2025',
    progress: 0.0,
  ),
];

// Demo data for Author screen
const List<AuthorEntity> demoAuthorItems = [
  AuthorEntity(
    image:
        'https://imgs.search.brave.com/06y_UGpqC2WO7A0wUNodf1gbBVQFeVd4B6Wx2VLw8oQ/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9jZG4u/dmVjdG9yc3RvY2su/Y29tL2kvNTAwcC8y/Ni80MC9wcm9maWxl/LXBsYWNlaG9sZGVy/LWltYWdlLWdyYXkt/c2lsaG91ZXR0ZS12/ZWN0b3ItMjIxMjI2/NDAuanBn',
    name: 'Rosell Marie H. Trinidad',
    university: 'Holy Angel University',
    achievement: 'Top 1, March 2025 MTLE',
    greeting: 'Hi, Achievian RMTs!',
    message:
        'I\'m honored to be the Top 1 of the March 2025 MTLE-but more than the title, it\'s the journey, the discipline, and the faith that brought me here. I created these practice questions to help you believe in your own potential. Every item, every explanation, and every challenge was made with one goal in mind: to help you become the next topnotcher.\n\nKeep going. Trust the process. You\'re closer than you think.',
  ),
  AuthorEntity(
    image:
        'https://imgs.search.brave.com/06y_UGpqC2WO7A0wUNodf1gbBVQFeVd4B6Wx2VLw8oQ/rs:fit:500:0:1:0/g:ce/aHR0cHM6Ly9jZG4u/dmVjdG9yc3RvY2su/Y29tL2kvNTAwcC8y/Ni80MC9wcm9maWxl/LXBsYWNlaG9sZGVy/LWltYWdlLWdyYXkt/c2lsaG91ZXR0ZS12/ZWN0b3ItMjIxMjI2/NDAuanBn',
    name: 'Janette G. Madrigal',
    university: 'Saint Louis University',
    achievement: 'Top 1, August 2023 MTLE',
    greeting: 'Hello Future RMTs!',
    message:
        'Your journey to becoming an RMT is filled with challenges, but remember that every question you answer, every concept you master, brings you one step closer to your goal. Believe in yourself and keep pushing forward!',
  ),
];

// Demo data for Progress screen
final ProgressEntity demoProgressData = ProgressEntity(
  currentScore: 90.0,
  level: 'Achievian Topnotcher Potential',
  message:
      'Excellent work! You\'re on topnotcher path - keep pushing and stay sharp.',
  strengthWeakness: const StrengthWeakness(
    bestSubject: 'Clinical Chemistry',
    bestAverage: 88.00,
    weakestSubject: 'Hematology',
    weakestAverage: 57.18,
  ),
  scoreHistory: [
    ScoreData(date: DateTime(2025, 7, 15), score: 86.0),
    ScoreData(date: DateTime(2025, 7, 18), score: 82.0),
    ScoreData(date: DateTime(2025, 7, 21), score: 89.0),
    ScoreData(date: DateTime(2025, 7, 27), score: 93.0),
    ScoreData(date: DateTime(2025, 7, 28), score: 90.0),
  ],
  screentimeData: ScreentimeData(
    dailyAverage: 228,
    longestScreentime: 390,
    shortestScreentime: 75,
    dailyBreakdown: [
      DailyScreentime(date: DateTime(2025, 7, 20), minutes: 250),
      DailyScreentime(date: DateTime(2025, 7, 21), minutes: 180),
      DailyScreentime(date: DateTime(2025, 7, 22), minutes: 320),
      DailyScreentime(date: DateTime(2025, 7, 23), minutes: 390),
      DailyScreentime(date: DateTime(2025, 7, 24), minutes: 150),
      DailyScreentime(date: DateTime(2025, 7, 25), minutes: 200),
      DailyScreentime(date: DateTime(2025, 7, 26), minutes: 175),
    ],
  ),
  calendarData: CalendarData(
    currentMonth: DateTime(2025, 1),
    thisMonthStreak: 10,
    longestStreak: 18,
    days: _generateCalendarDays(DateTime(2025, 1)),
  ),
);

// Helper function to generate calendar days for a month
List<CalendarDay> _generateCalendarDays(DateTime month) {
  final days = <CalendarDay>[];
  final firstDay = DateTime(month.year, month.month, 1);
  final lastDay = DateTime(month.year, month.month + 1, 0);
  final firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday

  // Add days from previous month to fill the first week
  final prevMonthLastDay = DateTime(month.year, month.month, 0);
  for (int i = firstWeekday - 1; i > 0; i--) {
    days.add(
      CalendarDay(
        date: DateTime(
          prevMonthLastDay.year,
          prevMonthLastDay.month,
          prevMonthLastDay.day - i + 1,
        ),
        status: DayStatus.inactive,
      ),
    );
  }

  // Add days of current month
  for (int day = 1; day <= lastDay.day; day++) {
    final date = DateTime(month.year, month.month, day);
    DayStatus status;

    if (day <= 17) {
      status = DayStatus.completed; // Dark blue with white AX
    } else if (day <= 19) {
      status = DayStatus.current; // White with light blue AX
    } else {
      status = DayStatus.inactive; // Light gray
    }

    days.add(CalendarDay(date: date, status: status));
  }

  // Fill remaining days to complete the last week
  final remainingDays = 42 - days.length; // 6 weeks * 7 days
  for (int day = 1; day <= remainingDays; day++) {
    days.add(
      CalendarDay(
        date: DateTime(month.year, month.month + 1, day),
        status: DayStatus.inactive,
      ),
    );
  }

  return days;
}

// Grading brackets data
const List<GradingBracket> gradingBrackets = [
  GradingBracket(
    scoreRange: 'Below 50%',
    level: 'Recharge & Refocus',
    message:
        'Double your effort. Revisit the basics and rebuild your foundation.',
  ),
  GradingBracket(
    scoreRange: '50% - 64%',
    level: 'Warming Up',
    message: 'Progress is showing. Strengthen weak areas and stay consistent.',
  ),
  GradingBracket(
    scoreRange: '65% - 74%',
    level: 'Almost There',
    message:
        'You\'re on the right track. Improve accuracy and keep practicing.',
  ),
  GradingBracket(
    scoreRange: '75% - 84%',
    level: 'Solid Achievian',
    message:
        'Strong performance! Focus on high-yield topics and aim even higher.',
  ),
  GradingBracket(
    scoreRange: '85% - 89%',
    level: 'Board Ready',
    message:
        'You\'re nearly there. Sharpen your details and maintain your momentum.',
  ),
  GradingBracket(
    scoreRange: '90% and Above',
    level: 'Achievian Topnotcher Potential',
    message:
        'Excellent work! You\'re on topnotcher path - keep pushing and stay sharp.',
  ),
];
