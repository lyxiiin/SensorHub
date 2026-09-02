import 'package:dio/dio.dart';

class ApiResponse<T> {
  final int statusCode;
  final bool isSuccess;
  final T? data;
  final String? message;
  ApiResponse({
    required this.statusCode,
    required this.isSuccess,
    this.data,
    this.message,
  });
  factory ApiResponse.fromDioResponse(
    Response response,
    T Function(dynamic json)? fromJson,
  ) {
    final statusCode = response.statusCode ?? 0;
    final success = statusCode >= 200 && statusCode < 300;
    final body = response.data;
    return ApiResponse(
        statusCode: statusCode,
        isSuccess: success,
        data: success && fromJson != null ? fromJson(body) : null,
        message: !success ? (body is Map ? body['message']?.toString() ?? "未知错误" : "未知错误") : null,
    );
  }
}
