import '../models/branch.dart';
import '../models/customer_address.dart';

abstract class BranchRepository {
  Future<List<Branch>> getBranches();
  Future<Branch?> getBranchById(String id);
  Future<List<CustomerAddress>> getSavedAddresses();
  Future<Branch> getEligibleBranchForAddress(CustomerAddress address);
}

class MockBranchRepository implements BranchRepository {
  static const List<Branch> sampleBranches = [
    Branch(
      id: 'branch_blr_01',
      name: 'Indiranagar Flagship Store',
      area: 'Indiranagar',
      address: 'Shop 14, 100 Feet Road, HAL 2nd Stage, Indiranagar',
      phone: '+91 80 4123 9901',
      openingHours: '6:30 AM - 10:00 PM',
      deliveryCoverage: 'Indiranagar, Domlur, HAL, Ulsoor, Old Airport Rd',
      estimatedDeliveryMinutes: 25,
      minOrderAmountPaise: 9900,
      freeDeliveryThresholdPaise: 24900,
      standardDeliveryFeePaise: 2900,
      isOpen: true,
      isAcceptingOrders: true,
    ),
    Branch(
      id: 'branch_blr_02',
      name: 'Koramangala Market Hub',
      area: 'Koramangala',
      address: 'Plot 42, 80 Feet Road, 4th Block, Koramangala',
      phone: '+91 80 4123 9902',
      openingHours: '6:00 AM - 10:30 PM',
      deliveryCoverage: 'Koramangala (Blocks 1-8), Ejipura, SG Palya, ST Bed',
      estimatedDeliveryMinutes: 20,
      minOrderAmountPaise: 9900,
      freeDeliveryThresholdPaise: 24900,
      standardDeliveryFeePaise: 2500,
      isOpen: true,
      isAcceptingOrders: true,
    ),
    Branch(
      id: 'branch_blr_03',
      name: 'Whitefield Farm Fresh Outlet',
      area: 'Whitefield',
      address: 'No. 8, ITPL Main Road, Prestige Ozone Junction, Whitefield',
      phone: '+91 80 4123 9903',
      openingHours: '7:00 AM - 10:00 PM',
      deliveryCoverage: 'Whitefield, Kadugodi, Hope Farm, Hoodi, Brookefield',
      estimatedDeliveryMinutes: 35,
      minOrderAmountPaise: 14900,
      freeDeliveryThresholdPaise: 29900,
      standardDeliveryFeePaise: 3500,
      isOpen: true,
      isAcceptingOrders: true,
    ),
    Branch(
      id: 'branch_blr_04',
      name: 'Jayanagar Traditional Mandi',
      area: 'Jayanagar',
      address: 'Opp. BDA Complex, 9th Main Road, 4th Block, Jayanagar',
      phone: '+91 80 4123 9904',
      openingHours: '6:00 AM - 9:30 PM',
      deliveryCoverage:
          'Jayanagar (Blocks 1-9), JP Nagar, Basavanagudi, Tilaknagar',
      estimatedDeliveryMinutes: 25,
      minOrderAmountPaise: 9900,
      freeDeliveryThresholdPaise: 24900,
      standardDeliveryFeePaise: 2900,
      isOpen: true,
      isAcceptingOrders: true,
    ),
    Branch(
      id: 'branch_blr_05',
      name: 'Malleshwaram Heritage Store',
      area: 'Malleshwaram',
      address: 'Cross 8, Sampige Road, Near 8th Cross Circle, Malleshwaram',
      phone: '+91 80 4123 9905',
      openingHours: '6:30 AM - 9:30 PM',
      deliveryCoverage: 'Malleshwaram, Rajajinagar, Sadashivanagar, Vyalikaval',
      estimatedDeliveryMinutes: 30,
      minOrderAmountPaise: 9900,
      freeDeliveryThresholdPaise: 24900,
      standardDeliveryFeePaise: 2900,
      isOpen: true,
      isAcceptingOrders: true,
    ),
    Branch(
      id: 'branch_blr_06',
      name: 'HSR Layout Green Depot',
      area: 'HSR Layout',
      address: 'Building 12, 27th Main Road, Sector 1, HSR Layout',
      phone: '+91 80 4123 9906',
      openingHours: '6:30 AM - 10:00 PM',
      deliveryCoverage: 'HSR Layout (Sectors 1-7), Haralur, Bellandur, Agara',
      estimatedDeliveryMinutes: 25,
      minOrderAmountPaise: 9900,
      freeDeliveryThresholdPaise: 24900,
      standardDeliveryFeePaise: 2900,
      isOpen: true,
      isAcceptingOrders: true,
    ),
  ];

  static const List<CustomerAddress> sampleAddresses = [
    CustomerAddress(
      id: 'addr_01',
      label: 'Home',
      fullAddress: 'Flat 402, Green Meadows, 12th Cross, Indiranagar',
      area: 'Indiranagar',
      landmark: 'Near CMH Hospital',
      pinCode: '560038',
      eligibleBranchId: 'branch_blr_01',
      isDefault: true,
    ),
    CustomerAddress(
      id: 'addr_02',
      label: 'Office',
      fullAddress: 'Innov8 Tech Park, 80 Feet Road, 4th Block, Koramangala',
      area: 'Koramangala',
      landmark: 'Opp Sony World Signal',
      pinCode: '560034',
      eligibleBranchId: 'branch_blr_02',
      isDefault: false,
    ),
    CustomerAddress(
      id: 'addr_03',
      label: "Parents' Home",
      fullAddress: 'Villa 14, Brigade Gateway, 8th Main, Malleshwaram',
      area: 'Malleshwaram',
      landmark: 'Near Orion Mall',
      pinCode: '560055',
      eligibleBranchId: 'branch_blr_05',
      isDefault: false,
    ),
  ];

  @override
  Future<List<Branch>> getBranches() async {
    return sampleBranches;
  }

  @override
  Future<Branch?> getBranchById(String id) async {
    return sampleBranches.firstWhere(
      (b) => b.id == id,
      orElse: () => sampleBranches.first,
    );
  }

  @override
  Future<List<CustomerAddress>> getSavedAddresses() async {
    return sampleAddresses;
  }

  @override
  Future<Branch> getEligibleBranchForAddress(CustomerAddress address) async {
    return sampleBranches.firstWhere(
      (b) => b.id == address.eligibleBranchId,
      orElse: () => sampleBranches.first,
    );
  }
}
