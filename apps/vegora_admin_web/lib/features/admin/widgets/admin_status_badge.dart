import 'package:flutter/material.dart';
import 'package:vegora_core/vegora_core.dart';

/// 2026 SaaS-style status badge with an indicator dot and muted background tint.
class AdminStatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color? activeColor;
  final Color? inactiveColor;

  const AdminStatusBadge({
    super.key,
    required this.label,
    required this.isActive,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isActive
        ? (activeColor ?? AppColors.success)
        : (inactiveColor ?? AppColors.textSecondary);

    final bgColor = isActive
        ? (activeColor?.withValues(alpha: 0.12) ?? AppColors.primaryContainer)
        : (inactiveColor?.withValues(alpha: 0.12) ?? AppColors.surfaceVariant);

    final dotColor = isActive
        ? (activeColor ?? AppColors.primary)
        : (inactiveColor ?? AppColors.textMuted);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dotColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: baseColor,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
