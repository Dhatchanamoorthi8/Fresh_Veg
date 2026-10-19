import 'package:flutter/material.dart';

class ProductCategory {
  final String id;
  final String name;
  final String nameTa;
  final String subtitle;
  final IconData icon;
  final String emoji;
  final Color badgeColor;
  final String? imageUrl;
  final bool isActive;
  final int sortOrder;

  const ProductCategory({
    required this.id,
    required this.name,
    this.nameTa = '',
    required this.subtitle,
    required this.icon,
    required this.emoji,
    this.badgeColor = const Color(0xFF15803D),
    this.imageUrl,
    this.isActive = true,
    this.sortOrder = 0,
  });

  /// Returns Tamil category name when languageCode is 'ta' and available, else English name.
  String displayName([String? languageCode]) {
    if (languageCode == 'ta' && nameTa.trim().isNotEmpty) {
      return nameTa;
    }
    return name;
  }

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = json['name'] as String;
    final nameTa = json['name_ta'] as String? ?? '';
    final localName = json['local_name'] as String? ?? '';
    final imageUrl = json['image_url'] as String?;
    final isActive = json['is_active'] as bool? ?? true;
    final sortOrder = (json['sort_order'] as num?)?.toInt() ?? 0;

    IconData iconData;
    String emojiChar = '🥗';
    switch (id) {
      case 'leafy_greens':
        iconData = Icons.eco_rounded;
        emojiChar = '🥬';
        break;
      case 'everyday_veggies':
        iconData = Icons.local_florist_rounded;
        emojiChar = '🍅';
        break;
      case 'root_veggies':
        iconData = Icons.grass_rounded;
        emojiChar = '🥕';
        break;
      case 'onions_potatoes':
        iconData = Icons.shopping_basket_rounded;
        emojiChar = '🥔';
        break;
      case 'fresh_fruits':
        iconData = Icons.apple_rounded;
        emojiChar = '🍎';
        break;
      case 'seasonal_harvest':
        iconData = Icons.wb_sunny_rounded;
        emojiChar = '🌾';
        break;
      default:
        iconData = Icons.category_rounded;
        emojiChar = '🥗';
    }

    final customEmoji = json['emoji'] as String?;
    if (customEmoji != null && customEmoji.isNotEmpty) {
      emojiChar = customEmoji;
    }

    return ProductCategory(
      id: id,
      name: name,
      nameTa: nameTa,
      subtitle: localName,
      icon: iconData,
      emoji: emojiChar,
      badgeColor: const Color(0xFF15803D),
      imageUrl: imageUrl,
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_ta': nameTa,
      'local_name': subtitle,
      'icon_name': 'category_rounded',
      'emoji': emoji,
      'slug': id,
      'image_url': imageUrl,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  ProductCategory copyWith({
    String? id,
    String? name,
    String? nameTa,
    String? subtitle,
    IconData? icon,
    String? emoji,
    Color? badgeColor,
    String? imageUrl,
    bool? isActive,
    int? sortOrder,
  }) {
    return ProductCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      nameTa: nameTa ?? this.nameTa,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      emoji: emoji ?? this.emoji,
      badgeColor: badgeColor ?? this.badgeColor,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
