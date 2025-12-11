import 'package:sqflite/sqflite.dart';
import '../models/qing_ping_sensor.dart';
import '../services/sqlite_service.dart';

class QingPingSensorDao {
  Future<Database> get db async => SqliteService().database;

  Future<int> insert(QingPingSensor sensor) async {
    final db = await this.db;
    return await db.insert('QingPingSensor', sensor.toMap());
  }

  Future<List<QingPingSensor>> getAll() async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query('QingPingSensor');
    return maps.map((e) => QingPingSensor.fromMap(e)).toList();
  }

  Future<QingPingSensor?> getById(int id) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps =
    await db.query('QingPingSensor', where: 'config_id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return QingPingSensor.fromMap(maps.first);
    }
    return null;
  }

  Future<QingPingSensor?> getByDeviceId(String deviceId) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db
        .query('QingPingSensor', where: 'device_id = ?', whereArgs: [deviceId]);
    if (maps.isNotEmpty) {
      return QingPingSensor.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(QingPingSensor sensor) async {
    final db = await this.db;
    return await db.update(
      'QingPingSensor',
      sensor.toMap(),
      where: 'id = ?',
      whereArgs: [sensor.configId],
    );
  }

  Future<int> delete(int id) async {
    final db = await this.db;
    return await db.delete('QingPingSensor', where: 'id = ?', whereArgs: [id]);
  }
}