import 'package:sensor_hub/data/models/notification_message.dart';
import 'package:sensor_hub/data/services/sqlite_service.dart';
import 'package:sqflite/sqflite.dart';

class NotificationMessageDao {
  static final NotificationMessageDao _instance = NotificationMessageDao._internal();
  factory NotificationMessageDao() => _instance;
  NotificationMessageDao._internal();

  Future<Database> get db async => SqliteService().database;

  Future<int> insert(NotificationMessage message) async {
    final db = await this.db;
    return await db.insert("notification_messages", message.toMap());
  }

  Future<int> deleteById(int id) async {
    final db = await this.db;
    return await db.delete(
      "notification_messages",
      where: 'id = ?',
      whereArgs: [id],
    );
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