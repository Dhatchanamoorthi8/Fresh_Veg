import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Reusable widget for displaying produce/product images with graceful
/// network loading, error handling, asset support, and emoji fallback.
class ProductImageView extends StatelessWidget {
  final String? imageUrl;
  final String fallbackEmoji;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double emojiSize;

  const ProductImageView({
    super.key,
    required this.imageUrl,
    this.fallbackEmoji = '🥬',
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.emojiSize = 44.0,
  });

  @override
  Widget build(BuildContext context) {
    final cleanUrl = imageUrl?.trim();
    final hasValidUrl = cleanUrl != null && cleanUrl.isNotEmpty;

    Widget imageContent;

    if (hasValidUrl) {
      if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        imageContent = Image.network(
          cleanUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              width: width,
              height: height,
              color: AppColors.neutral100,
              alignment: Alignment.center,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildFallbackEmoji(),
        );
      } else if (cleanUrl.startsWith('assets/')) {
        imageContent = Image.asset(
          cleanUrl,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallbackEmoji(),
        );
      } else {
        imageContent = _buildFallbackEmoji();
      }
    } else {
      imageContent = _buildFallbackEmoji();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageContent);
    }

    return imageContent;
  }

  Widget _buildFallbackEmoji() {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      color: AppColors.neutral50,
      child: Text(
        fallbackEmoji.isNotEmpty ? fallbackEmoji : '🥬',
        style: TextStyle(fontSize: emojiSize),
      ),
    );
  }
}
