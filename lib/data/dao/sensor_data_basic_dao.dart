import 'package:sensor_hub/data/models/sensor_data_subclasses/sensor_data_basic.dart';
import 'package:sensor_hub/data/services/sqlite_service.dart';
import 'package:sqflite/sqflite.dart';

class SensorDataBasicDao {
  static final SensorDataBasicDao _instance = SensorDataBasicDao._internal();
  factory SensorDataBasicDao() => _instance;
  SensorDataBasicDao._internal();

  Future<Database> get db async => SqliteService().database;

  Future<void> createTable(String tableName) async {
    final db = await this.db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        config_id INTEGER NOT NULL,
        datetime INTEGER NOT NULL,
        temperature INTEGER NOT NULL,
        humidity INTEGER NOT NULL,
      );
    ''');
  }

  Future<int> insert(String tableName, SensorDataBasic data) async {
    final db = await this.db;
    return await db.insert(tableName, data.toMap());
  }

  Future<List<SensorDataBasic>> queryAll(String tableName) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((e) => SensorDataBasic.fromMap(e)).toList();
  }

  Future<List<SensorDataBasic>> queryByTimeRange(
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
    return maps.map((e) => SensorDataBasic.fromMap(e)).toList();
  }
}