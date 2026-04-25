import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/recipes_provider.dart';
import '../../pantry/providers/pantry_provider.dart';


class AiChefScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const AiChefScreen({super.key, this.initialQuery});

  @override
  ConsumerState<AiChefScreen> createState() => _AiChefScreenState();
}

class _AiChefScreenState extends ConsumerState<AiChefScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isGeneratingSingle = false;
  String? _singleError;
  String? _currentQuery;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.initialQuery != null) {
      _currentQuery = widget.initialQuery;
      _isGeneratingSingle = true;
      _generateSingleRecipe(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _generateSingleRecipe(String query, {String? imageUrl, List<String>? ingredientHint}) async {
    try {
      final recipe = await ref.read(recipesServiceProvider).generateFromName(query, imageUrl: imageUrl, ingredientHint: ingredientHint);
      if (mounted) {
        context.pushReplacement('/recipes/${recipe.id}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _singleError = e.toString();
          _isGeneratingSingle = false;
        });
      }
    }
  }

  void _startGeneration(String query, {String? imageUrl, List<String>? ingredientHint}) {
    setState(() {
      _currentQuery = query;
      _isGeneratingSingle = true;
      _singleError = null;
    });
    _generateSingleRecipe(query, imageUrl: imageUrl, ingredientHint: ingredientHint);
  }

  @override
  Widget build(BuildContext context) {
    if (_isGeneratingSingle) {
      return _buildSingleLoadingState();
    }
    if (_singleError != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
                  onPressed: () => context.pop(),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF7ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.flame, size: 64, color: Color(0xFFEA580C)),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Oops! The kitchen got too hot',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Our AI Chef needs a quick breather. Please try asking again.',
                        style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () {
                            if (_currentQuery != null) {
                              _startGeneration(_currentQuery!);
                            }
                          },
                          child: Text(
                            'Try Again',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'Go back',
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildAiKitchenState();
  }

  Widget _buildSingleLoadingState() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.sparkles, size: 64, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'AI Chef is cooking...',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Creating a unique recipe for\n"${_currentQuery ?? widget.initialQuery ?? 'your request'}"',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiKitchenState() {
    final pantryAsync = ref.watch(pantryProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'AI Kitchen',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: pantryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading pantry: $e')),
        data: (pantryItems) {
          if (pantryItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.chefHat, size: 80, color: AppColors.border),
                    const SizedBox(height: 24),
                    Text(
                      'Ready to cook?',
                      style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add some items to your pantry, then ask the AI Chef to brainstorm unique recipes for you!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(fontSize: 16, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }

          final aiListAsync = ref.watch(generateAiListProvider);

          return aiListAsync.when(
            loading: () => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: const Icon(LucideIcons.chefHat, size: 80, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Brainstorming recipes...',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            error: (e, _) => Center(child: Text('Error generating recipes: $e')),
            data: (recipes) {
              return ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: recipes.length,
                separatorBuilder: (context, index) => const SizedBox(height: 24),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  final matchingCount = recipe.ingredients.where((i) => i.fromPantry).length;
                  final missingCount = recipe.ingredients.length - matchingCount;

                  return GestureDetector(
                    onTap: () async {
                      setState(() {
                        _currentQuery = recipe.title;
                        _isGeneratingSingle = true;
                        _singleError = null;
                      });
                      
                      String? imageUrl;
                      try {
                        imageUrl = await ref.read(generateAiImageProvider(recipe).future);
                      } catch (_) {}

                      final ingredientHint = recipe.ingredients.map((i) => i.name).toList();
                      _generateSingleRecipe(recipe.title, imageUrl: imageUrl, ingredientHint: ingredientHint);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Stack for the Image & Badges
                        SizedBox(
                          height: 180,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                                Consumer(
                                  builder: (context, ref, _) {
                                    final imageAsync = ref.watch(generateAiImageProvider(recipe));
                                    return imageAsync.when(
                                      data: (imageUrl) => CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: AppColors.surfaceTint,
                                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: AppColors.surfaceTint,
                                          child: const Center(child: Icon(LucideIcons.image, size: 48, color: AppColors.primary)),
                                        ),
                                      ),
                                      loading: () => Container(
                                        color: AppColors.surfaceTint,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(LucideIcons.sparkles, size: 32, color: AppColors.primary),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Cooking photo...',
                                              style: GoogleFonts.outfit(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                                letterSpacing: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      error: (_, __) => Container(
                                        color: AppColors.surfaceTint,
                                        child: const Center(child: Icon(LucideIcons.image, size: 48, color: AppColors.primary)),
                                      ),
                                    );
                                  },
                                ),
                                // Badges
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4E9E2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFF006241).withValues(alpha: 0.1)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.sparkles, size: 12, color: Color(0xFF006241)),
                                        const SizedBox(width: 4),
                                        Text('AI Generated', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF006241))),
                                      ],
                                    ),
                                  ),
                                ),
                                if (missingCount == 0)
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4E9E2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFF006241).withValues(alpha: 0.1)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.checkCircle2, size: 12, color: Color(0xFF006241)),
                                          const SizedBox(width: 4),
                                          Text('Ready to cook', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF006241))),
                                        ],
                                      ),
                                    ),
                                  )
                                else
                                  Positioned(
                                    top: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFFEDD5)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.alertCircle, size: 10, color: Color(0xFFEA580C)),
                                          const SizedBox(width: 4),
                                          Text('Missing $missingCount', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C))),
                                        ],
                                      ),
                                    ),
                                  ),
                            ],
                          ),
                        ),

                        // Info section
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                recipe.title,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E1E1E),
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Time & Servings
                              Row(
                                children: [
                                  Text(
                                    recipe.estimatedTime,
                                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF)),
                                  ),
                                  const SizedBox(width: 16),
                                  Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle)),
                                  const SizedBox(width: 16),
                                  Text(
                                    '${recipe.servings} Servings',
                                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Matching / Missing counts
                              Row(
                                children: [
                                  Text(
                                    '$matchingCount matching',
                                    style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF006241)),
                                  ),
                                  if (missingCount > 0) ...[
                                    const SizedBox(width: 12),
                                    Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle)),
                                    const SizedBox(width: 12),
                                    Text(
                                      '$missingCount missing',
                                      style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFFF97316)),
                                    ),
                                  ],
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Bottom row with avatars and Generate button
                              Container(
                                padding: const EdgeInsets.only(top: 16),
                                decoration: const BoxDecoration(
                                  border: Border(top: BorderSide(color: Color(0xFFF9FAFB), width: 1)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Overlapping avatars
                                    Row(
                                      children: [
                                        for (int i = 0; i < 3; i++)
                                          Align(
                                            widthFactor: 0.7,
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF3F4F6),
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 2),
                                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)],
                                              ),
                                              alignment: Alignment.center,
                                              child: const Text('✨', style: TextStyle(fontSize: 10)),
                                            ),
                                          ),
                                      ],
                                    ),
                                    // Generate recipe button
                                    GestureDetector(
                                      onTap: () {
                                        final imageUrl = ref.read(generateAiImageProvider(recipe)).valueOrNull;
                                        final ingredientHint = recipe.ingredients.map((i) => i.name).toList();
                                        _startGeneration(recipe.title, imageUrl: imageUrl, ingredientHint: ingredientHint);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF006241),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF006241).withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'View recipe',
                                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
