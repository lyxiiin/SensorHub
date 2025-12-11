import 'package:sqflite/sqflite.dart';
import '../models/sensor_reading.dart';
import '../services/sqlite_service.dart';

class SensorReadingDao {
  Future<Database> get db async => SqliteService().database;

  Future<void> createTable(String tableName) async {
    final db = await this.db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        config_id TEXT NOT NULL,
        name TEXT NOT NULL,
        datetime INTEGER NOT NULL,
        temp INTEGER NOT NULL,
        humidity INTEGER NOT NULL,
        co2 INTEGER NOT NULL
      )
    ''');
  }

  Future<int> insert(String tableName, SensorReading reading) async {
    final db = await this.db;
    return await db.insert(tableName, reading.toMap());
  }

  Future<List<SensorReading>> queryAll(String tableName) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((e) => SensorReading.fromMap(e)).toList();
  }

  Future<List<SensorReading>> queryByTimeRange(
      String tableName,
      int startTime,
      int endTime,
      ) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(
      tableName,
      where: 'datetime BETWEEN ? AND ?',
      whereArgs: [startTime, endTime],
    );
    return maps.map((e) => SensorReading.fromMap(e)).toList();
  }
}