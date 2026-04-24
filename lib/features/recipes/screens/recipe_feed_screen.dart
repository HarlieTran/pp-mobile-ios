import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/global_header.dart';
import '../providers/recipes_provider.dart';
import '../models/recipe_models.dart';
import '../../pantry/providers/pantry_provider.dart';
import '../../pantry/models/pantry_models.dart';
import 'dart:async';
import '../../planner/providers/planner_provider.dart';
class RecipeFeedScreen extends ConsumerStatefulWidget {
  const RecipeFeedScreen({super.key});

  @override
  ConsumerState<RecipeFeedScreen> createState() => _RecipeFeedScreenState();
}

class _RecipeFeedScreenState extends ConsumerState<RecipeFeedScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  
  final FocusNode _searchFocus = FocusNode();
  final LayerLink _searchLayerLink = LayerLink();
  OverlayEntry? _searchOverlay;
  Timer? _debounceTimer;
  String _liveSearchQuery = '';

  final List<String> _filters = [
    'All',
    'Ready to cook',
    'Quick eats',
    'High protein',
  ];

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus) {
        _showSearchOverlay();
      } else {
        _hideSearchOverlay();
      }
    });
  }

  void _onSearchChanged(String val) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      setState(() => _liveSearchQuery = val.trim());
      _searchOverlay?.markNeedsBuild();
    });
  }

  void _showSearchOverlay() {
    if (_searchOverlay != null) return;
    
    _searchOverlay = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width - 48,
          child: CompositedTransformFollower(
            link: _searchLayerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 56), // 48 (height) + 8 (padding)
            child: Material(
              color: Colors.transparent,
              child: Consumer(builder: (context, ref, child) {
                return _buildDropdownContent(ref);
              }),
            ),
          ),
        );
      },
    );
    Overlay.of(context).insert(_searchOverlay!);
  }

  void _hideSearchOverlay() {
    _searchOverlay?.remove();
    _searchOverlay = null;
  }

  Widget _buildDropdownContent(WidgetRef ref) {
    final query = _liveSearchQuery;
    if (query.isEmpty) return const SizedBox.shrink();

    final searchResult = ref.watch(recipeSearchProvider(query));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFF3F4F6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              _searchFocus.unfocus();
              _searchCtrl.clear();
              context.push('/recipes/ai-chef', extra: query);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Generate: "$query"',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
          searchResult.when(
            data: (recipes) {
              if (recipes.isEmpty) return const SizedBox.shrink();
              return Column(
                children: [
                  const Divider(height: 1),
                  ...recipes.take(5).map((recipe) => ListTile(
                    title: Text(recipe.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                    subtitle: Text('${recipe.readyInMinutes ?? 30} mins', style: GoogleFonts.outfit(fontSize: 12)),
                    leading: const Icon(LucideIcons.utensils, size: 20, color: AppColors.textSecondary),
                    onTap: () {
                      _searchFocus.unfocus();
                      _searchCtrl.clear();
                      context.push('/recipes/${recipe.id}');
                    },
                  )),
                ],
              );
            },
            loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchCtrl.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(recipeSuggestionsProvider(_selectedFilter));
    final pantryState = ref.watch(pantryProvider);

    // Build a set of near-expiring ingredient names from the pantry
    final Set<String> expiringNames = {};
    final List<PantryItem> expiringItems = [];
    pantryState.whenData((items) {
      for (final item in items) {
        if (item.expiryStatus == ExpiryStatus.expiringSoon ||
            item.expiryStatus == ExpiryStatus.expired) {
          expiringNames.add(item.rawName.toLowerCase());
          expiringItems.add(item);
        }
      }
    });

    final searchResults = _searchQuery.isNotEmpty 
        ? ref.watch(recipeSearchProvider(_searchQuery)) 
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/recipes/ai-chef');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.sparkles, color: Colors.white),
        label: Text(
          'AI Kitchen',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: suggestions.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.textHint),
                    const SizedBox(height: 12),
                    Text('Failed to load recipes',
                        style: GoogleFonts.outfit(color: AppColors.textHint)),
                  ],
                ),
              ),
              data: (recipes) => _buildBody(recipes, expiringNames, expiringItems),
            ),
    );
  }

  Widget _buildBody(List<Recipe> recipes, Set<String> expiringNames, List<PantryItem> expiringItems) {
    return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header + Search bar ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: GlobalHeader(title: 'My recipes'),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 24,
                      right: 24,
                        child: CompositedTransformTarget(
                          link: _searchLayerLink,
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF3F4F6)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                          children: [
                            const Icon(LucideIcons.search, size: 18, color: Color(0xFF9CA3AF)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                onChanged: _onSearchChanged,
                                onSubmitted: (val) {
                                  _searchFocus.unfocus();
                                },
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'What do you want to cook?',
                                  hintStyle: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                          ),
                        ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Filter chips ──
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = filter == _selectedFilter;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF006241) : Colors.white,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF006241) : const Color(0xFFF3F4F6),
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF006241).withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            filter,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ── Curated meals header ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Curated meals',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E1E1E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.push('/profile/favourites'),
                        child: Row(
                          children: [
                            Text(
                              'Show favorites',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF006241),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.heart, size: 12, color: Color(0xFF006241)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Recipe cards ──
                if (recipes.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Text(
                          'No recipes found',
                          style: GoogleFonts.outfit(color: AppColors.textHint),
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recipes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      return _RecipeCard(
                        recipe: recipes[index],
                        expiringNames: expiringNames,
                      );
                    },
                  ),

                if (expiringItems.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _RescueMissionCard(expiringItems: expiringItems, recipes: recipes),
                  ),
                ],
              ],
            ),
          );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Recipe Card — with press-to-zoom image, smart badges, animated waste saver
// ────────────────────────────────────────────────────────────────────────────
class _RecipeCard extends ConsumerStatefulWidget {
  final Recipe recipe;
  final Set<String> expiringNames;
  const _RecipeCard({required this.recipe, required this.expiringNames});

  @override
  ConsumerState<_RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends ConsumerState<_RecipeCard> with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final int matchingCount = recipe.usedIngredientCount ?? 0;
    final int missingCount = recipe.missedIngredientCount ?? 0;
    final int total = matchingCount + missingCount;
    final int matchScore = total > 0 ? ((matchingCount / total) * 100).round() : 100;
    final bool isPerfectMatch = missingCount == 0;

    final savedRecipesAsync = ref.watch(savedRecipesProvider);
    final isSaved = savedRecipesAsync.valueOrNull?.any((r) => r.id == recipe.id) ?? false;
    
    // Meal planner integration
    // Note: To properly support MealPlanner, we need to import plannerProvider and planner_models
    // We'll add the necessary imports if they're missing, or assume they are added.
    // Wait, let me make sure plannerProvider is available in this file. It is imported at line 8.
    // Let's check: import '../../planner/providers/planner_provider.dart'; -> Yes it is.
    final plannerAsync = ref.watch(plannerProvider);
    final isPlanned = plannerAsync.valueOrNull?.entries.any((item) => item.recipeId == recipe.id) ?? false;

    // Smart waste saver detection: check if recipe title contains any expiring pantry item name
    final titleLower = recipe.title.toLowerCase();
    final bool usesExpiring = widget.expiringNames.any((name) => titleLower.contains(name));

    // Chef's pick only when match > 60%
    final bool showChefPick = matchScore > 60;

    return GestureDetector(
      onTap: () => context.push('/recipes/${recipe.id}'),
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: isPerfectMatch ? const Color(0xFFF0FDF4) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPerfectMatch ? Colors.green.shade400 : const Color(0xFFF3F4F6),
              width: isPerfectMatch ? 2 : 1,
            ),
            boxShadow: [
              if (isPerfectMatch)
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero image with hover-scale ──
              Stack(
                children: [
                  SizedBox(
                    height: 192,
                    width: double.infinity,
                    child: AnimatedScale(
                      scale: _isPressed ? 1.05 : 1.0,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOut,
                      child: recipe.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: recipe.imageUrl!,
                              fit: BoxFit.cover,
                              imageBuilder: (context, imageProvider) => Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                  ),
                                ),
                                child: Transform.scale(
                                  scale: 1.08,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: imageProvider,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : Container(color: const Color(0xFFF3F4F6)),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () async {
                        try {
                          await ref.read(savedRecipesProvider.notifier).toggleSave(recipe);
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save recipe', style: GoogleFonts.outfit()),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isSaved ? Icons.favorite : Icons.favorite_border,
                          color: const Color(0xFF006241),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  if (isPerfectMatch)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.green.shade600),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          "✨ 100% Match",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else if (showChefPick)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF006241),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          "Chef's pick",
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // Heart button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () async {
                        await ref.read(recipesServiceProvider).toggleSave(recipe.id);
                        ref.invalidate(savedRecipesProvider);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSaved ? Colors.green : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.heart,
                          size: 18,
                          color: isSaved ? Colors.green : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Card body ── (p-5 = 20px)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (usesExpiring) const _WasteSaverBadge(),
                        _UniformBadge(
                          bgColor: const Color(0xFFF4F8F2),
                          borderColor: const Color(0xFF006241).withValues(alpha: 0.1),
                          textColor: const Color(0xFF006241),
                          child: Text('$matchScore% match'),
                        ),
                        if (missingCount == 0)
                          _UniformBadge(
                            bgColor: const Color(0xFFD4E9E2),
                            borderColor: const Color(0xFF006241).withValues(alpha: 0.1),
                            textColor: const Color(0xFF006241),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.checkCircle2, size: 12, color: Color(0xFF006241)),
                                const SizedBox(width: 4),
                                const Text('Ready to cook'),
                              ],
                            ),
                          )
                        else
                          _UniformBadge(
                            bgColor: const Color(0xFFFFF7ED),
                            borderColor: const Color(0xFFFFEDD5),
                            textColor: const Color(0xFFEA580C),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.alertCircle, size: 10, color: Color(0xFFEA580C)),
                                const SizedBox(width: 4),
                                Text('Missing $missingCount'),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Title
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

                    // Time & Difficulty
                    Row(
                      children: [
                        Text(
                          '${recipe.readyInMinutes ?? 25}m',
                          style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(width: 16),
                        Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFFE5E7EB), shape: BoxShape.circle)),
                        const SizedBox(width: 16),
                        Text(
                          'Easy',
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

                    // Bottom row
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
                                    child: const Text('🥘', style: TextStyle(fontSize: 10)),
                                  ),
                                ),
                              Align(
                                widthFactor: 0.7,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9FAFB),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('+2', style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w800, color: const Color(0xFF9CA3AF))),
                                ),
                              ),
                            ],
                          ),
                          // View recipe button
                          GestureDetector(
                            onTap: () => context.push('/recipes/${recipe.id}'),
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
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Animated pulsing Waste Saver badge — animate-pulse from the mockup
// ────────────────────────────────────────────────────────────────────────────
class _WasteSaverBadge extends StatefulWidget {
  const _WasteSaverBadge();

  @override
  State<_WasteSaverBadge> createState() => _WasteSaverBadgeState();
}

class _WasteSaverBadgeState extends State<_WasteSaverBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: child,
        );
      },
      child: Container(
        width: 100,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          border: Border.all(color: const Color(0xFFFEE2E2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DefaultTextStyle(
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFDC2626),
            letterSpacing: -0.2,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.shieldAlert, size: 10, color: Color(0xFFDC2626)),
              const SizedBox(width: 4),
              const Text('Waste saver'),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// UniformBadge — w-[100px] h-8 rounded-lg
// ────────────────────────────────────────────────────────────────────────────
class _UniformBadge extends StatelessWidget {
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final Widget child;

  const _UniformBadge({
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: GoogleFonts.outfit(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: -0.2,
        ),
        child: child,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Rescue Mission CTA
// ────────────────────────────────────────────────────────────────────────────
class _RescueMissionCard extends StatelessWidget {
  final List<PantryItem> expiringItems;
  final List<Recipe> recipes;
  const _RescueMissionCard({required this.expiringItems, required this.recipes});

  @override
  Widget build(BuildContext context) {
    if (expiringItems.isEmpty) return const SizedBox.shrink();
    
    // Pick the most urgent item
    final item = expiringItems.first;
    final name = item.rawName.toLowerCase();
    
    // Find recipes that use this item
    final matchingRecipes = recipes.where((r) => r.title.toLowerCase().contains(name)).toList();
    final recipeCount = matchingRecipes.length;

    int daysLeft = 0;
    if (item.expiryDate != null) {
      daysLeft = DateTime.parse(item.expiryDate!).difference(DateTime.now()).inDays;
    }

    return GestureDetector(
      onTap: () {
        if (matchingRecipes.isNotEmpty) {
          context.push('/recipes/${matchingRecipes.first.id}');
        } else {
          context.push('/recipes/ai-chef', extra: name);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF006241).withValues(alpha: 0.1)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rescue mission',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF006241),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Save your $name',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E1E),
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recipeCount > 0
                      ? "We found $recipeCount recipe${recipeCount == 1 ? '' : 's'} that utilize your $name expiring in ${daysLeft > 0 ? daysLeft : 0} days. Don't let it go to waste!"
                      : "Your $name is expiring in ${daysLeft > 0 ? daysLeft : 0} days. Tap here to ask the AI Chef for recipe ideas! Don't let it go to waste!",
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      recipeCount > 0 ? 'See rescue recipes' : 'Generate rescue recipes',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF006241),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronRight, size: 14, color: Color(0xFF006241)),
                  ],
                ),
              ],
            ),
            Positioned(
              right: -32,
              bottom: -32,
              child: Transform.rotate(
                angle: -0.2,
                child: Icon(
                  LucideIcons.leaf,
                  size: 100,
                  color: const Color(0xFF006241).withValues(alpha: 0.05),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
