import 'package:sensor_hub/data/models/sensor_data_subclasses/sensor_data_co2.dart';
import 'package:sqflite/sqflite.dart';
import '../services/sqlite_service.dart';

class SensorDataCo2Dao {
  static final SensorDataCo2Dao _instance = SensorDataCo2Dao._internal();
  factory SensorDataCo2Dao() => _instance;
  SensorDataCo2Dao._internal();

  Future<Database> get db async => SqliteService().database;

  Future<void> createTable(String tableName) async {
    final db = await this.db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        config_id INTEGER NOT NULL,
        datetime INTEGER NOT NULL,
        temperature INTEGER NOT NULL,
        humidity INTEGER NOT NULL,
        co2 INTEGER NOT NULL
      );
    ''');
  }
  Future<int> deleteTable(String tableName) async {
    final db = await this.db;
    return await db.delete(tableName);

  }

  Future<int> insert(String tableName, SensorDataCo2 data) async {
    final db = await this.db;
    return await db.insert(tableName, data.toMap());
  }

  Future<List<SensorDataCo2>> queryAll(String tableName) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((e) => SensorDataCo2.fromMap(e)).toList();
  }

  Future<List<SensorDataCo2>> queryByTimeRange(
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
    return maps.map((e) => SensorDataCo2.fromMap(e)).toList();
  }
}