import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/global_header.dart';
import '../providers/pantry_provider.dart';
import '../models/pantry_models.dart';
import '../widgets/add_item_sheet.dart';
import '../widgets/edit_item_sheet.dart';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashWidth;
  final double radius;

  DashedBorderPainter({
    this.color = Colors.black,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
    this.dashWidth = 5.0,
    this.radius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    Path path = Path()..addRRect(rrect);
    Path dashPath = Path();

    double distance = 0.0;
    for (PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth;
        distance += gap;
      }
      distance = 0.0; // reset for next metric
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.radius != radius;
  }
}

class PantryScreen extends ConsumerStatefulWidget {
  const PantryScreen({super.key});

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _healthFilter = 'All';
  String _duration = 'Week';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(pantryProvider.notifier).fetchItems());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final pantryState = ref.watch(pantryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: pantryState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text('Failed to load pantry',
                  style: GoogleFonts.outfit(color: AppColors.textHint)),
            ],
          ),
        ),
        data: (items) {
          int total = items.length;
          int expiring = items.where((i) => i.expiryStatus == ExpiryStatus.expiringSoon || i.expiryStatus == ExpiryStatus.expired).length;
          int noDate = items.where((i) => i.expiryDate == null).length;
          int stable = total - expiring - noDate;

          double expWidth = total > 0 ? (expiring / total) : 0;
          double noDateWidth = total > 0 ? (noDate / total) : 0;

          final allCategories = items.map((i) => _getCategoryLabel(i.category, i.rawName)).toSet().toList()..sort();
          final categoryOptions = ['All', ...allCategories];

          final inventoryItems = items.where((i) {
            final matchesSearch = i.rawName.toLowerCase().contains(_searchQuery);
            final catLabel = _getCategoryLabel(i.category, i.rawName);
            final matchesCategory = _selectedCategory == 'All' || catLabel == _selectedCategory;
            
            bool matchesHealth = true;
            if (_healthFilter == 'Expiring') {
              matchesHealth = i.expiryStatus == ExpiryStatus.expiringSoon || i.expiryStatus == ExpiryStatus.expired;
            } else if (_healthFilter == 'No date') {
              matchesHealth = i.expiryDate == null;
            } else if (_healthFilter == 'Stable') {
              matchesHealth = i.expiryDate != null && i.expiryStatus != ExpiryStatus.expiringSoon && i.expiryStatus != ExpiryStatus.expired;
            }

            return matchesSearch && matchesCategory && matchesHealth;
          }).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(pantryProvider.notifier).fetchItems(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const GlobalHeader(title: 'My pantry'),
                      Positioned(
                        bottom: -24,
                        left: 24,
                        right: 24,
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
                                  controller: _searchController,
                                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Search your stock...',
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
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(LucideIcons.x, size: 18, color: Color(0xFF9CA3AF)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F8F2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(LucideIcons.activity, size: 16, color: Color(0xFF006241)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Stock insights',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFF3F4F6)),
                                ),
                                child: Row(
                                  children: ['Week', 'Month', 'All'].map((d) {
                                    final isSelected = _duration == d;
                                    return GestureDetector(
                                      onTap: () => setState(() => _duration = d),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white : Colors.transparent,
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: isSelected ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 2,
                                            )
                                          ] : null,
                                        ),
                                        child: Text(
                                          d,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected ? const Color(0xFF006241) : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Pantry health',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                              Text(
                                '$total items',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  color: const Color(0xFF006241),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: SizedBox(
                              height: 12,
                              child: Row(
                                children: [
                                  if (expWidth > 0) Expanded(flex: (expWidth * 100).toInt(), child: Container(color: const Color(0xFFEF4444))),
                                  if (noDateWidth > 0) Expanded(flex: (noDateWidth * 100).toInt(), child: Container(color: const Color(0xFFFB923C))),
                                  if (total > 0 && (1 - expWidth - noDateWidth) > 0) Expanded(flex: ((1 - expWidth - noDateWidth) * 100).toInt(), child: Container(color: const Color(0xFF006241))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _healthFilter = _healthFilter == 'Expiring' ? 'All' : 'Expiring'),
                                  child: _buildStatPill(
                                    icon: LucideIcons.alertCircle,
                                    value: expiring.toString(),
                                    label: 'Expiring',
                                    valueColor: const Color(0xFFDC2626),
                                    labelColor: const Color(0xFFF87171),
                                    iconColor: const Color(0xFFEF4444),
                                    bgColor: const Color(0xFFFEF2F2),
                                    borderColor: const Color(0xFFFEE2E2),
                                    isSelected: _healthFilter == 'Expiring',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _healthFilter = _healthFilter == 'No date' ? 'All' : 'No date'),
                                  child: _buildStatPill(
                                    icon: LucideIcons.calendarX,
                                    value: noDate.toString(),
                                    label: 'No date',
                                    valueColor: const Color(0xFFEA580C),
                                    labelColor: const Color(0xFFFB923C),
                                    iconColor: const Color(0xFFF97316),
                                    bgColor: const Color(0xFFFFF7ED),
                                    borderColor: const Color(0xFFFFEDD5),
                                    isSelected: _healthFilter == 'No date',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _healthFilter = _healthFilter == 'Stable' ? 'All' : 'Stable'),
                                  child: _buildStatPill(
                                    icon: LucideIcons.package,
                                    value: stable.toString(),
                                    label: 'Stable',
                                    valueColor: const Color(0xFF006241),
                                    labelColor: const Color(0xFF006241).withValues(alpha: 0.6),
                                    iconColor: const Color(0xFF006241),
                                    bgColor: const Color(0xFFF4F8F2),
                                    borderColor: const Color(0xFFD4E9E2),
                                    isSelected: _healthFilter == 'Stable',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      scrollDirection: Axis.horizontal,
                      itemCount: categoryOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categoryOptions[index];
                        final isSelected = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF006241) : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF006241) : const Color(0xFFF3F4F6),
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ] : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              cat,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Stock inventory',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (inventoryItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(LucideIcons.packageOpen, size: 64, color: AppColors.textHint.withValues(alpha: 0.5)),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty ? 'No items match "$_searchQuery"' : 'Your pantry is empty',
                                style: GoogleFonts.outfit(color: AppColors.textHint, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: inventoryItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = inventoryItems[index];
                        String emoji = '🥫';
                        final name = item.rawName.toLowerCase();
                        if (name.contains('milk')) emoji = '🥛';
                        else if (name.contains('spinach') || name.contains('lettuce')) emoji = '🥬';
                        else if (name.contains('avocado')) emoji = '🥑';
                        else if (name.contains('chicken') || name.contains('poultry')) emoji = '🍗';
                        else if (name.contains('egg')) emoji = '🥚';
                        else if (name.contains('cheese')) emoji = '🧀';
                        else if (name.contains('apple')) emoji = '🍎';
                        else if (name.contains('tomato')) emoji = '🍅';
                        else if (name.contains('onion') || name.contains('garlic')) emoji = '🧅';
                        else if (name.contains('lemon') || name.contains('lime')) emoji = '🍋';
                        else if (name.contains('salt') || name.contains('pepper') || name.contains('spice')) emoji = '🧂';
                        else if (name.contains('fish') || name.contains('salmon') || name.contains('tuna')) emoji = '🐟';
                        else if (name.contains('beef') || name.contains('pork') || name.contains('meat')) emoji = '🥩';
                        else if (name.contains('coffee') || name.contains('tea')) emoji = '☕';
                        else if (name.contains('bread') || name.contains('bakery')) emoji = '🍞';
                        else if (name.contains('yogurt')) emoji = '🍨';

                        String dateStr = item.expiryDate != null ? DateFormat('yyyy-MM-dd').format(DateTime.parse(item.expiryDate!)) : 'N/A';

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF3F4F6)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _showEditItemDialog(context, item),
                              child: Row(
                                children: [
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF4F8F2),
                                      borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(emoji, style: const TextStyle(fontSize: 32)),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _capitalizeWords(item.rawName),
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -0.2,
                                              color: AppColors.textPrimary,
                                              height: 1.2,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                '${item.quantity} ${item.unit}',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF9CA3AF),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '•',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFFD1D5DB),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Exp. $dateStr',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF9CA3AF),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(LucideIcons.trash2, size: 16, color: Color(0xFFE5E7EB)),
                                        onPressed: () => ref.read(pantryProvider.notifier).deleteItem(item.id),
                                        splashRadius: 20,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: CustomPaint(
                      painter: DashedBorderPainter(
                        color: const Color(0xFFD1D5DB),
                        strokeWidth: 1.5,
                        gap: 6.0,
                        dashWidth: 6.0,
                        radius: 16.0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F0EB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                  )
                                ],
                              ),
                              child: const Icon(LucideIcons.shoppingCart, color: Color(0xFF9CA3AF), size: 20),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Just finished shopping?',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bulk add items or scan your latest receipt to update your kitchen mission.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B7280),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              onPressed: () => context.push('/pantry/scan'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF006241),
                                side: const BorderSide(color: Color(0xFF006241), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Text(
                                'Bulk update',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
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
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String value,
    required String label,
    required Color valueColor,
    required Color labelColor,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? valueColor : borderColor, width: isSelected ? 2 : 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddItemSheet(
        onAdd: (payload) {
          ref.read(pantryProvider.notifier).addItem(payload);
        },
      ),
    );
  }

  void _showEditItemDialog(BuildContext context, PantryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditItemSheet(
        item: item,
        onUpdate: (payload) {
          ref.read(pantryProvider.notifier).updateItem(item.id, payload);
        },
      ),
    );
  }

  String _getCategoryLabel(String category, String itemName) {
    String finalCategory = category.toLowerCase();
    if (finalCategory == 'other' || finalCategory.isEmpty) {
      final lowerName = itemName.toLowerCase();
      final singular = lowerName.endsWith('ies') ? lowerName.substring(0, lowerName.length - 3) + 'y' 
                     : lowerName.endsWith('es') ? lowerName.substring(0, lowerName.length - 2) 
                     : lowerName.endsWith('s') ? lowerName.substring(0, lowerName.length - 1) 
                     : lowerName;

      final produce = ["tomato", "potato", "carrot", "cucumber", "onion", "garlic", "apple", "banana", "broccoli", "pepper", "spinach", "lettuce", "strawberry", "radish", "eggplant", "salad", "celery", "mushroom", "zucchini", "squash", "cabbage", "cauliflower", "asparagus", "corn", "bean", "pea", "grape", "orange", "lemon", "lime", "berry", "melon", "peach", "plum", "cherry", "avocado", "kale", "mango", "fruit", "pear", "kiwi", "pineapple"];
      final dairy = ["milk", "egg", "cheese", "butter", "cream", "yogurt", "ghee", "kefir", "whey"];
      final meat = ["beef", "chicken", "pork", "sausage", "ham", "bacon", "turkey", "tenderloin", "lamb", "veal", "duck", "venison", "prosciutto", "salami"];
      final seafood = ["fish", "salmon", "tuna", "shrimp", "crab", "lobster", "scallop", "clam", "mussel", "oyster", "squid", "octopus", "cod", "halibut", "tilapia", "anchovy", "sardine"];
      final spices = ["salt", "pepper", "parsley", "basil", "oregano", "cinnamon", "cumin", "spice", "herb", "thyme", "rosemary", "sage", "cilantro", "mint", "dill", "chive", "paprika", "nutmeg", "clove", "ginger", "turmeric", "saffron", "cardamom", "coriander"];
      final condiments = ["oil", "vinegar", "mustard", "ketchup", "mayo", "sauce", "dressing", "sugar", "syrup", "honey", "jam", "jelly", "spread", "dip", "salsa", "relish", "soy", "teriyaki", "sriracha"];
      
      bool matches(List<String> keywords) => keywords.any((k) => lowerName.contains(k) || singular.contains(k));
      
      if (matches(produce)) finalCategory = 'produce';
      else if (matches(dairy)) finalCategory = 'dairy';
      else if (matches(meat)) finalCategory = 'meat';
      else if (matches(seafood)) finalCategory = 'seafood';
      else if (matches(spices)) finalCategory = 'spices';
      else if (matches(condiments)) finalCategory = 'condiments';
    }

    switch (finalCategory) {
      case 'produce': return 'Produce';
      case 'condiments & oils':
      case 'condiments': return 'Condiments & Oils';
      case 'dairy & eggs':
      case 'dairy': return 'Dairy & Eggs';
      case 'meat & poultry':
      case 'meat': return 'Meat & Poultry';
      case 'spices & herbs':
      case 'spices': 
      case 'herbs':
      case 'seasoning': return 'Spices & Herbs';
      case 'seafood': return 'Seafood';
      case 'beverages': 
      case 'drink':
      case 'tea':
      case 'coffee': return 'Beverages';
      case 'grains & pasta':
      case 'grains': 
      case 'pasta': return 'Grains & Pasta';
      case 'bakery': return 'Bakery';
      case 'frozen': return 'Frozen';
      case 'pantry': return 'Pantry';
      default: return finalCategory.isNotEmpty ? finalCategory[0].toUpperCase() + finalCategory.substring(1).toLowerCase() : 'Other';
    }
  }
}
