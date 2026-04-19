import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/planner_provider.dart';

/// Feature: 3.7 Meal Planner — Weekly plan with shopping list
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(plannerProvider.notifier).fetchPlan());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(plannerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => context.go('/'),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceTint,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                  Text(
                    'Meal Planner',
                    style: TextStyle(fontFamily: 'Matter', 
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(plannerProvider.notifier).clearPlan();
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 22),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceTint,
                      padding: const EdgeInsets.all(10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  labelColor: AppColors.textPrimary,
                  unselectedLabelColor: AppColors.textHint,
                  labelStyle: TextStyle(fontFamily: 'Matter', fontSize: 14, fontWeight: FontWeight.w600),
                  dividerHeight: 0,
                  tabs: const [
                    Tab(text: 'Weekly Plan'),
                    Tab(text: 'Shopping List'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Weekly Plan
                  planState.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const Center(child: Text('Failed to load plan')),
                    data: (plan) {
                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _weekdays.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final meal = i < plan.entries.length ? plan.entries[i] : null;
                          final isToday = i == DateTime.now().weekday - 1;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? AppColors.primary.withValues(alpha: 0.06)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: isToday
                                  ? Border.all(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      width: 1.5)
                                  : null,
                              boxShadow: [
                                if (!isToday)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Day
                                Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? AppColors.primary
                                        : AppColors.surfaceTint,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _weekdays[i],
                                    style: TextStyle(fontFamily: 'Matter', 
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isToday
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Meal
                                Expanded(
                                  child: meal != null
                                      ? Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              meal.title,
                                              style: TextStyle(fontFamily: 'Matter', 
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Tap to view recipe',
                                              style: TextStyle(fontFamily: 'Matter', 
                                                fontSize: 13,
                                                color: AppColors.textHint,
                                              ),
                                            ),
                                          ],
                                        )
                                      : Text(
                                          'No meal planned',
                                          style: TextStyle(fontFamily: 'Matter', 
                                            fontSize: 14,
                                            color: AppColors.textHint,
                                          ),
                                        ),
                                ),

                                // Add/Remove
                                IconButton(
                                  onPressed: () {
                                    if (meal != null) {
                                      ref.read(plannerProvider.notifier)
                                          .removeRecipe(meal.recipeId);
                                    } else {
                                      context.go('/recipes');
                                    }
                                  },
                                  icon: Icon(
                                    meal != null
                                        ? Icons.remove_circle_outline
                                        : Icons.add_circle_outline,
                                    color: meal != null
                                        ? AppColors.error
                                        : AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),

                  // Shopping List
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(
                          'Shopping list will appear here',
                          style: TextStyle(fontFamily: 'Matter', 
                              fontSize: 16, color: AppColors.textHint),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add meals to your weekly plan first',
                          style: TextStyle(fontFamily: 'Matter', 
                              fontSize: 14, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
