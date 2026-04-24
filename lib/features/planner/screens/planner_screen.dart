import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/global_header.dart';
import '../providers/planner_provider.dart';
import '../models/planner_models.dart';
import 'shopping_list_screen.dart';

class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});
  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  late DateTime _weekStart;
  String? _selectedDayStr; // yyyy-MM-dd of focused day
  final ScrollController _scrollCtrl = ScrollController();
  final Map<String, GlobalKey> _dayKeys = {};

  static DateTime _mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday % 7));

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
    _selectedDayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    Future.microtask(() {
      ref.read(plannerProvider.notifier).fetchPlan();
      ref.read(plannerNotesProvider.notifier).fetchNotes();
    });
  }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  List<_Day> get _weekDays => List.generate(7, (i) {
    final d = _weekStart.add(Duration(days: i));
    final now = DateTime.now();
    final iso = DateFormat('yyyy-MM-dd').format(d);
    _dayKeys.putIfAbsent(iso, () => GlobalKey());
    return _Day(
      abbr: DateFormat('EEE').format(d).toUpperCase(),
      num: d.day.toString(),
      full: DateFormat('EEEE').format(d).toUpperCase(),
      iso: iso,
      isToday: d.year == now.year && d.month == now.month && d.day == now.day,
      dt: d,
    );
  });

  void _scrollToDay(String iso) {
    setState(() => _selectedDayStr = iso);
    final key = _dayKeys[iso];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(key!.currentContext!, duration: const Duration(milliseconds: 400), curve: Curves.easeOut, alignmentPolicy: ScrollPositionAlignmentPolicy.explicit);
    }
  }

  Future<void> _pickDateForRecipe(int recipeId) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF006241), onPrimary: Colors.white, surface: Colors.white, onSurface: Color(0xFF1E1E1E))), child: child!),
    );
    if (picked != null && mounted) {
      await ref.read(plannerProvider.notifier).addRecipe(recipeId, date: DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final planState = ref.watch(plannerProvider);
    final days = _weekDays;
    final month = DateFormat('MMMM yyyy').format(_weekStart.add(const Duration(days: 3))).toUpperCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header ──
          const GlobalHeader(title: 'My planner'),

          // ── Week strip (below header, not overlapping title) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF3F4F6)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(children: [
                  // Month nav
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    GestureDetector(onTap: () => setState(() { _weekStart = _weekStart.subtract(const Duration(days: 7)); _selectedDayStr = null; }),
                      child: const Padding(padding: EdgeInsets.all(4), child: Icon(LucideIcons.chevronLeft, size: 20, color: Color(0xFF9CA3AF)))),
                    Text(month, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF1E1E1E), letterSpacing: 0.5)),
                    GestureDetector(onTap: () => setState(() { _weekStart = _weekStart.add(const Duration(days: 7)); _selectedDayStr = null; }),
                      child: const Padding(padding: EdgeInsets.all(4), child: Icon(LucideIcons.chevronRight, size: 20, color: Color(0xFF9CA3AF)))),
                  ]),
                  const SizedBox(height: 12),
                  // Day buttons
                  planState.when(
                    loading: () => const SizedBox(height: 56),
                    error: (_, __) => const SizedBox(height: 56),
                    data: (plan) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: days.map((day) {
                      final sel = _selectedDayStr == day.iso;
                      final has = plan.entries.any((e) => e.date == day.iso);
                      return GestureDetector(
                        onTap: () => _scrollToDay(day.iso),
                        child: AnimatedScale(scale: sel ? 1.1 : 1.0, duration: const Duration(milliseconds: 200),
                          child: Stack(clipBehavior: Clip.none, children: [
                            Container(width: 40, height: 64, padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(color: sel ? const Color(0xFF006241) : Colors.transparent, borderRadius: BorderRadius.circular(12),
                                boxShadow: sel ? [BoxShadow(color: const Color(0xFF006241).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(day.abbr, style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w800, color: sel ? Colors.white : const Color(0xFF9CA3AF))),
                                const SizedBox(height: 4),
                                Text(day.num, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w800, color: sel ? Colors.white : const Color(0xFF9CA3AF))),
                              ])),
                            if (day.isToday && !sel) Positioned(bottom: 4, left: 0, right: 0, child: Center(child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF006241), shape: BoxShape.circle)))),
                            if (has && !sel) Positioned(top: -2, right: -2, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFFFB923C), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                            if (ref.watch(plannerNotesProvider).containsKey(day.iso) && !sel) Positioned(bottom: -2, left: -2, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF006241), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                          ])));
                    }).toList()),
                  ),
                ]),
              ),
            ),
          ),

          // ── Undated recipes (vertical list) ──
          planState.when(
            loading: () => const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator())),
            error: (_, __) => Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Failed to load plan', style: GoogleFonts.outfit(color: AppColors.textHint)))),
            data: (plan) {
              final undated = plan.entries.where((e) => e.date == null).toList();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Header
                Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Row(children: [
                  const Icon(LucideIcons.inbox, size: 18, color: Color(0xFF006241)),
                  const SizedBox(width: 8),
                  Text('Undated recipes', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E1E1E), letterSpacing: -0.3)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFF4F8F2), borderRadius: BorderRadius.circular(999)),
                    child: Text('${undated.length}', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF006241)))),
                ])),
                const SizedBox(height: 12),
                // Vertical list of undated
                if (undated.isNotEmpty)
                  ...undated.map((m) => _UndatedCard(meal: m, onTapDate: () => _pickDateForRecipe(m.recipeId), onTapInfo: () => context.push('/recipes/${m.recipeId}'), onRemove: () => ref.read(plannerProvider.notifier).removeRecipe(m.recipeId)))
                else
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: CustomPaint(
                    painter: _DashedBorderPainter(color: const Color(0xFFE5E7EB), radius: 16, dashWidth: 6, dashSpace: 4),
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(color: const Color(0xFFF9FAFB).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
                      child: Center(child: Text('Queue empty', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF))))))),

                const SizedBox(height: 32),

                // ── Day sections ──
                ...days.map((dayObj) {
                  final meals = plan.entries.where((e) => e.date == dayObj.iso).toList();
                  final focused = _selectedDayStr == dayObj.iso;
                  return _DaySection(key: _dayKeys[dayObj.iso], day: dayObj, meals: meals, focused: focused, note: ref.watch(plannerNotesProvider)[dayObj.iso], onRemove: (id) => ref.read(plannerProvider.notifier).removeRecipe(id), onTapInfo: (id) => context.push('/recipes/$id'), onTapDate: (id) => _pickDateForRecipe(id), onAcceptDrop: (recipeId) => ref.read(plannerProvider.notifier).addRecipe(recipeId, date: dayObj.iso), onTapNote: () => _showNoteDetail(dayObj.iso));
                }),

                const SizedBox(height: 16),

                // ── Quick Notes CTA ──
                _buildNotesCta(),
              ]);
            },
          ),
        ]),
      ),
      // ── Shop FAB ──
      floatingActionButton: GestureDetector(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
        child: Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: const Color(0xFF4D6B5E), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF4D6B5E).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 8))]),
          child: Stack(alignment: Alignment.center, children: [
            const Icon(LucideIcons.shoppingCart, color: Colors.white, size: 22),
            Positioned(top: 14, right: 14, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle))),
          ]),
        ),
      ),
    );
  }

  // ── Quick Notes CTA (styled like Bulk Update in Pantry) ──
  Widget _buildNotesCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: const Color(0xFFD1D5DB), radius: 16, dashWidth: 6, dashSpace: 6, strokeWidth: 1.5),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F0EB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
              ),
              child: const Icon(LucideIcons.stickyNote, color: Color(0xFF9CA3AF), size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              'Quick Notes',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: -0.2, color: const Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            Text(
              'Pin reminders, events, or memos to any day on your planner.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280), height: 1.4),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: _showAddNoteDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF006241),
                side: const BorderSide(color: Color(0xFF006241), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Add a note', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Add note (bottom sheet matching app theme) ──
  void _showAddNoteDialog() {
    final noteCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Handle
              Center(child: Container(height: 4, width: 40, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              // Title
              Text('Add Note', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 20),

              // Date selector
              Text('Date', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setSheetState(() => selectedDate = picked);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(LucideIcons.calendar, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                      style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // Note input
              Text('Note', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. My graduation day!',
                  hintStyle: GoogleFonts.outfit(fontSize: 14, color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),

              // Buttons row
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.border),
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: Text('Cancel', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(
                  onPressed: () {
                    if (noteCtrl.text.trim().isNotEmpty) {
                      ref.read(plannerNotesProvider.notifier).saveNote(DateFormat('yyyy-MM-dd').format(selectedDate), noteCtrl.text.trim());
                      Navigator.pop(ctx);
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                )),
              ]),
            ]),
          ),
        );
      }),
    );
  }

  // ── Show note detail (bottom sheet matching app theme) ──
  void _showNoteDetail(String iso) {
    final notes = ref.read(plannerNotesProvider);
    final note = notes[iso];
    if (note == null) return;
    final date = DateTime.parse(iso);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Handle
          Center(child: Container(height: 4, width: 40, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          // Title row
          Row(children: [
            Expanded(child: Text('Note — ${DateFormat('EEEE, MMM d').format(date)}',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
          ]),
          const SizedBox(height: 20),
          // Note content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(note, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5)),
          ),
          const SizedBox(height: 24),
          // Buttons row
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () { ref.read(plannerNotesProvider.notifier).deleteNote(iso); Navigator.pop(context); },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textSecondary,
              ),
              child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            )),
            const SizedBox(width: 12),
            Expanded(child: FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Done', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ── Undated card (vertical, tappable for date picker, info + trash icons) ──
class _UndatedCard extends StatelessWidget {
  final MealPlanEntry meal;
  final VoidCallback onTapDate;
  final VoidCallback onTapInfo;
  final VoidCallback onRemove;
  const _UndatedCard({required this.meal, required this.onTapDate, required this.onTapInfo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<int>(
      data: meal.recipeId,
      feedback: Material(color: Colors.transparent, child: SizedBox(width: MediaQuery.of(context).size.width - 48, child: Opacity(opacity: 0.85, child: _card()))),
      childWhenDragging: Opacity(opacity: 0.3, child: _card()),
      child: _card(),
    );
  }

  Widget _card() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: GestureDetector(
        onTap: onTapDate,
        child: Container(
          height: 96, 
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF3F4F6)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))]),
          child: Row(children: [
            Container(width: 80, height: 80, margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFFF3F4F6)), clipBehavior: Clip.antiAlias,
            child: meal.imageUrl != null && meal.imageUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: meal.imageUrl!, 
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Center(child: Text('🍲', style: TextStyle(fontSize: 24))),
                  )
                : const Center(child: Text('🍲', style: TextStyle(fontSize: 24)))),
            const SizedBox(width: 12),
            Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(meal.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E1E1E), height: 1.2, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Row(children: [
                  Text('Undated', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFFB923C))),
                  Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: const BoxDecoration(color: Color(0xFFD1D5DB), shape: BoxShape.circle)),
                  Text('${meal.readyInMinutes ?? 25}m', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF))),
                ]),
              ]))),
            Padding(padding: const EdgeInsets.only(right: 12), child: Row(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(onTap: onTapInfo, child: const Padding(padding: EdgeInsets.all(4), child: Icon(LucideIcons.info, size: 16, color: Color(0xFF9CA3AF)))),
              const SizedBox(width: 4),
              GestureDetector(onTap: onRemove, child: const Padding(padding: EdgeInsets.all(4), child: Icon(LucideIcons.trash2, size: 18, color: Color(0xFFD1D5DB)))),
            ])),
          ]),
        ),
      ),
    );
  }
}

// ── Day section with drag target ──
class _DaySection extends StatelessWidget {
  final _Day day;
  final List<MealPlanEntry> meals;
  final bool focused;
  final String? note;
  final void Function(int) onRemove;
  final void Function(int) onTapInfo;
  final void Function(int) onTapDate;
  final void Function(int) onAcceptDrop;
  final VoidCallback onTapNote;

  const _DaySection({super.key, required this.day, required this.meals, required this.focused, this.note, required this.onRemove, required this.onTapInfo, required this.onTapDate, required this.onAcceptDrop, required this.onTapNote});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayIso = DateFormat('yyyy-MM-dd').format(now);

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Day header
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: focused ? const Color(0xFFF4F8F2) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border(bottom: BorderSide(color: focused ? const Color(0xFF006241).withValues(alpha: 0.2) : const Color(0xFFF3F4F6))),
          ),
          child: AnimatedScale(
            scale: focused ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                if (focused) Container(width: 4, height: 24, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: const Color(0xFF006241), borderRadius: BorderRadius.circular(999))),
                Text('${day.full}, ${DateFormat('MMM').format(day.dt).toUpperCase()} ${day.num}',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.5, color: focused ? const Color(0xFF006241) : const Color(0xFF1E1E1E))),
              ]),
              if (note != null)
                GestureDetector(
                  onTap: onTapNote,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFF4F8F2), borderRadius: BorderRadius.circular(8)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.stickyNote, size: 12, color: Color(0xFF006241)),
                      const SizedBox(width: 4),
                      Text('Note', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF006241))),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // Mission cards
        if (meals.isNotEmpty)
          ...meals.map((meal) {
            final isActive = meal.date == todayIso;
            return _MissionCard(meal: meal, isActive: isActive, onRemove: () => onRemove(meal.recipeId), onTapInfo: () => onTapInfo(meal.recipeId), onTapDate: () => onTapDate(meal.recipeId));
          })
        else
          // Empty — also a drag target
          DragTarget<int>(
            onAcceptWithDetails: (d) => onAcceptDrop(d.data),
            builder: (ctx, cand, _) {
              final hovering = cand.isNotEmpty;
              if (hovering) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(color: const Color(0xFFF4F8F2), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF006241), width: 2)),
                  child: Center(child: Text('Drop here', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF006241)))),
                );
              }
              return CustomPaint(
                painter: _DashedBorderPainter(color: const Color(0xFFE5E7EB), radius: 16, dashWidth: 6, dashSpace: 4),
                child: Container(
                  width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(16)),
                  child: Center(child: Text('No plans for ${day.abbr.toLowerCase()}', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFD1D5DB)))),
                ),
              );
            },
          ),

        // Always show a drag target below existing cards too
        if (meals.isNotEmpty)
          DragTarget<int>(
            onAcceptWithDetails: (d) => onAcceptDrop(d.data),
            builder: (ctx, cand, _) {
              final hovering = cand.isNotEmpty;
              if (!hovering) return const SizedBox.shrink();
              return Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(color: const Color(0xFFF4F8F2), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF006241), width: 2)),
                child: Center(child: Text('Drop here', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF006241)))),
              );
            },
          ),
      ]),
    );
  }
}

// ── Mission card — 3 states: completed, active, planned (from PlannerView.jsx) ──
class _MissionCard extends StatefulWidget {
  final MealPlanEntry meal;
  final bool isActive;
  final VoidCallback onRemove;
  final VoidCallback onTapInfo;
  final VoidCallback onTapDate;

  const _MissionCard({required this.meal, required this.isActive, required this.onRemove, required this.onTapInfo, required this.onTapDate});

  @override
  State<_MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<_MissionCard> {
  bool isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<int>(
      data: widget.meal.recipeId,
      feedback: Material(color: Colors.transparent, child: SizedBox(width: MediaQuery.of(context).size.width - 48, child: Opacity(opacity: 0.85, child: _card()))),
      childWhenDragging: Opacity(opacity: 0.3, child: _card()),
      child: _card(),
    );
  }

  Widget _card() {
    final isAct = widget.isActive;

    // Mockup colors per state
    final Color bgColor = isCompleted ? const Color(0xFFD4E9E2).withValues(alpha: 0.3)
        : isAct ? Colors.white
        : const Color(0xFFFCFCF9);
    final Color borderColor = isCompleted ? Colors.transparent
        : isAct ? const Color(0xFF006241)
        : const Color(0xFFF3F4F6);
    final double borderW = isAct ? 2 : 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: widget.onTapDate,
        child: Opacity(
          opacity: isCompleted ? 0.6 : 1.0,
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: borderW),
              boxShadow: [
                if (isAct) BoxShadow(color: const Color(0xFF006241).withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))
                else BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(children: [
              // Image with completed overlay
              Container(width: 80, height: 80, margin: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: const Color(0xFFF3F4F6)), clipBehavior: Clip.antiAlias,
                child: Stack(children: [
                  if (widget.meal.imageUrl != null && widget.meal.imageUrl!.isNotEmpty)
                    ColorFiltered(
                      colorFilter: isCompleted ? const ColorFilter.mode(Colors.grey, BlendMode.saturation) : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                      child: CachedNetworkImage(imageUrl: widget.meal.imageUrl!, fit: BoxFit.cover, width: 80, height: 80,
                        imageBuilder: (_, p) => Container(decoration: BoxDecoration(image: DecorationImage(image: p, fit: BoxFit.cover)),
                          child: Transform.scale(scale: 1.08, child: Container(decoration: BoxDecoration(image: DecorationImage(image: p, fit: BoxFit.cover))))),
                        errorWidget: (context, url, error) => const Center(child: Icon(LucideIcons.chefHat, size: 24, color: Color(0xFF9CA3AF))),
                      ),
                    )
                  else
                    const Center(child: Icon(LucideIcons.chefHat, size: 24, color: Color(0xFF9CA3AF))),
                  // Completed checkmark overlay
                  if (isCompleted)
                    Positioned.fill(child: Container(
                      decoration: BoxDecoration(color: const Color(0xFF006241).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                      child: const Center(child: Text('✔', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700))),
                    )),
                ])),
              // Text
              Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.meal.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.3,
                      color: isCompleted ? const Color(0xFF9CA3AF) : const Color(0xFF1E1E1E),
                      decoration: isCompleted ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text('Planned',
                      style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF))),
                    Container(width: 4, height: 4, margin: const EdgeInsets.symmetric(horizontal: 8), decoration: const BoxDecoration(color: Color(0xFFD1D5DB), shape: BoxShape.circle)),
                    Text('${widget.meal.readyInMinutes ?? 25}m', style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF9CA3AF))),
                  ]),
                ]))),
              // Actions — different per state
              Padding(padding: const EdgeInsets.only(right: 12), child: Row(mainAxisSize: MainAxisSize.min, children: [
                GestureDetector(onTap: widget.onTapInfo, child: const Padding(padding: EdgeInsets.all(4), child: Icon(LucideIcons.info, size: 16, color: Color(0xFF9CA3AF)))),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      isCompleted = !isCompleted;
                    });
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted ? const Color(0xFF006241) : const Color(0xFFD1D5DB),
                        width: 2,
                      ),
                      color: isCompleted ? const Color(0xFF006241) : Colors.transparent,
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(onTap: widget.onRemove, child: Padding(padding: const EdgeInsets.all(4),
                  child: Icon(LucideIcons.trash2, size: 18, color: const Color(0xFFD1D5DB)))),
              ])),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Dashed border painter (matches CSS border-dashed) ──
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;

  _DashedBorderPainter({required this.color, this.radius = 16, this.dashWidth = 6, this.dashSpace = 4, this.strokeWidth = 1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final len = dashWidth.clamp(0, metric.length - distance);
        final extracted = metric.extractPath(distance, distance + len);
        canvas.drawPath(extracted, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Day {
  final String abbr, num, full, iso;
  final bool isToday;
  final DateTime dt;
  const _Day({required this.abbr, required this.num, required this.full, required this.iso, required this.isToday, required this.dt});
}
