import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_interceptor.dart';

/// ──────────────────────────────────────────────
/// Singleton Dio HTTP client
/// Mirrors: pp-backend common/routing + OkHttp interceptor pattern
/// ──────────────────────────────────────────────

class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  late final Dio dio;

  void init() {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8788';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      AuthInterceptor(),
      LogInterceptor(requestBody: true, responseBody: true),
    ]);
  }
}
