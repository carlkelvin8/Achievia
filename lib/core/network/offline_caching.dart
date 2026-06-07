import 'dart:convert';

import 'package:achievia/data/models/quiz/qotd_dto.dart';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:achievia/data/models/quiz/quiz_dto.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

@lazySingleton
@injectable
class OfflineCaching {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'cache.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        // Create Questions table
        await db.execute('''
        CREATE TABLE questions (
          id INTEGER PRIMARY KEY,
          title TEXT,
          courseId INTEGER,
          description TEXT,
          image TEXT,
          day_subject TEXT,
          createdAt TEXT
        )
      ''');
        // Create QOTD table
        await db.execute('''
        CREATE TABLE qotd (
          id INTEGER PRIMARY KEY,
          quizId INTEGER,
          questionText TEXT,
          choices TEXT,
          questions TEXT,
          title TEXT
        )
      ''');
        // Create Quiz table
        await db.execute('''
        CREATE TABLE quiz (
          id INTEGER PRIMARY KEY,
          title TEXT,
          description TEXT,
          createdAt TEXT,
          subjectId INTEGER,
          questions TEXT
        )
      ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
          CREATE TABLE qotd (
            id INTEGER PRIMARY KEY,
            quizId INTEGER,
            questionText TEXT,
            choices TEXT,
            questions TEXT,
            title TEXT
          )
        ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
          CREATE TABLE quiz (
            id INTEGER PRIMARY KEY,
            title TEXT,
            description TEXT,
            createdAt TEXT,
            subjectId INTEGER,
            questions TEXT
          )
        ''');
        }
      },
    );
  }

  // ---------------- QuestionsDto caching ----------------
  Future<void> insertQuestionsToCache(List<QuestionsDto> dto) async {
    final db = await database;
    Batch batch = db.batch();
    for (var item in dto) {
      batch.insert(
        'questions',
        item.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<QuestionsDto>> getQuestionsFromCache() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('questions');
    return maps.map((map) => QuestionsDto.fromJson(map)).toList();
  }

  // ---------------- QotdDto caching ----------------
  Future<void> insertQotdToCache(List<QotdDto> dto) async {
    final db = await database;
    Batch batch = db.batch();
    for (var item in dto) {
      batch.insert(
        'qotd',
        item.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<QotdDto>> getQotdFromCache() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('qotd');
    return maps.map((map) {
      return QotdDto(
        title: (map['title'] ?? '').toString(),
        id: map['id'],
        quizId: map['quizId'],
        questionText: map['questionText'],
        choices: List<Map<String, dynamic>>.from(jsonDecode(map['choices'])),
        questions: map['questions'] != null
            ? List<Map<String, dynamic>>.from(jsonDecode(map['questions']))
            : null,
      );
    }).toList();
  }

  // ---------------- QuizDto caching ----------------
  Future<void> insertQuizToCache(List<QuizDtoItems> items) async {
    final db = await database;
    Batch batch = db.batch();
    for (var item in items) {
      batch.insert(
        'quiz',
        item.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> replaceGeneratedMockboardCache({
    required List<QuestionsDto> questions,
    required List<QuizDtoItems> quizItems,
  }) async {
    final db = await database;
    final batch = db.batch()
      ..delete('questions')
      ..delete('quiz');

    for (final question in questions) {
      batch.insert(
        'questions',
        question.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    for (final quizItem in quizItems) {
      batch.insert(
        'quiz',
        quizItem.toSqliteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<QuizDtoItems>> getQuizFromCache() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('quiz');
    return maps.map((map) {
      final questions = List<Map<String, dynamic>>.from(
        jsonDecode(map['questions']),
      );
      return QuizDtoItems(
        id: map['id'] as int,
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        createdAt: map['createdAt'] ?? '',
        subjectId: map['subjectId'] as int,
        questions: questions
            .map(
              (q) => QuestionsItemsDto(
                id: q['id'] as int,
                questionText: q['questionText'] ?? '',
                choices: (q['choices'] as List<dynamic>)
                    .map(
                      (c) => ChoicesDto.fromJson(Map<String, dynamic>.from(c)),
                    )
                    .toList(),
              ),
            )
            .toList(),
      );
    }).toList();
  }
}
