import 'package:sensor_hub/data/models/qingping_sensor_state.dart';
import 'package:sensor_hub/data/models/sensor_data_subclasses/sensor_data_co2.dart';
import 'package:sqflite/sqflite.dart';
import '../services/sqlite_service.dart';

class QingPingSensorStateDao {
  static final QingPingSensorStateDao _instance = QingPingSensorStateDao._internal();
  factory QingPingSensorStateDao() => _instance;
  QingPingSensorStateDao._internal();

  Future<Database> get db async => SqliteService().database;

  Future<void> createTable(String tableName) async {
    final db = await this.db;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableName(
        config_id INTEGER NOT NULL,
        usbInsert INTEGER NOT NULL,
        batteryLevel INTEGER NOT NULL,
        signalStrength INTEGER NOT NULL,
        voltage INTEGER NOT NULL,
        networkType INTEGER NOT NULL,
        datetime INTEGER NOT NULL,
        uptime INTEGER NOT NULL
      );
    ''');
  }

  Future<int> deleteTable(String tableName) async {
    final db = await this.db;
    return await db.delete(tableName);
  }


  Future<int> insert(String tableName, QingPingSensorState data) async {
    final db = await this.db;
    return await db.insert(tableName, data.toMap());
  }

  Future<List<QingPingSensorState>> queryAll(String tableName) async {
    final db = await this.db;
    final List<Map<String, dynamic>> maps = await db.query(tableName);
    return maps.map((e) => QingPingSensorState.fromMap(e)).toList();
  }

}