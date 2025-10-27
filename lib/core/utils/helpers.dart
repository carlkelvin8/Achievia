import 'package:achievia/domain/entities/examination_results_entity.dart';
import 'package:achievia/domain/entities/reminders_entity.dart';
import 'package:flutter/material.dart';

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