import 'package:sqflite/sqflite.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/models/sensor_type.dart';
import 'package:sensor_hub/data/services/sqlite_service.dart';

class MeasurementDao {
  static final MeasurementDao _instance = MeasurementDao._internal();
  factory MeasurementDao() => _instance;
  MeasurementDao._internal();

  Future<Database> get db async => SqliteService().database;

  // 单次写入多条数据
  Future insertBatch(List<Measurement> measurements) async {
    final database = await db;
    final batch = database.batch();

    for(final m in measurements){
      batch.insert('measurements', {
        'config_id': m.configId,
        'sensor_type': m.sensorType.name,
        'timestamp': m.timestamp,
        'value': m.value,
      });
      batch.rawInsert('''INSERT OR REPLACE INTO device_latest (config_id, sensor_type, timestamp, value) VALUES (?, ?, ?, ?)''',
        [m.configId, m.sensorType.name, m.timestamp, m.value]);
    }
    await batch.commit(noResult: true);
  }

  // 查询指定设备的历史数据
  Future<List<Measurement>> queryHistory({
    required int configId,
    required SensorType type,
    int? startTime,
    int? endTime,
  }) async {
    final database = await db;
    String where = 'config_id = ? AND sensor_type = ?';
    List<dynamic> whereArgs = [configId, type.name];
    if(startTime != null){
      where += ' AND timestamp >= ?';
      whereArgs.add(startTime);
    }
    if(endTime != null){
      where += ' AND timestamp <= ?';
      whereArgs.add(endTime);
    }

    final List<Map<String, dynamic>> maps = await database.query(
      'measurements',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp ASC',
    );
    return maps.map((e) => Measurement.fromMap(e)).toList();
  }

  // 查询指定设备最新值
  Future<Map<SensorType, Measurement>> queryLatest(int configId) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'device_latest',
      where: 'config_id = ?',
      whereArgs: [configId],
    );
    final result = <SensorType, Measurement>{};
    for (final map in maps){
       final m = Measurement.fromLatestMap(map);
       result[m.sensorType] = m;
    }
    return result;
  }

  // SQL级别阈值查询，查询指定设备、指定传感器类型、指定数值范围
  Future<List<Measurement>> queryByThreshold({
    required int configId,
    required SensorType type,
    int? maxValue,
    int? minValue
  }) async {
    final database = await db;
    String where = 'config_id = ? AND sensor_type = ?';
    List<dynamic> whereArgs = [configId,type.name];
    if (maxValue != null){
      where += ' AND value <= ?';
      whereArgs.add(maxValue);
    }
    if (minValue != null){
      where += ' AND value >= ?';
      whereArgs.add(minValue);
    }
    final List<Map<String, dynamic>> maps = await database.query(
      'measurements',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: 100,
    );
    return maps.map((e) => Measurement.fromMap(e)).toList();
  }
}