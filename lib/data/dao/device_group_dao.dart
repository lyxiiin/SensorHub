import 'package:sqflite/sqflite.dart';
import 'package:sensor_hub/utils/app_logger.dart';

import '../models/device_group.dart';
import '../services/sqlite_service.dart';

/// 设备分组表（device_group）的数据访问对象。
///
/// device_group 是被 device_configs(groupId) 外键引用的独立实体，
/// 按一表一 DAO 划分；device_configs 侧不直接写这张表。
class DeviceGroupDao {
  static final DeviceGroupDao _instance = DeviceGroupDao._internal();
  factory DeviceGroupDao() => _instance;
  DeviceGroupDao._internal();

  Future<Database> get database async => SqliteService().database;

  // 查询所有分组（sortOrder 优先、groupId 兜底）
  Future<List<DeviceGroup>> getAll() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'device_group',
        orderBy: 'sortOrder ASC, groupId ASC',
      );
      logD('查询所有设备分组: ${maps.length} 个', tag: 'DAO');
      return maps.map((e) => DeviceGroup.fromMap(e)).toList();
    } catch (e) {
      logE('查询所有设备分组失败: $e', error: e, tag: 'DAO');
      rethrow;
    }
  }

  /// 按 ID 查询单个分组（设备详情页用它把 device_configs.groupId 翻译成分组名）
  Future<DeviceGroup?> getById(int id) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'device_group',
        where: 'groupId = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return DeviceGroup.fromMap(maps.first);
    } catch (e) {
      logE('查询设备分组失败: id=$id, $e', error: e, tag: 'DAO');
      rethrow;
    }
  }

  Future<int> insert(DeviceGroup group) async {
    if (group.groupName.length > 20) {
      logE('插入分组失败: ${group.groupName}, 长度 ${group.groupName.length} 超出上限 20', tag: 'DAO');
      throw ArgumentError.value(
        group.groupName,
        'groupName',
        '分组名长度不能超过 20 字符 (当前 ${group.groupName.length})',
      );
    }
    final db = await database;
    try {
      final id = await db.insert("device_group", group.toMap());
      logD('插入设备分组成功: ${group.groupName} (id=$id)', tag: 'DAO');
      return id;
    } catch (e) {
      logE('插入设备分组失败: ${group.groupName}, $e', error: e, tag: 'DAO');
      rethrow;
    }
  }

  Future<int> update(DeviceGroup group) async {
    if (group.groupId == null) {
      throw ArgumentError('ID cannot be null for update');
    }
    final db = await database;
    try {
      final count = await db.update(
        "device_group",
        group.toMap(),
        where: 'groupId = ?',
        whereArgs: [group.groupId],
      );
      logD('更新分组配置: ${group.groupName} (id=${group.groupId})', tag: 'DAO');
      return count;
    } catch (e) {
      logE('更新分组配置失败: ${group.groupName}, $e', error: e, tag: 'DAO');
      rethrow;
    }
  }

  /// 整体重写排序值：[orderedIds] 的下标即新的 sortOrder。
  ///
  /// 拖拽排序只改少量相邻项，逐条 update 也行；但整体重写语义最简单，
  /// 且分组数量级很小（个位数到几十），放进一个事务里开销可以忽略。
  /// 事务保证中途失败时不会出现"半个新序半个旧序"。
  Future<void> updateSortOrders(List<int> orderedIds) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        for (int i = 0; i < orderedIds.length; i++) {
          await txn.update(
            'device_group',
            {'sortOrder': i},
            where: 'groupId = ?',
            whereArgs: [orderedIds[i]],
          );
        }
      });
      logD('重写分组排序: ${orderedIds.length} 个', tag: 'DAO');
    } catch (e) {
      logE('重写分组排序失败: $e', error: e, tag: 'DAO');
      rethrow;
    }
  }

  Future<int> delete(int id) async {
    final db = await database;
    try {
      // 注意 await：少了它日志会抢在删除完成前打印，
      // 返回值也会变成未完成的 Future（历史 bug，本次修复）
      final count = await db.delete(
        "device_group",
        where: 'groupId = ?',
        whereArgs: [id],
      );
      logD('删除分组配置: id=$id', tag: 'DAO');
      return count;
    } catch (e) {
      logE('删除分组配置失败: id=$id, $e', error: e, tag: 'DAO');
      rethrow;
    }
  }
}
