// ──────────────────────────────────────────────
// Onboarding Models
// Mirrors: pp-backend modules/onboarding
// ──────────────────────────────────────────────

class OnboardingQuestion {
  final String key;
  final String label;
  final String type; // 'multi_select', 'text', etc.
  final List<String> options;

  const OnboardingQuestion({
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
  });

  factory OnboardingQuestion.fromJson(Map<String, dynamic> json) {
    return OnboardingQuestion(
      key: json['key'] as String,
      label: json['label'] as String,
      type: json['type'] as String,
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class OnboardingAnswer {
  final String questionKey;
  final List<String>? optionValues;
  final String? answerText;

  const OnboardingAnswer({
    required this.questionKey,
    this.optionValues,
    this.answerText,
  });

  Map<String, dynamic> toJson() => {
        'questionKey': questionKey,
        if (optionValues != null) 'optionValues': optionValues,
        if (answerText != null) 'answerText': answerText,
      };
}
