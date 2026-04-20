import 'package:achievia/domain/entities/api/auth/user_entity.dart';
import 'package:achievia/domain/entities/widgets/examination_results_entity.dart';
import 'package:achievia/domain/entities/widgets/medical_abbreviation_entity.dart';
import 'package:achievia/domain/entities/widgets/notes_entity.dart';
import 'package:achievia/domain/entities/widgets/pdf_entity.dart';
import 'package:achievia/domain/entities/widgets/questions_entity.dart';
import 'package:achievia/presentation/widgets/buttons/reusable_button.dart';
import 'package:flutter/material.dart';
import 'package:achievia/domain/entities/widgets/author_entity.dart';
import 'package:achievia/domain/entities/widgets/progress_entity.dart';

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

// Demo data for Author screen
const List<AuthorEntity> demoAuthorItems = [
  AuthorEntity(
    image: 'https://christian18.sirv.com/employees/face_690f9182255ea.pdf',
    name: 'Rosell Marie H. Trinidad',
    university: 'Holy Angel University',
    achievement: 'Top 1, March 2025 MTLE',
    greeting: 'Hi, Achievian RMTs!',
    message:
        'I\'m honored to be the Top 1 of the March 2025 MTLE-but more than the title, it\'s the journey, the discipline, and the faith that brought me here. I created these practice questions to help you believe in your own potential. Every item, every explanation, and every challenge was made with one goal in mind: to help you become the next topnotcher.\n\nKeep going. Trust the process. You\'re closer than you think.',
  ),
  AuthorEntity(
    image: 'https://christian18.sirv.com/employees/face_690f9182255ea.pdf',
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

final List<MedicalAbbreviation> medicalAbbreviations = [
  const MedicalAbbreviation(abbreviation: 'AC', expansion: 'adenylyl cyclase'),
  const MedicalAbbreviation(
    abbreviation: 'ADP',
    expansion: 'adenosine diphosphate',
  ),
  const MedicalAbbreviation(
    abbreviation: 'ADPR',
    expansion: 'adenosine diphosphate ribose',
  ),
  const MedicalAbbreviation(
    abbreviation: 'AIDS',
    expansion: 'acquired immune deficiency syndrome',
  ),
  const MedicalAbbreviation(
    abbreviation: 'ALT',
    expansion: 'alanine transaminase',
  ),
  const MedicalAbbreviation(
    abbreviation: 'AST',
    expansion: 'aspartate transaminase',
  ),
  const MedicalAbbreviation(
    abbreviation: 'ATP',
    expansion: 'adenosine triphosphate',
  ),
  const MedicalAbbreviation(
    abbreviation: 'BPP',
    expansion: 'Baclofen phosphate',
  ),
  const MedicalAbbreviation(
    abbreviation: 'cAMP',
    expansion: 'cyclic 3\'-adenosine monophosphate',
  ),
  const MedicalAbbreviation(
    abbreviation: 'CNS',
    expansion: 'central nervous system',
  ),
  const MedicalAbbreviation(
    abbreviation: 'DAP',
    expansion: 'diaminopimelic acid',
  ),
  const MedicalAbbreviation(
    abbreviation: 'EBV',
    expansion: 'Epstein-Barr virus',
  ),
  const MedicalAbbreviation(
    abbreviation: 'EF-2',
    expansion: 'elongation factor 2',
  ),
  const MedicalAbbreviation(
    abbreviation: 'EIEC',
    expansion: 'enteroinvasive Escherichia coli',
  ),
  const MedicalAbbreviation(
    abbreviation: 'ELISA',
    expansion: 'enzyme-linked immunosorbent assay',
  ),
  const MedicalAbbreviation(
    abbreviation: 'ETEC',
    expansion: 'enterotoxigenic Escherichia coli',
  ),
  const MedicalAbbreviation(
    abbreviation: 'fMET',
    expansion: 'N-formyl-methionine',
  ),
  const MedicalAbbreviation(
    abbreviation: 'GABA',
    expansion: 'γ-aminobutyric acid',
  ),
  const MedicalAbbreviation(abbreviation: 'GI', expansion: 'gastrointestinal'),
  const MedicalAbbreviation(
    abbreviation: 'GTP',
    expansion: 'guanosine-5\'-triphosphate',
  ),
  const MedicalAbbreviation(abbreviation: 'GU', expansion: 'genitourinary'),
  const MedicalAbbreviation(
    abbreviation: 'HBsAg',
    expansion: 'hepatitis B surface antigen',
  ),
];

final List<NotesEntity> mnemonics = [
  NotesEntity(
    image: 'https://christian18.sirv.com/employees/face_690f9182255ea.pdf',
    title: 'NFPA Symbol',
  ),
  NotesEntity(
    image: 'https://christian18.sirv.com/employees/face_690f9182255ea.pdf',
    title: 'ISBT Blood Groups',
  ),
  NotesEntity(
    image: 'https://christian18.sirv.com/employees/face_690f9182255ea.pdf',
    title: 'Radial Immunodiffusion',
  ),
  NotesEntity(
    image: 'https://christian18.sirv.com/employees/face_690f9182255ea.pdf',
    title: 'DNA Viruses',
  ),
  NotesEntity(
    image: 'https://christian18.sirv.com/employees/face_690f9182255ea.pdf',
    title: 'Gram Positive Bacilli',
  ),
];

final List<PdfEntity> procedures = [
  PdfEntity(text: 'DAT'),
  PdfEntity(text: 'Blood Typing'),
  PdfEntity(text: 'Manual CBC'),
  PdfEntity(text: 'Manual RBC Count'),
  PdfEntity(text: 'Manual Platelet Count'),
  PdfEntity(text: 'Manual Crossmatching'),
  PdfEntity(text: 'Manual CBC'),
  PdfEntity(text: 'Manual RBC Count'),
];

final List<QuestionsEntityWidget> questions = [
  QuestionsEntityWidget(
    icon: Icons.question_answer_rounded,
    label: 'Question Bank',
    sub_label:
        'A comprehensive collection of board exam–style questions designed to cover all major topics, helping you practice, assess your understanding, and prepare effectively for the actual exam.',
    callback: (context) =>
        Navigator.pushNamed(context, '/onboarding-questions'),
  ),
  QuestionsEntityWidget(
    icon: Icons.edit_document,
    label: 'Mock Boards',
    sub_label:
        'Simulated board examinations designed to mirror the actual exam experience, helping you assess your readiness, build confidence, and identify areas that need improvement before the real test.',
    callback: (context) =>
        Navigator.pushNamed(context, '/onboarding-questions'),
  ),
  QuestionsEntityWidget(
    icon: Icons.emoji_events_sharp,
    label: 'Pre Boards',
    sub_label:
        'A final one-take comprehensive exam that simulates the actual board, available only once and unlocked 2 weeks before the scheduled board exam to help you gauge your ultimate readiness.',
    callback: (context) =>
        Navigator.pushNamed(context, '/onboarding-questions'),
  ),
];

final List<String> assets = [
  'Review each question carefully.',
  'Skip questions that are hard and come back to them if there’s still time.',
  'Manage your time wisely — don’t get stuck on one question.',
  'Focus throughout the exam and avoid distractions.',
];
final List<String> assets2 = [
  'General Passing Average: Minimum of 75% overall.',
  'Minimum Subject Score: You must not score below 50% in any major subject. One subject below 50% results in automatic failure.',
];

List<Widget> buildExamFooter({
  required VoidCallback onPrev,
  required VoidCallback onToggleModal,
  required VoidCallback? onNext,
  required bool isAnswered,
  required Color iconColor,
  double buttonWidth = 240,
  double buttonHeight = 50,
}) {
  return [
    IconButton(
      onPressed: onPrev,
      icon: Icon(Icons.arrow_back_ios, color: iconColor),
    ),
    ReusableButton(
      title: isAnswered ? 'ANSWERED' : 'UNANSWERED',
      onPressed: onToggleModal,
      width: buttonWidth,
      height: buttonHeight,
    ),
    IconButton(
      onPressed: onNext,
      icon: Icon(Icons.arrow_forward_ios, color: iconColor),
    ),
  ];
}

// Mock data for Top Achievians
final List<UserEntity> mockTopAchievians = [
  UserEntity(
    id: 1,
    firstName: 'Elijah',
    middleName: 'August',
    lastName: 'Gleason',
    university: 'Nienow - Willms University',
    purpose: 'MTLE',
    dateOfExamination: DateTime(2026, 2, 10),
    profileImage:
        'https://cdn.jsdelivr.net/gh/faker-js/assets-person-portrait/female/512/65.jpg',
  ),
  UserEntity(
    id: 2,
    firstName: 'Sarah',
    middleName: 'Marie',
    lastName: 'Johnson',
    university: 'University of California',
    purpose: 'MTLE',
    dateOfExamination: DateTime(2026, 3, 15),
    profileImage:
        'https://cdn.jsdelivr.net/gh/faker-js/assets-person-portrait/female/512/45.jpg',
  ),
  UserEntity(
    id: 3,
    firstName: 'Michael',
    middleName: 'James',
    lastName: 'Rodriguez',
    university: 'State University',
    purpose: 'MTLE',
    dateOfExamination: DateTime(2026, 4, 20),
    profileImage:
        'https://cdn.jsdelivr.net/gh/faker-js/assets-person-portrait/male/512/32.jpg',
  ),
  UserEntity(
    id: 4,
    firstName: 'Emily',
    middleName: 'Grace',
    lastName: 'Williams',
    university: 'Metro University',
    purpose: 'MTLE',
    dateOfExamination: DateTime(2026, 2, 28),
    profileImage:
        'https://cdn.jsdelivr.net/gh/faker-js/assets-person-portrait/female/512/78.jpg',
  ),
  UserEntity(
    id: 5,
    firstName: 'David',
    middleName: 'Paul',
    lastName: 'Brown',
    university: 'National University',
    purpose: 'MTLE',
    dateOfExamination: DateTime(2026, 5, 10),
    profileImage:
        'https://cdn.jsdelivr.net/gh/faker-js/assets-person-portrait/male/512/21.jpg',
  ),
  UserEntity(
    id: 6,
    firstName: 'Jessica',
    middleName: 'Ann',
    lastName: 'Davis',
    university: 'Coastal University',
    purpose: 'MTLE',
    dateOfExamination: DateTime(2026, 3, 5),
    profileImage:
        'https://cdn.jsdelivr.net/gh/faker-js/assets-person-portrait/female/512/89.jpg',
  ),
];

// Mock data for Top Streak Achievians (can be same or different)
final List<UserEntity> mockTopStreakAchievians = List.from(mockTopAchievians);
