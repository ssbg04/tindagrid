import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';

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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: tr.addProduct,
            icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 28),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Inventory Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  title: tr.totalProducts,
                  value: '${sampleProducts.length}',
                  icon: Icons.inventory_2_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
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

          // Search bar
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              hintText: tr.searchPlaceholder,
              filled: true,
              fillColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Product List
          ...sampleProducts.map((p) {
            final int stock = p['stock'] as int;
            final isLow = stock <= 6;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isLow ? AppColors.alertLight : AppColors.primaryLight,
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: isLow ? AppColors.alert : AppColors.primary,
                  ),
                ),
                title: Text(
                  p['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${p['barcode']} • ${tr.costPrice}: ₱${(p['cost'] as double).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₱${(p['price'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLow ? AppColors.alertLight : Colors.grey.withAlpha(40),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$stock ${tr.inStock}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isLow ? AppColors.alert : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(30),
            radius: 20,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
