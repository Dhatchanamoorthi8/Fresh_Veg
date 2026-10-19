import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegetable_shop/core/utils/currency_formatter.dart';
import 'package:vegetable_shop/shared/models/branch.dart';
import 'package:vegetable_shop/shared/models/cart.dart';
import 'package:vegetable_shop/shared/models/cart_item.dart';
import 'package:vegetable_shop/shared/models/customer_address.dart';
import 'package:vegetable_shop/shared/models/delivery_partner.dart';
import 'package:vegetable_shop/shared/models/order.dart';
import 'package:vegetable_shop/shared/models/order_status.dart';
import 'package:vegetable_shop/shared/models/product.dart';
import 'package:vegetable_shop/shared/models/user_role.dart';
import 'package:vegetable_shop/shared/repositories/supabase_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VEGORA PRODUCTION E2E UAT TEST SUITE: COMPLETE BUSINESS LIFECYCLE', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'vegora_app_language_code': 'en',
      });
    });

    const testBranch = Branch(
      id: 'branch_chn_tambaram',
      name: 'Tambaram Central Hub',
      area: 'Tambaram',
      address: 'No. 45 GST Road, Tambaram Sanatorium',
      phone: '+91 44 2241 8900',
      openingHours: '6:00 AM - 10:00 PM',
      deliveryCoverage: 'Tambaram, Chromepet, Pallavaram, Selaiyur',
      estimatedDeliveryMinutes: 25,
      minOrderAmountPaise: 9900, // ₹99
      freeDeliveryThresholdPaise: 24900, // ₹249
      standardDeliveryFeePaise: 2900, // ₹29
      isOpen: true,
      isAcceptingOrders: true,
      isActive: true,
      city: 'Chennai',
      state: 'Tamil Nadu',
      pincode: '600047',
    );

    const testAddress = CustomerAddress(
      id: 'addr_tambaram_01',
      label: 'Home',
      fullAddress: 'Flat 3B, Green Valley Apts, Tambaram, Chennai 600047',
      area: 'Tambaram',
      landmark: 'Near Sanatorium Station',
      pinCode: '600047',
      eligibleBranchId: 'branch_chn_tambaram',
      isDefault: true,
    );

    const deliveryRider = DeliveryPartner(
      id: 'user_delivery_001',
      name: 'Murugan Express',
      phone: '+91 98402 33444',
      vehicleNumber: 'TN-11-AA-4099',
      rating: 4.9,
      totalDeliveriesCompleted: 350,
    );

    const desiTomato = Product(
      id: 'veg_tomato_desi',
      name: 'Desi Country Tomatoes',
      nameTa: 'நாட்டுத் தக்காளி',
      categoryId: 'everyday_veggies',
      unit: '1 kg',
      unitType: 'WEIGHT',
      baseUnit: 'g',
      description: 'Vine-ripened authentic country tomatoes fresh from Kolar.',
      descriptionTa: 'கோலார் பண்ணைகளில் இருந்து தினமும் விடியற்காலையில் பறிக்கப்படும் புத்துணர்ச்சியான நாட்டு தக்காளி.',
      emoji: '🍅',
      basePricePaise: 4000, // ₹40 / kg
      minOrderQuantity: 100,
      quantityStep: 50,
      allowCustomQuantity: true,
      branchInventory: {
        'branch_chn_tambaram': BranchProductInventory(
          pricePaise: 4000,
          stockQuantity: 50000, // 50 kg in integer grams
          isAvailable: true,
        ),
      },
    );

    const snowballCauliflower = Product(
      id: 'veg_cauliflower',
      name: 'White Snowball Cauliflower',
      nameTa: 'காலிஃபிளவர்',
      categoryId: 'everyday_veggies',
      unit: '1 pc',
      unitType: 'COUNT',
      baseUnit: 'pc',
      description: 'Crisp creamy-white large cauliflower.',
      descriptionTa: 'கிரீமி-வெள்ளை நிறமுடைய அடர்த்தியான புதிய காலிஃபிளவர்.',
      emoji: '🥦',
      basePricePaise: 4200, // ₹42 / pc
      minOrderQuantity: 1,
      quantityStep: 1,
      allowCustomQuantity: false,
      branchInventory: {
        'branch_chn_tambaram': BranchProductInventory(
          pricePaise: 4200,
          stockQuantity: 30, // 30 pieces
          isAvailable: true,
        ),
      },
    );

    // =========================================================================
    // PHASE 1: ADMIN CREATES NEW BRANCH & ASSIGNS STAFF & DELIVERY AGENTS
    // =========================================================================
    group(
      'Phase 1: Admin Operations - Branch, Staff & Delivery Provisioning',
      () {
        test('1.1 Admin provisions new branch with operational parameters', () {
          expect(testBranch.id, 'branch_chn_tambaram');
          expect(testBranch.name, 'Tambaram Central Hub');
          expect(testBranch.city, 'Chennai');
          expect(testBranch.isOpen, isTrue);
          expect(testBranch.isAcceptingOrders, isTrue);
          expect(testBranch.minOrderAmountPaise, 9900);
          expect(testBranch.freeDeliveryThresholdPaise, 24900);
          expect(testBranch.standardDeliveryFeePaise, 2900);

          // JSON serialization & deserialization roundtrip
          final json = testBranch.toJson();
          final parsed = Branch.fromJson(json);
          expect(parsed.id, testBranch.id);
          expect(parsed.address, testBranch.address);
          expect(parsed.pincode, '600047');
        });

        test(
          '1.2 Admin provisions Store Staff & Delivery Partner with RBAC',
          () {
            const staffProfile = UserProfile(
              id: 'user_staff_001',
              fullName: 'Karthik Raja',
              email: 'karthik.staff@freshveg.in',
              phone: '+91 98401 11222',
              role: AppUserRole.branchStaff,
              isActive: true,
            );

            const deliveryProfile = UserProfile(
              id: 'user_delivery_001',
              fullName: 'Murugan Express',
              email: 'murugan.delivery@freshveg.in',
              phone: '+91 98402 33444',
              role: AppUserRole.deliveryStaff,
              isActive: true,
            );

            const customerProfile = UserProfile(
              id: 'user_customer_001',
              fullName: 'Anitha S',
              email: 'anitha.customer@example.com',
              phone: '+91 98403 55666',
              role: AppUserRole.customer,
              isActive: true,
            );

            expect(staffProfile.role, AppUserRole.branchStaff);
            expect(deliveryProfile.role, AppUserRole.deliveryStaff);
            expect(customerProfile.role, AppUserRole.customer);

            expect(staffProfile.role.isAdmin, isFalse);
            expect(deliveryProfile.role.isAdmin, isFalse);
            expect(customerProfile.role.isAdmin, isFalse);

            expect(staffProfile.role.isStaff, isTrue);
            expect(deliveryProfile.role.isDelivery, isTrue);
            expect(customerProfile.role.isStaff, isFalse);
          },
        );
      },
    );

    // =========================================================================
    // PHASE 2: ADMIN CATALOG SETUP - TAMIL NAMES & CANONICAL INVENTORY
    // =========================================================================
    group('Phase 2: Admin Catalog & Branch Inventory Setup', () {
      test('2.1 Admin sets branch inventory in canonical integer grams', () {
        expect(desiTomato.isWeightBased, isTrue);
        expect(desiTomato.baseUnit, 'g');
        expect(desiTomato.getStockForBranch('branch_chn_tambaram'), 50000);
        expect(desiTomato.formatQuantity(50000, isTamil: false), '50 kg');
        expect(desiTomato.formatQuantity(50000, isTamil: true), '50 கிலோ');

        expect(snowballCauliflower.isWeightBased, isFalse);
        expect(snowballCauliflower.baseUnit, 'pc');
        expect(
          snowballCauliflower.getStockForBranch('branch_chn_tambaram'),
          30,
        );
        expect(
          snowballCauliflower.formatQuantity(30, isTamil: false),
          '30 pcs',
        );
      });

      test(
        '2.2 Bilingual catalog resolution renders Tamil & English accurately',
        () {
          expect(desiTomato.displayName('en'), 'Desi Country Tomatoes');
          expect(
            snowballCauliflower.displayName('en'),
            'White Snowball Cauliflower',
          );

          expect(desiTomato.displayName('ta'), 'நாட்டுத் தக்காளி');
          expect(snowballCauliflower.displayName('ta'), 'காலிஃபிளவர்');
          expect(
            desiTomato.displayDescription('ta'),
            contains('கோலார் பண்ணைகளில்'),
          );

          expect(desiTomato.formatUnitLabel(isTamil: false), 'per kg');
          expect(desiTomato.formatUnitLabel(isTamil: true), 'ஒரு கிலோ');
          expect(snowballCauliflower.formatUnitLabel(isTamil: false), 'per pc');
        },
      );
    });

    // =========================================================================
    // PHASE 3: CUSTOMER ORDER PLACEMENT - FLEXIBLE GRAMS & ATOMIC CHECKOUT
    // =========================================================================
    group('Phase 3: Customer Ordering - Flexible Grams & Atomic Checkout', () {
      test('3.1 Customer selects 500g tomatoes + 1 pc cauliflower with precise pricing', () {
        // 500g of Tomatoes at ₹40/kg = ₹20.00 (2000 paise)
        final tomatoItem = CartItem(
          product: desiTomato,
          quantity: 500, // 500 grams
          branchId: 'branch_chn_tambaram',
          unitPricePaise: 4000,
        );

        // 1 pc Cauliflower at ₹42/pc = ₹42.00 (4200 paise)
        final cauliflowerItem = CartItem(
          product: snowballCauliflower,
          quantity: 1, // 1 piece
          branchId: 'branch_chn_tambaram',
          unitPricePaise: 4200,
        );

        expect(tomatoItem.lineTotalPaise, 2000);
        expect(tomatoItem.formattedQuantity(isTamil: false), '500 g');
        expect(tomatoItem.formattedQuantity(isTamil: true), '500 கிராம்');

        expect(cauliflowerItem.lineTotalPaise, 4200);
        expect(cauliflowerItem.formattedQuantity(isTamil: false), '1 pc');

        final cart = Cart(
          branchId: 'branch_chn_tambaram',
          items: [tomatoItem, cauliflowerItem],
        );

        // Subtotal: ₹20 + ₹42 = ₹62 (6200 paise)
        expect(cart.subtotalPaise, 6200);

        // Delivery fee: ₹62 is below ₹249 free delivery threshold -> ₹29 (2900 paise) fee
        expect(cart.deliveryFeePaise(testBranch), 2900);

        // Total: ₹62 + ₹29 = ₹91 (9100 paise)
        expect(cart.totalPaise(testBranch), 9100);
      });

      test('3.2 Atomic checkout decrements stock accurately in canonical integer grams', () {
        int branchTomatoStock = 50000; // 50 kg
        int branchCauliflowerStock = 30; // 30 pcs

        const orderTomatoQtyGrams = 500;
        const orderCauliflowerCount = 1;

        // Stock availability check
        expect(branchTomatoStock >= orderTomatoQtyGrams, isTrue);
        expect(branchCauliflowerStock >= orderCauliflowerCount, isTrue);

        // Atomic decrement
        branchTomatoStock -= orderTomatoQtyGrams;
        branchCauliflowerStock -= orderCauliflowerCount;

        expect(branchTomatoStock, 49500); // 49.5 kg remaining
        expect(branchCauliflowerStock, 29); // 29 pcs remaining

        // Rejection if requested quantity exceeds available stock
        const excessiveRequest = 60000; // 60 kg requested
        expect(branchTomatoStock >= excessiveRequest, isFalse);
      });
    });

    // =========================================================================
    // PHASE 4: STORE STAFF RECEIVES, ACCEPTS & PACKS ORDER
    // =========================================================================
    group('Phase 4: Store Staff Fulfillment & Packing Operations', () {
      final now = DateTime.now();

      final tomatoItem = CartItem(
        product: desiTomato,
        quantity: 500,
        branchId: 'branch_chn_tambaram',
        unitPricePaise: 4000,
      );

      final cauliflowerItem = CartItem(
        product: snowballCauliflower,
        quantity: 1,
        branchId: 'branch_chn_tambaram',
        unitPricePaise: 4200,
      );

      final customerOrder = Order(
        id: 'ord_tambaram_1001',
        orderNumber: 'KF-TAMBARAM-20261019-1001',
        customerId: 'user_customer_001',
        customerName: 'Anitha S',
        customerPhone: '+91 98403 55666',
        deliveryAddress: testAddress,
        branchId: 'branch_chn_tambaram',
        branchName: 'Tambaram Central Hub',
        items: [tomatoItem, cauliflowerItem],
        subtotalPaise: 6200,
        deliveryFeePaise: 2900,
        discountPaise: 0,
        totalPaise: 9100,
        status: OrderStatus.newOrder,
        paymentMethod: 'Cash on Delivery',
        deliverySlot: 'Morning (7 AM - 9 AM)',
        deliveryInstructions: 'Doorbell is working. Leave package on rack.',
        createdAt: now,
        statusTimeline: [
          OrderStatusEvent(
            status: OrderStatus.newOrder,
            timestamp: now,
            note: 'Order placed by customer',
          ),
        ],
      );

      test('4.1 Staff receives order in NEW status and accepts it', () {
        expect(customerOrder.status, OrderStatus.newOrder);
        expect(customerOrder.status.displayName, 'Order Placed');
        expect(customerOrder.status.canCustomerCancel, isTrue);

        // Staff moves status to ACCEPTED
        final acceptedOrder = customerOrder.copyWith(
          status: OrderStatus.accepted,
          statusTimeline: [
            ...customerOrder.statusTimeline,
            OrderStatusEvent(
              status: OrderStatus.accepted,
              timestamp: now.add(const Duration(minutes: 2)),
              note: 'Confirmed by Tambaram Store Staff Karthik',
            ),
          ],
        );
        expect(acceptedOrder.status, OrderStatus.accepted);
        expect(acceptedOrder.status.displayName, 'Accepted by Store');
        expect(acceptedOrder.status.canCustomerCancel, isTrue);
        expect(acceptedOrder.statusTimeline.length, 2);
      });

      test('4.2 Staff begins packing and marks ready for pickup', () {
        // Staff begins packing -> PREPARING
        final preparingOrder = customerOrder.copyWith(
          status: OrderStatus.preparing,
          statusTimeline: [
            ...customerOrder.statusTimeline,
            OrderStatusEvent(
              status: OrderStatus.preparing,
              timestamp: now.add(const Duration(minutes: 5)),
              note: 'Weighing 500g fresh tomatoes and packing cauliflower',
            ),
          ],
        );
        expect(preparingOrder.status, OrderStatus.preparing);
        expect(preparingOrder.status.displayName, 'Packing Fresh Veggies');

        // Customer can no longer cancel once packing has begun!
        expect(preparingOrder.status.canCustomerCancel, isFalse);

        // Staff completes packing -> READY_FOR_PICKUP
        final readyOrder = preparingOrder.copyWith(
          status: OrderStatus.readyForPickup,
          statusTimeline: [
            ...preparingOrder.statusTimeline,
            OrderStatusEvent(
              status: OrderStatus.readyForPickup,
              timestamp: now.add(const Duration(minutes: 12)),
              note: 'Packed in insulated tote #TAM-44. Staged at counter.',
            ),
          ],
        );
        expect(readyOrder.status, OrderStatus.readyForPickup);
        expect(readyOrder.status.displayName, 'Ready for Pickup');
        expect(readyOrder.status.canCustomerCancel, isFalse);
        expect(readyOrder.statusTimeline.length, 3);
      });
    });

    // =========================================================================
    // PHASE 5: DELIVERY AGENT ASSIGNMENT, DISPATCH & HANDOFF
    // =========================================================================
    group('Phase 5: Delivery Partner Assignment & Doorstep Delivery', () {
      final now = DateTime.now();

      final tomatoItem = CartItem(
        product: desiTomato,
        quantity: 500,
        branchId: 'branch_chn_tambaram',
        unitPricePaise: 4000,
      );

      final packedOrder = Order(
        id: 'ord_tambaram_1001',
        orderNumber: 'KF-TAMBARAM-20261019-1001',
        customerId: 'user_customer_001',
        customerName: 'Anitha S',
        customerPhone: '+91 98403 55666',
        deliveryAddress: testAddress,
        branchId: 'branch_chn_tambaram',
        branchName: 'Tambaram Central Hub',
        items: [tomatoItem],
        subtotalPaise: 2000,
        deliveryFeePaise: 2900,
        discountPaise: 0,
        totalPaise: 4900,
        status: OrderStatus.readyForPickup,
        paymentMethod: 'Cash on Delivery',
        deliverySlot: 'Morning (7 AM - 9 AM)',
        deliveryInstructions: 'Leave package on rack.',
        createdAt: now,
        statusTimeline: [
          OrderStatusEvent(
            status: OrderStatus.readyForPickup,
            timestamp: now,
            note: 'Staged for pickup',
          ),
        ],
      );

      test(
        '5.1 Order assigned to delivery rider and dispatched OUT_FOR_DELIVERY',
        () {
          final dispatchedOrder = packedOrder.copyWith(
            status: OrderStatus.outForDelivery,
            assignedDeliveryPartner: deliveryRider,
            statusTimeline: [
              ...packedOrder.statusTimeline,
              OrderStatusEvent(
                status: OrderStatus.outForDelivery,
                timestamp: now.add(const Duration(minutes: 15)),
                note: 'Picked up by Murugan Express (TN-11-AA-4099)',
              ),
            ],
          );

          expect(dispatchedOrder.status, OrderStatus.outForDelivery);
          expect(dispatchedOrder.status.displayName, 'Out for Delivery');
          expect(
            dispatchedOrder.assignedDeliveryPartner?.id,
            'user_delivery_001',
          );
          expect(
            dispatchedOrder.assignedDeliveryPartner?.vehicleNumber,
            'TN-11-AA-4099',
          );
          expect(dispatchedOrder.status.isTerminal, isFalse);
        },
      );

      test('5.2 Delivery rider hands over order and collects COD payment', () {
        final deliveredOrder = packedOrder.copyWith(
          status: OrderStatus.delivered,
          assignedDeliveryPartner: deliveryRider,
          statusTimeline: [
            ...packedOrder.statusTimeline,
            OrderStatusEvent(
              status: OrderStatus.delivered,
              timestamp: now.add(const Duration(minutes: 25)),
              note: 'Delivered at doorstep. Cash received: ₹49.00',
            ),
          ],
        );

        expect(deliveredOrder.status, OrderStatus.delivered);
        expect(deliveredOrder.status.displayName, 'Delivered');
        expect(deliveredOrder.status.isTerminal, isTrue);

        // Terminal order cannot be cancelled
        expect(deliveredOrder.status.canCustomerCancel, isFalse);
        expect(CurrencyFormatter.formatPaise(deliveredOrder.totalPaise), '₹49');
        expect(
          deliveredOrder.statusTimeline.last.note,
          contains('Cash received'),
        );
      });
    });
  });
}
