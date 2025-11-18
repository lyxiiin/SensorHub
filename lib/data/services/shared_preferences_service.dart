import 'package:shared_preferences/shared_preferences.dart';
import '../exceptions/shared_preferences_exception.dart';

class SPUtil {
  static final SPUtil _instance = SPUtil._internal();
  static SharedPreferences? _prefs;

  factory SPUtil() => _instance;
  SPUtil._internal();

  static bool _isInitialized = false;
  static Exception? _initError;

  // 改进的初始化方法
  static Future<SPUtil> getInstance() async {
    if (!_isInitialized) {
      try {
        _prefs = await SharedPreferences.getInstance();
        _isInitialized = true;
        _initError = null;
      } catch (e) {
        _isInitialized = true;
        _initError = e is Exception ? e : Exception('Unknown error: $e');
        throw SharedPreferencesInitException("SharedPreferences 初始化失败: $e");
      }
    }

    if (_initError != null) {
      throw _initError!;
    }

    return _instance;
  }

  // 静态初始化方法
  static Future<void> init() async {
    await getInstance();
  }

  // 状态检查
  static bool get isInitialized => _isInitialized && _initError == null;
  static bool get hasError => _initError != null;
  static Exception? get error => _initError;

  // 重新初始化
  static Future<bool> reinitialize() async {
    _isInitialized = false;
    _initError = null;
    _prefs = null;

    try {
      await getInstance();
      return true;
    } catch (e) {
      return false;
    }
  }

  // prefs getter
  SharedPreferences get prefs {
    if (!_isInitialized) {
      throw SharedPreferencesInitException("SharedPreferences 未初始化，请在 main() 中调用 init() 或 getInstance()");
    }
    if (_initError != null) {
      throw _initError!;
    }
    return _prefs!;
  }

  // 便捷操作方法
  Future<bool> setString(String key, String value) => prefs.setString(key, value);
  String getString(String key, {String defaultValue = ''}) => prefs.getString(key) ?? defaultValue;

  Future<bool> setInt(String key, int value) => prefs.setInt(key, value);
  int getInt(String key, {int defaultValue = 0}) => prefs.getInt(key) ?? defaultValue;

  Future<bool> setDouble(String key, double value) => prefs.setDouble(key, value);
  double getDouble(String key, {double defaultValue = 0.0}) => prefs.getDouble(key) ?? defaultValue;

  Future<bool> setBool(String key, bool value) => prefs.setBool(key, value);
  bool getBool(String key, {bool defaultValue = false}) => prefs.getBool(key) ?? defaultValue;

  Future<bool> setStringList(String key, List<String> value) => prefs.setStringList(key, value);
  List<String> getStringList(String key, {List<String> defaultValue = const []}) => prefs.getStringList(key) ?? defaultValue;

  // 其他实用方法
  bool containsKey(String key) => prefs.containsKey(key);
  Future<bool> remove(String key) => prefs.remove(key);
  Future<bool> clear() => prefs.clear();
  Set<String> getKeys() => prefs.getKeys();
}