import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ride_record.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('bike_speedometer.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          await db.execute(
              'ALTER TABLE ride_records ADD COLUMN memo TEXT');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
            CREATE TABLE ride_records (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                year INTEGER NOT NULL,
                month INTEGER NOT NULL,
                day INTEGER NOT NULL,
                totalDistance REAL NOT NULL,
                maxSpeed REAL NOT NULL,
                avgSpeed REAL NOT NULL,
                duration INTEGER NOT NULL,
                pathPoints TEXT NOT NULL,
                createdAt INTEGER NOT NULL,
                memo TEXT
            )
        ''');
  }

  Future<int> insertRecord(RideRecord record) async {
    final db = await database;
    return await db.insert('ride_records', record.toMap());
  }

  Future<void> updateMemo(int id, String memo) async {
    final db = await database;
    await db.update(
      'ride_records',
      {'memo': memo},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<RideRecord>> getAllRecords() async {
    final db = await database;
    final maps = await db.query('ride_records', orderBy: 'createdAt DESC');
    return maps.map((m) => RideRecord.fromMap(m)).toList();
  }

  Future<List<RideRecord>> getRecordsByDate(int year, int month, int day) async {
    final db = await database;
    final maps = await db.query(
      'ride_records',
      where: 'year = ? AND month = ? AND day = ?',
      whereArgs: [year, month, day],
      orderBy: 'createdAt ASC',
    );
    return maps.map((m) => RideRecord.fromMap(m)).toList();
  }

  Future<List<RideRecord>> getRecordsByMonth(int year, int month) async {
    final db = await database;
    final maps = await db.query(
      'ride_records',
      where: 'year = ? AND month = ?',
      whereArgs: [year, month],
      orderBy: 'createdAt ASC',
    );
    return maps.map((m) => RideRecord.fromMap(m)).toList();
  }

  Future<List<RideRecord>> getRecordsByYear(int year) async {
    final db = await database;
    final maps = await db.query(
      'ride_records',
      where: 'year = ?',
      whereArgs: [year],
      orderBy: 'createdAt ASC',
    );
    return maps.map((m) => RideRecord.fromMap(m)).toList();
  }

  Future<bool> insertRecordIfNotExists(RideRecord record) async {
    final db = await database;
    final existing = await db.query(
      'ride_records',
      where: 'createdAt = ?',
      whereArgs: [record.createdAt],
    );
    if (existing.isNotEmpty) return false;
    await db.insert('ride_records', record.toMap());
    return true;
  }

  Future<int> deleteRecord(int id) async {
    final db = await database;
    return await db.delete('ride_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllRecords() async {
    final db = await database;
    await db.delete('ride_records');
  }
}
