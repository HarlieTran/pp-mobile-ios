import '../../../core/network/api_client.dart';
import '../models/profile_models.dart';

/// ──────────────────────────────────────────────
/// Profile API Service
/// Mirrors: pp-backend modules/users/services/profile.service.ts
/// Endpoints: GET /me/profile, PATCH /me/profile
/// ──────────────────────────────────────────────

class ProfileService {
  final _dio = ApiClient.instance.dio;

  /// GET /me/profile
  Future<UserProfile> fetchProfile() async {
    final response = await _dio.get('/me/profile');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// PATCH /me/profile
  Future<UserProfile> updateProfile(UpdateProfilePayload payload) async {
    final response =
        await _dio.patch('/me/profile', data: payload.toJson());
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }
}
