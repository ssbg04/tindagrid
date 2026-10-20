import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../core/theme/app_theme.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    // Sample inventory items
    final sampleProducts = [
      {'name': 'Coca-Cola Mismo 300ml', 'barcode': '4800016644021', 'stock': 24, 'cost': 15.0, 'price': 20.0},
      {'name': 'SkyFlakes Crackers Single', 'barcode': '4800016644038', 'stock': 48, 'cost': 6.5, 'price': 9.0},
      {'name': 'Kopiko Blanca 30g Sachet', 'barcode': '8996001414002', 'stock': 32, 'cost': 10.5, 'price': 14.0},
      {'name': 'Bear Brand Fortified 33g', 'barcode': '4800361280011', 'stock': 4, 'cost': 12.0, 'price': 16.0},
      {'name': 'Lucky Me! Pancit Canton Kalamansi', 'barcode': '4800361300023', 'stock': 18, 'cost': 13.0, 'price': 17.0},
      {'name': 'Safeguard Pure White 60g', 'barcode': '4902430730030', 'stock': 6, 'cost': 22.0, 'price': 28.0},
      {'name': 'Silver Swan Sukang Puti 200ml', 'barcode': '4800123000045', 'stock': 12, 'cost': 9.0, 'price': 12.0},
      {'name': 'Datu Puti Toyo 200ml', 'barcode': '4800123000052', 'stock': 15, 'cost': 10.0, 'price': 13.0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr.inventoryTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: tr.addProduct,
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr.isTaglish ? 'Bubuksan ang Barcode Scanner para mag-add...' : 'Opening Barcode Scanner to add item...'),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Soft Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildSoftSummaryCard(
                      context,
                      title: tr.totalProducts,
                      value: '${sampleProducts.length}',
                      icon: Icons.inventory_2_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSoftSummaryCard(
                      context,
                      title: tr.lowStockWarning,
                      value: '2',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.alert,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Soft Search bar
              TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  hintText: tr.searchPlaceholder,
                ),
              ),
              const SizedBox(height: 16),

              // Product List (Soft UI Cards)
              ...sampleProducts.map((p) {
                final int stock = p['stock'] as int;
                final isLow = stock <= 6;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: SoftDecorations.card(context, radius: 14),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: CircleAvatar(
                        radius: 19,
                        backgroundColor: isLow ? AppColors.alertLight : AppColors.primaryLight,
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: isLow ? AppColors.alert : AppColors.primary,
                          size: 19,
                        ),
                      ),
                      title: Text(
                        p['name'] as String,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      subtitle: Text(
                        '${p['barcode']} • ${tr.costPrice}: ₱${(p['cost'] as double).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱${(p['price'] as double).toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isLow
                                  ? AppColors.alertLight
                                  : (isLight ? AppColors.surfaceMutedLight : Colors.white10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$stock ${tr.inStock}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isLow ? AppColors.alert : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSoftSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SoftDecorations.card(context, radius: 14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(25),
            radius: 20,
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
