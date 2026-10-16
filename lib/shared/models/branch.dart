class Branch {
  final String id;
  final String name;
  final String code;
  final String area;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final String? managerName;
  final String? contactEmail;
  final String openingHours;
  final String deliveryCoverage;
  final int estimatedDeliveryMinutes;
  final int minOrderAmountPaise;
  final int freeDeliveryThresholdPaise;
  final int standardDeliveryFeePaise;
  final bool isOpen;
  final bool isAcceptingOrders;
  final bool isActive;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  const Branch({
    required this.id,
    required this.name,
    this.code = '',
    required this.area,
    required this.address,
    this.city = 'Bengaluru',
    this.state = 'Karnataka',
    this.pincode = '',
    required this.phone,
    this.managerName,
    this.contactEmail,
    required this.openingHours,
    required this.deliveryCoverage,
    this.estimatedDeliveryMinutes = 30,
    this.minOrderAmountPaise = 9900, // ₹99
    this.freeDeliveryThresholdPaise = 24900, // Free delivery above ₹249
    this.standardDeliveryFeePaise = 2900, // ₹29
    this.isOpen = true,
    this.isAcceptingOrders = true,
    this.isActive = true,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      name: json['name'] as String,
      code:
          json['code'] as String? ??
          (json['id'] as String? ?? '').toUpperCase(),
      area: json['area'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? 'Bengaluru',
      state: json['state'] as String? ?? 'Karnataka',
      pincode: json['pincode'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      managerName: json['manager_name'] as String?,
      contactEmail: json['contact_email'] as String?,
      openingHours: json['opening_hours'] as String? ?? '6:30 AM - 10:00 PM',
      deliveryCoverage: json['delivery_coverage'] as String? ?? '',
      estimatedDeliveryMinutes:
          (json['estimated_delivery_minutes'] as num?)?.toInt() ?? 30,
      minOrderAmountPaise:
          (json['min_order_amount_paise'] as num?)?.toInt() ?? 9900,
      freeDeliveryThresholdPaise:
          (json['free_delivery_threshold_paise'] as num?)?.toInt() ?? 24900,
      standardDeliveryFeePaise:
          (json['standard_delivery_fee_paise'] as num?)?.toInt() ?? 2900,
      isOpen: json['is_open'] as bool? ?? true,
      isAcceptingOrders: json['is_accepting_orders'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (code.isNotEmpty) 'code': code,
      'area': area,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
      if (managerName != null) 'manager_name': managerName,
      if (contactEmail != null) 'contact_email': contactEmail,
      'opening_hours': openingHours,
      'delivery_coverage': deliveryCoverage,
      'estimated_delivery_minutes': estimatedDeliveryMinutes,
      'min_order_amount_paise': minOrderAmountPaise,
      'free_delivery_threshold_paise': freeDeliveryThresholdPaise,
      'standard_delivery_fee_paise': standardDeliveryFeePaise,
      'is_open': isOpen,
      'is_accepting_orders': isAcceptingOrders,
      'is_active': isActive,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  Branch copyWith({
    String? id,
    String? name,
    String? code,
    String? area,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? phone,
    String? managerName,
    String? contactEmail,
    String? openingHours,
    String? deliveryCoverage,
    int? estimatedDeliveryMinutes,
    int? minOrderAmountPaise,
    int? freeDeliveryThresholdPaise,
    int? standardDeliveryFeePaise,
    bool? isOpen,
    bool? isAcceptingOrders,
    bool? isActive,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      area: area ?? this.area,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      phone: phone ?? this.phone,
      managerName: managerName ?? this.managerName,
      contactEmail: contactEmail ?? this.contactEmail,
      openingHours: openingHours ?? this.openingHours,
      deliveryCoverage: deliveryCoverage ?? this.deliveryCoverage,
      estimatedDeliveryMinutes:
          estimatedDeliveryMinutes ?? this.estimatedDeliveryMinutes,
      minOrderAmountPaise: minOrderAmountPaise ?? this.minOrderAmountPaise,
      freeDeliveryThresholdPaise:
          freeDeliveryThresholdPaise ?? this.freeDeliveryThresholdPaise,
      standardDeliveryFeePaise:
          standardDeliveryFeePaise ?? this.standardDeliveryFeePaise,
      isOpen: isOpen ?? this.isOpen,
      isAcceptingOrders: isAcceptingOrders ?? this.isAcceptingOrders,
      isActive: isActive ?? this.isActive,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Branch && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

typedef StoreBranch = Branch;
