import 'package:logger/logger.dart';

/// 全局 Logger 实例
///
/// 基于 logger 包封装，提供统一的日志输出格式。
/// 使用方式：
/// ```dart
/// logD('调试信息');
/// logI('关键业务节点');
/// logW('警告信息', tag: 'MQTT');
/// logE('错误信息', error: e, tag: 'DB');
/// ```
final appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
);

/// 将 tag 拼入消息前缀，如 [MQTT] 已连接
String _format(dynamic message, String? tag) =>
    tag != null ? '[$tag] $message' : '$message';

/// Debug 级别日志：开发调试信息，消息收发细节、内部状态
void logD(dynamic message, {String? tag}) =>
    appLogger.d(_format(message, tag));

/// Info 级别日志：关键业务节点，连接成功、设备添加、配置加载
void logI(dynamic message, {String? tag}) =>
    appLogger.i(_format(message, tag));

/// Warning 级别日志：异常但可恢复的情况，重连、校验失败、数据缺失
void logW(dynamic message, {String? tag}) =>
    appLogger.w(_format(message, tag));

/// Error 级别日志：不可恢复错误，连接失败、数据库异常、初始化失败
void logE(dynamic message, {dynamic error, StackTrace? stack, String? tag}) =>
    appLogger.e(_format(message, tag), error: error, stackTrace: stack);
