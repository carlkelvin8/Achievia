import 'package:achievia/data/models/quiz/questions_dto.dart';
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

  return await openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
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
    },
  );
}

Future<void> insertDataToCache(List<QuestionsDto> dto)async{
  final db = await database;
  Batch batch = db.batch();
  for (var index in dto) {
    batch.insert('questions' , index.toJson(),conflictAlgorithm: ConflictAlgorithm.replace);
  }

  await batch.commit();
}

Future<List<QuestionsDto>> getDataFromCache()async{
  final db = await database;
  final List<Map<String,dynamic>> maps = await db.query('questions');
  return List.generate(maps.length, (i){
    return QuestionsDto.fromJson(maps[i]);
  });
}

}

