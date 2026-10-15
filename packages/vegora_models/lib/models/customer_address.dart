class CustomerAddress {
  final String id;
  final String label; // "Home", "Work", "Other"
  final String fullAddress;
  final String area;
  final String landmark;
  final String pinCode;
  final String eligibleBranchId;
  final bool isDefault;

  const CustomerAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.area,
    required this.landmark,
    required this.pinCode,
    required this.eligibleBranchId,
    this.isDefault = false,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] as String,
      label: json['title'] as String? ?? 'Home',
      fullAddress: json['full_address'] as String? ?? '',
      area: json['area'] as String? ?? '',
      landmark: json['landmark'] as String? ?? '',
      pinCode: json['pincode'] as String? ?? '',
      eligibleBranchId:
          json['eligible_branch_id'] as String? ?? 'branch_blr_01',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson({String? userId}) {
    final map = <String, dynamic>{
      'id': id,
      'title': label,
      'full_address': fullAddress,
      'area': area,
      'landmark': landmark,
      'pincode': pinCode,
      'is_default': isDefault,
    };
    if (userId != null) {
      map['user_id'] = userId;
    }
    return map;
  }

  CustomerAddress copyWith({
    String? id,
    String? label,
    String? fullAddress,
    String? area,
    String? landmark,
    String? pinCode,
    String? eligibleBranchId,
    bool? isDefault,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      area: area ?? this.area,
      landmark: landmark ?? this.landmark,
      pinCode: pinCode ?? this.pinCode,
      eligibleBranchId: eligibleBranchId ?? this.eligibleBranchId,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
