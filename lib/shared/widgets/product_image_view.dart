import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Reusable widget for displaying produce/product images with graceful
/// network loading, error handling, asset support, and realistic produce fallback.
class ProductImageView extends StatelessWidget {
  final String? imageUrl;
  final String fallbackEmoji;
  final String? productName;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double emojiSize;

  const ProductImageView({
    super.key,
    required this.imageUrl,
    this.fallbackEmoji = '🥬',
    this.productName,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.emojiSize = 44.0,
  });

  /// List of discredited/mismatched stock photo patterns to reject immediately
  static const List<String> discreditedPatterns = [
    'photo-1546470427-0d4db154ceb7', // caramel milkshake
    'photo-1599305090598-fe179d501227', // cosmetic cream jar
    'photo-1615485500704-8e990f9900f7', // loose seed grains
    'photo-1518843875459-f738682238a6', // assortment with eggplant
    'photo-1512621776951-a57141f2eefd', // salad bowl
    'photo-1599940824399-b87987ceb72a', // pine forest
    'photo-1588252303782-cb80119abd6d', // red chillies for green chillies
    'photo-1563565375-f3fdfdbefa83', // multi-color bell peppers
    'photo-1615485290382-441e4d049cb5', // broccoli for cabbage
    'photo-1509358271058-acd22cc93898', // spice spoons for drumstick
    'photo-1508747703725-719777637510', // red onions for baby potato
    'Acer_Wallpaper', // laptop wallpaper
  ];

  /// Curated map of 100% verified authentic local produce assets
  static const Map<String, String> verifiedProduceAssets = {
    '🍅': 'assets/images/products/veg_tomato_desi.jpg',
    '🧅': 'assets/images/products/veg_onion_nasik.jpg',
    '🥔': 'assets/images/products/veg_potato_jyoti.jpg',
    '🥬': 'assets/images/products/veg_palak.jpg',
    '🌿': 'assets/images/products/veg_methi.jpg',
    '🌱': 'assets/images/products/veg_bhindi.jpg',
    '🍃': 'assets/images/products/veg_coriander.jpg',
    '🥕': 'assets/images/products/veg_carrot_orange.jpg',
    '🫑': 'assets/images/products/veg_capsicum_green.jpg',
    '🌶️': 'assets/images/products/veg_green_chilli.jpg',
    '🥒': 'assets/images/products/veg_cucumber_desi.jpg',
    '🥦': 'assets/images/products/veg_cabbage.jpg',
    '🫚': 'assets/images/products/veg_ginger.jpg',
    '🧄': 'assets/images/products/veg_garlic.jpg',
    '🍌': 'assets/images/products/fruit_banana_yelakki.jpg',
    '🍎': 'assets/images/products/fruit_apple_kinnaur.jpg',
    '🫐': 'assets/images/products/fruit_pomegranate.jpg',
    '🥭': 'assets/images/products/fruit_papaya.jpg',
    '🍈': 'assets/images/products/fruit_papaya.jpg',
    '🍋': 'assets/images/products/veg_lemon.jpg',
  };

  /// Match produce by English, Hindi, or Tamil name keywords to verified local asset
  static String? matchAssetByName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('desi') && (lower.contains('tomato') || lower.contains('tamatar') || lower.contains('தக்காளி'))) {
      return 'assets/images/products/veg_tomato_desi.jpg';
    }
    if (lower.contains('tomato') || lower.contains('tamatar') || lower.contains('தக்காளி')) {
      return 'assets/images/products/veg_tomato_hybrid.jpg';
    }
    if (lower.contains('onion') || lower.contains('pyaz') || lower.contains('pyaaz') || lower.contains('வெங்காயம்')) {
      return 'assets/images/products/veg_onion_nasik.jpg';
    }
    if (lower.contains('baby') && (lower.contains('potato') || lower.contains('aloo') || lower.contains('உருளைக்கிழங்கு'))) {
      return 'assets/images/products/veg_potato_baby.jpg';
    }
    if (lower.contains('potato') || lower.contains('aloo') || lower.contains('உருளைக்கிழங்கு')) {
      return 'assets/images/products/veg_potato_jyoti.jpg';
    }
    if (lower.contains('spinach') || lower.contains('palak') || lower.contains('பசலைக் கீரை')) {
      return 'assets/images/products/veg_palak.jpg';
    }
    if (lower.contains('methi') || lower.contains('fenugreek') || lower.contains('வெந்தய')) {
      return 'assets/images/products/veg_methi.jpg';
    }
    if (lower.contains('coriander') || lower.contains('cilantro') || lower.contains('dhania') || lower.contains('கொத்தமல்லி')) {
      return 'assets/images/products/veg_coriander.jpg';
    }
    if (lower.contains('bhindi') || lower.contains('okra') || lower.contains('lady') || lower.contains('வெண்டைக்காய்')) {
      return 'assets/images/products/veg_bhindi.jpg';
    }
    if (lower.contains('carrot') || lower.contains('gajar') || lower.contains('கேரட்')) {
      return 'assets/images/products/veg_carrot_orange.jpg';
    }
    if (lower.contains('capsicum') || lower.contains('bell pepper') || lower.contains('குடைமிளகாய்')) {
      return 'assets/images/products/veg_capsicum_green.jpg';
    }
    if (lower.contains('chilli') || lower.contains('chili') || lower.contains('mirch') || lower.contains('மிளகாய்')) {
      return 'assets/images/products/veg_green_chilli.jpg';
    }
    if (lower.contains('cucumber') || lower.contains('kheera') || lower.contains('வெள்ளரிக்காய்')) {
      return 'assets/images/products/veg_cucumber_desi.jpg';
    }
    if (lower.contains('cabbage') || lower.contains('patta gobhi') || lower.contains('முட்டைக்கோஸ்')) {
      return 'assets/images/products/veg_cabbage.jpg';
    }
    if (lower.contains('cauliflower') || lower.contains('phool gobhi') || lower.contains('காலிஃபிளவர்')) {
      return 'assets/images/products/veg_cauliflower.jpg';
    }
    if (lower.contains('ginger') || lower.contains('adrak') || lower.contains('இஞ்சி')) {
      return 'assets/images/products/veg_ginger.jpg';
    }
    if (lower.contains('garlic') || lower.contains('lahsun') || lower.contains('பூண்டு')) {
      return 'assets/images/products/veg_garlic.jpg';
    }
    if (lower.contains('lemon') || lower.contains('nimbu') || lower.contains('எலுமிச்ச')) {
      return 'assets/images/products/veg_lemon.jpg';
    }
    if (lower.contains('banana') || lower.contains('kela') || lower.contains('வாழைப்பழம்')) {
      return 'assets/images/products/fruit_banana_yelakki.jpg';
    }
    if (lower.contains('apple') || lower.contains('seb') || lower.contains('ஆப்பிள்')) {
      return 'assets/images/products/fruit_apple_kinnaur.jpg';
    }
    if (lower.contains('pomegranate') || lower.contains('anar') || lower.contains('anaar') || lower.contains('மாதுள')) {
      return 'assets/images/products/fruit_pomegranate.jpg';
    }
    if (lower.contains('papaya') || lower.contains('papita') || lower.contains('பப்பாளி')) {
      return 'assets/images/products/fruit_papaya.jpg';
    }
    if (lower.contains('drumstick') || lower.contains('moringa') || lower.contains('sahjan') || lower.contains('முருங்கை')) {
      return 'assets/images/products/veg_drumstick.jpg';
    }
    if (lower.contains('bitter') || lower.contains('karela') || lower.contains('பாகற்காய்')) {
      return 'assets/images/products/veg_bitter_gourd.jpg';
    }
    return null;
  }

  /// Intelligently resolves a high-quality photograph URL for any produce item
  static String? resolveImageUrl(String? url, String? emoji, [String? name]) {
    final clean = url?.trim();

    // 1. If an incoming URL matches known discredited stock photos, reject it
    final isDiscredited = clean != null &&
        discreditedPatterns.any((pat) => clean.contains(pat));

    if (clean != null &&
        clean.isNotEmpty &&
        !isDiscredited &&
        (clean.startsWith('http://') ||
            clean.startsWith('https://') ||
            clean.startsWith('assets/'))) {
      return clean;
    }

    // 2. Check by product name first for maximum precision
    if (name != null && name.isNotEmpty) {
      final matchedAsset = matchAssetByName(name);
      if (matchedAsset != null) return matchedAsset;
    }

    // 3. Fallback to emoji match
    if (emoji != null && verifiedProduceAssets.containsKey(emoji)) {
      return verifiedProduceAssets[emoji];
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = resolveImageUrl(imageUrl, fallbackEmoji, productName);
    final hasValidUrl = effectiveUrl != null && effectiveUrl.isNotEmpty;

    Widget imageContent;

    if (hasValidUrl) {
      if (effectiveUrl.startsWith('http://') || effectiveUrl.startsWith('https://')) {
        imageContent = Image.network(
          effectiveUrl,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: (width != null && width! > 0) ? (width! * 2).toInt() : 360,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return AnimatedOpacity(
                opacity: frame == null ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: child,
              );
            }
            return _buildShimmerPlaceholder();
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _buildShimmerPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) => _buildGracefulFallback(),
        );
      } else if (effectiveUrl.startsWith('assets/')) {
        imageContent = Image.asset(
          effectiveUrl,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: (width != null && width! > 0) ? (width! * 2).toInt() : 360,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              return child;
            }
            return _buildShimmerPlaceholder();
          },
          errorBuilder: (context, error, stackTrace) => _buildGracefulFallback(),
        );
      } else {
        imageContent = _buildGracefulFallback();
      }
    } else {
      imageContent = _buildGracefulFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageContent);
    }

    return imageContent;
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F2),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primary.withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGracefulFallback() {
    final assetPath = (productName != null ? matchAssetByName(productName!) : null) ??
        verifiedProduceAssets[fallbackEmoji];
    if (assetPath != null) {
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: (width != null && width! > 0) ? (width! * 2).toInt() : 360,
        errorBuilder: (context, error, stackTrace) => _buildEmojiContainer(),
      );
    }
    return _buildEmojiContainer();
  }

  Widget _buildEmojiContainer() {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: borderRadius,
      ),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          fallbackEmoji.isNotEmpty ? fallbackEmoji : '🥬',
          style: TextStyle(fontSize: emojiSize * 0.7),
        ),
      ),
    );
  }
}
