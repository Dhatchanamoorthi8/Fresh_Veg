import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vegetable_shop/core/localization/app_locale_state.dart';
import 'package:vegetable_shop/core/theme/app_theme.dart';
import 'package:vegora_core/localization/app_localizations.dart';
import 'package:vegetable_shop/shared/models/branch.dart';
import 'package:vegetable_shop/shared/models/cart.dart';
import 'package:vegetable_shop/shared/models/cart_item.dart';
import 'package:vegetable_shop/shared/models/category.dart';
import 'package:vegetable_shop/shared/models/product.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // SECTION 1: TAMIL SUPPORT & LOCALIZATION TESTS
  // ---------------------------------------------------------------------------
  group('1. Tamil Language Support & Typography Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'vegora_app_language_code': 'en',
      });
    });

    test(
      '1.1 Font family and fallback configuration includes Noto Sans Tamil',
      () {
        final themeEn = AppTheme.getTheme(locale: const Locale('en'));
        final themeTa = AppTheme.getTheme(locale: const Locale('ta'));

        // In Tamil mode, NotoSansTamil is active font
        expect(themeTa.textTheme.bodyMedium?.fontFamily, 'NotoSansTamil');
        // In both modes, fallback fonts include NotoSansTamil
        expect(
          themeEn.textTheme.bodyMedium?.fontFamilyFallback,
          contains('NotoSansTamil'),
        );
        // Ensure sufficient line-height (1.38) for Tamil vowel signs and ligatures
        expect(
          themeTa.textTheme.bodyMedium?.height,
          greaterThanOrEqualTo(1.35),
        );
      },
    );

    test(
      '1.2 Language switching and AppLocalizations translation dictionary',
      () {
        const enLoc = AppLocalizations(Locale('en'));
        const taLoc = AppLocalizations(Locale('ta'));

        expect(enLoc.appName, 'Vegora');
        expect(taLoc.appName, 'வெகோரா');

        expect(enLoc.appTagline, 'Freshness at Your Doorstep');
        expect(taLoc.appTagline, 'உங்கள் வீட்டு வாசலில் புத்துணர்ச்சி');

        expect(enLoc.addToCart, 'Add to Cart');
        expect(taLoc.addToCart, 'கூடையில் சேர்');

        expect(enLoc.gramsUnit, 'g');
        expect(taLoc.gramsUnit, 'கிராம்');

        expect(enLoc.kgUnit, 'kg');
        expect(taLoc.kgUnit, 'கிலோ');

        expect(enLoc.perKg, 'per kg');
        expect(taLoc.perKg, 'ஒரு கிலோ');
      },
    );

    test('1.3 Language preference persistence via AppLocaleNotifier', () async {
      SharedPreferences.setMockInitialValues({
        'vegora_app_language_code': 'en',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(appLocaleProvider.notifier);
      expect(container.read(appLocaleProvider).languageCode, 'en');

      await notifier.setLanguage('ta');
      expect(container.read(appLocaleProvider).languageCode, 'ta');

      // Verify stored preference in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('vegora_app_language_code'), 'ta');
    });

    test('1.4 Dual-language vegetable names (English and Tamil)', () {
      const tomato = Product(
        id: 'prod_tomato',
        name: 'Tomato',
        nameTa: 'தக்காளி',
        categoryId: 'everyday_veggies',
        unit: '1 kg',
        description: 'Fresh farm ripe country tomatoes',
        descriptionTa: 'பண்ணை புதிய நாட்டு தக்காளி',
        basePricePaise: 4000,
      );

      expect(tomato.displayName('en'), 'Tomato');
      expect(tomato.displayName('ta'), 'தக்காளி');
      expect(
        tomato.displayDescription('en'),
        'Fresh farm ripe country tomatoes',
      );
      expect(tomato.displayDescription('ta'), 'பண்ணை புதிய நாட்டு தக்காளி');
    });

    test('1.5 Missing Tamil translation gracefully falls back to English', () {
      const exoticHerb = Product(
        id: 'prod_rosemary',
        name: 'Fresh Rosemary',
        nameTa: '', // No Tamil translation provided
        categoryId: 'leafy_greens',
        unit: '100 g',
        description: 'Aromatic kitchen herb',
        descriptionTa: '',
        basePricePaise: 6500,
      );

      // Should return English name instead of null or empty string
      expect(exoticHerb.displayName('ta'), 'Fresh Rosemary');
      expect(exoticHerb.displayDescription('ta'), 'Aromatic kitchen herb');
    });

    test('1.6 Dual-language product categories', () {
      const category = ProductCategory(
        id: 'everyday_veggies',
        name: 'Everyday Veggies',
        nameTa: 'அன்றாட காய்கறிகள்',
        subtitle: 'Fresh Daily',
        icon: Icons.local_florist_rounded,
        emoji: '🍅',
      );

      expect(category.displayName('en'), 'Everyday Veggies');
      expect(category.displayName('ta'), 'அன்றாட காய்கறிகள்');

      const fallbackCat = ProductCategory(
        id: 'exotic',
        name: 'Hydroponics',
        subtitle: 'Pure Water',
        icon: Icons.eco_rounded,
        emoji: '🌱',
      );
      expect(fallbackCat.displayName('ta'), 'Hydroponics');
    });

    test('1.7 JSON serialization & deserialization preserves Tamil fields', () {
      final json = {
        'id': 'prod_onion',
        'name': 'Onion',
        'name_ta': 'வெங்காயம்',
        'description': 'Bellary big onions',
        'description_ta': 'பெல்லாரி பெரிய வெங்காயம்',
        'category_id': 'everyday_veggies',
        'unit': '1 kg',
        'unit_type': 'WEIGHT',
        'base_unit': 'g',
        'base_price_paise': 3500,
        'min_order_quantity': 250,
        'quantity_step': 250,
        'allow_custom_quantity': true,
        'is_active': true,
      };

      final product = Product.fromJson(json);
      expect(product.nameTa, 'வெங்காயம்');
      expect(product.descriptionTa, 'பெல்லாரி பெரிய வெங்காயம்');
      expect(product.unitType, 'WEIGHT');
      expect(product.isWeightBased, isTrue);

      final exported = product.toJson();
      expect(exported['name_ta'], 'வெங்காயம்');
      expect(exported['description_ta'], 'பெல்லாரி பெரிய வெங்காயம்');
      expect(exported['unit_type'], 'WEIGHT');
      expect(exported['base_unit'], 'g');
    });
  });

  // ---------------------------------------------------------------------------
  // SECTION 2: FLEXIBLE GRAM & KILOGRAM QUANTITY SELECTION & PRICING
  // ---------------------------------------------------------------------------
  group('2. Flexible Gram & Kilogram Pricing Rules', () {
    // Vegetable: Tomato at ₹40/kg (4000 paise/kg)
    const tomato = Product(
      id: 'prod_tomato',
      name: 'Tomato',
      nameTa: 'தக்காளி',
      categoryId: 'everyday_veggies',
      unit: '1 kg',
      unitType: 'WEIGHT',
      baseUnit: 'g',
      basePricePaise: 4000, // ₹40 per kg
      minOrderQuantity: 100,
      quantityStep: 100,
    );

    test('2.1 Exactly ₹4 for 100 g at ₹40/kg', () {
      final paise = tomato.calculatePricePaise(100, 4000);
      expect(paise, 400); // 400 paise = ₹4.00
      expect(paise / 100, 4.0);
    });

    test('2.2 Exactly ₹10 for 250 g at ₹40/kg', () {
      final paise = tomato.calculatePricePaise(250, 4000);
      expect(paise, 1000); // 1000 paise = ₹10.00
      expect(paise / 100, 10.0);
    });

    test('2.3 Exactly ₹20 for 500 g at ₹40/kg', () {
      final paise = tomato.calculatePricePaise(500, 4000);
      expect(paise, 2000); // 2000 paise = ₹20.00
      expect(paise / 100, 20.0);
    });

    test('2.4 Exactly ₹30 for 750 g at ₹40/kg', () {
      final paise = tomato.calculatePricePaise(750, 4000);
      expect(paise, 3000); // 3000 paise = ₹30.00
      expect(paise / 100, 30.0);
    });

    test('2.5 Exactly ₹40 for 1 kg (1000 g) at ₹40/kg', () {
      final paise = tomato.calculatePricePaise(1000, 4000);
      expect(paise, 4000); // 4000 paise = ₹40.00
      expect(paise / 100, 40.0);
    });

    test('2.6 Exactly ₹60 for 1.5 kg (1500 g) at ₹40/kg', () {
      final paise = tomato.calculatePricePaise(1500, 4000);
      expect(paise, 6000); // 6000 paise = ₹60.00
      expect(paise / 100, 60.0);
    });

    test('2.7 Exactly ₹80 for 2 kg (2000 g) at ₹40/kg', () {
      final paise = tomato.calculatePricePaise(2000, 4000);
      expect(paise, 8000); // 8000 paise = ₹80.00
      expect(paise / 100, 80.0);
    });

    test('2.8 Custom gram quantities calculate accurately without float errors', () {
      // 350 g of Tomato at ₹40/kg -> (4000 * 350) / 1000 = 1400 paise = ₹14.00
      expect(tomato.calculatePricePaise(350, 4000), 1400);

      // Carrot at ₹65/kg (6500 paise)
      const carrot = Product(
        id: 'prod_carrot',
        name: 'Carrot',
        unitType: 'WEIGHT',
        basePricePaise: 6500,
      );
      // 250 g of Carrot at ₹65/kg -> (6500 * 250) / 1000 = 1625 paise = ₹16.25
      expect(carrot.calculatePricePaise(250, 6500), 1625);
    });

    test('2.9 Invalid or zero quantities return zero', () {
      expect(tomato.calculatePricePaise(0, 4000), 0);
      expect(tomato.calculatePricePaise(-500, 4000), 0);
    });

    test(
      '2.10 Piece-based products calculate per-piece without gram division',
      () {
        // Coconut or English Cucumber sold by piece
        const coconut = Product(
          id: 'prod_coconut',
          name: 'Fresh Coconut',
          nameTa: 'தேங்காய்',
          unit: '1 pc',
          unitType: 'PIECE',
          baseUnit: 'piece',
          basePricePaise: 3500, // ₹35 per piece
        );

        expect(coconut.isWeightBased, isFalse);
        // 1 pc = ₹35 (3500 paise)
        expect(coconut.calculatePricePaise(1, 3500), 3500);
        // 3 pcs = ₹105 (10500 paise)
        expect(coconut.calculatePricePaise(3, 3500), 10500);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // SECTION 3: CART, STOCK & INVENTORY INTEGRATION TESTS
  // ---------------------------------------------------------------------------
  group('3. Cart, Stock & Inventory Integration Tests', () {
    const testBranch = Branch(
      id: 'branch_central',
      name: 'Chennai Central Hub',
      area: 'T Nagar',
      address: '12 Usman Road',
      phone: '9840012345',
      openingHours: '6 AM - 10 PM',
      deliveryCoverage: 'T Nagar, Kodambakkam',
      minOrderAmountPaise: 9900, // ₹99
      freeDeliveryThresholdPaise: 24900, // ₹249
      standardDeliveryFeePaise: 2900, // ₹29
    );

    const tomato = Product(
      id: 'prod_tomato',
      name: 'Tomato',
      nameTa: 'தக்காளி',
      unitType: 'WEIGHT',
      baseUnit: 'g',
      basePricePaise: 4000, // ₹40/kg
      branchInventory: {
        'branch_central': BranchProductInventory(
          stockQuantity: 50000, // 50 kg in integer grams
          pricePaise: 4000,
          isAvailable: true,
        ),
      },
    );

    test('3.1 CartItem line total uses integer grams calculation', () {
      final item250g = CartItem(
        product: tomato,
        quantity: 250, // 250 grams
        branchId: 'branch_central',
        unitPricePaise: 4000,
      );

      expect(item250g.lineTotalPaise, 1000); // ₹10.00
      expect(item250g.formattedQuantity(isTamil: false), '250 g');
      expect(item250g.formattedQuantity(isTamil: true), '250 கிராம்');

      final item1500g = CartItem(
        product: tomato,
        quantity: 1500, // 1.5 kg
        branchId: 'branch_central',
        unitPricePaise: 4000,
      );

      expect(item1500g.lineTotalPaise, 6000); // ₹60.00
      expect(item1500g.formattedQuantity(isTamil: false), '1.5 kg');
      expect(item1500g.formattedQuantity(isTamil: true), '1.5 கிலோ');
    });

    test('3.2 Combining items: adding 250 g and 250 g yields 500 g', () {
      final itemA = CartItem(
        product: tomato,
        quantity: 250,
        branchId: 'branch_central',
        unitPricePaise: 4000,
      );
      final combined = itemA.copyWith(quantity: itemA.quantity + 250);

      expect(combined.quantity, 500);
      expect(combined.lineTotalPaise, 2000); // ₹20.00
      expect(combined.formattedQuantity(isTamil: false), '500 g');
    });

    test(
      '3.3 Stock availability validates against canonical integer grams',
      () {
        // 50 kg in stock = 50,000 g
        final stockGrams = tomato.getStockForBranch('branch_central');
        expect(stockGrams, 50000);

        // Order of 25,000 g (25 kg) is within stock
        expect(25000 <= stockGrams, isTrue);

        // Order of 55,000 g (55 kg) exceeds available stock
        expect(55000 <= stockGrams, isFalse);
      },
    );

    test(
      '3.4 Branch-specific pricing applies correctly to gram quantities',
      () {
        const multiBranchTomato = Product(
          id: 'prod_tomato',
          name: 'Tomato',
          unitType: 'WEIGHT',
          basePricePaise: 4000, // ₹40/kg default
          branchInventory: {
            'branch_central': BranchProductInventory(
              stockQuantity: 10000,
              pricePaise: 4000, // ₹40/kg
              isAvailable: true,
            ),
            'branch_omr': BranchProductInventory(
              stockQuantity: 10000,
              pricePaise: 5000, // ₹50/kg
              isAvailable: true,
            ),
          },
        );

        // 500 g at Central (₹40/kg) = ₹20 (2000 paise)
        final centralPrice = multiBranchTomato.getPricePaiseForBranch(
          'branch_central',
        );
        expect(multiBranchTomato.calculatePricePaise(500, centralPrice), 2000);

        // 500 g at OMR (₹50/kg) = ₹25 (2500 paise)
        final omrPrice = multiBranchTomato.getPricePaiseForBranch('branch_omr');
        expect(multiBranchTomato.calculatePricePaise(500, omrPrice), 2500);
      },
    );

    test(
      '3.5 Cart totals, free delivery and discounts with gram quantities',
      () {
        // Cart with 5 kg of Tomato (5000 g @ ₹40/kg = ₹200 / 20,000 paise)
        // and 1 kg of Carrot (1000 g @ ₹60/kg = ₹60 / 6,000 paise)
        // Subtotal = ₹260 (26,000 paise)
        // Above free delivery threshold (₹249) -> delivery fee is 0
        const carrot = Product(
          id: 'prod_carrot',
          name: 'Carrot',
          unitType: 'WEIGHT',
          basePricePaise: 6000,
        );

        final cart = Cart(
          branchId: 'branch_central',
          items: [
            CartItem(
              product: tomato,
              quantity: 5000,
              branchId: 'branch_central',
              unitPricePaise: 4000,
            ),
            CartItem(
              product: carrot,
              quantity: 1000,
              branchId: 'branch_central',
              unitPricePaise: 6000,
            ),
          ],
        );

        expect(cart.subtotalPaise, 26000); // ₹260.00
        expect(cart.isEligibleForFreeDelivery(testBranch), isTrue);
        expect(cart.deliveryFeePaise(testBranch), 0);
        expect(cart.totalPaise(testBranch), 26000);
      },
    );

    test('3.6 Admin stock conversion: kg to integer grams normalization', () {
      // Admin inputs 25 kg in admin portal
      const adminInputKg = 25.0;
      final canonicalGrams = (adminInputKg * 1000).round();
      expect(canonicalGrams, 25000);

      // Formatted back for admin view
      expect(tomato.formatQuantity(canonicalGrams, isTamil: false), '25 kg');
      expect(tomato.formatQuantity(canonicalGrams, isTamil: true), '25 கிலோ');

      // Admin inputs 1.5 kg
      const smallStockKg = 1.5;
      final smallStockGrams = (smallStockKg * 1000).round();
      expect(smallStockGrams, 1500);
      expect(tomato.formatQuantity(smallStockGrams, isTamil: false), '1.5 kg');
    });

    test(
      '3.7 CartItem supports quantity in grams and bilingual formatting',
      () {
        final item = CartItem(
          product: tomato,
          quantity: 500, // 500 grams
          branchId: 'branch_central',
          unitPricePaise: 4000,
        );

        expect(item.quantity, 500);
        expect(item.totalPaise, 2000);
        expect(item.product.nameTa, 'தக்காளி');
        expect(item.product.displayName('ta'), 'தக்காளி');
        expect(item.product.displayName('en'), 'Tomato');
        expect(item.formattedQuantity(isTamil: false), '500 g');
        expect(item.formattedQuantity(isTamil: true), '500 கிராம்');
      },
    );
  });
}
