import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sensor_hub/utils/app_logger.dart';

class SqliteService {
  static final SqliteService _instance = SqliteService._internal();
  factory SqliteService() => _instance;
  SqliteService._internal();
  static Database? _database;

  Future<Database> get database async {
    if(_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // 获取应用文档目录（安全、可写）
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = join(directory.path, 'sensor_hub_database.db');
    logI('数据库初始化: $dbPath', tag: 'DB');
    return await openDatabase(
      dbPath,
      version: 2,
      onCreate:_onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  Future<void> _onCreate(Database db, int version) async {
    logI('创建数据库表 (v$version)', tag: 'DB');
    await db.execute('''
      CREATE TABLE device_configs (
        configId INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceName TEXT NOT NULL,
        broker TEXT NOT NULL,
        port INTEGER NOT NULL,
        clientId TEXT NOT NULL,
        upTopic TEXT NOT NULL,
        downTopic TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE notification_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        configId INTEGER NOT NULL,
        severity INTEGER NOT NULL,
        sensorName TEXT NOT NULL,
        sensorType INTEGER NOT NULL,
        value INTEGER NOT NULL,
        datetime INTEGER NOT NULL
      );
    ''');
    // 时序数据表（窄表）
    db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        config_id INTEGER NOT NULL,
        sensor_type TEXT NOT NULL,
        value INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      );
    ''');

    // 为常用查询创建索引
    db.execute('''
      CREATE INDEX idx_measurements_config_type_time
        ON measurements(config_id, sensor_type, timestamp);
    ''');

    // 设备最新快照表
    db.execute('''
      CREATE TABLE device_latest (
        config_id INTEGER NOT NULL,
        sensor_type TEXT NOT NULL,
        value INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        PRIMARY KEY (config_id, sensor_type)
      );
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    logI('数据库升级: v$oldVersion -> v$newVersion', tag: 'DB');
    // 示例：如果未来要加新表或字段，可在此处理
    if (oldVersion < 2) {
      await db.execute('''
      CREATE TABLE IF NOT EXISTS measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        config_id INTEGER NOT NULL,
        sensor_type TEXT NOT NULL,
        value INTEGER NOT NULL,
        timestamp INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_measurements_config_type_time
        ON measurements(config_id, sensor_type, timestamp);
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS device_latest (
        config_id INTEGER NOT NULL,
        sensor_type TEXT NOT NULL,
        value INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        PRIMARY KEY (config_id, sensor_type)
      );
    ''');
    }
  }
}