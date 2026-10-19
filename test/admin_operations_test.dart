import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vegetable_shop/core/utils/currency_formatter.dart';
import 'package:vegora_admin_web/features/admin/admin_shell.dart';
import 'package:vegetable_shop/shared/models/branch.dart';
import 'package:vegetable_shop/shared/models/category.dart';
import 'package:vegetable_shop/shared/models/product.dart';
import 'package:vegetable_shop/shared/models/promotion.dart';
import 'package:vegetable_shop/shared/models/user_role.dart';
import 'package:vegetable_shop/shared/repositories/supabase_auth_repository.dart';

void main() {
  group('1. Admin Navigation & Shell Tests', () {
    test(
      'All 13 Admin Navigation sections are configured with unique routes',
      () {
        expect(adminMenuItems.length, 13);

        final expectedSections = [
          AdminMenuSection.dashboard,
          AdminMenuSection.branches,
          AdminMenuSection.vegetables,
          AdminMenuSection.categories,
          AdminMenuSection.inventory,
          AdminMenuSection.prices,
          AdminMenuSection.promotions,
          AdminMenuSection.orders,
          AdminMenuSection.staff,
          AdminMenuSection.deliveryAgents,
          AdminMenuSection.deliveryAssignments,
          AdminMenuSection.reports,
          AdminMenuSection.settings,
        ];

        final menuSections = adminMenuItems.map((item) => item.section).toSet();
        expect(menuSections, equals(expectedSections.toSet()));

        final routes = adminMenuItems.map((item) => item.route).toSet();
        // Ensure all 13 routes are distinct
        expect(routes.length, 13);
        expect(routes.contains('/admin'), isTrue);
        expect(routes.contains('/admin/branches'), isTrue);
        expect(routes.contains('/admin/vegetables'), isTrue);
        expect(routes.contains('/admin/categories'), isTrue);
        expect(routes.contains('/admin/inventory'), isTrue);
        expect(routes.contains('/admin/prices'), isTrue);
        expect(routes.contains('/admin/promotions'), isTrue);
        expect(routes.contains('/admin/orders'), isTrue);
        expect(routes.contains('/admin/staff'), isTrue);
        expect(routes.contains('/admin/delivery-agents'), isTrue);
        expect(routes.contains('/admin/delivery-assignments'), isTrue);
        expect(routes.contains('/admin/reports'), isTrue);
        expect(routes.contains('/admin/settings'), isTrue);
      },
    );

    testWidgets(
      'AdminScaffold renders desktop sidebar with all 14 options including Logout',
      (tester) async {
        // Simulate Desktop viewport (width >= 960)
        tester.view.physicalSize = const Size(1280, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AdminScaffold(
                currentSection: AdminMenuSection.dashboard,
                title: 'Dashboard Overview',
                body: Center(child: Text('Dashboard Content Body')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check titles from menu items
        expect(find.text('Vegora'), findsOneWidget);
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Manage Branches'), findsOneWidget);
        expect(find.text('Manage Vegetables'), findsOneWidget);
        expect(find.text('Categories'), findsOneWidget);
        expect(find.text('Branch Inventory'), findsOneWidget);
        expect(find.text('Price Management'), findsOneWidget);
        expect(find.text('Discounts & Promotions'), findsOneWidget);
        expect(find.text('Customer Orders'), findsOneWidget);
        expect(find.text('Branch Staff'), findsOneWidget);
        expect(find.text('Delivery Agents'), findsOneWidget);
        expect(find.text('Delivery Dispatch'), findsOneWidget);
        expect(find.text('Sales Reports'), findsOneWidget);
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Logout'), findsOneWidget);
        expect(find.text('Dashboard Content Body'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminScaffold renders mobile AppBar and Drawer toggle on small screens',
      (tester) async {
        // Simulate Mobile viewport (< 960px)
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: AdminScaffold(
                currentSection: AdminMenuSection.branches,
                title: 'Manage Branches',
                body: Center(child: Text('Branches Mobile View')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // AppBar title is visible
        expect(find.text('Manage Branches'), findsOneWidget);
        expect(find.text('Branches Mobile View'), findsOneWidget);

        // Open Drawer
        final scaffoldState = tester.firstState<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        // Inside Drawer
        expect(find.text('Vegora Admin Hub'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Switch to Customer Store'),
          100,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Switch to Customer Store'), findsOneWidget);
      },
    );
  });

  group('2. Manage Branches Model & Business Rules Tests', () {
    test('Branch JSON serialization preserves all required admin fields', () {
      final now = DateTime.now();
      final branch = Branch(
        id: 'branch_mum_andheri',
        name: 'Andheri West Hub',
        code: 'MUM001',
        area: 'Andheri West',
        address: 'Shop 4, Greenfield Heights, Link Road',
        city: 'Mumbai',
        state: 'Maharashtra',
        pincode: '400053',
        phone: '+91 98200 11223',
        managerName: 'Sunil Shinde',
        contactEmail: 'andheri@vegora.in',
        openingHours: '6:00 AM - 10:00 PM',
        deliveryCoverage: 'Andheri West, Juhu, Versova',
        minOrderAmountPaise: 9900,
        freeDeliveryThresholdPaise: 29900,
        standardDeliveryFeePaise: 3000,
        isOpen: true,
        isAcceptingOrders: true,
        isActive: true,
        createdAt: now,
      );

      final json = branch.toJson();
      expect(json['id'], 'branch_mum_andheri');
      expect(json['name'], 'Andheri West Hub');
      expect(json['code'], 'MUM001');
      expect(json['city'], 'Mumbai');
      expect(json['state'], 'Maharashtra');
      expect(json['pincode'], '400053');
      expect(json['manager_name'], 'Sunil Shinde');
      expect(json['contact_email'], 'andheri@vegora.in');
      expect(json['is_active'], isTrue);

      final parsed = Branch.fromJson(json);
      expect(parsed.code, 'MUM001');
      expect(parsed.city, 'Mumbai');
      expect(parsed.pincode, '400053');
      expect(parsed.managerName, 'Sunil Shinde');
    });

    test('Deactivating a branch retains historical identifier and data', () {
      final activeBranch = Branch(
        id: 'branch_old_01',
        name: 'Legacy Station Branch',
        code: 'OLD001',
        area: 'Old Town',
        address: '10 Old Station Road',
        phone: '+91 98000 00000',
        openingHours: '7:00 AM - 9:00 PM',
        deliveryCoverage: 'Old Town',
        minOrderAmountPaise: 10000,
        freeDeliveryThresholdPaise: 30000,
        standardDeliveryFeePaise: 4000,
        isOpen: true,
        isAcceptingOrders: true,
        isActive: true,
      );

      final deactivated = activeBranch.copyWith(
        isActive: false,
        isAcceptingOrders: false,
      );
      expect(deactivated.id, 'branch_old_01');
      expect(deactivated.isActive, isFalse);
      expect(deactivated.isAcceptingOrders, isFalse);
      // Historical references remain completely intact
    });
  });

  group('3. Manage Vegetables & Branch Inventory Separation Tests', () {
    test(
      'Product details are shared while price and stock vary per branch',
      () {
        final tomato = Product(
          id: 'veg_tomato_hybrid',
          sku: 'TOM-HYB-001',
          name: 'Country Red Tomatoes',
          localName: 'Tamatar',
          categoryId: 'daily_veggies',
          unit: 'kg',
          description: 'Plump, farm-ripe red tomatoes with optimal acidity.',
          storageTips: 'Store at room temperature until fully ripe.',
          origin: 'Nashik, Maharashtra',
          imageUrl: 'https://supabase.co/storage/v1/object/public/product-images/tomato.jpg',
          emoji: '🍅',
          basePricePaise: 4000, // ₹40.00 base price
          originalPricePaise: 5000, // ₹50.00 MRP
          isOrganic: false,
          isSeasonal: false,
          isActive: true,
          isFeatured: true,
          branchInventory: {
            'branch_blr_01': const BranchProductInventory(
              pricePaise: 3800, // ₹38.00 at Koramangala
              stockQuantity: 45,
              lowStockThreshold: 10,
              isAvailable: true,
            ),
            'branch_blr_02': const BranchProductInventory(
              pricePaise: 4200, // ₹42.00 at Indiranagar
              stockQuantity: 0, // Out of stock at Indiranagar
              lowStockThreshold: 5,
              isAvailable: false,
            ),
          },
        );

        // Verify shared details
        expect(tomato.sku, 'TOM-HYB-001');
        expect(tomato.unit, 'kg');
        expect(tomato.isFeatured, isTrue);

        // Verify branch 1 availability and pricing
        expect(tomato.getPricePaiseForBranch('branch_blr_01'), 3800);
        expect(tomato.isAvailableAtBranch('branch_blr_01'), isTrue);

        // Verify branch 2 availability and pricing
        expect(tomato.getPricePaiseForBranch('branch_blr_02'), 4200);
        expect(tomato.isAvailableAtBranch('branch_blr_02'), isFalse);

        // Verify unassigned branch falls back to basePricePaise but is unavailable
        expect(tomato.getPricePaiseForBranch('branch_mum_01'), 4000);
        expect(tomato.isAvailableAtBranch('branch_mum_01'), isFalse);
      },
    );

    test('Updating branch-specific price recalculates margin without modifying base product', () {
      final initialProduct = Product(
        id: 'veg_spinach',
        sku: 'SPN-ORG-001',
        name: 'Organic Baby Spinach',
        localName: 'Palak',
        categoryId: 'leafy_greens',
        unit: '250 g',
        description: 'Fresh organic tender baby spinach leaves.',
        storageTips: 'Refrigerate in a clean damp paper towel.',
        origin: 'Pune, Maharashtra',
        emoji: '🥬',
        basePricePaise: 3500,
        originalPricePaise: 4000,
        branchInventory: {
          'branch_blr_01': const BranchProductInventory(
            pricePaise: 3500,
            stockQuantity: 20,
            lowStockThreshold: 5,
            isAvailable: true,
          ),
        },
      );

      // Admin updates branch price to ₹30.00
      final updatedInventory = Map<String, BranchProductInventory>.from(
        initialProduct.branchInventory,
      );
      updatedInventory['branch_blr_01'] = const BranchProductInventory(
        pricePaise: 3000,
        stockQuantity: 20,
        lowStockThreshold: 5,
        isAvailable: true,
      );

      final updatedProduct = initialProduct.copyWith(
        branchInventory: updatedInventory,
      );

      expect(updatedProduct.basePricePaise, 3500); // Base price intact
      expect(
        updatedProduct.getPricePaiseForBranch('branch_blr_01'),
        3000,
      ); // Overridden price updated
      expect(
        CurrencyFormatter.formatPaise(
          updatedProduct.getPricePaiseForBranch('branch_blr_01'),
        ),
        '₹30',
      );
    });
  });

  group('4. Discounts, Promotions & Urgent Clearance Tests', () {
    test('Standard percentage promotion calculates discount correctly', () {
      final promo = Promotion(
        id: 'promo_monsoon_15',
        code: 'MONSOON15',
        title: 'Monsoon Green Harvest',
        description: 'Flat 15% off on fresh leafy greens',
        discountType: 'percentage',
        discountValue: 15,
        minOrderAmountPaise: 30000, // Min ₹300
        maxDiscountPaise: 7500, // Max ₹75
        isUrgentSale: false,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(days: 7)),
        isActive: true,
      );

      expect(promo.isExpired, isFalse);

      // Order ₹400 -> 15% is ₹60 (below cap)
      final disc1 = promo.calculateDiscountPaise(40000);
      expect(disc1, 6000);

      // Order ₹1000 -> 15% is ₹150 (hits cap of ₹75)
      final disc2 = promo.calculateDiscountPaise(100000);
      expect(disc2, 7500);

      // Order ₹200 (below min order ₹300) -> 0 discount
      final disc3 = promo.calculateDiscountPaise(20000);
      expect(disc3, 0);
    });

    test(
      'Urgent Clearance Flash Deal marks isUrgentSale and expires on schedule',
      () {
        final expiredFlashSale = Promotion(
          id: 'urgent_clearance_spinach',
          code: 'URGENT-PALAK',
          title: 'Urgent Farm Harvest Clearance',
          description: 'Morning plucked palak surplus.',
          discountType: 'percentage',
          discountValue: 35,
          minOrderAmountPaise: 0,
          isUrgentSale: true,
          startTime: DateTime.now().subtract(const Duration(hours: 36)),
          endTime: DateTime.now().subtract(
            const Duration(hours: 12),
          ), // Expired 12 hours ago
          isActive: true,
        );

        expect(expiredFlashSale.isUrgentSale, isTrue);
        expect(expiredFlashSale.isExpired, isTrue);
        // Expired promotion cannot be applied at checkout
        expect(expiredFlashSale.calculateDiscountPaise(10000), 0);
      },
    );
  });

  group('5. Categories & Catalog Schema Tests', () {
    test('ProductCategory model handles emoji and active status', () {
      const cat = ProductCategory(
        id: 'root_veggies',
        name: 'Root & Tuber Vegetables',
        subtitle: 'Potatoes, carrots, beets, and sweet potatoes',
        icon: Icons.grass_rounded,
        emoji: '🥕',
        imageUrl: 'https://supabase.co/storage/v1/object/public/product-images/roots.jpg',
        sortOrder: 3,
        isActive: true,
      );

      final json = cat.toJson();
      expect(json['id'], 'root_veggies');
      expect(json['name'], 'Root & Tuber Vegetables');
      expect(json['emoji'], '🥕');
      expect(json['sort_order'], 3);
      expect(json['is_active'], isTrue);

      final parsed = ProductCategory.fromJson(json);
      expect(parsed.name, 'Root & Tuber Vegetables');
      expect(parsed.emoji, '🥕');
      expect(parsed.imageUrl, isNotNull);
    });
  });

  group('6. Security & Role Permissions Tests', () {
    test('Only Administrator role is authorized for admin actions', () {
      const adminUser = UserProfile(
        id: 'u_admin_01',
        email: 'admin@vegora.in',
        fullName: 'System Administrator',
        role: AppUserRole.superAdmin,
        isActive: true,
      );

      const customerUser = UserProfile(
        id: 'u_customer_01',
        email: 'customer@gmail.com',
        fullName: 'Jane Customer',
        role: AppUserRole.customer,
        isActive: true,
      );

      const staffUser = UserProfile(
        id: 'u_staff_01',
        email: 'staff@vegora.in',
        fullName: 'Store Staff Member',
        role: AppUserRole.branchStaff,
        branchId: 'branch_blr_01',
        isActive: true,
      );

      expect(adminUser.role.isAdmin, isTrue);
      expect(customerUser.role.isAdmin, isFalse);
      expect(staffUser.role.isAdmin, isFalse);
    });
  });
}
