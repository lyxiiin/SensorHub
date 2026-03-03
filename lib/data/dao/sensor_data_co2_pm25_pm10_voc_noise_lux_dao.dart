import 'package:sensor_hub/data/models/sensor_data_subclasses/sensor_data_co2_pm25_pm10_voc_noise_lux.dart';
import 'package:sqflite/sqflite.dart';
import '../services/sqlite_service.dart';

class SensorDataCo2Pm25Pm10VocNoiseLuxDao {
  static final SensorDataCo2Pm25Pm10VocNoiseLuxDao _instance = SensorDataCo2Pm25Pm10VocNoiseLuxDao._internal();
  factory SensorDataCo2Pm25Pm10VocNoiseLuxDao() => _instance;
  SensorDataCo2Pm25Pm10VocNoiseLuxDao._internal();

  Future<Database> get db async => SqliteService().database;

  Future<void> createTable(String tableName) async {
    final db = await this.db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        config_id INTEGER NOT NULL,
        datetime INTEGER NOT NULL,
        temperature INTEGER NOT NULL,
        humidity INTEGER NOT NULL,
        co2 INTEGER NOT NULL,
        pm25 INTEGER NOT NULL,
        pm10 INTEGER NOT NULL,
        voc INTEGER NOT NULL,
        noise INTEGER NOT NULL,
        lux INTEGER NOT NULL
      );
    ''');
  }

  Future<int> insert(String tableName, SensorDataCo2Pm25Pm10VocNoiseLux data) async {
    final db = await this.db;
    return await db.insert(tableName, data.toMap());
  }

  Future<List<SensorDataCo2Pm25Pm10VocNoiseLux>> queryAll(String tableName) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((e) => SensorDataCo2Pm25Pm10VocNoiseLux.fromMap(e)).toList();
  }

  Future<List<SensorDataCo2Pm25Pm10VocNoiseLux>> queryByTimeRange(
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
    return maps.map((e) => SensorDataCo2Pm25Pm10VocNoiseLux.fromMap(e)).toList();
  }
}