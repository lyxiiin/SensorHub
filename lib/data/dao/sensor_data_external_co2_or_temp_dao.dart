import 'package:sensor_hub/data/models/sensor_data_subclasses/sensor_data_external_co2_or_temp.dart';
import 'package:sqflite/sqflite.dart';
import '../services/sqlite_service.dart';

class SensorDataExternalCo2OrTempDao {
  static final SensorDataExternalCo2OrTempDao _instance = SensorDataExternalCo2OrTempDao._internal();
  factory SensorDataExternalCo2OrTempDao() => _instance;
  SensorDataExternalCo2OrTempDao._internal();

  Future<Database> get db async => SqliteService().database;

  Future<void> createTable(String tableName) async {
    final db = await this.db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        config_id INTEGER NOT NULL,
        datetime INTEGER NOT NULL,
        temperature INTEGER NOT NULL,
        humidity INTEGER NOT NULL,
        externalCo2 INTEGER NOT NULL,
        externalTemperature INTEGER NOT NULL
      );
    ''');
  }

  Future<int> insert(String tableName, SensorDataExternalCo2OrTemp data) async {
    final db = await this.db;
    return await db.insert(tableName, data.toMap());
  }

  Future<List<SensorDataExternalCo2OrTemp>> queryAll(String tableName) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((e) => SensorDataExternalCo2OrTemp.fromMap(e)).toList();
  }

  Future<List<SensorDataExternalCo2OrTemp>> queryByTimeRange(
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
    return maps.map((e) => SensorDataExternalCo2OrTemp.fromMap(e)).toList();
  }
}