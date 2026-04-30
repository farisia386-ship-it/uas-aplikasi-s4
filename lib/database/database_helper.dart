import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/taks.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'taskmate.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        deadline TEXT NOT NULL,
        isCompleted INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertTask(Task task) async {
    Database db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasks() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      orderBy: 'deadline ASC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<List<Task>> getTasksByCategory(String category) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tasks',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'deadline ASC',
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<int> updateTask(Task task) async {
    Database db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    Database db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}