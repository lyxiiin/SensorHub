import 'package:sensor_hub/data/models/sensor_channel.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sensor_hub/data/models/measurement.dart';
import 'package:sensor_hub/data/services/sqlite_service.dart';
import 'package:sensor_hub/utils/app_logger.dart';

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
        'sensor_channel':m.channel.name,
        'timestamp': m.timestamp,
        'value': m.value,
      });
      batch.rawInsert('''INSERT OR REPLACE INTO device_latest (config_id, sensor_type, sensor_channel, timestamp, value) VALUES (?, ?, ?, ?, ?)''',
        [m.configId, m.sensorType.name, m.channel.name, m.timestamp, m.value]);
    }
    try {
      await batch.commit(noResult: true);
      logD('批量写入 ${measurements.length} 条测量数据', tag: 'DAO');
    } catch (e) {
      logE('批量写入测量数据失败: $e', error: e, tag: 'DAO');
      rethrow;
    }
  }

  // 查询指定设备的历史数据
  Future<List<Measurement>> queryHistory({
    required int configId,
    required SensorKey key,
    int? startTime,
    int? endTime,
  }) async {
    final database = await db;
    // (物理量, 通道) 两维定位：同一物理量的不同通道是独立序列
    String where = 'config_id = ? AND sensor_type = ? AND sensor_channel = ?';
    List<dynamic> whereArgs = [configId, key.type.name, key.channel.name];
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
  Future<Map<SensorKey, Measurement>> queryLatest(int configId) async {
    final database = await db;
    final List<Map<String, dynamic>> maps = await database.query(
      'device_latest',
      where: 'config_id = ?',
      whereArgs: [configId],
    );
    final result = <SensorKey, Measurement>{};
    for (final map in maps){
       final m = Measurement.fromLatestMap(map);
       result[m.key] = m;
    }
    return result;
  }

  // SQL级别阈值查询，查询指定设备、指定传感器类型、指定数值范围
  Future<List<Measurement>> queryByThreshold({
    required int configId,
    required SensorKey key,
    int? maxValue,
    int? minValue
  }) async {
    final database = await db;
    // 同上：按 (物理量, 通道) 过滤，避免内外两路数据混在一起
    String where = 'config_id = ? AND sensor_type = ? AND sensor_channel = ?';
    List<dynamic> whereArgs = [configId, key.type.name, key.channel.name];
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