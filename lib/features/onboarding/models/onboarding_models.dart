// ──────────────────────────────────────────────
// Onboarding Models
// Mirrors: pp-backend modules/onboarding
// ──────────────────────────────────────────────

class OnboardingOption {
  final String label;
  final String value;

  const OnboardingOption({required this.label, required this.value});

  factory OnboardingOption.fromJson(Map<String, dynamic> json) {
    return OnboardingOption(
      label: json['label']?.toString() ?? json['value']?.toString() ?? '',
      value: json['value']?.toString() ?? json['label']?.toString() ?? '',
    );
  }
}

class OnboardingQuestion {
  final String key;
  final String label;
  final String type; // 'multi_select', 'text', etc.
  final List<OnboardingOption> options;

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
              ?.map((e) {
                if (e is Map<String, dynamic>) {
                  return OnboardingOption.fromJson(e);
                } else if (e is String) {
                  return OnboardingOption(label: e, value: e);
                }
                return OnboardingOption(label: e.toString(), value: e.toString());
              })
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
