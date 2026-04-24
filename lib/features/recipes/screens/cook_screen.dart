import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../models/recipe_models.dart';
import '../providers/recipes_provider.dart';
import '../../pantry/providers/pantry_provider.dart';

/// ──────────────────────────────────────────────
/// Cook Screen
/// Preview ingredient deductions then confirm
/// to update the pantry
/// ──────────────────────────────────────────────

class CookScreen extends ConsumerStatefulWidget {
  final RecipeDetail recipe;
  const CookScreen({super.key, required this.recipe});

  @override
  ConsumerState<CookScreen> createState() => _CookScreenState();
}

class _CookScreenState extends ConsumerState<CookScreen> {
  CookResult? _dryRunResult;
  bool _isLoading = true;
  bool _isRecalculating = false;
  bool _isConfirming = false;
  int _servings = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _servings = (widget.recipe.servings ?? 1).round();
    _fetchDryRun();
  }

  Future<void> _fetchDryRun({bool silent = false}) async {
    setState(() {
      if (silent) {
        _isRecalculating = true;
      } else {
        _isLoading = true;
      }
      _error = null;
    });
    try {
      final result = await ref.read(recipesServiceProvider).cookRecipe(
            recipeId: widget.recipe.id,
            servingsUsed: _servings.toDouble(),
            dryRun: true,
          );
      if (mounted) {
        setState(() {
          _dryRunResult = result;
          _isLoading = false;
          _isRecalculating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _isRecalculating = false;
        });
      }
    }
  }

  Future<void> _confirmCook() async {
    setState(() => _isConfirming = true);
    try {
      await ref.read(recipesServiceProvider).cookRecipe(
            recipeId: widget.recipe.id,
            servingsUsed: _servings.toDouble(),
            dryRun: false,
          );
      // Invalidate pantry to refresh after deductions
      ref.invalidate(pantryProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cook recipe: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        title: Text(
          'Cook Now',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load deduction preview',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error ?? 'Unknown error',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _fetchDryRun,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Recipe header
                    Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF212121).withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.recipe.title,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(_dryRunResult?.updatedItems.length ?? 0) + (_dryRunResult?.removedItems.length ?? 0)} ingredients affected',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Servings stepper
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Servings',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: _servings > 1
                                      ? () {
                                          setState(() => _servings -= 1);
                                          _fetchDryRun(silent: true);
                                        }
                                      : null,
                                  icon: const Icon(LucideIcons.minus),
                                  iconSize: 20,
                                  color: AppColors.textPrimary,
                                  disabledColor: AppColors.textSecondary.withValues(alpha: 0.3),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.surfaceTint,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: SizedBox(
                                    width: 24,
                                    child: Center(
                                      child: _isRecalculating
                                          ? const SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : Text(
                                              _servings.toString(),
                                              style: GoogleFonts.outfit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() => _servings += 1);
                                    _fetchDryRun(silent: true);
                                  },
                                  icon: const Icon(LucideIcons.plus),
                                  iconSize: 20,
                                  color: AppColors.textPrimary,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.surfaceTint,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deductions list
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          if (_dryRunResult?.updatedItems.isEmpty == true && _dryRunResult?.removedItems.isEmpty == true) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              child: Column(
                                children: [
                                  Icon(LucideIcons.info, size: 48, color: AppColors.primary.withValues(alpha: 0.2)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Nothing to update',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'No matching ingredients were found in your pantry.',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Summary Cards
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      border: Border.all(color: Colors.blue.shade100),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${_dryRunResult?.updatedItems.length ?? 0}',
                                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.blue.shade700),
                                        ),
                                        Text(
                                          'UPDATED',
                                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue.shade600, letterSpacing: 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      border: Border.all(color: Colors.red.shade100),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          '${_dryRunResult?.removedItems.length ?? 0}',
                                          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.red.shade700),
                                        ),
                                        Text(
                                          'REMOVED',
                                          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade600, letterSpacing: 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          if (_dryRunResult?.updatedItems.isNotEmpty == true) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.check, size: 16, color: Colors.blue.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Quantity Reduced',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ..._dryRunResult!.updatedItems.map((item) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAF7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name[0].toUpperCase() + item.name.substring(1),
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            item.beforeQty.toStringAsFixed(item.beforeQty == item.beforeQty.roundToDouble() ? 0 : 1),
                                            style: GoogleFonts.outfit(fontSize: 13, color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(LucideIcons.arrowRight, size: 12, color: AppColors.textSecondary),
                                          const SizedBox(width: 4),
                                          Text(
                                            item.afterQty.toStringAsFixed(item.afterQty == item.afterQty.roundToDouble() ? 0 : 1),
                                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],

                          if (_dryRunResult?.removedItems.isNotEmpty == true) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Icon(LucideIcons.trash2, size: 16, color: Colors.red.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Removed Completely',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ..._dryRunResult!.removedItems.map((item) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7FAF7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Text(
                                        'USED UP',
                                        style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700, letterSpacing: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                          ],

                          if (_dryRunResult?.unmatchedIngredients.isNotEmpty == true) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.alertCircle, size: 16, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Not found in pantry',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _dryRunResult!.unmatchedIngredients.map((ing) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceTint,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    ing,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),

                    // Confirm button
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed:
                                _isConfirming ? null : _confirmCook,
                            icon: _isConfirming
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.local_fire_department_rounded),
                            label: Text(
                              'Confirm & Cook',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
