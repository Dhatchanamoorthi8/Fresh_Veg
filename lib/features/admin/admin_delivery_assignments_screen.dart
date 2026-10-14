import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../shared/models/order.dart';
import '../../shared/models/order_status.dart';
import '../../shared/providers/app_providers.dart';
import '../../shared/repositories/supabase_order_repository.dart';
import 'admin_shell.dart';

class AdminDeliveryAssignmentsScreen extends ConsumerStatefulWidget {
  const AdminDeliveryAssignmentsScreen({super.key});

  @override
  ConsumerState<AdminDeliveryAssignmentsScreen> createState() =>
      _AdminDeliveryAssignmentsScreenState();
}

class _AdminDeliveryAssignmentsScreenState
    extends ConsumerState<AdminDeliveryAssignmentsScreen> {
  bool _isLoading = true;
  List<Order> _unassignedOrders = [];
  List<Map<String, dynamic>> _deliveryAgents = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final orderRepo = ref.read(orderRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);

      if (orderRepo is SupabaseOrderRepository) {
        final orders = await orderRepo.getAllOrders();
        // Orders ready for dispatch: ACCEPTED, PREPARING, READY_FOR_PICKUP, or NEW without delivery staff assigned
        final pending = orders
            .where(
              (o) =>
                  o.assignedDeliveryPartner == null &&
                  (o.status == OrderStatus.accepted ||
                      o.status == OrderStatus.preparing ||
                      o.status == OrderStatus.readyForPickup ||
                      o.status == OrderStatus.newOrder),
            )
            .toList();

        final agents = await authRepo.getDeliveryAgents();

        if (mounted) {
          setState(() {
            _unassignedOrders = pending;
            _deliveryAgents = agents;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load assignments: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAssignModal(Order order) {
    String? selectedAgentId = _deliveryAgents.isNotEmpty
        ? _deliveryAgents.first['id'] as String?
        : null;

    if (selectedAgentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No active delivery agents found in system. Please provision delivery staff first.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Assign Order #${order.orderNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Address: ${order.deliveryAddressText}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.neutral700,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedAgentId,
                decoration: const InputDecoration(
                  labelText: 'Select Delivery Agent',
                  border: OutlineInputBorder(),
                ),
                items: _deliveryAgents.map((agent) {
                  return DropdownMenuItem(
                    value: agent['id'] as String,
                    child: Text(
                      '${agent['full_name']} (${agent['phone'] ?? "No Phone"})',
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedAgentId = v);
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
              ),
              onPressed: isSaving
                  ? null
                  : () async {
                      if (selectedAgentId == null) return;
                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        final repo = ref.read(orderRepositoryProvider);
                        if (repo is SupabaseOrderRepository) {
                          await repo.assignDeliveryStaff(
                            order.id,
                            selectedAgentId!,
                          );
                          await repo.updateOrderStatus(
                            order.id,
                            OrderStatus.outForDelivery,
                          );

                          if (mounted) {
                            nav.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Delivery partner assigned! Order marked Out for Delivery.',
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                            _loadData();
                          }
                        }
                      } catch (e) {
                        setDialogState(() => isSaving = false);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Assignment error: $e'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Confirm Assignment',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      currentSection: AdminMenuSection.deliveryAssignments,
      title: 'Delivery Assignments Dispatch',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadData,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _unassignedOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'All active orders are currently assigned to delivery partners.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: _unassignedOrders.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final o = _unassignedOrders[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppColors.neutral200),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(
                        Icons.delivery_dining_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      '#${o.orderNumber} • ${o.customerName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${o.deliveryAddressText} • Slot: ${o.deliverySlot}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyFormatter.formatPaise(o.totalPaise),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(
                            Icons.assignment_ind_rounded,
                            size: 16,
                          ),
                          label: const Text('Assign Partner'),
                          onPressed: () => _showAssignModal(o),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
