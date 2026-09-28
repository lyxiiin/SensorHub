import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sensor_hub/utils/app_logger.dart';

/// SQLite 不支持 ADD CONSTRAINT：
/// 给已有表加外键只能：RENAME 旧表 → 建新表 → INSERT...SELECT 搬数据 → DROP 旧表。
/// 所有结构性变更必须走 [_onUpgrade] 的版本化增量步骤，且 onCreate/onUpgrade
/// 两条路径的最终 schema 必须一致。
class SqliteService {
  static final SqliteService _instance = SqliteService._internal();

  factory SqliteService() => _instance;

  SqliteService._internal();

  static const int _databaseVersion = 5;

  /// 缓存初始化 Future：并发首次调用只初始化一次；失败时清除缓存以便重试
  static Future<Database>? _databaseFuture;

  Future<Database> get database {
    final cached = _databaseFuture;
    if (cached != null) return cached;
    final future = _initDatabase();
    _databaseFuture = future;
    future.then(
      (_) {},
      onError: (Object _, StackTrace _) {
        if (identical(_databaseFuture, future)) _databaseFuture = null;
      },
    );
    return future;
  }

  Future<Database> _initDatabase() async {
    // 获取应用文档目录（安全、可写）
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = join(directory.path, 'sensor_hub_database.db');
    logI('数据库初始化: $dbPath', tag: 'DB');
    await _backupBeforeUpgrade(dbPath);
    return _openDatabase(dbPath);
  }

  /// 按当前版本打开数据库并启用外键；生产与迁移测试共用同一套回调
  Future<Database> _openDatabase(String dbPath) async {
    final db = await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      // 显式声明：降级（安装旧版 App）时删库重建
      onDowngrade: onDatabaseDowngradeDelete,
    );
    // 外键必须在 openDatabase 之后启用：onUpgrade 在事务内执行，PRAGMA 在事务内是 no-op
    await db.execute('PRAGMA foreign_keys = ON');
    return db;
  }

  /// 仅供迁移测试：在任意路径以与生产完全相同的逻辑打开数据库
  Future<Database> openForTest(String dbPath) => _openDatabase(dbPath);

  /// 升级前备份旧库文件（全新安装 / 已是最新版本时跳过）
  Future<void> _backupBeforeUpgrade(String dbPath) async {
    final file = File(dbPath);
    if (!await file.exists()) return;
    final diskVersion = await _peekUserVersion(dbPath);
    if (diskVersion <= 0 || diskVersion >= _databaseVersion) return;
    final backupPath = '$dbPath.v$diskVersion.bak';
    try {
      await file.copy(backupPath);
      logI('升级前备份: $backupPath', tag: 'DB');
    } catch (e) {
      // 备份失败不阻塞启动，仅告警
      logW('升级前备份失败: $e', tag: 'DB');
    }
  }

  /// 只读探测磁盘库文件的 user_version（不带 version 打开，不触发迁移回调）
  Future<int> _peekUserVersion(String dbPath) async {
    final db = await openDatabase(dbPath);
    try {
      final rows = await db.rawQuery('PRAGMA user_version');
      return (rows.first['user_version'] as int?) ?? 0;
    } finally {
      await db.close();
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    logI('创建数据库表 (v$version)', tag: 'DB');
    // 设备分组表（父表，必须先于 device_configs 创建，保证外键引用目标存在）
    await db.execute('''
      CREATE TABLE IF NOT EXISTS device_group (
        groupId   INTEGER PRIMARY KEY AUTOINCREMENT,
        groupName TEXT    NOT NULL UNIQUE,
        sortOrder INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS device_configs (
        configId INTEGER PRIMARY KEY AUTOINCREMENT,
        deviceName TEXT NOT NULL,
        broker TEXT NOT NULL,
        port INTEGER NOT NULL,
        clientId TEXT NOT NULL,
        upTopic TEXT NOT NULL,
        downTopic TEXT NOT NULL,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        macAddress TEXT NOT NULL,
        groupId INTEGER REFERENCES device_group(groupId) ON DELETE SET NULL
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
        datetime INTEGER NOT NULL,
        FOREIGN KEY (configId) REFERENCES device_configs(configId) ON DELETE CASCADE
      );
    ''');
    // 时序数据表（窄表）
    await db.execute('''
      CREATE TABLE measurements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        config_id INTEGER NOT NULL,
        sensor_type TEXT NOT NULL,
        value INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        FOREIGN KEY (config_id) REFERENCES device_configs(configId) ON DELETE CASCADE
      );
    ''');

    // 为常用查询创建索引
    await db.execute('''
      CREATE INDEX idx_measurements_config_type_time
        ON measurements(config_id, sensor_type, timestamp);
    ''');

    // 设备最新快照表
    await db.execute('''
      CREATE TABLE device_latest (
        config_id INTEGER NOT NULL,
        sensor_type TEXT NOT NULL,
        value INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        PRIMARY KEY (config_id, sensor_type),
        FOREIGN KEY (config_id) REFERENCES device_configs(configId) ON DELETE CASCADE
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
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE device_configs ADD COLUMN macAddress TEXT NOT NULL DEFAULT '';
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS device_group (
          groupId   INTEGER PRIMARY KEY AUTOINCREMENT,
          groupName TEXT    NOT NULL UNIQUE,
          sortOrder INTEGER NOT NULL DEFAULT 0, 
          createdAt INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        ALTER TABLE device_configs
          ADD COLUMN groupId INTEGER REFERENCES device_group(groupId) ON DELETE SET NULL;
      ''');

      await db.execute(
        'DELETE FROM notification_messages WHERE configId NOT IN (SELECT configId FROM device_configs)',
      );
      await db.execute(
        'DELETE FROM measurements WHERE config_id NOT IN (SELECT configId FROM device_configs)',
      );
      await db.execute(
        'DELETE FROM device_latest WHERE config_id NOT IN (SELECT configId FROM device_configs)',
      );

      await db.execute(
        'ALTER TABLE notification_messages RENAME TO notification_messages_old',
      );
      await db.execute('''
    CREATE TABLE notification_messages (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      configId   INTEGER NOT NULL,
      severity   INTEGER NOT NULL,
      sensorName TEXT    NOT NULL,
      sensorType INTEGER NOT NULL,
      value      INTEGER NOT NULL,
      datetime   INTEGER NOT NULL,
      FOREIGN KEY (configId) REFERENCES device_configs(configId) ON DELETE CASCADE
    );
  ''');
      await db.execute('''
    INSERT INTO notification_messages
      (id, configId, severity, sensorName, sensorType, value, datetime)
    SELECT id, configId, severity, sensorName, sensorType, value, datetime
      FROM notification_messages_old;
  ''');
      await db.execute('DROP TABLE notification_messages_old');

      // 4b. measurements —— 注意先删索引：RENAME 后索引名不变，直接建新索引会撞名！
      await db.execute(
        'DROP INDEX IF EXISTS idx_measurements_config_type_time',
      );
      await db.execute('ALTER TABLE measurements RENAME TO measurements_old');
      await db.execute('''
    CREATE TABLE measurements (
      id          INTEGER PRIMARY KEY AUTOINCREMENT,
      config_id   INTEGER NOT NULL,
      sensor_type TEXT    NOT NULL,
      value       INTEGER NOT NULL,
      timestamp   INTEGER NOT NULL,
      FOREIGN KEY (config_id) REFERENCES device_configs(configId) ON DELETE CASCADE
    );
  ''');
      await db.execute('''
    INSERT INTO measurements (id, config_id, sensor_type, value, timestamp)
    SELECT id, config_id, sensor_type, value, timestamp FROM measurements_old;
  ''');
      await db.execute('DROP TABLE measurements_old');
      await db.execute('''
    CREATE INDEX idx_measurements_config_type_time
      ON measurements(config_id, sensor_type, timestamp);
  ''');

      // 4c. device_latest（复合主键，无独立索引）
      await db.execute('ALTER TABLE device_latest RENAME TO device_latest_old');
      await db.execute('''
    CREATE TABLE device_latest (
      config_id   INTEGER NOT NULL,
      sensor_type TEXT    NOT NULL,
      value       INTEGER NOT NULL,
      timestamp   INTEGER NOT NULL,
      PRIMARY KEY (config_id, sensor_type),
      FOREIGN KEY (config_id) REFERENCES device_configs(configId) ON DELETE CASCADE
    );
  ''');
      await db.execute('''
    INSERT INTO device_latest (config_id, sensor_type, value, timestamp)
    SELECT config_id, sensor_type, value, timestamp FROM device_latest_old;
  ''');
      await db.execute('DROP TABLE device_latest_old');

      // 迁移自检，发现违规直接抛错 → 整个升级回滚
      final violations = await db.rawQuery('PRAGMA foreign_key_check');
      if (violations.isNotEmpty) {
        // sqflite 的 DatabaseException 是抽象类，不能直接实例化
        throw Exception('外键迁移自检失败: $violations');
      }
    }
    if (oldVersion < 5) {
      // v5：分组管理功能上线，sortOrder 成为权威排序依据。
      //
      // v4 的 onCreate/onUpgrade 建 device_group 时已带 sortOrder，
      // 但不能排除历史开发版装出的"v4 无 sortOrder"库
      // （迁移测试里就构造了这样一种）。
      // SQLite 的 ALTER ADD COLUMN 没有 IF NOT EXISTS，
      // 所以先查 table_info 再决定是否补列。
      //
      // 老行回填默认 0：全 0 时 getAll 的 orderBy 退化为按 groupId 排，
      // 与补列前的展示顺序一致，用户无感知。
      final columns = await db.rawQuery('PRAGMA table_info(device_group)');
      final hasSortOrder = columns.any((c) => c['name'] == 'sortOrder');
      if (!hasSortOrder) {
        await db.execute(
          'ALTER TABLE device_group ADD COLUMN sortOrder INTEGER NOT NULL DEFAULT 0',
        );
      }
    }
  }
}
