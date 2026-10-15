import 'package:flutter/material.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';

class BranchSwitchDialog extends StatelessWidget {
  final Branch currentBranch;
  final Branch newBranch;
  final Product? pendingProduct;
  final VoidCallback onConfirm;

  const BranchSwitchDialog({
    super.key,
    required this.currentBranch,
    required this.newBranch,
    this.pendingProduct,
    required this.onConfirm,
  });

  static Future<bool?> show({
    required BuildContext context,
    required Branch currentBranch,
    required Branch newBranch,
    Product? pendingProduct,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BranchSwitchDialog(
        currentBranch: currentBranch,
        newBranch: newBranch,
        pendingProduct: pendingProduct,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Switch Store Branch?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              children: [
                const TextSpan(
                  text: 'Your cart already contains fresh items from ',
                ),
                TextSpan(
                  text: currentBranch.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: '.\n\nFresh vegetable inventory and prices are branch-specific. Switching to ',
                ),
                TextSpan(
                  text: newBranch.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const TextSpan(text: ' will empty your current cart.'),
              ],
            ),
          ),
          if (pendingProduct != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Text(
                    pendingProduct!.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Adding: ${pendingProduct!.name}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep Current Branch'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          onPressed: () {
            Navigator.pop(context, true);
            onConfirm();
          },
          child: const Text('Switch & Clear Cart'),
        ),
      ],
    );
  }
}
