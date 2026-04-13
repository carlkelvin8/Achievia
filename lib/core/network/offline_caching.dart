import 'dart:convert';
import 'package:achievia/data/models/quiz/questions_dto.dart';
import 'package:achievia/data/models/quiz/qotd_dto.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:injectable/injectable.dart';

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

  // DELETE old DB (dev only)
  await deleteDatabase(path); // <- ensures fresh DB is created

  return await openDatabase(
    path,
    version: 2,
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
        questions: map['questions'] != null ? List<Map<String, dynamic>>.from(jsonDecode(map['questions'])) : null,
      );
    }).toList();
  }
}
