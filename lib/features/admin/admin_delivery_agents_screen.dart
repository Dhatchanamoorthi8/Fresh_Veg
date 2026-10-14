import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/providers/app_providers.dart';
import 'admin_shell.dart';

final deliveryAgentsListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final authRepo = ref.watch(authRepositoryProvider);
      return authRepo.getDeliveryAgents();
    });

class AdminDeliveryAgentsScreen extends ConsumerStatefulWidget {
  const AdminDeliveryAgentsScreen({super.key});

  @override
  ConsumerState<AdminDeliveryAgentsScreen> createState() =>
      _AdminDeliveryAgentsScreenState();
}

class _AdminDeliveryAgentsScreenState
    extends ConsumerState<AdminDeliveryAgentsScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateAgentDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
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
              Icon(
                Icons.delivery_dining_rounded,
                color: AppColors.statusDelivered,
              ),
              SizedBox(width: 8),
              Text(
                'Create Delivery Partner Account',
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
                      'Provision a delivery partner account securely with role "delivery_staff" in Supabase Auth.',
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
                        labelText: 'Partner Full Name',
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
                        labelText: 'Partner Email Address',
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
                backgroundColor: AppColors.statusDelivered,
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
                          role: 'delivery_staff',
                        );

                        ref.invalidate(deliveryAgentsListProvider);
                        nav.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Delivery partner account successfully created!',
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
                  : const Text('Create Partner'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAgentActive(Map<String, dynamic> agent) async {
    final bool currentActive = agent['is_active'] as bool? ?? true;
    final bool nextActive = !currentActive;

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.adminToggleUserActive(
        targetUserId: agent['id'] as String,
        shouldBeActive: nextActive,
      );
      ref.invalidate(deliveryAgentsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${agent['full_name']} account ${nextActive ? "activated" : "deactivated"}.',
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
    final agentsAsync = ref.watch(deliveryAgentsListProvider);

    return AdminScaffold(
      currentSection: AdminMenuSection.deliveryAgents,
      title: 'Delivery Partner Fleet',
      actions: [
        IconButton(
          icon: const Icon(Icons.person_add_rounded),
          tooltip: 'Create Partner Account',
          onPressed: _showCreateAgentDialog,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => ref.invalidate(deliveryAgentsListProvider),
        ),
      ],
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search partners by name or email...',
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
                DropdownButton<String>(
                  value: _statusFilter,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                      value: 'all',
                      child: Text('All Status', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'active',
                      child: Text(
                        'Active Only',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'inactive',
                      child: Text('Suspended', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _statusFilter = val);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: agentsAsync.when(
              data: (agentList) {
                final query = _searchController.text.trim().toLowerCase();
                final filtered = agentList.where((a) {
                  final name = (a['full_name'] as String? ?? '').toLowerCase();
                  final email = (a['email'] as String? ?? '').toLowerCase();
                  final isActive = a['is_active'] as bool? ?? true;

                  final matchesQuery =
                      query.isEmpty ||
                      name.contains(query) ||
                      email.contains(query);
                  final matchesStatus =
                      _statusFilter == 'all' ||
                      (_statusFilter == 'active' && isActive) ||
                      (_statusFilter == 'inactive' && !isActive);
                  return matchesQuery && matchesStatus;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.delivery_dining_rounded,
                          size: 54,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No delivery partners found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add delivery partners to assign store orders.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.statusDelivered,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.person_add_rounded, size: 18),
                          label: const Text('Add Delivery Partner'),
                          onPressed: _showCreateAgentDialog,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final agent = filtered[index];
                    final isActive = agent['is_active'] as bool? ?? true;

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
                                  ? AppColors.statusDelivered.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.two_wheeler_rounded,
                                color: isActive
                                    ? AppColors.statusDelivered
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
                                        agent['full_name'] as String? ??
                                            'Delivery Partner',
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
                                    agent['email'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (agent['phone'] != null &&
                                      (agent['phone'] as String)
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      '+91 ${agent['phone']}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.neutral700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (val) {
                                if (val == 'toggle_active') {
                                  _toggleAgentActive(agent);
                                } else if (val == 'reset_pw') {
                                  ref
                                      .read(authRepositoryProvider)
                                      .resetPasswordForEmail(
                                        agent['email'] as String,
                                      );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Password reset email sent to ${agent['email']}',
                                      ),
                                    ),
                                  );
                                }
                              },
                              itemBuilder: (ctx) => [
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
                                      const SizedBox(width: 8),
                                      Text(
                                        isActive
                                            ? 'Deactivate Partner'
                                            : 'Activate Partner',
                                        style: TextStyle(
                                          color: isActive
                                              ? AppColors.error
                                              : AppColors.primary,
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
                    'Error loading delivery fleet: $err',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.statusDelivered,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Partner'),
        onPressed: _showCreateAgentDialog,
      ),
    );
  }
}
