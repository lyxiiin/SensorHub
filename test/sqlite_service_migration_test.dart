import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sensor_hub/data/services/sqlite_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// 数据库迁移测试：在桌面端通过 sqflite_common_ffi 运行真实 SQLite。
///
/// 五条路径最终都必须收敛到同一个 v6 终态（sensor_channel 重构，
/// 见 lib/doc/sensor_channel_refactor_plan.md §3 / §10.2）：
///   1. 全新安装（onCreate）
///   2. v5 → v6（本次重构新增的迁移步）
///   3. v1 → v6
///   4. v3 → v6
///   5. v4 → v6
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

  // ---------- v6 终态契约常量（方案 §3.1） ----------

  const int terminalVersion = 6;
  const String channelDefault = 'primary'; // 与 PRAGMA table_info 的 dflt_value 比较（去引号后）
  const String measurementIndex = 'idx_measurements_config_type_time';

  // ---------- PRAGMA 读取辅助 ----------

  /// PRAGMA table_info：列名 → 该列的元数据行（type / notnull / dflt_value / pk）
  Future<Map<String, Map<String, Object?>>> tableInfo(
    Database db,
    String table,
  ) async {
    final rows = await db.rawQuery('PRAGMA table_info($table)');
    return {
      for (final row in rows) row['name']! as String: row,
    };
  }

  /// PRAGMA index_info：按 seqno 排序后的索引列名
  Future<List<String>> indexColumns(Database db, String index) async {
    final rows = (await db.rawQuery('PRAGMA index_info($index)')).toList()
      ..sort((a, b) => (a['seqno']! as int).compareTo(b['seqno']! as int));
    return rows.map((r) => r['name']! as String).toList();
  }

  /// PRAGMA table_info 的 pk 序号：按主键顺序返回组成主键的列名
  Future<List<String>> primaryKeyColumns(Database db, String table) async {
    final columns = (await tableInfo(db, table)).values.toList()
      ..sort(
        (a, b) => ((a['pk'] as int?) ?? 0).compareTo((b['pk'] as int?) ?? 0),
      );
    return columns
        .where((c) => ((c['pk'] as int?) ?? 0) > 0)
        .map((c) => c['name']! as String)
        .toList();
  }

  /// dflt_value 形如 "'primary'"，去掉引号后比较默认值
  String? defaultOf(Map<String, Object?> column) =>
      (column['dflt_value'] as String?)?.replaceAll("'", '').trim();

  Future<int> userVersion(Database db) async =>
      ((await db.rawQuery('PRAGMA user_version')).single['user_version'] as int?) ??
      0;

  /// 断言数据库已处于 v6 终态：无论走 onCreate 还是哪条升级路径，结果必须一致。
  ///
  /// 覆盖方案 §10.2 要求的三件事：measurements / device_latest 都有 sensor_channel、
  /// device_latest 主键含 channel、历史查询索引含 channel（外加版本号与外键完整性）。
  Future<void> expectTerminalV6Schema(
    Database db, {
    required String origin,
  }) async {
    String at(String message) => '[$origin] $message';

    // 1) 版本号推进到 v6
    expect(await userVersion(db), terminalVersion, reason: at('user_version 不是 v6'));

    // 2) 五张表齐全，且迁移用的临时表已清理干净
    final tableNames = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    )).map((r) => r['name']).toList();
    expect(
      tableNames,
      containsAll([
        'device_group',
        'device_configs',
        'notification_messages',
        'measurements',
        'device_latest',
      ]),
      reason: at('缺少终态表'),
    );
    expect(tableNames, isNot(contains('measurements_old')), reason: at('临时表未清理'));
    expect(
      tableNames,
      isNot(contains('device_latest_old')),
      reason: at('临时表未清理'),
    );

    // 3) measurements.sensor_channel：TEXT NOT NULL DEFAULT 'primary'
    final measurementColumns = await tableInfo(db, 'measurements');
    final measurementChannel = measurementColumns['sensor_channel'];
    expect(
      measurementChannel,
      isNotNull,
      reason: at('measurements 缺少 sensor_channel 列'),
    );
    expect(
      measurementChannel!['type'],
      'TEXT',
      reason: at('measurements.sensor_channel 类型应为 TEXT'),
    );
    expect(
      measurementChannel['notnull'],
      1,
      reason: at('measurements.sensor_channel 应声明 NOT NULL'),
    );
    expect(
      defaultOf(measurementChannel),
      channelDefault,
      reason: at("measurements.sensor_channel 默认值应为 'primary'"),
    );

    // 4) device_latest.sensor_channel 同上
    final latestColumns = await tableInfo(db, 'device_latest');
    final latestChannel = latestColumns['sensor_channel'];
    expect(latestChannel, isNotNull, reason: at('device_latest 缺少 sensor_channel 列'));
    expect(
      latestChannel!['type'],
      'TEXT',
      reason: at('device_latest.sensor_channel 类型应为 TEXT'),
    );
    expect(
      latestChannel['notnull'],
      1,
      reason: at('device_latest.sensor_channel 应声明 NOT NULL'),
    );
    expect(
      defaultOf(latestChannel),
      channelDefault,
      reason: at("device_latest.sensor_channel 默认值应为 'primary'"),
    );

    // 5) device_latest 主键必须是 (config_id, sensor_type, sensor_channel)
    const expectedLatestPk = ['config_id', 'sensor_type', 'sensor_channel'];
    expect(
      await primaryKeyColumns(db, 'device_latest'),
      expectedLatestPk,
      reason: at('device_latest 主键应含 sensor_channel'),
    );
    final pkIndexes = (await db.rawQuery(
      'PRAGMA index_list(device_latest)',
    )).where((r) => r['origin'] == 'pk').toList();
    expect(pkIndexes, hasLength(1), reason: at('device_latest 主键索引缺失'));
    expect(
      await indexColumns(db, pkIndexes.single['name']! as String),
      expectedLatestPk,
      reason: at('device_latest 主键索引列应含 sensor_channel'),
    );

    // 6) 历史查询索引改为四列且没有残留同名旧索引
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index' AND name = ?",
        [measurementIndex],
      ),
      hasLength(1),
      reason: at('索引 $measurementIndex 数量异常'),
    );
    expect(
      await indexColumns(db, measurementIndex),
      ['config_id', 'sensor_type', 'sensor_channel', 'timestamp'],
      reason: at('索引 $measurementIndex 应包含 sensor_channel'),
    );

    // 7) v6 重建过的 device_latest 必须保留外键，且整库没有外键违规行。
    //
    //    这里只校验 device_latest：它在每条路径上都是被 v6 重建的，外键必然到位。
    //    measurements 走的是 ALTER ADD COLUMN（不重建表），外键由旧库原样带过来，
    //    例如 v4 fixture（沿用 v1 建表语句，本来没有外键）迁移后仍然没有外键，
    //    那是 v4 阶段遗留的状态、与 channel 重构无关，故交由各路径用例单独断言。
    final latestFks = await db.rawQuery('PRAGMA foreign_key_list(device_latest)');
    expect(latestFks, isNotEmpty, reason: at('device_latest 缺少外键'));
    expect(
      latestFks.first['table'],
      'device_configs',
      reason: at('device_latest 外键应指向 device_configs'),
    );
    expect(
      await db.rawQuery('PRAGMA foreign_key_check'),
      isEmpty,
      reason: at('存在外键违规行'),
    );
  }

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

  // v5 完整 schema：与 v6 的唯一差别是 measurements / device_latest 没有 sensor_channel
  // （device_latest 主键仍是 (config_id, sensor_type)，历史索引仍是三列）。
  Future<Database> createV5Database(String path) => openDatabase(
    path,
    version: 5,
    onCreate: (db, _) async {
      await db.execute('''
            CREATE TABLE device_group (
              groupId   INTEGER PRIMARY KEY AUTOINCREMENT,
              groupName TEXT    NOT NULL UNIQUE,
              sortOrder INTEGER NOT NULL DEFAULT 0,
              createdAt INTEGER NOT NULL
            )
          ''');
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
              password TEXT NOT NULL,
              macAddress TEXT NOT NULL DEFAULT '',
              groupId INTEGER REFERENCES device_group(groupId) ON DELETE SET NULL
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
              datetime INTEGER NOT NULL,
              FOREIGN KEY (configId) REFERENCES device_configs(configId) ON DELETE CASCADE
            )
          ''');
      await db.execute('''
            CREATE TABLE measurements (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              config_id INTEGER NOT NULL,
              sensor_type TEXT NOT NULL,
              value INTEGER NOT NULL,
              timestamp INTEGER NOT NULL,
              FOREIGN KEY (config_id) REFERENCES device_configs(configId) ON DELETE CASCADE
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
              PRIMARY KEY (config_id, sensor_type),
              FOREIGN KEY (config_id) REFERENCES device_configs(configId) ON DELETE CASCADE
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

  // v5 历史数据：两台设备 + temperature / humidity / co2 三类时序数据与最新快照
  Future<void> seedV5Data(Database db) async {
    await db.insert('device_configs', configRow(clientId: 'client-a', mac: true));
    await db.insert('device_configs', configRow(clientId: 'client-b', mac: true));
    final history = [
      {'config_id': 1, 'sensor_type': 'temperature', 'value': 2500, 'timestamp': 100},
      {'config_id': 1, 'sensor_type': 'humidity', 'value': 4000, 'timestamp': 100},
      {'config_id': 1, 'sensor_type': 'co2', 'value': 800, 'timestamp': 100},
      {'config_id': 2, 'sensor_type': 'temperature', 'value': 2300, 'timestamp': 120},
    ];
    for (final row in history) {
      await db.insert('measurements', row);
      await db.insert('device_latest', row);
    }
  }

  /// measurements / device_latest 行 → '<config_id>/<sensor_type>': sensor_channel
  Map<String, Object?> channelMap(List<Map<String, Object?>> rows) => {
    for (final row in rows)
      '${row['config_id']}/${row['sensor_type']}': row['sensor_channel'],
  };

  // ---------- 测试用例 ----------

  test('全新安装：v6 终态 schema（sensor_channel / 三列主键 / 四列索引）且外键生效', () async {
    final db = await service.openForTest(p.join(tempDir.path, 'fresh.db'));

    // 终态契约：版本号、表清单、channel 列、device_latest 主键、索引列、外键
    await expectTerminalV6Schema(db, origin: 'onCreate');

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

    // 写入合法数据：同一设备并行写入 external / internal 两个温度通道
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
    for (final row in [
      {'sensor_type': 'temperature', 'sensor_channel': 'external', 'value': 3000, 'timestamp': 1000},
      {'sensor_type': 'temperature', 'sensor_channel': 'internal', 'value': 3100, 'timestamp': 1100},
    ]) {
      await db.insert('measurements', {'config_id': configId, ...row});
      await db.insert('device_latest', {'config_id': configId, ...row});
    }

    // 默认值语义：不写 sensor_channel 的写入落在 primary（co2 这类单通道量走这里）
    await db.insert('device_latest', {
      'config_id': configId,
      'sensor_type': 'co2',
      'value': 800,
      'timestamp': 1200,
    });
    await db.insert('measurements', {
      'config_id': configId,
      'sensor_type': 'co2',
      'value': 800,
      'timestamp': 1200,
    });
    final co2Latest = await db.query(
      'device_latest',
      where: 'config_id = ? AND sensor_type = ?',
      whereArgs: [configId, 'co2'],
    );
    expect(co2Latest.single['sensor_channel'], 'primary');
    final co2Measurements = await db.query(
      'measurements',
      where: 'config_id = ? AND sensor_type = ?',
      whereArgs: [configId, 'co2'],
    );
    expect(co2Measurements.single['sensor_channel'], 'primary');

    // 主键含 channel：同 (config_id, sensor_type) 的两个通道可以共存
    final tempLatest = await db.query(
      'device_latest',
      where: 'config_id = ? AND sensor_type = ?',
      whereArgs: [configId, 'temperature'],
      orderBy: 'sensor_channel',
    );
    expect(tempLatest.map((r) => r['sensor_channel']), ['external', 'internal']);

    // 同 (config_id, sensor_type, sensor_channel) 重复写入被主键拒绝
    await expectLater(
      db.insert('device_latest', {
        'config_id': configId,
        'sensor_type': 'temperature',
        'sensor_channel': 'external',
        'value': 1,
        'timestamp': 2,
      }),
      throwsA(isA<DatabaseException>()),
    );

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

    // CASCADE：删除设备，消息/历史/快照（两个通道都在）全部自动清理
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

  test('v5 → v6：加列与主键扩展、旧温度/湿度归入 external、co2 保持 primary', () async {
    final path = p.join(tempDir.path, 'v5.db');
    final old = await createV5Database(path);
    await seedV5Data(old);

    // 预置库确实是 v5：无 sensor_channel 列、device_latest 主键两列、索引三列
    expect(await userVersion(old), 5);
    final oldMeasurementCols = (await old.rawQuery(
      'PRAGMA table_info(measurements)',
    )).map((c) => c['name']);
    expect(oldMeasurementCols, isNot(contains('sensor_channel')));
    final oldLatestCols = (await old.rawQuery(
      'PRAGMA table_info(device_latest)',
    )).map((c) => c['name']);
    expect(oldLatestCols, isNot(contains('sensor_channel')));
    expect(await primaryKeyColumns(old, 'device_latest'), [
      'config_id',
      'sensor_type',
    ]);
    expect(
      await indexColumns(old, measurementIndex),
      ['config_id', 'sensor_type', 'timestamp'],
    );
    await old.close();

    final db = await service.openForTest(path); // 触发 5→6 增量迁移

    // 终态契约：列 / 主键 / 索引 / 外键 / 版本号
    await expectTerminalV6Schema(db, origin: 'v5→v6');

    // v5 库本身带外键；measurements 走 ALTER ADD COLUMN（不重建表），外键必须原样保留
    final measurementFks = await db.rawQuery(
      'PRAGMA foreign_key_list(measurements)',
    );
    expect(measurementFks, isNotEmpty);
    expect(measurementFks.first['table'], 'device_configs');

    // 历史数据一条不丢
    final measurements = await db.query('measurements');
    expect(measurements, hasLength(4));
    expect(
      measurements.map((r) => r['value']),
      containsAll([2500, 4000, 800, 2300]),
    );

    // 通道归属（方案 §3.3 方案 A）：temperature / humidity → external，co2 保持 primary
    expect(channelMap(measurements), {
      '1/temperature': 'external',
      '1/humidity': 'external',
      '1/co2': 'primary',
      '2/temperature': 'external',
    });

    final latest = await db.query('device_latest');
    expect(latest, hasLength(4));
    expect(channelMap(latest), {
      '1/temperature': 'external',
      '1/humidity': 'external',
      '1/co2': 'primary',
      '2/temperature': 'external',
    });

    // 主键扩展后，同一 (config_id, sensor_type) 可同时保存 external 与 internal 两行
    await db.insert('device_latest', {
      'config_id': 1,
      'sensor_type': 'temperature',
      'sensor_channel': 'internal',
      'value': 2650,
      'timestamp': 200,
    });
    final tempLatest = await db.query(
      'device_latest',
      where: 'config_id = ? AND sensor_type = ?',
      whereArgs: [1, 'temperature'],
      orderBy: 'sensor_channel',
    );
    expect(tempLatest.map((r) => r['sensor_channel']), ['external', 'internal']);
    expect(tempLatest.map((r) => r['value']), [2500, 2650]);

    // 真正落在主键上：同 (config_id, sensor_type, sensor_channel) 重复写入被拒绝
    await expectLater(
      db.insert('device_latest', {
        'config_id': 1,
        'sensor_type': 'temperature',
        'sensor_channel': 'internal',
        'value': 2700,
        'timestamp': 300,
      }),
      throwsA(isA<DatabaseException>()),
    );

    // device_latest 的 sensor_channel 默认值语义：不写列 → primary
    await db.insert('device_latest', {
      'config_id': 2,
      'sensor_type': 'co2',
      'value': 700,
      'timestamp': 500,
    });
    final co2Latest = await db.query(
      'device_latest',
      where: 'config_id = ? AND sensor_type = ?',
      whereArgs: [2, 'co2'],
    );
    expect(co2Latest.single['sensor_channel'], 'primary');

    // measurements 的 sensor_channel 默认值语义：不写列 → primary
    final newMeasurementId = await db.insert('measurements', {
      'config_id': 1,
      'sensor_type': 'co2',
      'value': 900,
      'timestamp': 400,
    });
    final defaultMeasurement = await db.query(
      'measurements',
      where: 'id = ?',
      whereArgs: [newMeasurementId],
    );
    expect(defaultMeasurement.single['sensor_channel'], 'primary');

    // 历史表同样允许同一 (config_id, sensor_type) 的不同通道共存
    await db.insert('measurements', {
      'config_id': 1,
      'sensor_type': 'temperature',
      'sensor_channel': 'internal',
      'value': 2600,
      'timestamp': 400,
    });
    final tempMeasurements = await db.query(
      'measurements',
      where: 'config_id = ? AND sensor_type = ?',
      whereArgs: [1, 'temperature'],
    );
    expect(
      tempMeasurements.map((r) => r['sensor_channel']),
      containsAll(['external', 'internal']),
    );

    // 迁移后外键约束仍然生效：写入不存在的 config_id 直接被拒
    await expectLater(
      db.insert('measurements', {
        'config_id': 999,
        'sensor_type': 'co2',
        'value': 1,
        'timestamp': 1,
      }),
      throwsA(isA<DatabaseException>()),
    );
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);

    await db.close();
  });

  test('v1 → v6：数据保留、id 不变、孤儿清理、外键与 channel 到位', () async {
    final path = p.join(tempDir.path, 'v1.db');
    final old = await createV1Database(path);
    await seedData(old);
    await old.close();

    final db = await service.openForTest(path); // 触发 1→6 增量迁移

    // 终态契约：v1 一路补齐 macAddress / device_group / 外键 / sensor_channel
    await expectTerminalV6Schema(db, origin: 'v1→v6');

    // 结构到位
    final cols = await db.rawQuery('PRAGMA table_info(device_configs)');
    expect(cols.map((c) => c['name']), containsAll(['macAddress', 'groupId']));
    // v4 步骤重建过的两张子表都带上了外键
    for (final table in ['notification_messages', 'measurements']) {
      final fks = await db.rawQuery('PRAGMA foreign_key_list($table)');
      expect(fks, isNotEmpty, reason: '$table 缺少外键');
      expect(fks.first['table'], 'device_configs');
    }

    // 数据保留且 id 不变，孤儿消息（configId=999）被清理
    final msgs = await db.query('notification_messages', orderBy: 'id');
    expect(msgs.length, 1);
    expect(msgs.first['id'], 1);
    expect(msgs.first['configId'], 1);

    final configs = await db.query('device_configs', orderBy: 'configId');
    expect(configs.map((c) => c['configId']), [1, 2]);
    expect(configs.first['macAddress'], '');

    // v1 没有 measurements 表（由 v2 步骤新建），新写入默认落在 primary 通道
    await db.insert('measurements', {
      'config_id': 1,
      'sensor_type': 'temperature',
      'value': 25,
      'timestamp': 1,
    });
    final measurement = await db.query('measurements');
    expect(measurement.single['sensor_channel'], 'primary');

    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    await db.close();
  });

  test('v3 → v6：时序数据保留、外键/索引重建、旧温度归入 external', () async {
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

    final db = await service.openForTest(path); // 触发 3→6 增量迁移

    // 终态契约：重建后的外键、四列索引、channel 列与 device_latest 三列主键
    await expectTerminalV6Schema(db, origin: 'v3→v6');

    // 孤儿测量被清理，正常数据保留，旧温度数据归入 external 通道
    final ms = await db.query('measurements');
    expect(ms.length, 1);
    expect(ms.first['config_id'], 1);
    expect(ms.first['sensor_type'], 'temperature');
    expect(ms.first['sensor_channel'], 'external');

    final dl = await db.query('device_latest');
    expect(dl.length, 1);
    expect(dl.first['config_id'], 1);
    expect(dl.first['sensor_channel'], 'external');

    // v4 步骤重建 measurements 时加上的外键在 v6 加列后仍然存在
    final measurementFks = await db.rawQuery(
      'PRAGMA foreign_key_list(measurements)',
    );
    expect(measurementFks, isNotEmpty);
    expect(measurementFks.first['table'], 'device_configs');

    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    await db.close();
  });

  test('v4 → v6：device_group 补齐 sortOrder，旧数据回填默认 0', () async {
    final path = p.join(tempDir.path, 'v4.db');
    final old = await createV4Database(path);
    final groupA = await old.insert(
      'device_group',
      {'groupName': '客厅', 'createdAt': 100},
    );
    await old.insert('device_group', {'groupName': '卧室', 'createdAt': 200});
    await old.close();

    final db = await service.openForTest(path); // 触发 4→6 增量迁移

    // 终态契约（v6 负责的部分：channel 列 / 三列主键 / 四列索引 / device_latest 外键）
    //
    // 注意：v4 fixture 的 measurements / notification_messages 沿用 v1 建表语句，
    // 本身没有外键；v4→v6 只重建 device_latest，不会补这两张表的外键，故此处不断言。
    await expectTerminalV6Schema(db, origin: 'v4→v6');

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
