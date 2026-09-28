import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sensor_hub/data/services/sqlite_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// 数据库迁移测试：在桌面端通过 sqflite_common_ffi 运行真实 SQLite，
/// 覆盖四条升级路径：全新安装（onCreate）、v1→v5、v3→v5、v4→v5。
///
/// Windows 运行要求：sqlite3.dll 所在目录需在 PATH 中
/// （例如 Python 安装目录下的 DLLs 目录）。
void main() {
  setUpAll(() {
    ffi.sqfliteFfiInit();
    databaseFactory = ffi.databaseFactoryFfi;
  });

  late Directory tempDir;
  final service = SqliteService();

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('sqlite_migration_test');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // 测试失败时数据库连接可能未关闭，忽略目录清理错误
    }
  });

  // ---------- 旧版 schema 构造（模拟历史版本安装） ----------

  // v1 的两张基础表：无外键、无 macAddress
  Future<void> createV1Tables(Database db) async {
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
      )
    ''');
    await db.execute('''
      CREATE TABLE notification_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        configId INTEGER NOT NULL,
        severity INTEGER NOT NULL,
        sensorName TEXT NOT NULL,
        sensorType INTEGER NOT NULL,
        value INTEGER NOT NULL,
        datetime INTEGER NOT NULL
      )
    ''');
  }

  Future<Database> createV1Database(String path) =>
      openDatabase(path, version: 1, onCreate: (db, _) => createV1Tables(db));

  Future<Database> createV3Database(String path) => openDatabase(
    path,
    version: 3,
    onCreate: (db, _) async {
      await createV1Tables(db);
      await db.execute(
        "ALTER TABLE device_configs ADD COLUMN macAddress TEXT NOT NULL DEFAULT ''",
      );
      await db.execute('''
            CREATE TABLE measurements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              config_id INTEGER NOT NULL,
              sensor_type TEXT NOT NULL,
              value INTEGER NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');
      await db.execute(
        'CREATE INDEX idx_measurements_config_type_time ON measurements(config_id, sensor_type, timestamp)',
      );
      await db.execute('''
            CREATE TABLE device_latest (
              config_id INTEGER NOT NULL,
              sensor_type TEXT NOT NULL,
              value INTEGER NOT NULL,
              timestamp INTEGER NOT NULL,
              PRIMARY KEY (config_id, sensor_type)
            )
          ''');
    },
  );

  // v4 的完整 schema：在 v3 基础上引入 device_group（无 sortOrder）和 groupId 外键
  Future<Database> createV4Database(String path) => openDatabase(
    path,
    version: 4,
    onCreate: (db, _) async {
      await db.execute('''
            CREATE TABLE device_group (
              groupId   INTEGER PRIMARY KEY AUTOINCREMENT,
              groupName TEXT    NOT NULL UNIQUE,
              createdAt INTEGER NOT NULL
            )
          ''');
      await createV1Tables(db);
      await db.execute(
        "ALTER TABLE device_configs ADD COLUMN macAddress TEXT NOT NULL DEFAULT ''",
      );
      await db.execute(
        'ALTER TABLE device_configs ADD COLUMN groupId INTEGER REFERENCES device_group(groupId) ON DELETE SET NULL',
      );
      await db.execute('''
            CREATE TABLE measurements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              config_id INTEGER NOT NULL,
              sensor_type TEXT NOT NULL,
              value INTEGER NOT NULL,
              timestamp INTEGER NOT NULL
            )
          ''');
      await db.execute(
        'CREATE INDEX idx_measurements_config_type_time ON measurements(config_id, sensor_type, timestamp)',
      );
      await db.execute('''
            CREATE TABLE device_latest (
              config_id INTEGER NOT NULL,
              sensor_type TEXT NOT NULL,
              value INTEGER NOT NULL,
              timestamp INTEGER NOT NULL,
              PRIMARY KEY (config_id, sensor_type)
            )
          ''');
    },
  );

  Map<String, Object?> configRow({
    required String clientId,
    bool mac = false,
    int? groupId,
  }) {
    final row = <String, Object?>{
      'deviceName': '设备$clientId',
      'broker': '127.0.0.1',
      'port': 1883,
      'clientId': clientId,
      'upTopic': 'up/$clientId',
      'downTopic': 'down/$clientId',
      'username': 'u',
      'password': 'p',
    };
    if (mac) row['macAddress'] = '';
    if (groupId != null) row['groupId'] = groupId;
    return row;
  }

  // 两台设备 + 一条正常消息 + 一条孤儿消息（configId=999 指向不存在的设备）
  Future<void> seedData(Database db, {bool mac = false}) async {
    await db.insert(
      'device_configs',
      configRow(clientId: 'client-a', mac: mac),
    );
    await db.insert(
      'device_configs',
      configRow(clientId: 'client-b', mac: mac),
    );
    await db.insert('notification_messages', {
      'configId': 1,
      'severity': 1,
      'sensorName': '温度',
      'sensorType': 1,
      'value': 30,
      'datetime': 1000,
    });
    await db.insert('notification_messages', {
      'configId': 999,
      'severity': 1,
      'sensorName': '孤儿',
      'sensorType': 1,
      'value': 0,
      'datetime': 1000,
    });
  }

  // ---------- 测试用例 ----------

  test('全新安装：v5 终态 schema 完整且外键生效', () async {
    final db = await service.openForTest(p.join(tempDir.path, 'fresh.db'));

    // 表齐全
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );
    expect(
      tables.map((r) => r['name']),
      containsAll([
        'device_group',
        'device_configs',
        'notification_messages',
        'measurements',
        'device_latest',
      ]),
    );

    // device_configs 带 groupId 列
    final cols = await db.rawQuery('PRAGMA table_info(device_configs)');
    expect(cols.map((c) => c['name']), contains('groupId'));

    // device_group 带 sortOrder 列
    final groupCols = await db.rawQuery('PRAGMA table_info(device_group)');
    expect(groupCols.map((c) => c['name']), contains('sortOrder'));

    // 三张子表都声明了指向 device_configs 的外键
    for (final table in [
      'notification_messages',
      'measurements',
      'device_latest',
    ]) {
      final fks = await db.rawQuery('PRAGMA foreign_key_list($table)');
      expect(fks, isNotEmpty, reason: '$table 缺少外键');
      expect(fks.first['table'], 'device_configs');
    }

    // 写入合法数据
    await db.insert('device_group', {'groupName': '客厅', 'createdAt': 1});
    final configId = await db.insert(
      'device_configs',
      configRow(clientId: 'client-a', mac: true, groupId: 1),
    );
    await db.insert('notification_messages', {
      'configId': configId,
      'severity': 1,
      'sensorName': '温度',
      'sensorType': 1,
      'value': 30,
      'datetime': 1000,
    });
    await db.insert('measurements', {
      'config_id': configId,
      'sensor_type': 'temperature',
      'value': 30,
      'timestamp': 1000,
    });
    await db.insert('device_latest', {
      'config_id': configId,
      'sensor_type': 'temperature',
      'value': 30,
      'timestamp': 1000,
    });

    // 外键约束生效：引用不存在的 configId 直接报错
    await expectLater(
      db.insert('notification_messages', {
        'configId': configId + 100,
        'severity': 1,
        'sensorName': 'x',
        'sensorType': 1,
        'value': 0,
        'datetime': 1,
      }),
      throwsA(isA<DatabaseException>()),
    );

    // SET NULL：删除分组，设备保留但 groupId 置空
    await db.delete('device_group');
    final config = await db.query(
      'device_configs',
      where: 'configId = ?',
      whereArgs: [configId],
    );
    expect(config.single['groupId'], isNull);

    // CASCADE：删除设备，消息/历史/快照全部自动清理
    await db.delete(
      'device_configs',
      where: 'configId = ?',
      whereArgs: [configId],
    );
    expect(await db.query('notification_messages'), isEmpty);
    expect(await db.query('measurements'), isEmpty);
    expect(await db.query('device_latest'), isEmpty);

    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    await db.close();
  });

  test('v1 → v5：数据保留、id 不变、孤儿清理、外键到位', () async {
    final path = p.join(tempDir.path, 'v1.db');
    final old = await createV1Database(path);
    await seedData(old);
    await old.close();

    final db = await service.openForTest(path); // 触发 1→5 增量迁移

    // 结构到位
    final cols = await db.rawQuery('PRAGMA table_info(device_configs)');
    expect(cols.map((c) => c['name']), containsAll(['macAddress', 'groupId']));
    final fks = await db.rawQuery(
      'PRAGMA foreign_key_list(notification_messages)',
    );
    expect(fks, isNotEmpty);

    // 数据保留且 id 不变，孤儿消息（configId=999）被清理
    final msgs = await db.query('notification_messages', orderBy: 'id');
    expect(msgs.length, 1);
    expect(msgs.first['id'], 1);
    expect(msgs.first['configId'], 1);

    final configs = await db.query('device_configs', orderBy: 'configId');
    expect(configs.map((c) => c['configId']), [1, 2]);
    expect(configs.first['macAddress'], '');

    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    await db.close();
  });

  test('v3 → v5：时序数据保留、外键重建、索引重建', () async {
    final path = p.join(tempDir.path, 'v3.db');
    final old = await createV3Database(path);
    await seedData(old, mac: true);
    await old.insert('measurements', {
      'config_id': 1,
      'sensor_type': 'temperature',
      'value': 25,
      'timestamp': 1,
    });
    await old.insert('measurements', {
      'config_id': 999, // 孤儿测量数据
      'sensor_type': 'temperature',
      'value': 0,
      'timestamp': 2,
    });
    await old.insert('device_latest', {
      'config_id': 1,
      'sensor_type': 'temperature',
      'value': 25,
      'timestamp': 1,
    });
    await old.close();

    final db = await service.openForTest(path); // 触发 3→5 增量迁移

    // 孤儿测量被清理，正常数据保留
    final ms = await db.query('measurements');
    expect(ms.length, 1);
    expect(ms.first['config_id'], 1);
    final dl = await db.query('device_latest');
    expect(dl.length, 1);
    expect(dl.first['config_id'], 1);

    // 重建表后外键和索引都存在
    final fks = await db.rawQuery('PRAGMA foreign_key_list(measurements)');
    expect(fks, isNotEmpty);
    final indexes = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='index'",
    );
    expect(
      indexes.map((r) => r['name']),
      contains('idx_measurements_config_type_time'),
    );

    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    await db.close();
  });

  test('v4 → v5：device_group 补齐 sortOrder，旧数据回填默认 0', () async {
    final path = p.join(tempDir.path, 'v4.db');
    final old = await createV4Database(path);
    final groupA = await old.insert(
      'device_group',
      {'groupName': '客厅', 'createdAt': 100},
    );
    await old.insert('device_group', {'groupName': '卧室', 'createdAt': 200});
    await old.close();

    final db = await service.openForTest(path); // 触发 4→5 增量迁移

    // 新列存在，旧行回填默认值 0，数据保留且 id 不变
    final cols = await db.rawQuery('PRAGMA table_info(device_group)');
    expect(cols.map((c) => c['name']), contains('sortOrder'));
    final groups = await db.query('device_group', orderBy: 'groupId');
    expect(groups.length, 2);
    expect(groups.first['groupId'], groupA);
    expect(groups.first['groupName'], '客厅');
    expect(groups.first['sortOrder'], 0);
    expect(groups.last['sortOrder'], 0);

    // 新写入缺省 sortOrder 时落在默认值 0
    await db.insert('device_group', {'groupName': '书房', 'createdAt': 300});
    final inserted = await db.query(
      'device_group',
      where: 'groupName = ?',
      whereArgs: ['书房'],
    );
    expect(inserted.single['sortOrder'], 0);

    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    await db.close();
  });
}
