import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/pantry_models.dart';

class AddItemSheet extends StatefulWidget {
  final void Function(AddPantryItemPayload payload) onAdd;
  const AddItemSheet({super.key, required this.onAdd});

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _notesController = TextEditingController();
  String _selectedUnit = 'pcs';
  DateTime? _userPickedExpiryDate;
  int _currentLifespan = 30;

  static const _units = ['pcs', 'g', 'kg', 'oz', 'lb', 'ml', 'L', 'cup', 'tbsp', 'tsp'];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final text = _nameController.text.trim();
    if (text.isNotEmpty) {
      final category = ExpiryHelper.guessCategory(text);
      final lifespan = ExpiryHelper.getDefaultLifespanDays(category);
      if (lifespan != _currentLifespan) {
        setState(() => _currentLifespan = lifespan);
      }
    } else {
      if (_currentLifespan != 30) setState(() => _currentLifespan = 30);
    }
  }

  DateTime get _effectiveExpiryDate => _userPickedExpiryDate ?? DateTime.now().add(Duration(days: _currentLifespan));

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    widget.onAdd(AddPantryItemPayload(
      rawName: name,
      quantity: double.tryParse(_quantityController.text) ?? 1,
      unit: _selectedUnit,
      expiryDate: _effectiveExpiryDate.toIso8601String().split('T').first,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    ));
    Navigator.pop(context);
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveExpiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _userPickedExpiryDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add Pantry Item',
              style: TextStyle(
                fontFamily: 'Matter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Item Name
            Text('Item Name', style: _labelStyle),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Roma Tomato',
              ),
            ),
            const SizedBox(height: 16),

            // Quantity + Unit
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quantity', style: _labelStyle),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unit', style: _labelStyle),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedUnit,
                            isExpanded: true,
                            items: _units
                                .map((u) => DropdownMenuItem(
                                    value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedUnit = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Expiry Date
            Text('Expiry Date', style: _labelStyle),
            const SizedBox(height: 4),
            Text(
              _userPickedExpiryDate == null 
                  ? 'Default based on category ($_currentLifespan days). Tap to change.'
                  : 'Custom expiry set. Tap to change.',
              style: const TextStyle(
                fontFamily: 'Matter',
                fontSize: 12, 
                color: AppColors.textHint,
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickExpiryDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_effectiveExpiryDate.year}-${_effectiveExpiryDate.month.toString().padLeft(2, '0')}-${_effectiveExpiryDate.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontFamily: 'Matter',
                    fontSize: 14,
                    color: _userPickedExpiryDate != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Text('Notes (optional)', style: _labelStyle),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'e.g. opened, store in fridge',
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontFamily: 'Matter', fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Add Item',
                        style: TextStyle(fontFamily: 'Matter', fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _labelStyle => const TextStyle(
    fontFamily: 'Matter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
  );
}
