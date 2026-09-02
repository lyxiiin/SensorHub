import 'package:dio/dio.dart';
import 'package:sensor_hub/data/services/http/api_config.dart';
import 'package:sensor_hub/utils/app_logger.dart';

class ApiClient {
  late final Dio _dio;
  final ApiConfig _config;

  ApiClient(this._config) {
    _dio = Dio(BaseOptions(
      baseUrl: _config.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: _config.timeout,
      sendTimeout: _config.timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  Future<Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) async {
    logD('HTTP GET → ${_config.baseUrl}$path  params: $queryParameters', tag: 'ApiClient');
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
      logD('HTTP GET ← ${response.statusCode}, body长度: ${response.data?.toString().length ?? 0}', tag: 'ApiClient');
      return response;
    } on DioException catch (e) {
      logE('HTTP GET 失败: type=${e.type}, msg=${e.message}', tag: 'ApiClient');
      rethrow;
    }
  }

  Future<Response> post(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    dynamic body,
  }) async {
    logD('HTTP POST → ${_config.baseUrl}$path', tag: 'ApiClient');
    try {
      final response = await _dio.post(
        path,
        queryParameters: queryParameters,
        data: body,
        options: headers != null ? Options(headers: headers) : null,
      );
      logD('HTTP POST ← ${response.statusCode}', tag: 'ApiClient');
      return response;
    } on DioException catch (e) {
      logE('HTTP POST 失败: type=${e.type}, msg=${e.message}', tag: 'ApiClient');
      rethrow;
    }
  }

  void dispose() {
    _dio.close();
  }
}
