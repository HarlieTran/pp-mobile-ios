import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../models/pantry_models.dart';
import '../providers/pantry_provider.dart';

/// ──────────────────────────────────────────────
/// Scan Review Screen
/// Confirm, deselect, or edit AI-parsed ingredients
/// before committing them to the pantry
/// ──────────────────────────────────────────────

class ScanReviewScreen extends ConsumerStatefulWidget {
  final List<ParsedIngredient> items;
  const ScanReviewScreen({super.key, required this.items});

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late List<ParsedIngredient> _currentItems;
  late List<TextEditingController> _nameControllers;
  late List<TextEditingController> _quantityControllers;
  late List<String> _selectedUnits;
  late List<DateTime> _expiryDates;
  bool _isSubmitting = false;

  static const _units = ['pcs', 'g', 'kg', 'oz', 'lb', 'ml', 'L', 'cup', 'tbsp', 'tsp', 'unit', 'bowl'];

  @override
  void initState() {
    super.initState();
    _currentItems = List.from(widget.items);
    _nameControllers = _currentItems
        .map((i) {
          final words = i.name.split(' ');
          final capitalized = words.map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
          return TextEditingController(text: capitalized);
        })
        .toList();
    _quantityControllers = _currentItems
        .map((i) => TextEditingController(text: i.quantity))
        .toList();
    _selectedUnits = _currentItems.map((i) {
      final u = i.unit.toLowerCase();
      if (_units.contains(u)) return u;
      return 'pcs';
    }).toList();
    _expiryDates = _currentItems.map((i) {
      final lifespan = ExpiryHelper.getDefaultLifespanDays(i.category);
      return DateTime.now().add(Duration(days: lifespan));
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _nameControllers) {
      c.dispose();
    }
    for (final c in _quantityControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addManualRow() {
    setState(() {
      _currentItems.add(const ParsedIngredient(name: '', quantity: '1', unit: 'pcs', category: 'Other'));
      _nameControllers.add(TextEditingController(text: ''));
      _quantityControllers.add(TextEditingController(text: '1'));
      _selectedUnits.add('pcs');
      _expiryDates.add(DateTime.now().add(const Duration(days: 30)));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _currentItems.removeAt(index);
      _nameControllers[index].dispose();
      _nameControllers.removeAt(index);
      _quantityControllers[index].dispose();
      _quantityControllers.removeAt(index);
      _selectedUnits.removeAt(index);
      _expiryDates.removeAt(index);
    });
  }

  int get _selectedCount => _currentItems.length;

  Future<void> _addItems() async {
    setState(() => _isSubmitting = true);

    final payloads = <AddPantryItemPayload>[];
    for (int i = 0; i < _currentItems.length; i++) {
      if (_nameControllers[i].text.trim().isEmpty) continue;
      payloads.add(AddPantryItemPayload(
        rawName: _nameControllers[i].text.trim(),
        quantity:
            double.tryParse(_quantityControllers[i].text) ?? 1.0,
        unit: _selectedUnits[i],
        expiryDate: _expiryDates[i].toIso8601String().split('T').first,
      ));
    }

    if (payloads.isEmpty) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one valid item.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await ref.read(pantryProvider.notifier).bulkAddItems(payloads);
      if (mounted) context.go('/pantry');
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add items. Tap to retry.'),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _addItems,
            ),
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
          'Review Items',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // Info bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI detected ${_currentItems.length} items. Remove or edit before adding.',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Item list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _currentItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _currentItems[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Name and Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Transform.translate(
                              offset: const Offset(-2, 0),
                              child: TextField(
                                controller: _nameControllers[index],
                                textCapitalization: TextCapitalization.words,
                                onChanged: (value) {
                                  final newCategory = ExpiryHelper.guessCategory(value);
                                  if (newCategory != item.category) {
                                    setState(() {
                                      _currentItems[index] = ParsedIngredient(
                                        name: value,
                                        quantity: item.quantity,
                                        unit: item.unit,
                                        category: newCategory,
                                      );
                                      final lifespan = ExpiryHelper.getDefaultLifespanDays(newCategory);
                                      _expiryDates[index] = DateTime.now().add(Duration(days: lifespan));
                                    });
                                  }
                                },
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: 'Item name',
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (item.category.isNotEmpty)
                              Text(
                                item.category.toLowerCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _expiryDates[index],
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                                );
                                if (picked != null) {
                                  setState(() => _expiryDates[index] = picked);
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.event_outlined, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      'Exp: ${_expiryDates[index].year}-${_expiryDates[index].month.toString().padLeft(2, '0')}-${_expiryDates[index].day.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      const SizedBox(width: 16),
                      // Controls
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Quantity
                          Container(
                            width: 44,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: TextField(
                              controller: _quantityControllers[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 9),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Unit
                          Container(
                            width: 64,
                            height: 36,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedUnits[index],
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.textSecondary),
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                                items: _units
                                    .map((u) => DropdownMenuItem(
                                        value: u, child: Center(child: Text(u))))
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _selectedUnits[index] = v);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _removeItem(index),
                            icon: const Icon(LucideIcons.trash2),
                            color: AppColors.error,
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Add Row Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _addManualRow,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text('Add another item', style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),

          // Bottom button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed:
                      _isSubmitting || _selectedCount == 0 ? null : _addItems,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Add $_selectedCount item${_selectedCount == 1 ? '' : 's'}',
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
