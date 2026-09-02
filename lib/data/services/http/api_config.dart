class ApiConfig {
  final String baseUrl;
  final Duration timeout;
  final int maxRetries;
  final bool enableLogging;
  const ApiConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 15),
    this.maxRetries = 3,
    this.enableLogging = true,
  });
  // 不同环境
  static const development = ApiConfig(
    baseUrl: 'http://8.163.13.154:5000',
    timeout: Duration(seconds: 30),
    enableLogging: true,
  );
  // static const staging = ApiConfig(
  //   baseUrl: 'https://staging.example.com/api',
  //   timeout: Duration(seconds: 15),
  //   enableLogging: true,
  // );
  // static const production = ApiConfig(
  //   baseUrl: 'https://api.example.com/api',
  //   timeout: Duration(seconds: 10),
  //   enableLogging: false,
  // );
}