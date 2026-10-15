import 'package:flutter/material.dart';

import 'package:vegora_models/vegora_models.dart';

abstract class CatalogRepository {
  Future<List<ProductCategory>> getCategories();
  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
    String? branchId,
    bool inStockOnly = false,
  });
  Future<Product?> getProductById(String id);
  Future<List<Product>> getFeaturedProducts();
  Future<List<Product>> getSeasonalProducts();
  Future<List<Product>> getBestSellerProducts();
}

class MockCatalogRepository implements CatalogRepository {
  static const List<ProductCategory> sampleCategories = [
    ProductCategory(
      id: 'cat_everyday',
      name: 'Daily Essentials',
      subtitle: 'रोज की सब्जियां',
      icon: Icons.local_grocery_store_rounded,
      emoji: '🍅',
      badgeColor: Color(0xFFDC2626),
    ),
    ProductCategory(
      id: 'cat_leafy',
      name: 'Leafy Greens',
      subtitle: 'हरी साग-भाजी',
      icon: Icons.eco_rounded,
      emoji: '🥬',
      badgeColor: Color(0xFF16A34A),
    ),
    ProductCategory(
      id: 'cat_roots',
      name: 'Roots & Tubers',
      subtitle: 'जड़ वाली सब्जियां',
      icon: Icons.grass_rounded,
      emoji: '🥕',
      badgeColor: Color(0xFFEA580C),
    ),
    ProductCategory(
      id: 'cat_onions_potatoes',
      name: 'Onions & Potatoes',
      subtitle: 'प्याज और आलू',
      icon: Icons.egg_rounded,
      emoji: '🥔',
      badgeColor: Color(0xFFD97706),
    ),
    ProductCategory(
      id: 'cat_fruits',
      name: 'Fresh Fruits',
      subtitle: 'ताज़ा फल',
      icon: Icons.apple_rounded,
      emoji: '🍎',
      badgeColor: Color(0xFFE11D48),
    ),
    ProductCategory(
      id: 'cat_seasonal_exotic',
      name: 'Seasonal & Exotic',
      subtitle: 'मौसमी व विदेशी',
      icon: Icons.star_rounded,
      emoji: '🥦',
      badgeColor: Color(0xFF7C3AED),
    ),
  ];

  static const List<Product> sampleProducts = [
    // --- DAILY ESSENTIALS ---
    Product(
      id: 'prod_tomato_hybrid',
      name: 'Hybrid Fresh Tomatoes',
      localName: 'लाल टमाटर (Tamatar)',
      categoryId: 'cat_everyday',
      unit: '1 kg',
      description: 'Firm, ripe, and juicy tomatoes sourced directly from local Kolar farms. Perfect for gravies, curries, and salads.',
      storageTips: 'Store at room temperature away from direct sunlight.',
      origin: 'Kolar, Karnataka',
      emoji: '🍅',
      isBestSeller: true,
      basePricePaise: 3400, // ₹34
      originalPricePaise: 4200, // ₹42
      branchInventory: {
        'branch_blr_01': BranchProductInventory(
          stockQuantity: 28,
          pricePaise: 3200,
        ),
        'branch_blr_02': BranchProductInventory(
          stockQuantity: 35,
          pricePaise: 3000,
        ),
        'branch_blr_03': BranchProductInventory(
          stockQuantity: 18,
          pricePaise: 3400,
        ),
        'branch_blr_04': BranchProductInventory(
          stockQuantity: 22,
          pricePaise: 3200,
        ),
        'branch_blr_05': BranchProductInventory(
          stockQuantity: 15,
          pricePaise: 3400,
        ),
      },
    ),
    Product(
      id: 'prod_tomato_country',
      name: 'Country Tomatoes (Nati)',
      localName: 'नाटी टमाटर (Country Tamatar)',
      categoryId: 'cat_everyday',
      unit: '500 g',
      description: 'Tangy indigenous sour tomatoes with thin skin and intense flavor, prized for traditional rasam and sambar.',
      storageTips: 'Best used within 4 days. Keep in a breathable basket.',
      origin: 'Chintamani, Karnataka',
      emoji: '🍅',
      isOrganic: true,
      basePricePaise: 2600, // ₹26
      originalPricePaise: 3200,
      branchInventory: {
        'branch_blr_01': BranchProductInventory(stockQuantity: 14),
        'branch_blr_02': BranchProductInventory(stockQuantity: 20),
        'branch_blr_05': BranchProductInventory(
          stockQuantity: 0,
          isAvailable: false,
        ), // Out of stock at Malleshwaram!
      },
    ),
    Product(
      id: 'prod_ladyfinger_bhindi',
      name: 'Tender Lady Finger (Okra)',
      localName: 'ताज़ा भिंडी (Bhindi)',
      categoryId: 'cat_everyday',
      unit: '500 g',
      description: 'Crisp, tender, and slime-free young okra pods. Snaps easily at the tip, ideal for crispy Bhindi Masala.',
      storageTips: 'Dry thoroughly before storing in the refrigerator.',
      origin: 'Ramanagara, Karnataka',
      emoji: '🥒',
      isBestSeller: true,
      basePricePaise: 2800, // ₹28
      originalPricePaise: 3500,
    ),
    Product(
      id: 'prod_green_capsicum',
      name: 'Shimla Green Capsicum',
      localName: 'शिमला मिर्च (Capsicum)',
      categoryId: 'cat_everyday',
      unit: '500 g',
      description: 'Crunchy, deep green bell peppers with thick walls and sweet grassy note. Great for stir-fries and kadai dishes.',
      storageTips: 'Store unwashed in vegetable crisper drawer.',
      origin: 'Ooty, Tamil Nadu',
      emoji: '🫑',
      basePricePaise: 3800, // ₹38
    ),
    Product(
      id: 'prod_green_chillies',
      name: 'Spicy Green Chillies',
      localName: 'तीखी हरी मिर्च (Hari Mirch)',
      categoryId: 'cat_everyday',
      unit: '200 g',
      description: 'Sharp, aromatic green chillies that give an authentic kick to curries, chutneys, and tadkas.',
      storageTips:
          'Remove stems and store in an airtight container lined with tissue.',
      origin: 'Byadagi, Karnataka',
      emoji: '🌶️',
      basePricePaise: 1600, // ₹16
    ),
    Product(
      id: 'prod_cucumber_desi',
      name: 'Crisp Desi Cucumber',
      localName: 'देसी खीरा (Kheera)',
      categoryId: 'cat_everyday',
      unit: '500 g',
      description: 'Cool, refreshing, naturally sweet cucumber with high water content. Perfect for afternoon salads and raita.',
      storageTips: 'Keep chilled in crisper box.',
      origin: 'Mysuru, Karnataka',
      emoji: '🥒',
      basePricePaise: 2400, // ₹24
    ),

    // --- LEAFY GREENS ---
    Product(
      id: 'prod_spinach_palak',
      name: 'Farm Fresh Spinach (Palak)',
      localName: 'ताज़ा पालक (Palak)',
      categoryId: 'cat_leafy',
      unit: '1 bunch (250g)',
      description: 'Broad green leaves, rich in iron, harvested in the morning dew. Washed, trimmed, and root-cleaned.',
      storageTips: 'Wrap in paper towel and refrigerate.',
      origin: 'Hosur Valley Farms',
      emoji: '🥬',
      isOrganic: true,
      isBestSeller: true,
      basePricePaise: 2200, // ₹22
      originalPricePaise: 2800,
      branchInventory: {
        'branch_blr_01': BranchProductInventory(stockQuantity: 40),
        'branch_blr_02': BranchProductInventory(stockQuantity: 30),
        'branch_blr_03': BranchProductInventory(stockQuantity: 25),
      },
    ),
    Product(
      id: 'prod_fenugreek_methi',
      name: 'Fragrant Methi Leaves',
      localName: 'ताज़ा मेथी (Methi)',
      categoryId: 'cat_leafy',
      unit: '1 bunch (200g)',
      description: 'Intensely aromatic small leaves with distinctive mild bitter-sweet taste. Excellent for Methi Thepla and Aloo Methi.',
      storageTips: 'Pluck leaves, discard hard stems, store dry.',
      origin: 'Malur Farms',
      emoji: '🌿',
      basePricePaise: 2000, // ₹20
    ),
    Product(
      id: 'prod_coriander_dhaniya',
      name: 'Country Coriander (Dhaniya)',
      localName: 'हरा धनिया (Dhaniya)',
      categoryId: 'cat_leafy',
      unit: '1 bunch (150g)',
      description: 'Pungent, highly aromatic coriander with vibrant green roots. Adds finishing garnish and zest to every Indian dish.',
      storageTips:
          'Submerge root ends in a jar with water or wrap in wet towel.',
      origin: 'Doddaballapur, Karnataka',
      emoji: '🌱',
      basePricePaise: 1500, // ₹15
      originalPricePaise: 2000,
    ),
    Product(
      id: 'prod_mint_pudina',
      name: 'Fresh Mint Leaves (Pudina)',
      localName: 'पुदीना पत्ता (Pudina)',
      categoryId: 'cat_leafy',
      unit: '1 bunch (100g)',
      description: 'Invigorating spearmint leaves packed with natural menthol aroma. Essential for biryani, chutney, and mojitos.',
      storageTips: 'Refrigerate in a clean container with paper towel.',
      origin: 'Hosur Valley',
      emoji: '🌿',
      basePricePaise: 1200, // ₹12
    ),
    Product(
      id: 'prod_curry_leaves',
      name: 'Organic Curry Leaves (Kadi Patta)',
      localName: 'कढ़ी पत्ता (Kadi Patta)',
      categoryId: 'cat_leafy',
      unit: '50 g',
      description: 'Sun-grown aromatic dark green leaves. The soul of South Indian tadka and seasoning.',
      storageTips: 'Dry pluck and keep in an airtight glass container.',
      origin: 'Hassan, Karnataka',
      emoji: '🍃',
      basePricePaise: 800, // ₹8
    ),

    // --- ROOTS & TUBERS ---
    Product(
      id: 'prod_carrot_orange',
      name: 'Sweet Orange Carrots',
      localName: 'मीठी गाजर (Gajar)',
      categoryId: 'cat_roots',
      unit: '500 g',
      description: 'Plump, crisp, and high in beta-carotene. Washed clean from farm dirt, ready to slice, steam, or juice.',
      storageTips: 'Trim tops and store in plastic bag inside crisper.',
      origin: 'Ooty Hills, Tamil Nadu',
      emoji: '🥕',
      basePricePaise: 3200, // ₹32
      originalPricePaise: 4000,
    ),
    Product(
      id: 'prod_beetroot_fresh',
      name: 'Earthy Dark Beetroot',
      localName: 'चुकंदर (Chukandar)',
      categoryId: 'cat_roots',
      unit: '500 g',
      description: 'Deep ruby-purple roots with high antioxidant content and natural sweetness. Great for poriyal and juices.',
      storageTips: 'Keep in cool dry place or refrigerate.',
      origin: 'Kodaikanal, Tamil Nadu',
      emoji: '🟣',
      basePricePaise: 2600, // ₹26
    ),
    Product(
      id: 'prod_radish_mooli',
      name: 'White Radish (Mooli)',
      localName: 'ताज़ा सफेद मूली (Mooli)',
      categoryId: 'cat_roots',
      unit: '500 g',
      description: 'Crisp, pungent white daikon radish. Crisp texture with sharp peppery finish, perfect for Mooli Parathas.',
      storageTips: 'Store in airtight bag with air squeezed out.',
      origin: 'Chikkaballapur',
      emoji: '🥢',
      basePricePaise: 2400, // ₹24
    ),

    // --- ONIONS & POTATOES ---
    Product(
      id: 'prod_onion_nashik',
      name: 'Nashik Red Onions',
      localName: 'नासिक लाल प्याज (Pyaz)',
      categoryId: 'cat_onions_potatoes',
      unit: '1 kg',
      description: 'World-famous Nashik pink-red onions with multiple outer dry layers, strong pungency, and long shelf life.',
      storageTips: 'Store in an open ventilated basket away from potatoes.',
      origin: 'Nashik, Maharashtra',
      emoji: '🧅',
      isBestSeller: true,
      basePricePaise: 3800, // ₹38
      originalPricePaise: 4800,
      branchInventory: {
        'branch_blr_01': BranchProductInventory(
          stockQuantity: 50,
          pricePaise: 3600,
        ),
        'branch_blr_02': BranchProductInventory(
          stockQuantity: 45,
          pricePaise: 3500,
        ),
      },
    ),
    Product(
      id: 'prod_potato_pahadi',
      name: 'Pahadi Baby & Regular Potatoes',
      localName: 'पहाड़ी आलू (Aloo)',
      categoryId: 'cat_onions_potatoes',
      unit: '1 kg',
      description: 'Golden skin starchy potatoes from high altitude farms. Ideal texture for roasting, dum aloo, and crispy fries.',
      storageTips: 'Store in dark, cool pantry. Avoid light exposure.',
      origin: 'Hassan, Karnataka',
      emoji: '🥔',
      isBestSeller: true,
      basePricePaise: 3200, // ₹32
      originalPricePaise: 3800,
    ),
    Product(
      id: 'prod_ginger_adrak',
      name: 'Old Mountain Ginger (Adrak)',
      localName: 'पहाड़ी अदरक (Adrak)',
      categoryId: 'cat_onions_potatoes',
      unit: '250 g',
      description: 'Fibrous, intensely spicy aged ginger rhizomes. Gives warm depth to morning chai, curries, and pastes.',
      storageTips: 'Store unpeeled in paper bag in refrigerator.',
      origin: 'Wayanad, Kerala',
      emoji: '🫚',
      basePricePaise: 4200, // ₹42
    ),
    Product(
      id: 'prod_garlic_desi',
      name: 'Desi Small Clove Garlic',
      localName: 'देसी लहसुन (Lahsun)',
      categoryId: 'cat_onions_potatoes',
      unit: '250 g',
      description: 'Aromatic, high-pungency native garlic bulbs with tight skins and concentrated essential oils.',
      storageTips: 'Store in mesh wire basket in dry ambient room.',
      origin: 'Mandsaur, Madhya Pradesh',
      emoji: '🧄',
      basePricePaise: 6500, // ₹65
      originalPricePaise: 7500,
    ),

    // --- FRESH FRUITS ---
    Product(
      id: 'prod_banana_robusta',
      name: 'Golden Robusta Bananas',
      localName: 'केला (Kela)',
      categoryId: 'cat_fruits',
      unit: '500 g (Approx 4-5 pcs)',
      description: 'Naturally ripened, sweet, chemical-free bananas packed with potassium and natural dietary fiber.',
      storageTips: 'Keep at room temperature hung or on counter.',
      origin: 'Theni, Tamil Nadu',
      emoji: '🍌',
      isBestSeller: true,
      basePricePaise: 3000, // ₹30
    ),
    Product(
      id: 'prod_apple_royal_gala',
      name: 'Crisp Royal Gala Apples',
      localName: 'मीठा सेब (Seb)',
      categoryId: 'cat_fruits',
      unit: '4 pcs (Approx 600g)',
      description: 'Crunchy, sweet, and aromatic blush-red apples. Wax-free, juicy bite with mild floral aroma.',
      storageTips: 'Refrigerate to preserve crisp snap.',
      origin: 'Kinnaur, Himachal Pradesh',
      emoji: '🍎',
      basePricePaise: 11000, // ₹110
      originalPricePaise: 13500,
    ),
    Product(
      id: 'prod_pomegranate_kabuli',
      name: 'Ruby Red Pomegranate (Anaar)',
      localName: 'अनार (Anaar)',
      categoryId: 'cat_fruits',
      unit: '2 pcs (Approx 500g)',
      description: 'Large fruit with glistening dark red arils and soft edible seeds. Extremely rich in polyphenols.',
      storageTips:
          'Store whole at room temperature or arils in fridge container.',
      origin: 'Solapur, Maharashtra',
      emoji: '🫐',
      isOrganic: true,
      basePricePaise: 9500, // ₹95
    ),
    Product(
      id: 'prod_papaya_taiwan',
      name: 'Sweet Red Lady Papaya',
      localName: 'पपीता (Papita)',
      categoryId: 'cat_fruits',
      unit: '1 pc (Approx 1 kg)',
      description: 'Tree-ripened honey-sweet orange flesh with digestive enzymes. Ready to peel and enjoy.',
      storageTips: 'Once ripe, slice and keep in covered bowl in fridge.',
      origin: 'Anantapur, Andhra Pradesh',
      emoji: '🥭',
      basePricePaise: 5500, // ₹55
    ),

    // --- SEASONAL & EXOTIC ---
    Product(
      id: 'prod_broccoli_green',
      name: 'Farm Fresh Green Broccoli',
      localName: 'हरी ब्रोकली (Broccoli)',
      categoryId: 'cat_seasonal_exotic',
      unit: '1 pc (Approx 350g)',
      description: 'Tight green florets rich in vitamins K and C. Cultivated in misty Nilgiri hills.',
      storageTips: 'Keep in loose perforated bag in crisper.',
      origin: 'Nilgiris, Tamil Nadu',
      emoji: '🥦',
      isSeasonal: true,
      basePricePaise: 6800, // ₹68
      originalPricePaise: 8500,
      branchInventory: {
        'branch_blr_01': BranchProductInventory(
          stockQuantity: 12,
          pricePaise: 6800,
        ),
        'branch_blr_02': BranchProductInventory(
          stockQuantity: 10,
          pricePaise: 6800,
        ),
        'branch_blr_03': BranchProductInventory(
          stockQuantity: 8,
          pricePaise: 7200,
        ),
        'branch_blr_05': BranchProductInventory(
          stockQuantity: 0,
          isAvailable: false,
        ), // Out of stock at Malleshwaram
      },
    ),
    Product(
      id: 'prod_mushroom_button',
      name: 'Fresh Button Mushrooms',
      localName: 'मशरूम (Button Mushroom)',
      categoryId: 'cat_seasonal_exotic',
      unit: '1 pack (200g)',
      description: 'Firm, snow-white button mushrooms grown in controlled hygienic climate rooms. Great for pizzas and stews.',
      storageTips: 'Keep in original paper or punnet box in fridge.',
      origin: 'Kodaikanal, Tamil Nadu',
      emoji: '🍄',
      isSeasonal: true,
      basePricePaise: 5200, // ₹52
      originalPricePaise: 6500,
    ),
    Product(
      id: 'prod_baby_corn',
      name: 'Tender Sweet Baby Corn',
      localName: 'बेबी कॉर्न (Baby Corn)',
      categoryId: 'cat_seasonal_exotic',
      unit: '1 pack (200g)',
      description: 'Sweet, young, crunchy corn shoots. Excellent for stir-fries, manchurian, and soups.',
      storageTips: 'Keep chilled. Use within 3 days for maximum crunch.',
      origin: 'Devanahalli, Karnataka',
      emoji: '🌽',
      isSeasonal: true,
      basePricePaise: 4400, // ₹44
    ),
  ];

  @override
  Future<List<ProductCategory>> getCategories() async {
    return sampleCategories;
  }

  @override
  Future<List<Product>> getProducts({
    String? categoryId,
    String? searchQuery,
    String? branchId,
    bool inStockOnly = false,
  }) async {
    var list = sampleProducts;
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      list = list.where((p) => p.categoryId == categoryId).toList();
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.localName.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Future<Product?> getProductById(String id) async {
    return sampleProducts.firstWhere(
      (p) => p.id == id,
      orElse: () => sampleProducts.first,
    );
  }

  @override
  Future<List<Product>> getFeaturedProducts() async {
    return sampleProducts.where((p) => p.isBestSeller || p.isOrganic).toList();
  }

  @override
  Future<List<Product>> getSeasonalProducts() async {
    return sampleProducts.where((p) => p.isSeasonal).toList();
  }

  @override
  Future<List<Product>> getBestSellerProducts() async {
    return sampleProducts.where((p) => p.isBestSeller).toList();
  }
}
