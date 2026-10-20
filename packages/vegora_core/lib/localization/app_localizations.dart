import 'package:flutter/material.dart';

/// Vegora comprehensive bilingual localization supporting English and Tamil (தமிழ்).
class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ta')];

  static bool isSupported(Locale locale) =>
      supportedLocales.any((l) => l.languageCode == locale.languageCode);

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return loc ?? const AppLocalizations(Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get isTamil => locale.languageCode == 'ta';

  // --------------------------------------------------------------------------
  // Core Branding & App Info
  // --------------------------------------------------------------------------
  String get appName => isTamil ? 'வெகோரா' : 'Vegora';
  String get appTagline => isTamil
      ? 'உங்கள் வீட்டு வாசலில் புத்துணர்ச்சி'
      : 'Freshness at Your Doorstep';

  // --------------------------------------------------------------------------
  // Navigation Tabs
  // --------------------------------------------------------------------------
  String get navHome => isTamil ? 'முகப்பு' : 'Home';
  String get navCatalog => isTamil ? 'பட்டியல்' : 'Catalog';
  String get navCart => isTamil ? 'கூடை' : 'Cart';
  String get navOrders => isTamil ? 'ஆர்டர்கள்' : 'Orders';
  String get navProfile => isTamil ? 'சுயவிவரம்' : 'Account';

  // --------------------------------------------------------------------------
  // Common Actions & Buttons
  // --------------------------------------------------------------------------
  String get add => isTamil ? 'சேர்' : 'Add';
  String get addToCart => isTamil ? 'கூடையில் சேர்' : 'Add to Cart';
  String get added => isTamil ? 'சேர்க்கப்பட்டது' : 'Added';
  String get viewCart => isTamil ? 'கூடையைப் பார்' : 'View Cart';
  String get checkout => isTamil ? 'செக்அவுட்' : 'Checkout';
  String get placeOrder => isTamil ? 'ஆர்டர் செய்' : 'Place Order';
  String get cancel => isTamil ? 'ரத்து செய்' : 'Cancel';
  String get confirm => isTamil ? 'உறுதி செய்' : 'Confirm';
  String get apply => isTamil ? 'பயன்படுத்து' : 'Apply';
  String get clearAll => isTamil ? 'அனைத்தையும் நீக்கு' : 'Clear All';
  String get remove => isTamil ? 'நீக்கு' : 'Remove';
  String get edit => isTamil ? 'திருத்து' : 'Edit';
  String get save => isTamil ? 'சேமி' : 'Save';
  String get retry => isTamil ? 'மீண்டும் முயற்சி' : 'Retry';
  String get searchHint => isTamil
      ? 'புதிய காய்கறிகள், கீரைகளைத் தேடுங்கள்...'
      : 'Search fresh vegetables, greens...';

  // --------------------------------------------------------------------------
  // Produce Badges & Status
  // --------------------------------------------------------------------------
  String get organic => isTamil ? 'இயற்கை விளைச்சல்' : '100% ORGANIC';
  String get bestSeller => isTamil ? 'அதிக விற்பனை' : 'BEST SELLER';
  String get seasonal => isTamil ? 'பருவகாலம்' : 'SEASONAL';
  String get inStock => isTamil ? 'கையிருப்பில் உள்ளது' : 'In Stock';
  String get outOfStock => isTamil ? 'கையிருப்பில் இல்லை' : 'Out of Stock';

  // --------------------------------------------------------------------------
  // Quantity, Measurement & Units
  // --------------------------------------------------------------------------
  String get quantity => isTamil ? 'அளவு' : 'Quantity';
  String get selectQuantity =>
      isTamil ? 'அளவைத் தேர்ந்தெடுக்கவும்' : 'Select Quantity';
  String get customQuantity => isTamil ? 'விருப்ப அளவு' : 'Custom Quantity';
  String get gramsUnit => isTamil ? 'கிராம்' : 'g';
  String get kgUnit => isTamil ? 'கிலோ' : 'kg';
  String get pieceUnit => isTamil ? 'எண்ணிக்கை' : 'pc';
  String get bunchUnit => isTamil ? 'கட்டு' : 'bunch';
  String get perKg => isTamil ? 'ஒரு கிலோ' : 'per kg';
  String get perPiece => isTamil ? 'ஒன்று' : 'per piece';
  String get perBunch => isTamil ? 'ஒரு கட்டு' : 'per bunch';
  String get price => isTamil ? 'விலை' : 'Price';

  /// Helper to format quantities dynamically (e.g. 500 g -> "500 கிராம்" or "500 g")
  String formatQuantity(
    int quantityGramsOrCount, {
    String unitType = 'WEIGHT',
  }) {
    if (unitType == 'WEIGHT') {
      if (quantityGramsOrCount >= 1000 && quantityGramsOrCount % 100 == 0) {
        final kg = quantityGramsOrCount / 1000;
        final kgStr = kg % 1 == 0
            ? kg.toInt().toString()
            : kg.toStringAsFixed(1);
        return isTamil ? '$kgStr கிலோ' : '$kgStr kg';
      }
      return isTamil
          ? '$quantityGramsOrCount கிராம்'
          : '$quantityGramsOrCount g';
    } else if (unitType == 'BUNCH') {
      return isTamil
          ? '$quantityGramsOrCount கட்டு'
          : '$quantityGramsOrCount ${quantityGramsOrCount == 1 ? 'bunch' : 'bunches'}';
    } else {
      return isTamil
          ? '$quantityGramsOrCount எண்ணிக்கை'
          : '$quantityGramsOrCount ${quantityGramsOrCount == 1 ? 'pc' : 'pcs'}';
    }
  }

  // --------------------------------------------------------------------------
  // Cart & Pricing
  // --------------------------------------------------------------------------
  String get shoppingCart => isTamil ? 'வணிகக் கூடை' : 'Shopping Cart';
  String get cartEmptyTitle =>
      isTamil ? 'உங்கள் கூடை காலியாக உள்ளது' : 'Your Cart is Empty';
  String get cartEmptySubtitle => isTamil
      ? 'புதிய நாட்டுத் தக்காளி, கீரைகள் மற்றும் காய்கறிகளைத் தேர்ந்தெடுங்கள்!'
      : 'Fresh leafy greens, tomatoes, and crunchy veggies are waiting for you!';
  String get shopNow => isTamil ? 'காய்கறிகளை வாங்க' : 'Shop Fresh Vegetables';
  String get billDetails => isTamil ? 'கட்டண விவரங்கள்' : 'Bill Summary';
  String get subtotal => isTamil ? 'பொருட்கள் கூட்டுத்தொகை' : 'Item Subtotal';
  String get deliveryFee => isTamil ? 'டெலிவரி கட்டணம்' : 'Delivery Fee';
  String get freeDelivery => isTamil ? 'இலவச டெலிவரி' : 'FREE';
  String get discount => isTamil ? 'தள்ளுபடி' : 'Discount';
  String get grandTotal => isTamil ? 'மொத்த கட்டணம்' : 'To Pay';
  String get itemTotal => isTamil ? 'பொருள் மொத்தம்' : 'Item Total';
  String get fulfillingFrom => isTamil ? 'அங்காடி' : 'Fulfilling from';

  // --------------------------------------------------------------------------
  // Orders & Tracking
  // --------------------------------------------------------------------------
  String get orderHistory => isTamil ? 'ஆர்டர் வரலாறு' : 'Order History';
  String get trackOrder => isTamil ? 'ஆர்டரைக் கண்காணிக்க' : 'Track Order';
  String get orderPlaced =>
      isTamil ? 'ஆர்டர் பதிவு செய்யப்பட்டது' : 'Order Placed';
  String get acceptedByStore =>
      isTamil ? 'அங்காடி ஏற்றது' : 'Accepted by Store';
  String get packingVeggies =>
      isTamil ? 'காய்கறிகள் பேக் செய்யப்படுகிறது' : 'Packing Fresh Veggies';
  String get readyForPickup =>
      isTamil ? 'எடுத்துச் செல்ல தயார்' : 'Ready for Pickup';
  String get outForDelivery =>
      isTamil ? 'டெலிவரிக்கு வருகிறது' : 'Out for Delivery';
  String get delivered => isTamil ? 'டெலிவரி செய்யப்பட்டது' : 'Delivered';
  String get orderCancelled =>
      isTamil ? 'ஆர்டர் ரத்து செய்யப்பட்டது' : 'Order Cancelled';

  // --------------------------------------------------------------------------
  // Account & Language Settings
  // --------------------------------------------------------------------------
  String get accountTitle => isTamil ? 'என் கணக்கு' : 'My Account';
  String get languageSetting => isTamil ? 'பயன்பாட்டு மொழி' : 'App Language';
  String get englishLang => 'English';
  String get tamilLang => 'தமிழ் (Tamil)';
  String get chooseLanguage =>
      isTamil ? 'மொழியைத் தேர்வுசெய்க' : 'Choose Language';
  String get languageUpdated =>
      isTamil ? 'மொழி மாற்றப்பட்டது' : 'Language updated successfully';
  String get savedAddresses =>
      isTamil ? 'சேமிக்கப்பட்ட முகவரிகள்' : 'Saved Delivery Addresses';
  String get customerSupport =>
      isTamil ? 'உதவி மையம் & ஆதரவு' : 'Customer Support & Help';
  String get logout => isTamil ? 'வெளியேறு' : 'Log Out';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
