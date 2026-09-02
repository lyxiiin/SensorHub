import 'package:sensor_hub/data/models/sensor_record.dart';
import 'package:sensor_hub/data/services/http/api_client.dart';
import 'package:sensor_hub/data/services/http/api_config.dart';
import 'package:sensor_hub/data/services/http/api_response.dart';

class ApiService {
  late final ApiClient _client;

  static final ApiService _instance = ApiService._internal();
  factory ApiService({ApiConfig? config}){
    if(config != null) _instance._init(config);
    return _instance;
  }
  ApiService._internal();
  void _init(ApiConfig config) {
    _client = ApiClient(config);
  }

  Future<ApiResponse<List<SensorRecord>>> getHistory(String deviceId, String startTime, String endTime, String limit) async {
    final response = await _client.get(
      '/api/v1/history',
      queryParameters: {
        "device_id": deviceId,
        "start": startTime,
        "end": endTime,
        "limit": limit,
      },
    );
    return ApiResponse.fromDioResponse(response, (json) {
      final dataList = json['data'] as List<dynamic>? ?? [];
      return dataList
          .map((data) => SensorRecord.fromJson(data as Map<String, dynamic>))
          .toList();
    });
  }
}
