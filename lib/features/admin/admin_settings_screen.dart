import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/supabase_config.dart';
import 'admin_shell.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = Supabase.instance.client;
    final currentUser = client.auth.currentUser;

    return AdminScaffold(
      currentSection: AdminMenuSection.settings,
      title: 'Console Settings',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.neutral200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Administration',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primaryContainer,
                      child: Icon(
                        Icons.security_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    title: Text(
                      currentUser?.email ?? 'admin@kisanfresh.com',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Role: Super Administrator • ID: ${currentUser?.id ?? "N/A"}',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.neutral200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Backend & Database Infrastructure',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingRow('Supabase URL', SupabaseConfig.supabaseUrl),
                  const Divider(height: 20),
                  _buildSettingRow(
                    'Database Environment',
                    'AWS Mumbai (ap-south-1) - PostgreSQL 15',
                  ),
                  const Divider(height: 20),
                  _buildSettingRow(
                    'Storage Bucket',
                    'product-images (Public Web-Optimized)',
                  ),
                  const Divider(height: 20),
                  _buildSettingRow(
                    'Role-Based Access Control',
                    'Active (RLS Enforced with Security Definer Functions)',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.neutral200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Multi-Branch Operational Policies',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingRow(
                    'Default Operating Hours',
                    '6:30 AM – 10:00 PM',
                  ),
                  const Divider(height: 20),
                  _buildSettingRow(
                    'Delivery Radius Strategy',
                    'Branch Neighborhood Radius Match',
                  ),
                  const Divider(height: 20),
                  _buildSettingRow(
                    'Reorder Warning Threshold',
                    '5 Units (Configurable per SKU)',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.neutral700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.neutral900,
          ),
        ),
      ],
    );
  }
}
