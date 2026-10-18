/// Clean domain model representing a Delivery Partner / Fleet Agent.
class DeliveryAgent {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final bool isActive;
  final String? vehicleNumber;
  final double rating;
  final int totalDeliveries;

  const DeliveryAgent({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.isActive = true,
    this.vehicleNumber,
    this.rating = 4.8,
    this.totalDeliveries = 0,
  });

  factory DeliveryAgent.fromJson(Map<String, dynamic> json) {
    return DeliveryAgent(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Delivery Partner',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      vehicleNumber: json['vehicle_number'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.8,
      totalDeliveries: (json['total_deliveries'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'is_active': isActive,
      'vehicle_number': vehicleNumber,
      'rating': rating,
      'total_deliveries': totalDeliveries,
    };
  }

  DeliveryAgent copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    bool? isActive,
    String? vehicleNumber,
    double? rating,
    int? totalDeliveries,
  }) {
    return DeliveryAgent(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      rating: rating ?? this.rating,
      totalDeliveries: totalDeliveries ?? this.totalDeliveries,
    );
  }
}
