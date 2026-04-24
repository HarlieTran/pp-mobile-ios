import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../profile/providers/profile_provider.dart';
import '../models/onboarding_models.dart';
import '../providers/onboarding_provider.dart';
import '../widgets/step_progress_indicator.dart';

/// Feature: 3.2 Onboarding — Multi-step questionnaire
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = ref.watch(questionsProvider);
    final onboarding = ref.watch(onboardingProvider);

    return Scaffold(
      body: SafeArea(
        child: questions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (questionList) {
            if (questionList.isEmpty) {
              return const Center(child: Text('No questions available'));
            }

            final totalSteps = questionList.length;
            final currentStep = onboarding.currentStep.clamp(0, totalSteps - 1);
            final currentQuestion = questionList[currentStep];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (currentStep > 0)
                        IconButton(
                          onPressed: () =>
                              ref.read(onboardingProvider.notifier).prevStep(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceTint,
                            padding: const EdgeInsets.all(10),
                          ),
                        )
                      else
                        const SizedBox(width: 40),
                      Text(
                        'Step ${currentStep + 1} of $totalSteps',
                        style: TextStyle(fontFamily: 'Matter', 
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: Text(
                          'Skip',
                          style: TextStyle(fontFamily: 'Matter', 
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress
                  StepProgressIndicator(
                    currentStep: currentStep,
                    totalSteps: totalSteps,
                  ),
                  const SizedBox(height: 48),

                  // Question
                  Text(
                    currentQuestion.label,
                    style: TextStyle(fontFamily: 'Matter', 
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select all that apply',
                    style: TextStyle(fontFamily: 'Matter', 
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Options
                  Expanded(
                    child: currentQuestion.type == 'FREE_TEXT'
                        ? Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextField(
                              maxLines: 4,
                              onChanged: (val) {
                                ref.read(onboardingProvider.notifier).setAnswer(
                                  OnboardingAnswer(
                                    questionKey: currentQuestion.key,
                                    answerText: val,
                                  ),
                                );
                              },
                              style: const TextStyle(fontFamily: 'Matter', fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'E.g., cilantro, mushrooms...',
                                hintStyle: const TextStyle(fontFamily: 'Matter', color: AppColors.textHint),
                                filled: true,
                                fillColor: AppColors.surfaceTint,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: AppColors.primary),
                                ),
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: currentQuestion.options.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final option = currentQuestion.options[index];
                              final currentAnswer =
                                  onboarding.answers[currentQuestion.key];
                              final isSelected = currentAnswer?.optionValues
                                      ?.contains(option.value) ??
                                  false;

                              return _OptionTile(
                                label: option.label,
                                isSelected: isSelected,
                                onTap: () {
                                  final existing = List<String>.from(
                                      currentAnswer?.optionValues ?? []);
                                  if (isSelected) {
                                    existing.remove(option.value);
                                  } else {
                                    existing.add(option.value);
                                  }
                                  ref
                                      .read(onboardingProvider.notifier)
                                      .setAnswer(OnboardingAnswer(
                                        questionKey: currentQuestion.key,
                                        optionValues: existing,
                                      ));
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 20),

                  // Continue / Submit
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: onboarding.isSubmitting
                          ? null
                          : () {
                              if (currentStep < totalSteps - 1) {
                                ref.read(onboardingProvider.notifier).nextStep();
                              } else {
                                ref
                                    .read(onboardingProvider.notifier)
                                    .submit()
                                    .then((_) {
                                  ref.read(profileProvider.notifier).fetchProfile();
                                  context.go('/');
                                });
                              }
                            },
                      child: onboarding.isSubmitting
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              currentStep < totalSteps - 1
                                  ? 'Continue'
                                  : 'Get Started',
                              style: TextStyle(fontFamily: 'Matter', 
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontFamily: 'Matter', 
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
