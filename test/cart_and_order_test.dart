import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vegetable_shop/shared/models/branch.dart';
import 'package:vegetable_shop/shared/models/cart.dart';
import 'package:vegetable_shop/shared/models/cart_item.dart';
import 'package:vegetable_shop/shared/models/order_status.dart';
import 'package:vegetable_shop/shared/models/product.dart';
import 'package:vegetable_shop/shared/models/promotion.dart';
import 'package:vegetable_shop/shared/providers/cart_provider.dart';
import 'package:vegetable_shop/shared/repositories/order_repository.dart';

void main() {
  group('1. Cart & Price Calculation Tests', () {
    const testBranch = Branch(
      id: 'branch_01',
      name: 'Test Branch',
      area: 'Central',
      address: '123 Main St',
      phone: '9999999999',
      openingHours: '7 AM - 9 PM',
      deliveryCoverage: 'Central',
      minOrderAmountPaise: 9900, // ₹99
      freeDeliveryThresholdPaise: 24900, // ₹249
      standardDeliveryFeePaise: 2900, // ₹29
    );

    const productA = Product(
      id: 'prod_a',
      name: 'Tomato',
      localName: 'Tamatar',
      categoryId: 'cat_everyday',
      unit: '1 kg',
      description: 'Fresh red tomatoes',
      storageTips: 'Store cool',
      origin: 'Kolar',
      emoji: '🍅',
      basePricePaise: 4000, // ₹40
    );

    test('Empty cart calculations should be zero', () {
      const cart = Cart();
      expect(cart.isEmpty, isTrue);
      expect(cart.subtotalPaise, 0);
      expect(cart.deliveryFeePaise(testBranch), 0);
      expect(cart.totalPaise(testBranch), 0);
      expect(cart.totalItemCount, 0);
    });

    test(
      'Standard delivery fee applies when subtotal is below free threshold',
      () {
        // 2 units of Tomato: ₹40 * 2 = ₹80 (8000 paise)
        // Below ₹249 threshold -> delivery fee should be ₹29 (2900 paise)
        final cart = Cart(
          branchId: 'branch_01',
          items: [
            CartItem(
              product: productA,
              quantity: 2,
              branchId: 'branch_01',
              unitPricePaise: 4000,
            ),
          ],
        );

        expect(cart.subtotalPaise, 8000);
        expect(cart.isEligibleForFreeDelivery(testBranch), isFalse);
        expect(cart.deliveryFeePaise(testBranch), 2900);
        expect(cart.totalPaise(testBranch), 10900); // ₹80 + ₹29 = ₹109
      },
    );

    test('Free delivery applies when subtotal exceeds threshold', () {
      // 7 units of Tomato: ₹40 * 7 = ₹280 (28000 paise > 24900 threshold)
      final cart = Cart(
        branchId: 'branch_01',
        items: [
          CartItem(
            product: productA,
            quantity: 7,
            branchId: 'branch_01',
            unitPricePaise: 4000,
          ),
        ],
      );

      expect(cart.subtotalPaise, 28000);
      expect(cart.isEligibleForFreeDelivery(testBranch), isTrue);
      expect(cart.deliveryFeePaise(testBranch), 0);
      expect(cart.totalPaise(testBranch), 28000);
    });

    test('5% promotional discount applies for orders over ₹500', () {
      // 15 units of Tomato = 60000 paise (₹600)
      // 5% discount = 3000 paise (₹30)
      // Free delivery because 60000 > 24900
      // Total = 60000 - 3000 = 57000 paise (₹570)
      final cart = Cart(
        branchId: 'branch_01',
        items: [
          CartItem(
            product: productA,
            quantity: 15,
            branchId: 'branch_01',
            unitPricePaise: 4000,
          ),
        ],
      );

      expect(cart.discountPaise, 3000);
      expect(cart.totalPaise(testBranch), 57000);
    });
  });

  group('2. Multi-Branch Cart & Inventory Rules', () {
    const productCentralOnly = Product(
      id: 'prod_exotic',
      name: 'Broccoli',
      localName: 'Broccoli',
      categoryId: 'cat_seasonal_exotic',
      unit: '1 pc',
      description: 'Green broccoli',
      storageTips: 'Chilled',
      origin: 'Ooty',
      emoji: '🥦',
      basePricePaise: 6000,
      branchInventory: {
        'branch_01': BranchProductInventory(
          stockQuantity: 10,
          isAvailable: true,
        ),
        'branch_02': BranchProductInventory(
          stockQuantity: 0,
          isAvailable: false,
        ),
      },
    );

    test('Product out of stock at branch_02 cannot be purchased', () {
      expect(productCentralOnly.isAvailableAtBranch('branch_01'), isTrue);
      expect(productCentralOnly.isAvailableAtBranch('branch_02'), isFalse);
    });

    test('Branch mismatch throws BranchMismatchException when adding to existing cart', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);

      // Add item from branch_01
      const productNorm = Product(
        id: 'prod_norm',
        name: 'Carrot',
        localName: 'Gajar',
        categoryId: 'cat_roots',
        unit: '500g',
        description: 'Carrot',
        storageTips: 'Cool',
        origin: 'Ooty',
        emoji: '🥕',
        basePricePaise: 3000,
      );

      notifier.addItem(productNorm, 'branch_01');
      expect(container.read(cartProvider).branchId, 'branch_01');

      // Attempt adding item under branch_02
      expect(
        () => notifier.addItem(productNorm, 'branch_02'),
        throwsA(isA<BranchMismatchException>()),
      );
    });

    test('switchBranchAndClear successfully clears previous branch items', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(cartProvider.notifier);
      const productNorm = Product(
        id: 'prod_norm',
        name: 'Carrot',
        localName: 'Gajar',
        categoryId: 'cat_roots',
        unit: '500g',
        description: 'Carrot',
        storageTips: 'Cool',
        origin: 'Ooty',
        emoji: '🥕',
        basePricePaise: 3000,
      );

      notifier.addItem(productNorm, 'branch_01');
      expect(container.read(cartProvider).branchId, 'branch_01');

      // Switch to branch_02
      notifier.switchBranchAndClear('branch_02');
      expect(container.read(cartProvider).branchId, 'branch_02');
      expect(container.read(cartProvider).isEmpty, isTrue);
    });
  });

  group('3. Order Status State Transitions & Cancellation Rules', () {
    test('Customer can only cancel orders in NEW or ACCEPTED status', () {
      expect(OrderStatus.newOrder.canCustomerCancel, isTrue);
      expect(OrderStatus.accepted.canCustomerCancel, isTrue);
      expect(OrderStatus.preparing.canCustomerCancel, isFalse);
      expect(OrderStatus.readyForPickup.canCustomerCancel, isFalse);
      expect(OrderStatus.outForDelivery.canCustomerCancel, isFalse);
      expect(OrderStatus.delivered.canCustomerCancel, isFalse);
    });

    test('Order repository lifecycle transitions correctly', () async {
      final repo = MockOrderRepository();
      final allOrders = await repo.getAllOrders();
      expect(allOrders.isNotEmpty, isTrue);

      final newOrder = allOrders.firstWhere(
        (o) => o.status == OrderStatus.newOrder,
      );

      // Branch Staff accepts order
      final acceptedOrder = await repo.updateOrderStatus(
        newOrder.id,
        OrderStatus.accepted,
        reason: 'Confirmed by store staff',
      );
      expect(acceptedOrder.status, OrderStatus.accepted);

      // Branch Staff moves to preparing
      final preparingOrder = await repo.updateOrderStatus(
        newOrder.id,
        OrderStatus.preparing,
      );
      expect(preparingOrder.status, OrderStatus.preparing);

      // Customer attempts to cancel after preparing -> should throw
      expect(() => repo.cancelOrder(newOrder.id), throwsA(isA<Exception>()));

      // Store staff marks ready for pickup
      final readyOrder = await repo.updateOrderStatus(
        newOrder.id,
        OrderStatus.readyForPickup,
      );
      expect(readyOrder.status, OrderStatus.readyForPickup);

      // Delivery partner picks up and moves out for delivery
      final outForDeliveryOrder = await repo.updateOrderStatus(
        newOrder.id,
        OrderStatus.outForDelivery,
      );
      expect(outForDeliveryOrder.status, OrderStatus.outForDelivery);

      // Delivery partner marks delivered
      final deliveredOrder = await repo.updateOrderStatus(
        newOrder.id,
        OrderStatus.delivered,
      );
      expect(deliveredOrder.status, OrderStatus.delivered);
      expect(deliveredOrder.status.isTerminal, isTrue);
    });
  });

  group('3. Supabase Promotion Calculation Tests', () {
    final now = DateTime.now();

    final fixedPromo = Promotion(
      id: 'promo_fixed',
      code: 'FLAT50',
      title: 'Flat ₹50 Off',
      description: 'Flat ₹50 Off for orders above ₹399',
      discountType: 'fixed',
      discountValue: 5000, // 5000 paise = ₹50
      minOrderAmountPaise: 39900,
      startTime: now,
      endTime: now.add(const Duration(days: 30)),
    );

    final percentPromo = Promotion(
      id: 'promo_pct',
      code: 'GREENS10',
      title: '10% Off',
      description: '10% off for orders above ₹499',
      discountType: 'percentage',
      discountValue: 10,
      minOrderAmountPaise: 49900,
      maxDiscountPaise: 8000, // max ₹80
      startTime: now,
      endTime: now.add(const Duration(days: 30)),
    );

    test('Fixed promotion applies correctly above min order', () {
      expect(fixedPromo.calculateDiscountPaise(30000), 0); // below ₹399
      expect(
        fixedPromo.calculateDiscountPaise(40000),
        5000,
      ); // above ₹399 -> ₹50 off
    });

    test('Percentage promotion applies correctly and enforces maximum cap', () {
      expect(percentPromo.calculateDiscountPaise(40000), 0); // below ₹499
      expect(
        percentPromo.calculateDiscountPaise(60000),
        6000,
      ); // 10% of ₹600 = ₹60 (6000 paise)
      expect(
        percentPromo.calculateDiscountPaise(100000),
        8000,
      ); // 10% of ₹1000 = ₹100 -> capped at ₹80 (8000 paise)
    });
  });

  group('4. Database Model JSON Parsing Tests', () {
    test('Product parses database row with branch_inventory correctly', () {
      final json = {
        'id': 'prod_test_01',
        'name': 'Organic Spinach',
        'local_name': 'Palak',
        'category_id': 'leafy_greens',
        'unit': '1 bunch (250g)',
        'description': 'Fresh organic spinach leaves',
        'storage_tips': 'Keep in crisper',
        'origin': 'Hosur Valley',
        'emoji': '🥬',
        'base_price_paise': 2200,
        'original_price_paise': 2800,
        'is_organic': true,
        'branch_inventory': [
          {
            'branch_id': 'branch_blr_01',
            'stock_quantity': 45,
            'price_paise': 2000,
            'is_available': true,
          },
          {
            'branch_id': 'branch_blr_02',
            'stock_quantity': 0,
            'is_available': false,
          },
        ],
      };

      final product = Product.fromJson(json);
      expect(product.id, 'prod_test_01');
      expect(product.name, 'Organic Spinach');
      expect(product.basePricePaise, 2200);

      // Branch 1 has override price ₹20 (2000 paise) and stock 45
      expect(product.getPricePaiseForBranch('branch_blr_01'), 2000);
      expect(product.getStockForBranch('branch_blr_01'), 45);
      expect(product.isAvailableAtBranch('branch_blr_01'), isTrue);

      // Branch 2 is out of stock
      expect(product.isAvailableAtBranch('branch_blr_02'), isFalse);

      // Branch 3 falls back to base price
      expect(product.getPricePaiseForBranch('branch_blr_03'), 2200);
    });

    test('Branch parses from database row correctly', () {
      final json = {
        'id': 'branch_blr_01',
        'name': 'Indiranagar Central Hub',
        'area': 'Indiranagar',
        'address': '#108, 12th Main Road, HAL 2nd Stage',
        'phone': '+91 80 4123 5501',
        'opening_hours': '6:30 AM - 9:30 PM',
        'delivery_coverage': 'Indiranagar, Domlur, HAL, Ulsoor',
        'min_order_amount_paise': 9900,
        'free_delivery_threshold_paise': 24900,
        'standard_delivery_fee_paise': 2900,
        'is_active': true,
      };

      final branch = Branch.fromJson(json);
      expect(branch.id, 'branch_blr_01');
      expect(branch.name, 'Indiranagar Central Hub');
      expect(branch.minOrderAmountPaise, 9900);
      expect(branch.standardDeliveryFeePaise, 2900);
      expect(branch.isOpen, isTrue);
    });
  });
}
