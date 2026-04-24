import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/pantry_models.dart';

class EditItemSheet extends StatefulWidget {
  final PantryItem item;
  final void Function(UpdatePantryItemPayload payload) onUpdate;
  
  const EditItemSheet({super.key, required this.item, required this.onUpdate});

  @override
  State<EditItemSheet> createState() => _EditItemSheetState();
}

class _EditItemSheetState extends State<EditItemSheet> {
  late TextEditingController _quantityController;
  late String _selectedUnit;
  DateTime? _userPickedExpiryDate;

  late List<String> _availableUnits;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.item.quantity.toString());
    _selectedUnit = widget.item.unit;
    
    _availableUnits = ['pcs', 'g', 'kg', 'oz', 'lb', 'ml', 'L', 'cup', 'tbsp', 'tsp'];
    if (!_availableUnits.contains(_selectedUnit)) {
      _availableUnits.add(_selectedUnit);
    }

    if (widget.item.expiryDate != null) {
      _userPickedExpiryDate = DateTime.tryParse(widget.item.expiryDate!);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = double.tryParse(_quantityController.text);
    widget.onUpdate(UpdatePantryItemPayload(
      quantity: qty,
      unit: _selectedUnit,
      expiryDate: _userPickedExpiryDate?.toIso8601String().split('T').first,
    ));
    Navigator.pop(context);
  }

  Future<void> _pickExpiryDate() async {
    final initial = _userPickedExpiryDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
              'Edit ${widget.item.rawName}',
              style: TextStyle(
                fontFamily: 'Matter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

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
                            items: _availableUnits
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
                  _userPickedExpiryDate != null 
                    ? '${_userPickedExpiryDate!.year}-${_userPickedExpiryDate!.month.toString().padLeft(2, '0')}-${_userPickedExpiryDate!.day.toString().padLeft(2, '0')}'
                    : 'No date set',
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
                    child: const Text('Save',
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
