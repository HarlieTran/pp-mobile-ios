import '../../../core/network/api_client.dart';
import '../models/onboarding_models.dart';

/// ──────────────────────────────────────────────
/// Onboarding API Service
/// Mirrors: pp-backend modules/onboarding/services/onboarding.service.ts
/// Endpoints: GET /onboarding/questions, PUT /me/answers,
///            POST /me/onboarding/complete
/// ──────────────────────────────────────────────

class OnboardingService {
  final _dio = ApiClient.instance.dio;

  /// GET /onboarding/questions (public)
  Future<List<OnboardingQuestion>> fetchQuestions() async {
    final response = await _dio.get('/onboarding/questions');
    final list = response.data['questions'] as List<dynamic>;
    return list
        .map((q) => OnboardingQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  /// PUT /me/answers
  Future<void> saveAnswers(List<OnboardingAnswer> answers) async {
    await _dio.put('/me/answers', data: {
      'answers': answers.map((a) => a.toJson()).toList(),
    });
  }

  /// POST /me/onboarding/complete
  Future<void> completeOnboarding() async {
    await _dio.post('/me/onboarding/complete');
  }
}
