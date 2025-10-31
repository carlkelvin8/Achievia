import 'package:achievia/domain/entities/examination_results_entity.dart';
import 'package:achievia/domain/entities/pdf_entity.dart';
import 'package:achievia/domain/entities/reminders_entity.dart';
import 'package:flutter/material.dart';
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

// Demo data for Progress screen
const List<ProgressEntity> demoProgressItems = [
  ProgressEntity(
    title: 'Hematology topic 1',
    subtitle: 'Page 1 - page 32',
    dueDateLabel: 'July 6, 2025',
    progress: 0.1,
  ),
  ProgressEntity(
    title: 'Parasitology Lecture',
    subtitle: 'Study protozoans until nematodes',
    dueDateLabel: 'July 7, 2025',
    progress: 0.45,
  ),
  ProgressEntity(
    title: 'DAT Procedure',
    subtitle: 'Need to memorize every reagents and measurement',
    dueDateLabel: 'July 9, 2025',
    progress: 0.0,
  ),
];
