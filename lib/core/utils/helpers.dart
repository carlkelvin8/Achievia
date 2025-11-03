import 'package:achievia/domain/entities/examination_results_entity.dart';
import 'package:achievia/domain/entities/notes_entity.dart';
import 'package:achievia/domain/entities/pdf_entity.dart';
import 'package:achievia/domain/entities/reminders_entity.dart';
import 'package:flutter/material.dart';
import 'package:achievia/domain/entities/reminder_entity.dart';
import 'package:achievia/domain/entities/author_entity.dart';

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


final List<NotesEntity> notes = [
  NotesEntity(image: 'https://imgs.search.brave.com/vvOmHwq42yf8urfOjsQnnocDCOc_unxIiHgvw15HORw/rs:fit:500:0:1:0/g:ce/aHR0cDovL3d3dy53/cml0ZW9uLmNvb2wv/d3AtY29udGVudC91/cGxvYWRzLzIwMjEv/MDgvaVBhZFByb1dp/dGhOb3Rlc1BsdXNT/Y3JlZW5zaG90QW5k/UGVuY2lsOTAwLnBu/Zw', title: 'WBC anomalies'),
  NotesEntity(image: 'https://imgs.search.brave.com/vvOmHwq42yf8urfOjsQnnocDCOc_unxIiHgvw15HORw/rs:fit:500:0:1:0/g:ce/aHR0cDovL3d3dy53/cml0ZW9uLmNvb2wv/d3AtY29udGVudC91/cGxvYWRzLzIwMjEv/MDgvaVBhZFByb1dp/dGhOb3Rlc1BsdXNT/Y3JlZW5zaG90QW5k/UGVuY2lsOTAwLnBu/Zw', title: 'Transfusion Reactions'),
  NotesEntity(image: 'https://imgs.search.brave.com/vvOmHwq42yf8urfOjsQnnocDCOc_unxIiHgvw15HORw/rs:fit:500:0:1:0/g:ce/aHR0cDovL3d3dy53/cml0ZW9uLmNvb2wv/d3AtY29udGVudC91/cGxvYWRzLzIwMjEv/MDgvaVBhZFByb1dp/dGhOb3Rlc1BsdXNT/Y3JlZW5zaG90QW5k/UGVuY2lsOTAwLnBu/Zw', title: ' Protozoans'),
];


final List<NotesEntity> notes2 = [
  NotesEntity(image: 'https://imgs.search.brave.com/vvOmHwq42yf8urfOjsQnnocDCOc_unxIiHgvw15HORw/rs:fit:500:0:1:0/g:ce/aHR0cDovL3d3dy53/cml0ZW9uLmNvb2wv/d3AtY29udGVudC91/cGxvYWRzLzIwMjEv/MDgvaVBhZFByb1dp/dGhOb3Rlc1BsdXNT/Y3JlZW5zaG90QW5k/UGVuY2lsOTAwLnBu/Zw', title: ' Crystals in urine'),
];
