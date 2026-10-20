import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:vegora_core/vegora_core.dart';
import 'package:vegora_models/vegora_models.dart';
import 'package:vegora_repositories/vegora_repositories.dart';
import 'package:vegora_ui/vegora_ui.dart';

import 'admin_shell.dart';
import 'widgets/admin_status_badge.dart';
import 'widgets/admin_table_container.dart';

class AdminVegetablesScreen extends ConsumerStatefulWidget {
  const AdminVegetablesScreen({super.key});

  @override
  ConsumerState<AdminVegetablesScreen> createState() =>
      _AdminVegetablesScreenState();
}

class _AdminVegetablesScreenState extends ConsumerState<AdminVegetablesScreen> {
  bool _isLoading = true;
  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  List<Branch> _branches = [];

  String _searchQuery = '';
  String? _selectedCategory; // null = all
  String _statusFilter = 'ALL'; // 'ALL', 'ACTIVE', 'INACTIVE'
  int _currentPage = 1;
  int _rowsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final catalogRepo = ref.read(catalogRepositoryProvider);
      final branchRepo = ref.read(branchRepositoryProvider);

      if (catalogRepo is SupabaseCatalogRepository) {
        final prods = await catalogRepo.getAdminProducts();
        final cats = await catalogRepo.getAllCategories(includeInactive: true);
        final brs = await (branchRepo is SupabaseBranchRepository
            ? branchRepo.getAllBranches(includeInactive: true)
            : branchRepo.getBranches());

        if (mounted) {
          setState(() {
            _products = prods;
            _categories = cats;
            _branches = brs;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load vegetables: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Product> get _filteredProducts {
    return _products.where((p) {
      if (_statusFilter == 'ACTIVE' && !p.isActive) return false;
      if (_statusFilter == 'INACTIVE' && p.isActive) return false;

      if (_selectedCategory != null &&
          _selectedCategory != 'all' &&
          p.categoryId != _selectedCategory) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = p.name.toLowerCase().contains(q);
        final matchLocal = p.localName.toLowerCase().contains(q);
        final matchSku = p.sku.toLowerCase().contains(q);
        return matchName || matchLocal || matchSku;
      }
      return true;
    }).toList();
  }

  // --- ADD / EDIT VEGETABLE FORM MODAL ---
  void _showAddEditVegetableModal([Product? existingProduct]) {
    final isEditing = existingProduct != null;
    final formKey = GlobalKey<FormState>();

    final nameCtrl = TextEditingController(text: existingProduct?.name ?? '');
    final nameTaCtrl = TextEditingController(
      text: existingProduct?.nameTa ?? '',
    );
    final localNameCtrl = TextEditingController(
      text: existingProduct?.localName ?? '',
    );
    final skuCtrl = TextEditingController(text: existingProduct?.sku ?? '');
    final descCtrl = TextEditingController(
      text: existingProduct?.description ?? '',
    );
    final descTaCtrl = TextEditingController(
      text: existingProduct?.descriptionTa ?? '',
    );
    final tipsCtrl = TextEditingController(
      text: existingProduct?.storageTips ?? '',
    );
    final originCtrl = TextEditingController(
      text: existingProduct?.origin ?? 'Local Farm Partner',
    );
    final basePriceCtrl = TextEditingController(
      text: existingProduct != null
          ? (existingProduct.basePricePaise / 100).toStringAsFixed(0)
          : '40',
    );
    final origPriceCtrl = TextEditingController(
      text: existingProduct?.originalPricePaise != null
          ? (existingProduct!.originalPricePaise! / 100).toStringAsFixed(0)
          : '',
    );

    String selectedCategory =
        existingProduct?.categoryId ??
        (_categories.isNotEmpty ? _categories.first.id : 'everyday_veggies');

    String selectedUnitType = existingProduct?.unitType ?? 'weight';

    const unitOptions = [
      '1 kg',
      '500 g',
      '250 g',
      '1 pc',
      '1 bunch',
      '1 box',
      'piece',
      'bunch',
    ];
    String selectedUnit = existingProduct?.unit ?? '1 kg';
    if (!unitOptions.contains(selectedUnit)) {
      selectedUnit = '1 kg';
    }

    bool isOrganic = existingProduct?.isOrganic ?? false;
    bool isSeasonal = existingProduct?.isSeasonal ?? false;
    bool isBestSeller = existingProduct?.isBestSeller ?? false;
    bool isFeatured = existingProduct?.isFeatured ?? false;
    bool isActive = existingProduct?.isActive ?? true;

    // Image state
    Uint8List? pickedImageBytes;
    String? pickedImageName;
    String? uploadedImageUrl = existingProduct?.imageUrl;

    // Multi-branch allocation
    bool applyToAllBranches = true;
    final branchSelections = <String, bool>{};
    final branchPrices = <String, TextEditingController>{};
    final branchStocks = <String, TextEditingController>{};

    for (final b in _branches.where((b) => b.isActive)) {
      branchSelections[b.id] = true;
      final existingInv = existingProduct?.branchInventory[b.id];
      branchPrices[b.id] = TextEditingController(
        text: existingInv?.pricePaise != null
            ? (existingInv!.pricePaise! / 100).toStringAsFixed(0)
            : basePriceCtrl.text,
      );
      final rawStock = existingInv?.stockQuantity ?? 25;
      final displayStock =
          (existingProduct != null &&
              existingProduct.isWeightBased &&
              rawStock >= 1000)
          ? (rawStock / 1000).toStringAsFixed(rawStock % 1000 == 0 ? 0 : 1)
          : rawStock.toString();
      branchStocks[b.id] = TextEditingController(text: displayStock);
    }

    bool isSaving = false;
    String? modalError;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEditing
                      ? Icons.edit_note_rounded
                      : Icons.add_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isEditing ? 'Edit Vegetable' : 'Add New Vegetable',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 720,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (modalError != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                modalError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Section 1: Basic Information
                    const Text(
                      '1. Vegetable Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Vegetable Name (English) *',
                              hintText: 'e.g. Crisp English Cucumber',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Name is required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: nameTaCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tamil Name (தமிழ் பெயர்) *',
                              hintText: 'எ.கா. வெள்ளரிக்காய், தக்காளி',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Tamil name is required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: localNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Local Name / Hindi',
                              hintText: 'e.g. Kheera',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: skuCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Product SKU / Code *',
                              hintText: 'e.g. SKU-CUCUMBER-01',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'SKU required';
                              }
                              if (v.trim().length < 3) {
                                return 'Min 3 chars';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedUnitType,
                            decoration: const InputDecoration(
                              labelText: 'Unit Type *',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'weight',
                                child: Text('Weight (g / kg)'),
                              ),
                              DropdownMenuItem(
                                value: 'count',
                                child: Text('Count (pc / bunch)'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() {
                                  selectedUnitType = v;
                                  if (v == 'count' &&
                                      selectedUnit.contains('kg')) {
                                    selectedUnit = '1 pc';
                                  } else if (v == 'weight' &&
                                      !selectedUnit.contains('g') &&
                                      !selectedUnit.contains('kg')) {
                                    selectedUnit = '1 kg';
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category *',
                              border: OutlineInputBorder(),
                            ),
                            items: _categories.map((c) {
                              return DropdownMenuItem(
                                value: c.id,
                                child: Text('${c.emoji} ${c.name}'),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => selectedCategory = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit Display *',
                              border: OutlineInputBorder(),
                            ),
                            items: unitOptions.map((u) {
                              return DropdownMenuItem(value: u, child: Text(u));
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() => selectedUnit = v);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: descCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Description (English)',
                              hintText: 'Fresh, crunchy, and directly harvested from partner farms.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: descTaCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Description (தமிழ் விளக்கம்)',
                              hintText: 'புதிய, பண்ணை காய்கறிகள் நேரடியாக உங்கள் இல்லத்திற்கு.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: tipsCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Storage Tips',
                              hintText: 'Refrigerate in a paper towel bag.',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: originCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Farm Origin',
                              hintText: 'e.g. Ooty Organic Farms',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 2: Product Image Upload
                    const Text(
                      '2. Product Image (Supabase Storage)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.neutral100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.neutral200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: pickedImageBytes != null
                                ? Image.memory(
                                    pickedImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : (uploadedImageUrl != null &&
                                      uploadedImageUrl.isNotEmpty)
                                ? Image.network(
                                    uploadedImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.image_not_supported_rounded,
                                    ),
                                  )
                                : const Icon(
                                    Icons.eco_rounded,
                                    size: 32,
                                    color: AppColors.primary,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pickedImageName ??
                                      (uploadedImageUrl != null
                                          ? 'Existing Image Saved'
                                          : 'No image uploaded yet'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Images are stored in "product-images" Supabase bucket.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.neutral600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(
                              Icons.photo_library_rounded,
                              size: 18,
                            ),
                            label: const Text('Pick Image'),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1024,
                                maxHeight: 1024,
                                imageQuality: 85,
                              );
                              if (file != null) {
                                final bytes = await file.readAsBytes();
                                setDialogState(() {
                                  pickedImageBytes = bytes;
                                  pickedImageName = file.name;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Section 3: Pricing & Badges
                    const Text(
                      '3. Base Pricing & Badges',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: basePriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Base Price (₹) *',
                              prefixText: '₹ ',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Price required';
                              }
                              final num = double.tryParse(v.trim());
                              if (num == null || num < 0) {
                                return 'Invalid price';
                              }
                              return null;
                            },
                            onChanged: (val) {
                              // If applying to all, update all branch price controllers
                              if (applyToAllBranches) {
                                for (final ctrl in branchPrices.values) {
                                  ctrl.text = val;
                                }
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: origPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Original Price (₹) [Strikethrough]',
                              prefixText: '₹ ',
                              hintText: 'Optional',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('🌱 100% Organic'),
                          selected: isOrganic,
                          onSelected: (v) =>
                              setDialogState(() => isOrganic = v),
                        ),
                        FilterChip(
                          label: const Text('🌾 Seasonal Harvest'),
                          selected: isSeasonal,
                          onSelected: (v) =>
                              setDialogState(() => isSeasonal = v),
                        ),
                        FilterChip(
                          label: const Text('⭐ Bestseller'),
                          selected: isBestSeller,
                          onSelected: (v) =>
                              setDialogState(() => isBestSeller = v),
                        ),
                        FilterChip(
                          label: const Text('✨ Featured Product'),
                          selected: isFeatured,
                          onSelected: (v) =>
                              setDialogState(() => isFeatured = v),
                        ),
                        FilterChip(
                          label: const Text('✅ Active for Sale'),
                          selected: isActive,
                          onSelected: (v) => setDialogState(() => isActive = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Section 4: Multi-Branch Inventory Configuration (Requirement 4)
                    const Text(
                      '4. Multi-Branch Stock & Price Distribution',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Configure individual selling prices and stock quantities for each branch outlet.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.neutral300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutral100,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(9),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Store Branch',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  'Stock Qty',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 40),
                                const Text(
                                  'Branch Price (₹)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                const Text(
                                  'Available',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          for (final b in _branches.where((b) => b.isActive))
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: branchSelections[b.id] ?? true,
                                    activeColor: AppColors.primary,
                                    onChanged: (v) {
                                      setDialogState(() {
                                        branchSelections[b.id] = v ?? false;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          '${b.area} (${b.code})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.neutral600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    height: 38,
                                    child: TextFormField(
                                      controller: branchStocks[b.id],
                                      keyboardType: TextInputType.number,
                                      enabled: branchSelections[b.id] ?? true,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  SizedBox(
                                    width: 100,
                                    height: 38,
                                    child: TextFormField(
                                      controller: branchPrices[b.id],
                                      keyboardType: TextInputType.number,
                                      enabled: branchSelections[b.id] ?? true,
                                      decoration: const InputDecoration(
                                        prefixText: '₹ ',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
              onPressed: isSaving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
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
                        final catalogRepo = ref.read(catalogRepositoryProvider);
                        if (catalogRepo is! SupabaseCatalogRepository) {
                          throw Exception(
                            'Catalog repository is not configured.',
                          );
                        }

                        // Upload image if newly picked
                        String? finalImageUrl = uploadedImageUrl;
                        if (pickedImageBytes != null &&
                            pickedImageName != null) {
                          final uploadedUrl = await catalogRepo
                              .uploadProductImage(
                                pickedImageBytes!,
                                pickedImageName!,
                              );
                          if (uploadedUrl != null) {
                            finalImageUrl = uploadedUrl;
                          }
                        }

                        final prodId = isEditing
                            ? existingProduct.id
                            : 'veg_${skuCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

                        final basePaise =
                            ((double.tryParse(basePriceCtrl.text.trim()) ?? 0) *
                                    100)
                                .round();
                        final origPaise = origPriceCtrl.text.trim().isNotEmpty
                            ? ((double.tryParse(origPriceCtrl.text.trim()) ??
                                          0) *
                                      100)
                                  .round()
                            : null;

                        final productPayload = Product(
                          id: prodId,
                          sku: skuCtrl.text.trim().toUpperCase(),
                          name: nameCtrl.text.trim(),
                          nameTa: nameTaCtrl.text.trim(),
                          localName: localNameCtrl.text.trim(),
                          categoryId: selectedCategory,
                          unit: selectedUnit,
                          unitType: selectedUnitType,
                          baseUnit: selectedUnitType == 'weight'
                              ? 'g'
                              : 'piece',
                          minOrderQuantity: selectedUnitType == 'weight'
                              ? 100
                              : 1,
                          quantityStep: selectedUnitType == 'weight' ? 100 : 1,
                          allowCustomQuantity: true,
                          description: descCtrl.text.trim(),
                          descriptionTa: descTaCtrl.text.trim(),
                          storageTips: tipsCtrl.text.trim(),
                          origin: originCtrl.text.trim(),
                          imageUrl: finalImageUrl,
                          emoji: isEditing ? existingProduct.emoji : '🥬',
                          isOrganic: isOrganic,
                          isSeasonal: isSeasonal,
                          isBestSeller: isBestSeller,
                          isFeatured: isFeatured,
                          isActive: isActive,
                          basePricePaise: basePaise,
                          originalPricePaise: origPaise,
                        );

                        // Assemble multi-branch inventory map (normalize weight to integer grams)
                        final branchInventoryPayload =
                            <String, BranchProductInventory>{};
                        for (final b in _branches.where((b) => b.isActive)) {
                          final isSelected = branchSelections[b.id] ?? false;
                          if (isSelected) {
                            final stockInput =
                                double.tryParse(
                                  branchStocks[b.id]?.text.trim() ?? '',
                                ) ??
                                25.0;
                            final stockGrams = selectedUnitType == 'weight'
                                ? (stockInput * 1000).round()
                                : stockInput.round();

                            final priceVal = double.tryParse(
                              branchPrices[b.id]?.text.trim() ?? '',
                            );
                            final pricePaise = priceVal != null
                                ? (priceVal * 100).round()
                                : basePaise;

                            branchInventoryPayload[b.id] =
                                BranchProductInventory(
                                  pricePaise: pricePaise,
                                  stockQuantity: stockGrams,
                                  lowStockThreshold:
                                      selectedUnitType == 'weight' ? 5000 : 5,
                                  isAvailable: stockGrams > 0,
                                );
                          }
                        }

                        if (isEditing) {
                          await catalogRepo.updateVegetable(productPayload);
                          // Also persist updated branch inventories
                          for (final entry in branchInventoryPayload.entries) {
                            await catalogRepo
                                .updateBranchInventoryPricingAndStock(
                                  branchId: entry.key,
                                  productId: productPayload.id,
                                  pricePaise:
                                      entry.value.pricePaise ?? basePaise,
                                  stockQuantity: entry.value.stockQuantity,
                                  lowStockThreshold:
                                      entry.value.lowStockThreshold,
                                  isAvailable: entry.value.isAvailable,
                                );
                          }
                        } else {
                          await catalogRepo.createVegetable(
                            product: productPayload,
                            branchInventoryMap: branchInventoryPayload,
                          );
                        }

                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Vegetable "${productPayload.name}" updated successfully!'
                                    : 'Vegetable "${productPayload.name}" added and distributed to branches!',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          _loadData();
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
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      isEditing ? 'Save Changes' : 'Save Vegetable',
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

  // --- MANAGE BRANCH PRICES & STOCK MODAL (Requirement 5) ---
  void _showManageBranchPricesModal(Product product) {
    final priceControllers = <String, TextEditingController>{};
    final stockControllers = <String, TextEditingController>{};
    final availabilityMap = <String, bool>{};

    for (final b in _branches.where((b) => b.isActive)) {
      final inv = product.branchInventory[b.id];
      final currentPrice = inv?.pricePaise ?? product.basePricePaise;
      final currentStock = inv?.stockQuantity ?? 15;
      priceControllers[b.id] = TextEditingController(
        text: (currentPrice / 100).toStringAsFixed(0),
      );
      stockControllers[b.id] = TextEditingController(
        text: currentStock.toString(),
      );
      availabilityMap[b.id] = inv?.isAvailable ?? true;
    }

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
              const Icon(Icons.price_change_rounded, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Manage Prices & Stock: ${product.name}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 650,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Base catalog price: ${CurrencyFormatter.formatPaise(product.basePricePaise)} per ${product.unit}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (modalError != null)
                    Text(
                      modalError!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  for (final b in _branches.where((b) => b.isActive))
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppColors.neutral300),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${b.area} (${b.code})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.neutral600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: priceControllers[b.id],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Price (₹)',
                                  prefixText: '₹ ',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: stockControllers[b.id],
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Stock Qty',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: availabilityMap[b.id] ?? true,
                              activeTrackColor: AppColors.primaryLight,
                              activeThumbColor: AppColors.primary,
                              onChanged: (v) => setDialogState(
                                () => availabilityMap[b.id] = v,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                      setDialogState(() {
                        isSaving = true;
                        modalError = null;
                      });

                      try {
                        final repo = ref.read(catalogRepositoryProvider);
                        if (repo is! SupabaseCatalogRepository) return;

                        final nav = Navigator.of(ctx);
                        final messenger = ScaffoldMessenger.of(context);

                        for (final b in _branches.where((b) => b.isActive)) {
                          final priceVal =
                              double.tryParse(
                                priceControllers[b.id]?.text.trim() ?? '',
                              ) ??
                              0;
                          final stockVal =
                              int.tryParse(
                                stockControllers[b.id]?.text.trim() ?? '',
                              ) ??
                              0;

                          await repo.updateBranchInventoryPricingAndStock(
                            branchId: b.id,
                            productId: product.id,
                            pricePaise: (priceVal * 100).round(),
                            stockQuantity: stockVal,
                            isAvailable: availabilityMap[b.id] ?? true,
                          );
                        }

                        if (mounted) {
                          nav.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Branch prices and stocks updated successfully!',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                          _loadData();
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
                  : const Text(
                      'Save All Branch Prices',
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleProductActive(Product product) async {
    final nextState = !product.isActive;
    try {
      final repo = ref.read(catalogRepositoryProvider);
      if (repo is SupabaseCatalogRepository) {
        await repo.toggleProductActive(product.id, nextState);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nextState
                  ? 'Vegetable "${product.name}" activated.'
                  : 'Vegetable "${product.name}" deactivated.',
            ),
            backgroundColor: nextState
                ? AppColors.primary
                : AppColors.neutral700,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update status: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 960;
    final products = _filteredProducts;

    return AdminScaffold(
      currentSection: AdminMenuSection.vegetables,
      title: 'Manage Vegetables',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: _loadData,
        ),
      ],
      body: Column(
        children: [
          // Filter & Search Action Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search vegetables by name, Hindi name, SKU...',
                      hintStyle: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF0B6B3A),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _searchQuery = v;
                        _currentPage = 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      hint: const Text(
                        'All Categories',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        for (final c in _categories)
                          DropdownMenuItem(
                            value: c.id,
                            child: Text('${c.emoji} ${c.name}'),
                          ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedCategory = v;
                          _currentPage = 1;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem(
                          value: 'ACTIVE',
                          child: Text('Active Only'),
                        ),
                        DropdownMenuItem(
                          value: 'INACTIVE',
                          child: Text('Inactive Only'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _statusFilter = v;
                            _currentPage = 1;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
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
                    'Add Vegetable',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                  onPressed: () => _showAddEditVegetableModal(),
                ),
              ],
            ),
          ),

          // Vegetables List / Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.eco_rounded,
                          size: 64,
                          color: AppColors.neutral400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No vegetables found matching criteria.',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _showAddEditVegetableModal(),
                          child: const Text('Add New Vegetable'),
                        ),
                      ],
                    ),
                  )
                : isDesktop
                ? _buildDesktopTable(products)
                : _buildMobileList(products),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<Product> products) {
    final paginatedProducts = products
        .skip((_currentPage - 1) * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AdminTableContainer(
        currentPage: _currentPage,
        totalItems: products.length,
        rowsPerPage: _rowsPerPage,
        onPageChanged: (page) => setState(() => _currentPage = page),
        onRowsPerPageChanged: (rows) => setState(() {
          _rowsPerPage = rows;
          _currentPage = 1;
        }),
        itemName: 'vegetables',
        columns: const [
          AdminTableColumn(title: 'Vegetable & SKU', flex: 3),
          AdminTableColumn(title: 'Category & Unit', flex: 2),
          AdminTableColumn(title: 'Base Price', flex: 1),
          AdminTableColumn(title: 'Branch Coverage', flex: 2),
          AdminTableColumn(title: 'Status', flex: 1),
          AdminTableColumn(
            title: 'Actions',
            flex: 2,
            alignment: Alignment.centerRight,
          ),
        ],
        rows: paginatedProducts.map((prod) {
          final activeBranchesCount = prod.branchInventory.values
              .where((inv) => inv.isAvailable)
              .length;

          return AdminTableRow(
            cells: [
              // 0: Vegetable & SKU
              Row(
                children: [
                  ProductImageView(
                    imageUrl: prod.imageUrl,
                    fallbackEmoji: prod.emoji,
                    width: 44,
                    height: 44,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prod.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (prod.nameTa.isNotEmpty) ...[
                              Flexible(
                                child: Text(
                                  prod.nameTa,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0B6B3A),
                                  ),
                                ),
                              ),
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ] else if (prod.localName.isNotEmpty) ...[
                              Flexible(
                                child: Text(
                                  prod.localName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                prod.sku,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF475569),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 1: Category & Unit
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      prod.categoryId.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                        color: Color(0xFF334155),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unit: ${prod.unit}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),

              // 2: Base Price
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CurrencyFormatter.formatPaise(prod.basePricePaise),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0B6B3A),
                    ),
                  ),
                  if (prod.originalPricePaise != null)
                    Text(
                      CurrencyFormatter.formatPaise(prod.originalPricePaise!),
                      style: const TextStyle(
                        fontSize: 11,
                        decoration: TextDecoration.lineThrough,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                ],
              ),

              // 3: Branch Coverage
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: activeBranchesCount > 0
                      ? const Color(0xFFEBF7EE)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: activeBranchesCount > 0
                        ? const Color(0xFFB7E4C7)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  '$activeBranchesCount / ${_branches.length} Branches',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: activeBranchesCount > 0
                        ? const Color(0xFF1E7E34)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),

              // 4: Status
              AdminStatusBadge(
                label: prod.isActive ? 'Active' : 'Inactive',
                isActive: prod.isActive,
              ),

              // 5: Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.currency_rupee_rounded,
                      size: 19,
                      color: Color(0xFF0B6B3A),
                    ),
                    tooltip: 'Manage Branch Stock & Price',
                    onPressed: () => _showManageBranchPricesModal(prod),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 19,
                      color: Color(0xFF475569),
                    ),
                    tooltip: 'Edit Vegetable',
                    onPressed: () => _showAddEditVegetableModal(prod),
                  ),
                  IconButton(
                    icon: Icon(
                      prod.isActive
                          ? Icons.toggle_on_rounded
                          : Icons.toggle_off_rounded,
                      size: 28,
                      color: prod.isActive
                          ? const Color(0xFF0B6B3A)
                          : const Color(0xFF94A3B8),
                    ),
                    tooltip: prod.isActive ? 'Deactivate' : 'Activate',
                    onPressed: () => _toggleProductActive(prod),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList(List<Product> products) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final p = products[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProductImageView(
                      imageUrl: p.imageUrl,
                      fallbackEmoji: p.emoji,
                      width: 50,
                      height: 50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '${p.localName} • SKU: ${p.sku}',
                            style: TextStyle(
                              color: AppColors.neutral600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      CurrencyFormatter.formatPaise(p.basePricePaise),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Unit: ${p.unit} • ${p.categoryId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral700,
                      ),
                    ),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed: () => _showManageBranchPricesModal(p),
                          child: const Text('Branch Prices'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: () => _showAddEditVegetableModal(p),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
