import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/planner_provider.dart';
import '../models/planner_models.dart';
import '../../pantry/providers/pantry_provider.dart';
import '../../recipes/providers/recipes_provider.dart';
import '../../recipes/models/recipe_models.dart';

/// ──────────────────────────────────────────────
/// Shopping List — Starbucks-style redesign
/// Mirrors: ShoppingView.jsx mockup
/// ──────────────────────────────────────────────

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});
  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  String _selectedDay = 'All';
  final Set<int> _excludedRecipeIds = {};
  final Set<String> _cartNames = {};   // lowercased names moved to cart
  final List<Map<String, String>> _extraItems = [];
  final TextEditingController _customItemCtrl = TextEditingController();
  
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() { 
    _customItemCtrl.dispose(); 
    _searchCtrl.dispose();
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(plannerProvider);
    final pantryState = ref.watch(pantryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: planState.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (e, _) => Center(child: Text('Error loading plan', style: GoogleFonts.outfit(color: AppColors.error))),
          data: (plan) => _buildContent(context, plan, pantryState),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, MealPlan plan, AsyncValue pantryState) {
    // ── Week days from the current week ──
    final now = DateTime.now();
    final mondayOffset = now.weekday % 7;
    final weekStart = now.subtract(Duration(days: mondayOffset));
    final weekDays = List.generate(7, (i) {
      final d = weekStart.add(Duration(days: i));
      return _WeekDay(
        abbr: DateFormat('EEE').format(d).toUpperCase().substring(0, 3),
        num: d.day.toString(),
        iso: DateFormat('yyyy-MM-dd').format(d),
      );
    });

    // ── All recipes (planned + undated) ──
    final allRecipes = plan.entries;
    final filteredRecipes = allRecipes.where((e) {
      if (_selectedDay == 'All') return true;
      return e.date == _selectedDay;
    }).toList();

    // ── Active (not excluded) for shopping ──
    final activeRecipes = filteredRecipes.where((e) => !_excludedRecipeIds.contains(e.recipeId)).toList();

    // ── Compute ingredients ──
    final pantryItems = pantryState.value ?? [];
    final requiredMap = <String, List<String>>{};
    for (final recipe in activeRecipes) {
      for (final ing in recipe.requiredIngredients) {
        final name = ing.name.toLowerCase();
        requiredMap.putIfAbsent(name, () => []);
        if (ing.quantity.isNotEmpty) requiredMap[name]!.add(ing.quantity);
      }
    }

    final allIngredients = <_ShopItem>[];
    for (final entry in requiredMap.entries) {
      final amounts = entry.value.toSet().toList();
      final amountStr = amounts.isNotEmpty ? amounts.join(' & ') : 'Some';
      final inStock = pantryItems.any((p) => _isMatch(entry.key, p.rawName));
      allIngredients.add(_ShopItem(name: entry.key, amount: amountStr, inStock: inStock));
    }

    // Add extra/custom items
    final extras = _extraItems.map((e) => _ShopItem(name: e['name']!, amount: 'Manual', inStock: false)).toList();

    final toBuyAll = allIngredients.where((i) => !i.inStock).toList()..addAll(extras);
    final toBuy = toBuyAll.where((i) => !_cartNames.contains(i.name.toLowerCase())).toList();
    final inCart = toBuyAll.where((i) => _cartNames.contains(i.name.toLowerCase())).toList();
    final inPantry = allIngredients.where((i) => i.inStock).toList();

    return Column(children: [
      // ── Header ──
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(20)),
                child: const Icon(LucideIcons.chevronLeft, size: 24, color: Color(0xFF111827)),
              ),
            ),
            const SizedBox(width: 12),
            Text('Shopping list', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5)),
          ]),
          GestureDetector(
            onTap: () => _copyList(toBuy),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFF4F8F2), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.copy, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Copy list', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ]),
            ),
          ),
        ]),
      ),

      // ── Search bar ──
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: Colors.white,
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
                  onSubmitted: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search recipe to add...',
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
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(LucideIcons.x, size: 18, color: Color(0xFF9CA3AF)),
                ),
            ],
          ),
        ),
      ),

      // ── Content ──
      if (_searchQuery.isNotEmpty)
        Expanded(child: _buildSearchResults(context))
      else
        Expanded(child: ListView(padding: EdgeInsets.zero, children: [
        // ── Day strip ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
          ),
          child: Row(children: [
            // All button
            GestureDetector(
              onTap: () => setState(() => _selectedDay = 'All'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedDay == 'All' ? const Color(0xFF006241) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _selectedDay == 'All' ? [BoxShadow(color: const Color(0xFF006241).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('WEEK', style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w800, color: _selectedDay == 'All' ? Colors.white : const Color(0xFF9CA3AF))),
                  const SizedBox(height: 2),
                  Text('All', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: _selectedDay == 'All' ? Colors.white : const Color(0xFF9CA3AF))),
                ]),
              ),
            ),
            // Divider
            Container(width: 1, height: 32, margin: const EdgeInsets.symmetric(horizontal: 8), color: const Color(0xFFF3F4F6)),
            // Weekday buttons
            Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: weekDays.map((day) {
              final sel = _selectedDay == day.iso;
              final hasMeals = plan.entries.any((e) => e.date == day.iso);
              return GestureDetector(
                onTap: () => setState(() => _selectedDay = day.iso),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40, height: 48,
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF006241) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: sel ? [BoxShadow(color: const Color(0xFF006241).withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 3))] : null,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(day.abbr, style: GoogleFonts.outfit(fontSize: 7, fontWeight: FontWeight.w800, color: sel ? Colors.white : const Color(0xFF9CA3AF))),
                    const SizedBox(height: 2),
                    Text(day.num, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: sel ? Colors.white : (hasMeals ? AppColors.textPrimary : const Color(0xFF9CA3AF)))),
                  ]),
                ),
              );
            }).toList())),
          ]),
        ),

        // ── Recipes section ──
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('RECIPES TO SHOP FOR', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF111827), letterSpacing: 1.4)),
            const SizedBox(height: 24),
            // Recipe cards
            ...filteredRecipes.map((meal) {
              final isExcluded = _excludedRecipeIds.contains(meal.recipeId);
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isExcluded ? 0.4 : 1.0,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isExcluded ? const Color(0xFFF9FAFB) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isExcluded ? Colors.transparent : const Color(0xFFF3F4F6)),
                    boxShadow: isExcluded ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: meal.imageUrl != null
                        ? CachedNetworkImage(imageUrl: meal.imageUrl!, width: 56, height: 56, fit: BoxFit.cover)
                        : Container(width: 56, height: 56, color: const Color(0xFFF3F4F6), child: const Center(child: Text('🍲', style: TextStyle(fontSize: 24)))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(meal.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.3)),
                      const SizedBox(height: 4),
                      Text(meal.date == null ? 'UNDATED QUEUE' : 'APR ${DateTime.tryParse(meal.date!)?.day ?? meal.date}',
                        style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), letterSpacing: 0.5)),
                    ])),
                    GestureDetector(
                      onTap: () => setState(() {
                        if (isExcluded) { _excludedRecipeIds.remove(meal.recipeId); }
                        else { _excludedRecipeIds.add(meal.recipeId); }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(isExcluded ? LucideIcons.plusCircle : LucideIcons.x,
                          size: 20, color: isExcluded ? const Color(0xFF006241) : const Color(0xFFD1D5DB)),
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ]),
        ),

        const SizedBox(height: 8),

        // ── Lists section ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 80),
          child: Column(children: [
            // ── To Buy ──
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(left: BorderSide(color: Color(0xFF006241), width: 4)),
                  ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('To buy', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(12)),
                    child: Text('${toBuy.length} items', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFEA580C))),
                  ),
                ]),
                const SizedBox(height: 32),
                // Items
                ...toBuy.map((item) => _ToBuyRow(
                  item: item,
                  onTap: () => setState(() => _cartNames.add(item.name.toLowerCase())),
                  onRemove: () => setState(() {
                    _extraItems.removeWhere((e) => e['name']!.toLowerCase() == item.name.toLowerCase());
                    _cartNames.remove(item.name.toLowerCase());
                  }),
                )),
                // Custom item input
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF9FAFB)))),
                  child: Row(children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5E7EB), width: 2, style: BorderStyle.solid)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: TextField(
                      controller: _customItemCtrl,
                      style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Add custom item...',
                        hintStyle: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFFD1D5DB)),
                        border: InputBorder.none, isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _addCustomItem(),
                    )),
                    GestureDetector(
                      onTap: _addCustomItem,
                      child: const Icon(LucideIcons.plusCircle, size: 20, color: Color(0xFFD1D5DB)),
                    ),
                  ]),
                ),
                  ]),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── In My Cart ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF006241).withValues(alpha: 0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('In my cart', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF006241), letterSpacing: -0.3)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF4F8F2), borderRadius: BorderRadius.circular(12)),
                    child: Text('${inCart.length} items', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF006241))),
                  ),
                ]),
                const SizedBox(height: 24),
                if (inCart.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('Tap items above as you pick them up.', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), fontStyle: FontStyle.italic)),
                  ))
                else
                  ...inCart.map((item) => _InCartRow(
                    item: item,
                    onTap: () => setState(() => _cartNames.remove(item.name.toLowerCase())),
                  )),
              ]),
            ),

            const SizedBox(height: 16),

            // ── In Pantry ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBF9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF006241).withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Icon(LucideIcons.package, size: 16, color: const Color(0xFF006241).withValues(alpha: 0.5)),
                    const SizedBox(width: 8),
                    Text('In pantry', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.3)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                    child: Text('${inPantry.length} items', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280))),
                  ),
                ]),
                const SizedBox(height: 24),
                ...inPantry.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(children: [
                    Container(
                      width: 20, height: 20,
                      decoration: const BoxDecoration(color: Color(0xFFD4E9E2), shape: BoxShape.circle),
                      child: const Center(child: Icon(LucideIcons.package, size: 10, color: Color(0xFF006241))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_capitalize(item.name),
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280), decoration: TextDecoration.lineThrough, letterSpacing: -0.3)),
                      Text('ALREADY IN STOCK', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), letterSpacing: 0.5)),
                    ])),
                  ]),
                )),
                if (inPantry.isEmpty)
                  Center(child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('No matching pantry items.', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF), fontStyle: FontStyle.italic)),
                  )),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 32),
      ])),
    ]);
  }

  void _addCustomItem() {
    final text = _customItemCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _extraItems.insert(0, {'name': text});
      _customItemCtrl.clear();
    });
  }

  Widget _buildSearchResults(BuildContext context) {
    final searchAsync = ref.watch(recipeSearchProvider(_searchQuery));
    return searchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Search failed')),
      data: (recipes) {
        if (recipes.isEmpty) {
          return Center(child: Text('No recipes found', style: GoogleFonts.outfit(color: AppColors.textHint)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: recipes.length,
          itemBuilder: (context, i) {
            final recipe = recipes[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: recipe.imageUrl != null 
                    ? CachedNetworkImage(imageUrl: recipe.imageUrl!, width: 48, height: 48, fit: BoxFit.cover)
                    : Container(width: 48, height: 48, color: const Color(0xFFF3F4F6)),
                ),
                title: Text(recipe.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary),
                  onPressed: () async {
                    try {
                      await ref.read(plannerProvider.notifier).addRecipe(recipe.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Added to Shopping List', style: GoogleFonts.outfit()), 
                          backgroundColor: AppColors.primary,
                        ));
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Failed to add recipe', style: GoogleFonts.outfit()), 
                          backgroundColor: AppColors.error,
                        ));
                      }
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _copyList(List<_ShopItem> toBuy) {
    final lines = toBuy.map((i) => '☐ ${_capitalize(i.name)} (${i.amount})').join('\n');
    final text = '🛒 Shopping List\n\n$lines\n\nGenerated by PantryPal';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shopping list copied!', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  bool _isMatch(String recipeIngredient, String pantryItemName) {
    final a = recipeIngredient.toLowerCase().trim();
    final b = pantryItemName.toLowerCase().trim();
    if (a == b) return true;
    if (a.contains(b) || b.contains(a)) return true;

    String toSingular(String word) {
      if (word.endsWith('ies')) return '${word.substring(0, word.length - 3)}y';
      if (word.endsWith('oes')) return word.substring(0, word.length - 2);
      if (word.endsWith('ses') || word.endsWith('xes') || word.endsWith('zes') || word.endsWith('ches') || word.endsWith('shes')) return word.substring(0, word.length - 2);
      if (word.endsWith('s') && !word.endsWith('ss')) return word.substring(0, word.length - 1);
      return word;
    }

    final singA = a.split(' ').map(toSingular).join(' ');
    final singB = b.split(' ').map(toSingular).join(' ');
    if (singA == singB) return true;
    if (singA.contains(singB) || singB.contains(singA)) return true;

    final stopWords = {'fresh', 'chopped', 'diced', 'minced', 'ground', 'extra', 'virgin', 'organic', 'large', 'small', 'medium', 'boneless', 'skinless', 'unsalted', 'salted', 'reduced', 'low', 'fat', 'to', 'taste'};
    
    List<String> tokenize(String text) {
      return text.replaceAll(RegExp(r'[^a-z0-9\s]'), '').split(' ')
          .map((e) => e.trim())
          .where((e) => e.length > 1 && !stopWords.contains(e))
          .toList();
    }
    
    final ta = tokenize(singA);
    final tb = tokenize(singB);
    
    if (ta.isEmpty || tb.isEmpty) return false;
    
    int overlap = 0;
    for (final token in ta) {
      if (tb.contains(token)) overlap++;
    }
    
    final ratio = overlap / (ta.length > tb.length ? ta.length : tb.length);
    return ratio >= 0.5;
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── Data models ──

class _ShopItem {
  final String name;
  final String amount;
  final bool inStock;
  const _ShopItem({required this.name, required this.amount, required this.inStock});
}

class _WeekDay {
  final String abbr;
  final String num;
  final String iso;
  const _WeekDay({required this.abbr, required this.num, required this.iso});
}

// ── To Buy row ──

class _ToBuyRow extends StatelessWidget {
  final _ShopItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  const _ToBuyRow({required this.item, required this.onTap, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_capitalize(item.name), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827), letterSpacing: -0.3)),
            Text(item.amount.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF))),
          ])),
          GestureDetector(
            onTap: onRemove,
            child: const Padding(padding: EdgeInsets.all(4), child: Icon(LucideIcons.x, size: 16, color: Color(0xFFE5E7EB))),
          ),
        ]),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── In Cart row ──

class _InCartRow extends StatelessWidget {
  final _ShopItem item;
  final VoidCallback onTap;
  const _InCartRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(color: Color(0xFF006241), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x20006241), blurRadius: 4, offset: Offset(0, 2))]),
            child: const Center(child: Icon(LucideIcons.check, size: 10, color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_capitalize(item.name), style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827), letterSpacing: -0.3)),
            Text(item.amount.toUpperCase(), style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF))),
          ])),
        ]),
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
