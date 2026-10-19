import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegora_core/localization/app_localizations.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_locale_state.dart';
import '../../core/utils/currency_formatter.dart';
import '../models/product.dart';
import '../providers/branch_provider.dart';
import '../providers/cart_provider.dart';
import 'branch_switch_dialog.dart';
import 'product_image_view.dart';

/// Modal bottom sheet for interactive vegetable quantity selection (Grams / Kilograms / Count).
class QuantitySelectorSheet extends ConsumerStatefulWidget {
  final Product product;
  final int initialQuantity;

  const QuantitySelectorSheet({
    super.key,
    required this.product,
    this.initialQuantity = 0,
  });

  static Future<int?> show(
    BuildContext context, {
    required Product product,
    int initialQuantity = 0,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuantitySelectorSheet(
        product: product,
        initialQuantity: initialQuantity,
      ),
    );
  }

  /// Parses user custom text input (e.g. "250", "500g", "1.5kg", "2 kg") to canonical integer grams (or count).
  static int? parseInputToGrams(String input, {bool isWeightBased = true}) {
    final clean = input.trim().toLowerCase();
    if (clean.isEmpty) return null;

    if (!isWeightBased) {
      return int.tryParse(clean.replaceAll(RegExp(r'[^0-9]'), ''));
    }

    if (clean.endsWith('kg') ||
        clean.contains('kilo') ||
        clean.contains('கிலோ')) {
      final numPart = clean.replaceAll(RegExp(r'[^0-9.]'), '');
      final val = double.tryParse(numPart);
      return val != null ? (val * 1000).round() : null;
    }

    if (clean.endsWith('g') ||
        clean.contains('gram') ||
        clean.contains('கிராம்')) {
      final numPart = clean.replaceAll(RegExp(r'[^0-9.]'), '');
      final val = double.tryParse(numPart);
      return val?.round();
    }

    final val = double.tryParse(clean);
    if (val == null) return null;
    if (val < 20 && val % 1 != 0) {
      return (val * 1000).round();
    } else if (val < 10) {
      return (val * 1000).round();
    }
    return val.round();
  }

  @override
  ConsumerState<QuantitySelectorSheet> createState() =>
      _QuantitySelectorSheetState();
}

class _QuantitySelectorSheetState extends ConsumerState<QuantitySelectorSheet> {
  late int _selectedQuantity;
  final TextEditingController _customController = TextEditingController();
  bool _isCustomMode = false;
  String _customUnit = 'g'; // 'g' or 'kg'

  // Standard predefined quick-selection options in grams
  static const List<int> _weightOptionsGrams = [
    100,
    250,
    500,
    750,
    1000,
    1500,
    2000,
  ];

  // Standard count options
  static const List<int> _countOptions = [1, 2, 3, 5, 10];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (widget.initialQuantity > 0) {
      _selectedQuantity = widget.initialQuantity;
    } else {
      _selectedQuantity = p.isWeightBased ? 500 : 1;
    }
    _customController.text = _formatCustomInputText(_selectedQuantity);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  String _formatCustomInputText(int grams) {
    if (!widget.product.isWeightBased) return grams.toString();
    if (_customUnit == 'kg') {
      return (grams / 1000.0).toStringAsFixed(1);
    }
    return grams.toString();
  }

  void _onCustomInputChanged(String val) {
    final parsed = double.tryParse(val.trim());
    if (parsed == null || parsed <= 0) return;

    int newGrams;
    if (widget.product.isWeightBased) {
      if (_customUnit == 'kg') {
        newGrams = (parsed * 1000).round();
      } else {
        newGrams = parsed.round();
      }
    } else {
      newGrams = parsed.round();
    }

    if (newGrams > 0) {
      setState(() => _selectedQuantity = newGrams);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final isTamil = locale.languageCode == 'ta';
    final l10n = context.l10n;
    final currentBranch = ref.watch(selectedBranchProvider);
    final p = widget.product;

    final branchPricePaise = p.getPricePaiseForBranch(currentBranch.id);
    final maxStock = p.getStockForBranch(currentBranch.id);
    final isAvailable = p.isAvailableAtBranch(currentBranch.id);

    // Calculate line total for selected quantity
    final lineTotalPaise = p.calculatePricePaise(
      _selectedQuantity,
      branchPricePaise,
    );
    final isStockExceeded = _selectedQuantity > maxStock;

    final displayName = p.displayName(locale.languageCode);
    final displayUnit = p.formatUnitLabel(isTamil: isTamil);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Product Summary Header
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: ProductImageView(
                  imageUrl: p.imageUrl,
                  fallbackEmoji: p.emoji,
                  fit: BoxFit.cover,
                  emojiSize: 36,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: isTamil ? 1.35 : 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.formatPaise(branchPricePaise)} $displayUnit',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAvailable
                          ? '${isTamil ? "கையிருப்பு" : "Stock"}: ${p.formatQuantity(maxStock, isTamil: isTamil)}'
                          : l10n.outOfStock,
                      style: TextStyle(
                        fontSize: 12,
                        color: isAvailable
                            ? AppColors.textSecondary
                            : AppColors.statusCancelled,
                        fontWeight: isAvailable
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 14),

          // Label: Select Quantity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.selectQuantity,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (p.allowCustomQuantity)
                InkWell(
                  onTap: () {
                    setState(() {
                      _isCustomMode = !_isCustomMode;
                      if (_isCustomMode) {
                        _customController.text = _formatCustomInputText(
                          _selectedQuantity,
                        );
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      _isCustomMode
                          ? (isTamil ? 'நிலையான அளவுகள்' : 'Quick Options')
                          : (isTamil ? '+ விருப்ப அளவு' : '+ Custom Amount'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick selection chips
          if (!_isCustomMode)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (p.isWeightBased ? _weightOptionsGrams : _countOptions)
                  .map((qty) {
                    final isSelected = _selectedQuantity == qty;
                    final label = p.formatQuantity(qty, isTamil: isTamil);

                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedQuantity = qty);
                        }
                      },
                      selectedColor: AppColors.primaryContainer,
                      backgroundColor: AppColors.surfaceVariant,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  })
                  .toList(),
            )
          else
            // Custom Input Box
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: p.isWeightBased
                          ? 'e.g. 250 or 1.5'
                          : 'Enter count',
                      prefixIcon: const Icon(Icons.scale_rounded, size: 20),
                    ),
                    onChanged: _onCustomInputChanged,
                  ),
                ),
                if (p.isWeightBased) ...[
                  const SizedBox(width: 10),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'g',
                        label: Text(isTamil ? 'கிராம்' : 'g'),
                      ),
                      ButtonSegment(
                        value: 'kg',
                        label: Text(isTamil ? 'கிலோ' : 'kg'),
                      ),
                    ],
                    selected: {_customUnit},
                    onSelectionChanged: (set) {
                      setState(() {
                        _customUnit = set.first;
                        _customController.text = _formatCustomInputText(
                          _selectedQuantity,
                        );
                      });
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),

          const SizedBox(height: 16),

          // Stepper Row (- / +) with live Quantity Display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.quantity}: ${p.formatQuantity(_selectedQuantity, isTamil: isTamil)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.price}: ${CurrencyFormatter.formatPaise(lineTotalPaise)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Minus Button
                    IconButton.filledTonal(
                      icon: const Icon(Icons.remove, size: 18),
                      onPressed: _selectedQuantity > p.minOrderQuantity
                          ? () {
                              setState(() {
                                final step = p.quantityStep;
                                _selectedQuantity = (_selectedQuantity - step)
                                    .clamp(p.minOrderQuantity, 50000);
                                if (_isCustomMode) {
                                  _customController.text =
                                      _formatCustomInputText(_selectedQuantity);
                                }
                              });
                            }
                          : null,
                    ),
                    const SizedBox(width: 8),
                    // Plus Button
                    IconButton.filledTonal(
                      icon: const Icon(Icons.add, size: 18),
                      onPressed: _selectedQuantity < maxStock
                          ? () {
                              setState(() {
                                final step = p.quantityStep;
                                _selectedQuantity = (_selectedQuantity + step)
                                    .clamp(p.minOrderQuantity, maxStock);
                                if (_isCustomMode) {
                                  _customController.text =
                                      _formatCustomInputText(_selectedQuantity);
                                }
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (isStockExceeded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${isTamil ? "கையிருப்பை விட அதிக அளவு" : "Requested quantity exceeds available stock"} (${p.formatQuantity(maxStock, isTamil: isTamil)})',
                style: const TextStyle(
                  color: AppColors.statusCancelled,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Add to Cart Confirm Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.neutral300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: (!isAvailable || isStockExceeded)
                  ? null
                  : () {
                      try {
                        ref
                            .read(cartProvider.notifier)
                            .addItem(
                              p,
                              currentBranch.id,
                              quantity: _selectedQuantity,
                            );
                        Navigator.of(context).pop(_selectedQuantity);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${p.displayName(locale.languageCode)} (${p.formatQuantity(_selectedQuantity, isTamil: isTamil)}) ${isTamil ? "கூடையில் சேர்க்கப்பட்டது" : "added to cart!"}',
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } on BranchMismatchException catch (e) {
                        Navigator.of(context).pop();
                        final branches =
                            ref.read(branchesListProvider).value ?? [];
                        final oldBranch = branches.firstWhere(
                          (b) => b.id == e.currentBranchId,
                          orElse: () => currentBranch,
                        );

                        BranchSwitchDialog.show(
                          context: context,
                          currentBranch: oldBranch,
                          newBranch: currentBranch,
                          pendingProduct: p,
                          onConfirm: () {
                            ref
                                .read(cartProvider.notifier)
                                .switchBranchAndClear(
                                  currentBranch.id,
                                  initialProduct: p,
                                  initialQuantity: _selectedQuantity,
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Switched to ${currentBranch.name}. Cart refreshed.',
                                ),
                              ),
                            );
                          },
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$e'),
                            backgroundColor: AppColors.statusCancelled,
                          ),
                        );
                      }
                    },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.addToCart} • ${CurrencyFormatter.formatPaise(lineTotalPaise)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
