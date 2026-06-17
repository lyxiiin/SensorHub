import 'package:sensor_hub/data/models/notification_message.dart';
import 'package:sensor_hub/data/services/sqlite_service.dart';
import 'package:sensor_hub/utils/app_logger.dart';
import 'package:sqflite/sqflite.dart';

class NotificationMessageDao {
  static final NotificationMessageDao _instance = NotificationMessageDao._internal();
  factory NotificationMessageDao() => _instance;
  NotificationMessageDao._internal();

  Future<Database> get db async => SqliteService().database;

  Future<int> insert(NotificationMessage message) async {
    final db = await this.db;
    try {
      final id = await db.insert("notification_messages", message.toMap());
      logD('插入通知消息: id=$id', tag: 'DAO');
      return id;
    } catch (e) {
      logE('插入通知消息失败: $e', error: e, tag: 'DAO');
      rethrow;
    }
  }

  Future<int> deleteById(int id) async {
    final db = await this.db;
    try {
      final count = await db.delete(
        "notification_messages",
        where: 'id = ?',
        whereArgs: [id],
      );
      logD('删除通知消息: id=$id', tag: 'DAO');
      return count;
    } catch (e) {
      logE('删除通知消息失败: id=$id, $e', error: e, tag: 'DAO');
      rethrow;
    }
  }

  Future<List<NotificationMessage>> queryAll() async {
    final db = await this.db;
    final List<Map<String,dynamic>> maps = await db.query("notification_messages");
    return maps.map((e) => NotificationMessage.fromMap(e)).toList();
  }

  Future<List<NotificationMessage>> queryByDeviceName(String sensorName) async {
    final db = await this.db;
    final List<Map<String,dynamic>> maps = await db.query(
      "notification_messages",
      where: 'sensorName = ?',
      whereArgs: [sensorName],
    );
    return maps.map((e) => NotificationMessage.fromMap(e)).toList();
  }



}