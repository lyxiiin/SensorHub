import 'package:sqflite/sqflite.dart';
import '../models/sensor_data_subclasses/sensor_data_atmos_pressure.dart';
import '../services/sqlite_service.dart';

class SensorDataAtmosPressureDao {
  static final SensorDataAtmosPressureDao _instance = SensorDataAtmosPressureDao._internal();
  factory SensorDataAtmosPressureDao() => _instance;
  SensorDataAtmosPressureDao._internal();

  Future<Database> get db async => SqliteService().database;

  Future<void> createTable(String tableName) async {
    final db = await this.db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        config_id INTEGER NOT NULL,
        datetime INTEGER NOT NULL,
        temperature INTEGER NOT NULL,
        humidity INTEGER NOT NULL,
        atmosPressure INTEGER NOT NULL
      );
    ''');
  }

  Future<int> insert(String tableName, SensorDataAtmosPressure data) async {
    final db = await this.db;
    return await db.insert(tableName, data.toMap());
  }

  Future<List<SensorDataAtmosPressure>> queryAll(String tableName) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((e) => SensorDataAtmosPressure.fromMap(e)).toList();
  }

  Future<List<SensorDataAtmosPressure>> queryByTimeRange(
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
    return maps.map((e) => SensorDataAtmosPressure.fromMap(e)).toList();
  }
}