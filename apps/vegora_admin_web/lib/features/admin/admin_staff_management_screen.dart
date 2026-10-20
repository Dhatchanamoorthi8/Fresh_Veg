import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';

import 'admin_shell.dart';

final staffListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final authRepo = ref.watch(authRepositoryProvider);
      return authRepo.getStaffUsers();
    });

class AdminStaffManagementScreen extends ConsumerStatefulWidget {
  const AdminStaffManagementScreen({super.key});

  @override
  ConsumerState<AdminStaffManagementScreen> createState() =>
      _AdminStaffManagementScreenState();
}

class _AdminStaffManagementScreenState
    extends ConsumerState<AdminStaffManagementScreen> {
  final _searchController = TextEditingController();
  String _selectedBranchFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateStaffDialog(List<StoreBranch> branches) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? selectedBranchId = branches.isNotEmpty ? branches.first.id : null;
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.person_add_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Create Branch Staff Account',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This uses the secure server-side RPC to create an authenticated staff account and assign them to a store hub.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (dialogError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          dialogError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Staff Full Name',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v?.trim().isEmpty == true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Staff Email Address',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Initial Password (min 6 chars)',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'At least 6 characters'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Assign Store Branch',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: branches.map((b) {
                        return DropdownMenuItem(
                          value: b.id,
                          child: Text(
                            '${b.name} (${b.area})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedBranchId = val);
                        }
                      },
                      validator: (v) =>
                          v == null ? 'Please select a branch' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      setDialogState(() {
                        isSubmitting = true;
                        dialogError = null;
                      });

                      try {
                        final authRepo = ref.read(authRepositoryProvider);
                        await authRepo.adminCreateStaffOrAgent(
                          email: emailCtrl.text.trim(),
                          password: passwordCtrl.text,
                          fullName: nameCtrl.text.trim(),
                          role: 'branch_staff',
                          branchId: selectedBranchId,
                        );

                        ref.invalidate(staffListProvider);
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Branch staff account successfully created!',
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      } catch (err) {
                        setDialogState(() {
                          isSubmitting = false;
                          dialogError = err
                              .toString()
                              .replaceAll('Exception:', '')
                              .trim();
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Staff'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReassignBranchDialog(
    Map<String, dynamic> staff,
    List<StoreBranch> branches,
  ) {
    String? currentBranchId = staff['branch_id'] as String?;
    String? newBranchId =
        currentBranchId ?? (branches.isNotEmpty ? branches.first.id : null);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Reassign Branch Hub'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reassign ${staff['full_name']} (${staff['email']}) to another physical store branch:',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: newBranchId,
                decoration: const InputDecoration(
                  labelText: 'Select Store Branch',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: branches.map((b) {
                  return DropdownMenuItem(
                    value: b.id,
                    child: Text(
                      '${b.name} (${b.area})',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => newBranchId = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: (isSaving || newBranchId == null)
                  ? null
                  : () async {
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      setDialogState(() => isSaving = true);
                      try {
                        final authRepo = ref.read(authRepositoryProvider);
                        await authRepo.adminReassignStaffBranch(
                          staffUserId: staff['id'] as String,
                          newBranchId: newBranchId!,
                        );
                        ref.invalidate(staffListProvider);
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Staff branch reassigned successfully.',
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      } catch (err) {
                        setDialogState(() => isSaving = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: ${err.toString().replaceAll("Exception:", "").trim()}',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save Reassignment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditStaffDialog(
    Map<String, dynamic> staff,
    List<StoreBranch> branches,
  ) {
    final formKey = GlobalKey<FormState>();
    final emailCtrl = TextEditingController(
      text: staff['email'] as String? ?? '',
    );
    final nameCtrl = TextEditingController(
      text: staff['full_name'] as String? ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: staff['phone'] as String? ?? '',
    );
    String? selectedBranchId =
        staff['branch_id'] as String? ??
        (branches.isNotEmpty ? branches.first.id : null);
    bool isActive = staff['is_active'] as bool? ?? true;
    bool isSubmitting = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.fromLTRB(28, 20, 28, 10),
          actionsPadding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.badge_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Edit Staff Member Profile',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Update credentials, contact info, and store hub',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.neutral600,
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dialogError != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                dialogError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    // 1. EDITABLE EMAIL FIELD
                    TextFormField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Login & Notification Email *',
                        hintText: 'e.g. staff@vegora.com',
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          size: 20,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(),
                        helperText: 'Changing this updates login credentials across Supabase Auth.',
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Email is required';
                        if (!RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        ).hasMatch(val)) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    // 2. FULL NAME FIELD
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Staff Full Name *',
                        hintText: 'Enter complete name',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                        ),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return 'Full name is required';
                        if (val.length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    // 3. PHONE NUMBER FIELD
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number (Optional)',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        prefixText: '+91 ',
                        hintText: '10-digit mobile number',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        final val = v?.trim() ?? '';
                        if (val.isEmpty) return null;
                        final digits = val.replaceAll(RegExp(r'\D'), '');
                        if (digits.length < 10) {
                          return 'Must be at least 10 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),
                    // 4. ASSIGNED BRANCH DROPDOWN
                    DropdownButtonFormField<String>(
                      initialValue: selectedBranchId,
                      decoration: const InputDecoration(
                        labelText: 'Assigned Store Branch *',
                        prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: branches.map((b) {
                        return DropdownMenuItem(
                          value: b.id,
                          child: Text(
                            '${b.name} (${b.area})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedBranchId = val);
                        }
                      },
                      validator: (v) =>
                          v == null ? 'Please select a branch' : null,
                    ),
                    const SizedBox(height: 20),
                    // 5. ACCOUNT STATUS CARD
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryContainer.withValues(alpha: 0.3)
                            : AppColors.errorContainer.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppColors.primary.withValues(alpha: 0.25)
                              : AppColors.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isActive
                                ? Icons.check_circle_rounded
                                : Icons.block_rounded,
                            color: isActive
                                ? AppColors.primary
                                : AppColors.error,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Account Active Status',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isActive
                                      ? 'Staff member has access to POS & order fulfillment'
                                      : 'Account suspended (access is currently revoked)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isActive
                                        ? AppColors.primary
                                        : AppColors.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isActive,
                            activeTrackColor: AppColors.primary,
                            activeThumbColor: Colors.white,
                            onChanged: (val) =>
                                setDialogState(() => isActive = val),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      setDialogState(() {
                        isSubmitting = true;
                        dialogError = null;
                      });

                      try {
                        final authRepo = ref.read(authRepositoryProvider);
                        await authRepo.adminUpdateStaffOrAgent(
                          targetUserId: staff['id'] as String,
                          fullName: nameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          isActive: isActive,
                          branchId: selectedBranchId,
                        );

                        ref.invalidate(staffListProvider);
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Staff member "${nameCtrl.text.trim()}" updated successfully.',
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      } catch (err) {
                        setDialogState(() {
                          isSubmitting = false;
                          dialogError = err
                              .toString()
                              .replaceAll('Exception:', '')
                              .trim();
                        });
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteStaffConfirmation(Map<String, dynamic> staff) {
    bool isDeleting = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: 28,
              ),
              SizedBox(width: 8),
              Text(
                'Delete Staff Member',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to permanently delete this branch staff account? This will remove their branch access and authentication credentials.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.errorContainer,
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staff['full_name'] as String? ?? 'Staff Member',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              staff['email'] as String? ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (staff['branch_name'] != null)
                              Text(
                                'Hub: ${staff['branch_name']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dialogError!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              icon: isDeleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_forever_rounded, size: 18),
              label: const Text('Delete Staff Permanently'),
              onPressed: isDeleting
                  ? null
                  : () async {
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      setDialogState(() {
                        isDeleting = true;
                        dialogError = null;
                      });

                      try {
                        final authRepo = ref.read(authRepositoryProvider);
                        await authRepo.adminDeleteStaffOrAgent(
                          targetUserId: staff['id'] as String,
                        );

                        ref.invalidate(staffListProvider);
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Staff member "${staff['full_name']}" deleted permanently.',
                            ),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      } catch (err) {
                        setDialogState(() {
                          isDeleting = false;
                          dialogError = err
                              .toString()
                              .replaceAll('Exception:', '')
                              .trim();
                        });
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStaffActive(Map<String, dynamic> staff) async {
    final bool currentActive = staff['is_active'] as bool? ?? true;
    final bool nextActive = !currentActive;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.adminToggleUserActive(
        targetUserId: staff['id'] as String,
        shouldBeActive: nextActive,
      );
      ref.invalidate(staffListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${staff['full_name']} account ${nextActive ? "activated" : "deactivated"}.',
            ),
            backgroundColor: nextActive ? AppColors.primary : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    final branchesAsync = ref.watch(branchesListProvider);

    return AdminScaffold(
      currentSection: AdminMenuSection.staff,
      title: 'Store Staff Management',
      actions: [
        branchesAsync.when(
          data: (branches) => IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Create Staff Account',
            onPressed: () => _showCreateStaffDialog(branches),
          ),
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const SizedBox.shrink(),
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => ref.invalidate(staffListProvider),
        ),
      ],
      body: Column(
        children: [
          // Filter & Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search staff by name or email...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                branchesAsync.when(
                  data: (branches) => DropdownButton<String>(
                    value: _selectedBranchFilter,
                    underline: const SizedBox.shrink(),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text(
                          'All Branches',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      ...branches.map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(
                            b.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedBranchFilter = val);
                      }
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (err, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Staff List
          Expanded(
            child: staffAsync.when(
              data: (staffList) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = staffList.where((s) {
                  final name = (s['full_name'] as String? ?? '').toLowerCase();
                  final email = (s['email'] as String? ?? '').toLowerCase();
                  final branchId = s['branch_id'] as String? ?? '';

                  final matchesQuery =
                      query.isEmpty ||
                      name.contains(query) ||
                      email.contains(query);
                  final matchesBranch =
                      _selectedBranchFilter == 'all' ||
                      branchId == _selectedBranchFilter;
                  return matchesQuery && matchesBranch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.people_outline_rounded,
                          size: 54,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No branch staff members found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Use the "+" button above to provision store staff.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        branchesAsync.when(
                          data: (branches) => ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(
                              Icons.person_add_rounded,
                              size: 18,
                            ),
                            label: const Text('Add First Staff Member'),
                            onPressed: () => _showCreateStaffDialog(branches),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (err, stack) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final staff = filtered[index];
                    final isActive = staff['is_active'] as bool? ?? true;
                    final branchName =
                        staff['branch_name'] as String? ?? 'Unassigned';
                    final branchArea = staff['branch_area'] as String? ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isActive
                                  ? AppColors.statusPreparing.withValues(
                                      alpha: 0.2,
                                    )
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.storefront_rounded,
                                color: isActive
                                    ? AppColors.statusPreparing
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        staff['full_name'] as String? ??
                                            'Staff Member',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? AppColors.primaryContainer
                                              : AppColors.errorContainer,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          isActive ? 'Active' : 'Suspended',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isActive
                                                ? AppColors.primaryDark
                                                : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    staff['email'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        branchArea.isNotEmpty
                                            ? '$branchName ($branchArea)'
                                            : branchName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primaryDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Action options
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'edit') {
                                  branchesAsync.whenData((branches) {
                                    _showEditStaffDialog(staff, branches);
                                  });
                                } else if (val == 'toggle_active') {
                                  _toggleStaffActive(staff);
                                } else if (val == 'delete') {
                                  _showDeleteStaffConfirmation(staff);
                                } else if (val == 'reassign') {
                                  branchesAsync.whenData((branches) {
                                    _showReassignBranchDialog(staff, branches);
                                  });
                                } else if (val == 'reset_pw') {
                                  ref
                                      .read(authRepositoryProvider)
                                      .resetPasswordForEmail(
                                        staff['email'] as String,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Password reset email sent to ${staff['email']}',
                                      ),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 18,
                                        color: AppColors.textPrimary,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Edit Staff Profile'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'reassign',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.swap_horiz_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Reassign Branch'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'reset_pw',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.lock_reset_rounded, size: 18),
                                      SizedBox(width: 8),
                                      Text('Send Password Reset'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'toggle_active',
                                  child: Row(
                                    children: [
                                      Icon(
                                        isActive
                                            ? Icons.block_rounded
                                            : Icons
                                                  .check_circle_outline_rounded,
                                        size: 18,
                                        color: isActive
                                            ? AppColors.error
                                            : AppColors.primary,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        isActive
                                            ? 'Deactivate Staff'
                                            : 'Activate Staff',
                                        style: TextStyle(
                                          color: isActive
                                              ? AppColors.error
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppColors.error,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Delete Staff Member',
                                        style: TextStyle(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error loading staff: $err',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: branchesAsync.when(
        data: (branches) => FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Staff'),
          onPressed: () => _showCreateStaffDialog(branches),
        ),
        loading: () => const SizedBox.shrink(),
        error: (err, stack) => const SizedBox.shrink(),
      ),
    );
  }
}
