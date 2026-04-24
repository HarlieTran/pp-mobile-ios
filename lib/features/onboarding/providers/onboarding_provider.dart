import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding_models.dart';
import '../services/onboarding_service.dart';
import '../../profile/models/profile_models.dart';
import '../../profile/services/profile_service.dart';
import '../../profile/providers/profile_provider.dart';

/// ──────────────────────────────────────────────
/// Onboarding Provider
/// Mirrors: pp-frontend preferencesSlice
/// ──────────────────────────────────────────────

final onboardingServiceProvider = Provider((_) => OnboardingService());

final questionsProvider = FutureProvider<List<OnboardingQuestion>>((ref) async {
  final service = ref.read(onboardingServiceProvider);
  return service.fetchQuestions();
});

class OnboardingState {
  final int currentStep;
  final Map<String, OnboardingAnswer> answers;
  final bool isCompleted;
  final bool isSubmitting;

  const OnboardingState({
    this.currentStep = 0,
    this.answers = const {},
    this.isCompleted = false,
    this.isSubmitting = false,
  });

  OnboardingState copyWith({
    int? currentStep,
    Map<String, OnboardingAnswer>? answers,
    bool? isCompleted,
    bool? isSubmitting,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      answers: answers ?? this.answers,
      isCompleted: isCompleted ?? this.isCompleted,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>(
  (ref) => OnboardingNotifier(ref.read(onboardingServiceProvider), ref.read(profileServiceProvider)),
);

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final OnboardingService _service;
  final ProfileService _profileService;

  OnboardingNotifier(this._service, this._profileService) : super(const OnboardingState());

  void setAnswer(OnboardingAnswer answer) {
    final updated = Map<String, OnboardingAnswer>.from(state.answers);
    updated[answer.questionKey] = answer;
    state = state.copyWith(answers: updated);
  }

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() => state = state.copyWith(currentStep: state.currentStep - 1);

  Future<void> submit() async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _service.saveAnswers(state.answers.values.toList());

      final dietType = state.answers['dietary_preference']?.optionValues?.where((e) => e != 'none').toList() ?? [];
      final allergies = state.answers['allergies']?.optionValues ?? [];
      final disliked = state.answers['dislikes']?.answerText;

      await _profileService.updateProfile(UpdateProfilePayload(
        dietType: dietType,
        allergies: allergies,
        disliked: disliked,
      ));

      await _service.completeOnboarding();
      state = state.copyWith(isSubmitting: false, isCompleted: true);
    } catch (_) {
      state = state.copyWith(isSubmitting: false);
    }
  }
}
