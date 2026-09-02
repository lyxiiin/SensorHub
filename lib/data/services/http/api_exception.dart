import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic originalError;
  ApiException({
    this.statusCode,
    required this.message,
    this.originalError,
  });
  @override
  String toString() => 'ApiException($statusCode): $message';

  factory ApiException.fromError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return ApiException(message: '请求超时，请检查网络');
        case DioExceptionType.connectionError:
          return ApiException(message: '网络连接失败');
        default:
          return ApiException(message: 'HTTP 请求失败: ${error.message}');
      }
    }
    if (error is TimeoutException) {
      return ApiException(message: '请求超时，请检查网络');
    }
    if (error is SocketException) {
      return ApiException(message: '网络连接失败');
    }
    return ApiException(message: '未知网络错误: $error');
  }
}
