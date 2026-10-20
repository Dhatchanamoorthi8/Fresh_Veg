import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/localization/app_locale_state.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/models/order.dart';
import '../../shared/models/order_status.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/branch_provider.dart';
import '../../shared/providers/cart_provider.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/widgets/vegora_toast.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  final String? initialInstructions;

  const CheckoutScreen({super.key, this.initialInstructions});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late TextEditingController _instructionsController;
  String _selectedSlot = 'Today (Evening 5:00 PM - 7:00 PM)';
  String _paymentMethod = 'Cash on Delivery';
  bool _isSubmitting = false;

  final List<String> _availableSlots = [
    'Today (Evening 5:00 PM - 7:00 PM)',
    'Today (Night 8:00 PM - 10:00 PM)',
    'Tomorrow (Early Morning 6:30 AM - 8:30 AM)',
    'Tomorrow (Morning 9:00 AM - 11:00 AM)',
  ];

  @override
  void initState() {
    super.initState();
    _instructionsController = TextEditingController(
      text: widget.initialInstructions ?? '',
    );
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    final cart = ref.read(cartProvider);
    final currentBranch = ref.read(selectedBranchProvider);
    final currentAddress = ref.read(selectedAddressProvider);
    final customerName = ref.read(customerNameProvider);
    final customerPhone = ref.read(customerPhoneProvider) ?? '9876543210';

    final currentUser = ref.read(currentSupabaseUserProvider);
    if (currentUser == null) {
      VegoraToast.showWarning(
        context,
        'Please sign in to your customer account to place your order.',
        title: 'Sign In Required',
        actionLabel: 'Sign In',
        onAction: () => context.push('/login'),
      );
      return;
    }

    if (cart.isEmpty) {
      VegoraToast.showInfo(
        context,
        'Cart is empty. Please add fresh produce to order.',
        title: 'Empty Cart',
        icon: Icons.shopping_basket_outlined,
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final randomIdSuffix = 1000 + Random().nextInt(9000);
    final orderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
    final orderNumber = '#OD-$randomIdSuffix';

    final now = DateTime.now();
    final newOrder = Order(
      id: orderId,
      orderNumber: orderNumber,
      customerId: currentUser.id,
      customerName: customerName,
      customerPhone: customerPhone,
      deliveryAddress: currentAddress,
      branchId: currentBranch.id,
      branchName: currentBranch.name,
      items: List.from(cart.items),
      subtotalPaise: cart.subtotalPaise,
      deliveryFeePaise: cart.deliveryFeePaise(currentBranch),
      discountPaise: cart.discountPaise,
      totalPaise: cart.totalPaise(currentBranch),
      status: OrderStatus.newOrder,
      paymentMethod: _paymentMethod,
      deliverySlot: _selectedSlot,
      deliveryInstructions: _instructionsController.text.trim().isEmpty
          ? 'Standard doorstep delivery'
          : _instructionsController.text.trim(),
      createdAt: now,
      statusTimeline: [
        OrderStatusEvent(
          status: OrderStatus.newOrder,
          timestamp: now,
          note: 'Order submitted to store branch',
        ),
      ],
    );

    try {
      // Save order via Supabase transactional RPC & clear cart
      final createdOrder = await ref
          .read(ordersListProvider.notifier)
          .placeOrder(newOrder);
      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Navigate to confirmation screen with real persisted order
      context.go('/order-confirmation', extra: createdOrder);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      VegoraToast.showError(
        context,
        'Order placement failed: ${e.toString().replaceAll('Exception: ', '')}',
        title: 'Order Failed',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final currentBranch = ref.watch(selectedBranchProvider);
    final currentAddress = ref.watch(selectedAddressProvider);
    final customerName = ref.watch(customerNameProvider);
    final customerPhone = ref.watch(customerPhoneProvider) ?? '9876543210';
    final locale = ref.watch(appLocaleProvider);
    final isTamil = locale.languageCode == 'ta';

    final subtotal = cart.subtotalPaise;
    final deliveryFee = cart.deliveryFeePaise(currentBranch);
    final discount = cart.discountPaise;
    final total = cart.totalPaise(currentBranch);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isTamil ? 'செக்அவுட் & சரிபார்த்தல்' : 'Checkout & Review',
          style: AppTypography.screenHeading(fontSize: 20, isTamil: isTamil),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fresh harvest assurance banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    color: AppColors.primaryDark,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Direct Farm-Fresh Guarantee: Hand-picked and packed at ${currentBranch.name} for 30-min delivery.',
                      style: AppTypography.supporting(
                        fontSize: 12,
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                        isTamil: isTamil,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Delivery Address Card
            _buildSectionHeader(
              isTamil ? 'டெலிவரி முகவரி' : 'Delivery Location',
              Icons.pin_drop_rounded,
              isTamil: isTamil,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.home_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${currentAddress.label} ($customerName)',
                          style: AppTypography.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentAddress.fullAddress,
                          style: AppTypography.supporting(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Phone: +91 $customerPhone',
                          style: AppTypography.supporting(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/branches'),
                    child: Text(
                      isTamil ? 'மாற்று' : 'Change',
                      style: AppTypography.button(
                        fontSize: 13,
                        color: AppColors.primary,
                        isTamil: isTamil,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Store Fulfillment Branch
            _buildSectionHeader(
              isTamil ? 'நிறைவேற்றும் கிளை' : 'Fulfilling Store Branch',
              Icons.storefront_rounded,
              isTamil: isTamil,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentBranch.name,
                          style: AppTypography.body(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${currentBranch.area} • Est. ${currentBranch.estimatedDeliveryMinutes} min delivery',
                          style: AppTypography.supporting(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Delivery Time Slot Selector
            _buildSectionHeader(
              isTamil
                  ? 'டெலிவரி நேரத்தைத் தேர்ந்தெடுக்கவும்'
                  : 'Choose Delivery Slot',
              Icons.schedule_rounded,
              isTamil: isTamil,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: RadioGroup<String>(
                groupValue: _selectedSlot,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedSlot = val);
                },
                child: Column(
                  children: _availableSlots.map((slot) {
                    final isSelected = _selectedSlot == slot;
                    return RadioListTile<String>(
                      value: slot,
                      activeColor: AppColors.primary,
                      dense: true,
                      title: Text(
                        slot,
                        style: isSelected
                            ? AppTypography.body(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              )
                            : AppTypography.body(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Payment Method Selector
            _buildSectionHeader(
              isTamil ? 'பணம் செலுத்தும் முறை' : 'Payment Method',
              Icons.payment_rounded,
              isTamil: isTamil,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: RadioGroup<String>(
                groupValue: _paymentMethod,
                onChanged: (val) {
                  if (val != null) setState(() => _paymentMethod = val);
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'Cash on Delivery',
                      activeColor: AppColors.primary,
                      dense: true,
                      secondary: const Icon(
                        Icons.money_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        'Cash on Delivery (COD)',
                        style: AppTypography.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Pay cash or UPI to delivery partner at your doorstep',
                        style: AppTypography.supporting(fontSize: 11),
                      ),
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      value: 'Online UPI',
                      activeColor: AppColors.primary,
                      dense: true,
                      secondary: const Icon(
                        Icons.qr_code_2_rounded,
                        color: AppColors.statusPreparing,
                      ),
                      title: Text(
                        'Online UPI & Netbanking',
                        style: AppTypography.body(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Instant payment via Google Pay / PhonePe / BHIM UPI',
                        style: AppTypography.supporting(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Final Bill Summary
            _buildSectionHeader(
              isTamil ? 'ஆர்டர் சுருக்கம்' : 'Order Summary',
              Icons.receipt_long_rounded,
              isTamil: isTamil,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Items (${cart.totalItemCount})',
                    CurrencyFormatter.formatPaise(subtotal),
                  ),
                  const SizedBox(height: 6),
                  _buildSummaryRow(
                    'Delivery Charge',
                    deliveryFee == 0
                        ? 'FREE'
                        : CurrencyFormatter.formatPaise(deliveryFee),
                    isGreen: deliveryFee == 0,
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 6),
                    _buildSummaryRow(
                      'Discount Savings',
                      '-${CurrencyFormatter.formatPaise(discount)}',
                      isGreen: true,
                    ),
                  ],
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTamil ? 'மொத்த தொகை' : 'Total Amount',
                        style: AppTypography.body(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          isTamil: isTamil,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.formatPaise(total),
                        style: AppTypography.productPrice(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // Bottom Confirm Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _handlePlaceOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isTamil ? 'ஆர்டர் செய்க' : 'Place Order',
                          style: AppTypography.button(
                            fontSize: 16,
                            color: Colors.white,
                            isTamil: isTamil,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${CurrencyFormatter.formatPaise(total)}',
                          style: AppTypography.productPrice(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon, {
    bool isTamil = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: AppTypography.sectionHeading(
            fontSize: 15,
            color: AppColors.textPrimary,
            isTamil: isTamil,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.supporting(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTypography.productPrice(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isGreen ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
