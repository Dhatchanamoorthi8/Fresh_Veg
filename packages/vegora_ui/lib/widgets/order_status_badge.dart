import 'package:flutter/material.dart';

import 'package:vegora_models/vegora_models.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool isCompact;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = status.color;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: isCompact ? 13 : 16, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
