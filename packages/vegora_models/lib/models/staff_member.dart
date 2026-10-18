import 'user_role.dart';

/// Clean domain model representing a Store Staff Member.
class StaffMember {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final bool isActive;
  final String? branchId;
  final String branchName;
  final String branchArea;
  final AppUserRole role;

  const StaffMember({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.isActive = true,
    this.branchId,
    this.branchName = 'Store Hub',
    this.branchArea = '',
    this.role = AppUserRole.branchStaff,
  });

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? 'Staff Member',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      branchId: json['branch_id'] as String?,
      branchName: json['branch_name'] as String? ?? 'Store Hub',
      branchArea: json['branch_area'] as String? ?? '',
      role: AppUserRole.fromDb(json['role'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'is_active': isActive,
      'branch_id': branchId,
      'branch_name': branchName,
      'branch_area': branchArea,
      'role': role.toDb(),
    };
  }

  StaffMember copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    bool? isActive,
    String? branchId,
    String? branchName,
    String? branchArea,
    AppUserRole? role,
  }) {
    return StaffMember(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      branchId: branchId ?? this.branchId,
      branchName: branchName ?? this.branchName,
      branchArea: branchArea ?? this.branchArea,
      role: role ?? this.role,
    );
  }
}
