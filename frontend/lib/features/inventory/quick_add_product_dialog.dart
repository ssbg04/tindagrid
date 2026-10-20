import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/catalog/catalog_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/utils/feedback_helper.dart';

class QuickAddProductDialog extends ConsumerStatefulWidget {
  final String barcode;
  final CatalogBarcodeResult? initialMatch;
  final bool isTaglish;
  final void Function(Product product) onProductSaved;

  const QuickAddProductDialog({
    super.key,
    required this.barcode,
    this.initialMatch,
    this.isTaglish = true,
    required this.onProductSaved,
  });

  @override
  ConsumerState<QuickAddProductDialog> createState() => _QuickAddProductDialogState();
}

class _QuickAddProductDialogState extends ConsumerState<QuickAddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _sellingPriceController;
  late final TextEditingController _stockController;

  bool _isTingi = false;
  bool _isSaving = false;

  double get _costPrice => double.tryParse(_costPriceController.text.trim()) ?? 0.0;
  double get _sellingPrice => double.tryParse(_sellingPriceController.text.trim()) ?? 0.0;
  double get _estimatedProfit => _sellingPrice - _costPrice;
  double get _profitMargin => _sellingPrice > 0 ? (_estimatedProfit / _sellingPrice) * 100 : 0.0;

  @override
  void initState() {
    super.initState();
    final match = widget.initialMatch;
    final defaultPrice = match?.defaultPrice ?? 0.0;
    // Estimate standard retail wholesale cost (~80% of SRP)
    final estimatedCost = defaultPrice > 0 ? (defaultPrice * 0.8).roundToDouble() : 0.0;

    _nameController = TextEditingController(text: match?.name ?? '');
    _categoryController = TextEditingController(text: match?.category ?? 'General');
    _costPriceController = TextEditingController(
      text: estimatedCost > 0 ? estimatedCost.toStringAsFixed(2) : '',
    );
    _sellingPriceController = TextEditingController(
      text: defaultPrice > 0 ? defaultPrice.toStringAsFixed(2) : '',
    );
    _stockController = TextEditingController(text: '12');

    _costPriceController.addListener(() => setState(() {}));
    _sellingPriceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);
    final productId = const Uuid().v4();
    final stock = double.tryParse(_stockController.text.trim()) ?? 10.0;

    final companion = ProductsCompanion(
      id: drift.Value(productId),
      barcode: drift.Value(widget.barcode.trim()),
      name: drift.Value(_nameController.text.trim()),
      category: drift.Value(_categoryController.text.trim().isEmpty ? 'General' : _categoryController.text.trim()),
      costPrice: drift.Value(_costPrice),
      sellingPrice: drift.Value(_sellingPrice),
      currentStock: drift.Value(stock),
      isTingi: drift.Value(_isTingi),
      createdAt: drift.Value(DateTime.now()),
      updatedAt: drift.Value(DateTime.now()),
      isDeleted: const drift.Value(false),
    );

    try {
      await db.saveProduct(companion);
      final saved = await db.getProductByBarcode(widget.barcode.trim());

      // Crowdsource contribution in background if newly added
      final catalogClient = CatalogClient();
      catalogClient.contributeBarcode(
        barcode: widget.barcode.trim(),
        name: _nameController.text.trim(),
        category: _categoryController.text.trim(),
        defaultPrice: _sellingPrice,
      );

      await FeedbackHelper.triggerSuccessFeedback();

      if (mounted) {
        Navigator.of(context).pop();
        if (saved != null) {
          widget.onProductSaved(saved);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving product: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.isTaglish;
    final isAutoFilled = widget.initialMatch?.found == true;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 12,
      backgroundColor: Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr ? 'Mabilisang Dagdag-Paninda' : 'Quick-Add Product',
                              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              tr ? 'Pre-filled mula sa na-scan na barcode' : 'Auto-filled from scanned barcode',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Scanned Barcode Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code_rounded, size: 20, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Barcode: ',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
                      ),
                      Expanded(
                        child: Text(
                          widget.barcode,
                          style: GoogleFonts.sourceCodePro(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Auto-fill Celebratory Banner
                if (isAutoFilled)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tr
                                ? '✨ Nahanap sa Philippine Master Catalog! Na-auto-fill ang pangalan at SRP.'
                                : '✨ Found in Philippine Master Catalog! Name and SRP auto-filled.',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.brown.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Product Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: tr ? 'Pangalan ng Paninda *' : 'Product Name *',
                    hintText: tr ? 'hal. Lucky Me Pancit Canton Original' : 'e.g. Lucky Me Pancit Canton',
                    prefixIcon: const Icon(Icons.label_outline_rounded, size: 20),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? (tr ? 'Kailangan ang pangalan ng paninda' : 'Product name is required')
                      : null,
                ),
                const SizedBox(height: 12),

                // Category Field
                TextFormField(
                  controller: _categoryController,
                  decoration: InputDecoration(
                    labelText: tr ? 'Kategorya' : 'Category',
                    hintText: tr ? 'hal. Noodles, Inumin, Sabon' : 'e.g. Noodles, Beverage, Soap',
                    prefixIcon: const Icon(Icons.category_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 14),

                // Cost Price and Selling Price Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: tr ? 'Puhunan (₱)' : 'Cost Price (₱)',
                          prefixText: '₱ ',
                          hintText: '0.00',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (double.tryParse(v.trim()) == null) return tr ? 'Numero lang' : 'Number only';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: tr ? 'Presyo ng Tinda (₱) *' : 'Selling Price (₱) *',
                          prefixText: '₱ ',
                          hintText: '0.00',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return tr ? 'Kailangan' : 'Required';
                          }
                          final p = double.tryParse(v.trim());
                          if (p == null || p <= 0) return tr ? 'Invalid' : 'Invalid';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Real-time Profit / Tubo Pill
                if (_sellingPrice > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _estimatedProfit >= 0
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _estimatedProfit >= 0
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr ? 'Tinatayang Tubo (Kita):' : 'Estimated Profit:',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '₱${_estimatedProfit.toStringAsFixed(2)} (${_profitMargin.toStringAsFixed(1)}%)',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _estimatedProfit >= 0 ? AppColors.primary : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Initial Stock & Tingi Switch Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: tr ? 'Panimulang Stock (pcs)' : 'Initial Stock (pcs)',
                          hintText: '12',
                          prefixIcon: const Icon(Icons.inventory_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Text(
                          tr ? 'Tingi?' : 'Tingi?',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Switch(
                          value: _isTingi,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) => setState(() => _isTingi = val),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Save & Add Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 20),
                  label: Text(
                    _isSaving
                        ? (tr ? 'I-nirehistro...' : 'Saving...')
                        : (tr ? 'I-save at Idagdag sa Kart' : 'Save & Add to Cart'),
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
