import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../models/pantry_models.dart';

/// Reusable expiry tag widget with color-coded indicators
/// Mirrors: pp-backend pantry.types.ts ExpiryStatus
class ExpiryTag extends StatelessWidget {
  final ExpiryStatus status;
  final int? daysUntilExpiry;

  const ExpiryTag({
    super.key,
    required this.status,
    this.daysUntilExpiry,
  });

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      ExpiryStatus.expired => (AppColors.expiryExpired, 'Expired'),
      ExpiryStatus.expiringSoon => (
          (daysUntilExpiry != null && daysUntilExpiry! <= 2) ? AppColors.expiryExpired : AppColors.expirySoon,
          daysUntilExpiry != null ? '${daysUntilExpiry}d left' : 'Expiring soon'
        ),
      ExpiryStatus.fresh => (
          AppColors.expiryFresh,
          daysUntilExpiry != null ? '${daysUntilExpiry}d left' : 'Fresh'
        ),
      ExpiryStatus.noDate => (AppColors.textHint, 'No date'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
