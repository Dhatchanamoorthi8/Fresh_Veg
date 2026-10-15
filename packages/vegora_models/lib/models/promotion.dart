class Promotion {
  final String id;
  final String code;
  final String title;
  final String description;
  final String discountType; // 'percentage' or 'fixed'
  final int discountValue;
  final int minOrderAmountPaise;
  final int? maxDiscountPaise;
  final String? branchId;
  final String? categoryId;
  final bool isUrgentSale;
  final DateTime startTime;
  final DateTime endTime;
  final bool isActive;

  const Promotion({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.minOrderAmountPaise,
    this.maxDiscountPaise,
    this.branchId,
    this.categoryId,
    this.isUrgentSale = false,
    required this.startTime,
    required this.endTime,
    this.isActive = true,
  });

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      discountType: json['discount_type'] as String? ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toInt() ?? 10,
      minOrderAmountPaise:
          (json['min_order_amount_paise'] as num?)?.toInt() ?? 0,
      maxDiscountPaise: (json['max_discount_paise'] as num?)?.toInt(),
      branchId: json['branch_id'] as String?,
      categoryId: json['category_id'] as String?,
      isUrgentSale: json['is_urgent_sale'] as bool? ?? false,
      startTime:
          DateTime.tryParse(json['start_time'] as String? ?? '') ??
          DateTime.now(),
      endTime:
          DateTime.tryParse(json['end_time'] as String? ?? '') ??
          DateTime.now().add(const Duration(days: 30)),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_amount_paise': minOrderAmountPaise,
      'max_discount_paise': maxDiscountPaise,
      'branch_id': branchId,
      'category_id': categoryId,
      'is_urgent_sale': isUrgentSale,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'is_active': isActive,
    };
  }

  int calculateDiscountPaise(int subtotalPaise) {
    if (!isActive || isExpired) return 0;
    if (subtotalPaise < minOrderAmountPaise) return 0;
    int discount = 0;
    if (discountType == 'percentage') {
      discount = (subtotalPaise * (discountValue / 100.0)).round();
    } else {
      discount = discountValue;
    }
    if (maxDiscountPaise != null && discount > maxDiscountPaise!) {
      discount = maxDiscountPaise!;
    }
    return discount;
  }

  bool get isExpired => DateTime.now().isAfter(endTime);

  Promotion copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? discountType,
    int? discountValue,
    int? minOrderAmountPaise,
    int? maxDiscountPaise,
    String? branchId,
    String? categoryId,
    bool? isUrgentSale,
    DateTime? startTime,
    DateTime? endTime,
    bool? isActive,
  }) {
    return Promotion(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrderAmountPaise: minOrderAmountPaise ?? this.minOrderAmountPaise,
      maxDiscountPaise: maxDiscountPaise ?? this.maxDiscountPaise,
      branchId: branchId ?? this.branchId,
      categoryId: categoryId ?? this.categoryId,
      isUrgentSale: isUrgentSale ?? this.isUrgentSale,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isActive: isActive ?? this.isActive,
    );
  }
}
