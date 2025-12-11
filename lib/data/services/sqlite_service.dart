import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

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
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate:_onCreate,
      onUpgrade: _onUpgrade,
    );
  }
  Future<void> _onCreate(Database db, int version) async {
    //青萍设备表
    await db.execute('''
      CREATE TABLE QingPingSensor(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL,
        serial_number TEXT NOT NULL,
        collection_interval INTEGER NOT NULL,
        upload_interval INTEGER NOT NULL,
        firmware_version TEXT NOT NULL,
        hardware_version TEXT NOT NULL,
        comm_module_version TEXT NOT NULL,
        mcu_version TEXT NOT NULL,
        product_id TEXT NOT NULL,
        pm_sensor_sn TEXT NOT NULL,
        screen_type INTEGER NOT NULL,
        power_type INTEGER NOT NULL,
        wifi_support INTEGER NOT NULL,
        has_rs485 INTEGER NOT NULL,
        probe_type TEXT NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE device_configs (
        configId INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceName TEXT NOT NULL,
        broker TEXT NOT NULL,
        port INTEGER NOT NULL,
        clientId TEXT NOT NULL,
        topic TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL
      );
    ''');
  }
  // 青萍二氧化碳和温湿度监测仪 Wi-Fi 版
  Future<void> createDynamicTable(Database db, String tableName,) async {
    final buffer = StringBuffer('''
      CREATE TABLE $tableName(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        config_id TEXT NOT NULL,
        name TEXT NOT NULL,
        datetime INTEGER NOT NULL,
        temp INTEGER NOT NULL,
        humidity INTEGER NOT NULL,
        co2 INTEGER NOT NULL
      );
    ''');
    await db.execute(buffer.toString());
  }



  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 示例：如果未来要加新表或字段，可在此处理
    if (oldVersion < 2) {
      // await db.execute('ALTER TABLE ...');
    }
  }
}