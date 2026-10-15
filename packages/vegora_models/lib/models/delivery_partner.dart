class DeliveryPartner {
  final String id;
  final String name;
  final String phone;
  final String vehicleNumber;
  final double rating;
  final int totalDeliveriesCompleted;

  const DeliveryPartner({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    this.rating = 4.8,
    this.totalDeliveriesCompleted = 142,
  });
}
