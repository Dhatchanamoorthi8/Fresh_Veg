import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';

import 'admin_shell.dart';

class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  bool _isLoading = true;
  List<ProductCategory> _categories = [];
  Map<String, int> _productCounts = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(catalogRepositoryProvider);
      if (repo is SupabaseCatalogRepository) {
        final cats = await repo.getAllCategories(includeInactive: true);
        final prods = await repo.getAdminProducts();

        final counts = <String, int>{};
        for (final p in prods) {
          counts[p.categoryId] = (counts[p.categoryId] ?? 0) + 1;
        }

        if (mounted) {
          setState(() {
            _categories = cats;
            _productCounts = counts;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load categories: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEditCategoryModal([ProductCategory? existingCategory]) {
    final isEditing = existingCategory != null;
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(text: existingCategory?.name ?? '');
    final nameTaCtrl = TextEditingController(
      text: existingCategory?.nameTa ?? '',
    );
    final subtitleCtrl = TextEditingController(
      text: existingCategory?.subtitle ?? '',
    );
    final emojiCtrl = TextEditingController(
      text: existingCategory?.emoji ?? '🥗',
    );
    final sortCtrl = TextEditingController(
      text: (existingCategory?.sortOrder ?? (_categories.length + 1))
          .toString(),
    );

    bool isActive = existingCategory?.isActive ?? true;
    bool isSaving = false;
    String? modalError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.category_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                isEditing ? 'Edit Category' : 'Add New Category',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (modalError != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        modalError!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      SizedBox(
                        width: 70,
                        child: TextFormField(
                          controller: emojiCtrl,
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            labelText: 'Emoji',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Category Name (English) *',
                            hintText: 'e.g. Exotic Greens',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Name required'
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameTaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Category Name (Tamil / தமிழ்)',
                      hintText: 'e.g. அன்றாட காய்கறிகள்',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: subtitleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Local Subtitle / Hindi',
                      hintText: 'e.g. Videshi Sabzi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: sortCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Display Order',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SwitchListTile(
                          dense: true,
                          title: const Text(
                            'Active',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          value: isActive,
                          activeTrackColor: AppColors.primaryLight,
                          activeThumbColor: AppColors.primary,
                          onChanged: (v) => setDialogState(() => isActive = v),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() {
                        isSaving = true;
                        modalError = null;
                      });

                      final nav = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);

                      try {
                        final repo = ref.read(catalogRepositoryProvider);
                        if (repo is! SupabaseCatalogRepository) return;

                        final catId = isEditing
                            ? existingCategory.id
                            : nameCtrl.text.trim().toLowerCase().replaceAll(
                                RegExp(r'[^a-z0-9]'),
                                '_',
                              );

                        final catPayload = ProductCategory(
                          id: catId,
                          name: nameCtrl.text.trim(),
                          nameTa: nameTaCtrl.text.trim(),
                          subtitle: subtitleCtrl.text.trim(),
                          icon: Icons.category_rounded,
                          emoji: emojiCtrl.text.trim(),
                          sortOrder: int.tryParse(sortCtrl.text.trim()) ?? 0,
                          isActive: isActive,
                        );

                        if (isEditing) {
                          await repo.updateCategory(catPayload);
                        } else {
                          await repo.createCategory(catPayload);
                        }

                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Category "${catPayload.name}" updated!'
                                    : 'Category "${catPayload.name}" created!',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          _loadCategories();
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                          modalError = e
                              .toString()
                              .replaceAll('Exception:', '')
                              .trim();
                        });
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
                  : Text(
                      isEditing ? 'Save Changes' : 'Create Category',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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
      currentSection: AdminMenuSection.categories,
      title: 'Categories Management',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _loadCategories,
        ),
      ],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.neutral200)),
            ),
            child: Row(
              children: [
                const Text(
                  'Vegetable Product Categories',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B6B3A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text(
                    'Add Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  onPressed: () => _showAddEditCategoryModal(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _categories.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = _categories[index];
                      final count = _productCounts[c.id] ?? 0;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.neutral200),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryContainer,
                            child: Text(
                              c.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (c.nameTa.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    c.nameTa,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${c.subtitle.isNotEmpty ? "${c.subtitle} • " : ""}ID: ${c.id} • Order: ${c.sortOrder}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$count Vegetables',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_rounded,
                                  color: AppColors.neutral700,
                                ),
                                onPressed: () => _showAddEditCategoryModal(c),
                              ),
                              IconButton(
                                icon: Icon(
                                  c.isActive
                                      ? Icons.toggle_on_rounded
                                      : Icons.toggle_off_rounded,
                                  size: 28,
                                  color: c.isActive
                                      ? AppColors.primary
                                      : AppColors.neutral400,
                                ),
                                onPressed: () async {
                                  final repo = ref.read(
                                    catalogRepositoryProvider,
                                  );
                                  if (repo is SupabaseCatalogRepository) {
                                    await repo.toggleCategoryActive(
                                      c.id,
                                      !c.isActive,
                                    );
                                    _loadCategories();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
