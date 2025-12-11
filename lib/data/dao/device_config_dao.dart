import 'package:sqflite/sqflite.dart';

import '../models/device_config.dart';
import '../services/sqlite_service.dart';

class DeviceConfigDao {
  Future<Database> get db async => SqliteService().database;

  // 插入
  Future<int> insert(DeviceConfig config) async {
    final db = await this.db;
    return await db.insert('device_configs', config.toMap());
  }

  // 更新（根据 id）
  Future<int> update(DeviceConfig config) async {
    if (config.configId == null) throw ArgumentError('ID cannot be null for update');
    final db = await this.db;
    return await db.update(
      'device_configs',
      config.toMap(),
      where: 'configId = ?',
      whereArgs: [config.configId],
    );
  }

  // 删除
  Future<int> delete(int id) async {
    final db = await this.db;
    return await db.delete(
      'device_configs',
      where: 'configId = ?',
      whereArgs: [id],
    );
  }

  // 查询所有
  Future<List<DeviceConfig>> getAll() async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query('device_configs');
    return maps.map((e) => DeviceConfig.fromMap(e)).toList();
  }

  // 根据 ID 查询
  Future<DeviceConfig?> getById(int id) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(
      'device_configs',
      where: 'configId = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return DeviceConfig.fromMap(maps.first);
  }

  // 根据 clientId 查询（示例：唯一标识）
  Future<DeviceConfig?> getByClientId(String clientId) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(
      'device_configs',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );
    if (maps.isEmpty) return null;
    return DeviceConfig.fromMap(maps.first);
  }
}