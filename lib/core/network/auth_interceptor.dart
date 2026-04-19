import 'package:dio/dio.dart';
import '../auth/auth_service.dart';

/// ──────────────────────────────────────────────
/// Auth Interceptor
/// Mirrors: pp-backend auth/middleware/auth.middleware.ts
/// Automatically attaches the Cognito JWT id_token
/// ──────────────────────────────────────────────

class AuthInterceptor extends Interceptor {
  /// Public endpoints that don't require auth
  static const _publicPaths = [
    '/health',
    '/onboarding/questions',
  ];

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic = _publicPaths.any(
      (path) => options.path.contains(path),
    );

    if (!isPublic) {
      try {
        final token = await AuthService.instance.getIdToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {
        // Token fetch failed — let the request proceed and handle 401
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // TODO: Trigger global sign-out or token refresh
    }
    handler.next(err);
  }
}
