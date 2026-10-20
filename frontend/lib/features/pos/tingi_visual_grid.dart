import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/feedback_helper.dart';

class TingiItemData {
  final String id;
  final String emoji;
  final String name;
  final double price;

  const TingiItemData({
    required this.id,
    required this.emoji,
    required this.name,
    required this.price,
  });
}

class TingiVisualGrid extends ConsumerStatefulWidget {
  final void Function(String name, double price, int quantity) onAddTingi;
  final bool isTaglish;

  const TingiVisualGrid({
    super.key,
    required this.onAddTingi,
    this.isTaglish = true,
  });

  @override
  ConsumerState<TingiVisualGrid> createState() => _TingiVisualGridState();
}

class _TingiVisualGridState extends ConsumerState<TingiVisualGrid> {
  int _selectedMultiplier = 1;

  static const List<TingiItemData> _defaultTingiItems = [
    TingiItemData(id: 'tingi-egg', emoji: '🥚', name: 'Itlog (Fresh)', price: 10.0),
    TingiItemData(id: 'tingi-ice', emoji: '🧊', name: 'Yelo (Tube Ice)', price: 5.0),
    TingiItemData(id: 'tingi-coffee', emoji: '☕', name: 'Kopiko 78', price: 14.0),
    TingiItemData(id: 'tingi-candy', emoji: '🍬', name: 'Kendi (Maxx/XO)', price: 2.0),
    TingiItemData(id: 'tingi-noodles', emoji: '🍜', name: 'Pancit Canton', price: 18.0),
    TingiItemData(id: 'tingi-cigarette', emoji: '🚬', name: 'Yosi (1 stick)', price: 10.0),
    TingiItemData(id: 'tingi-sugar', emoji: '🍚', name: 'Asukal 1/4kg', price: 22.0),
    TingiItemData(id: 'tingi-shampoo', emoji: '🧴', name: 'Palmolive Sachet', price: 7.0),
    TingiItemData(id: 'tingi-soap', emoji: '🧼', name: 'Safeguard Sachet', price: 8.0),
  ];

  String _detectEmoji(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('itlog') || lower.contains('egg')) return '🥚';
    if (lower.contains('yelo') || lower.contains('ice')) return '🧊';
    if (lower.contains('kape') || lower.contains('coffee') || lower.contains('kopiko')) return '☕';
    if (lower.contains('kendi') || lower.contains('candy')) return '🍬';
    if (lower.contains('pancit') || lower.contains('noodle') || lower.contains('mami')) return '🍜';
    if (lower.contains('yosi') || lower.contains('sigarilyo') || lower.contains('marlboro')) return '🚬';
    if (lower.contains('asukal') || lower.contains('sugar')) return '🍚';
    if (lower.contains('shampoo') || lower.contains('conditioner')) return '🧴';
    if (lower.contains('sabon') || lower.contains('soap')) return '🧼';
    if (lower.contains('tinapay') || lower.contains('bread') || lower.contains('pandesal')) return '🍞';
    if (lower.contains('tubig') || lower.contains('water') || lower.contains('juice')) return '🥤';
    if (lower.contains('biskwit') || lower.contains('biscuit')) return '🍪';
    return '📦';
  }

  void _showAddCustomTingiDialog() {
    final tr = widget.isTaglish;
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedEmoji = '🥚';

    final emojis = ['🥚', '🧊', '☕', '🍬', '🍜', '🚬', '🍚', '🧴', '🧼', '🍞', '🥤', '🍪', '🧃', '📦'];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    tr ? 'Magdagdag ng Tingi Button' : 'Add Custom Tingi Item',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    tr ? 'Pumili ng Icon / Emoji:' : 'Select Emoji / Icon:',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emojis.map((e) {
                      final isSelected = e == selectedEmoji;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedEmoji = e),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 22)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: tr ? 'Pangalan ng Paninda *' : 'Item Name *',
                      hintText: tr ? 'hal. Pandesal / Fishball' : 'e.g. Bread / Candy',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: tr ? 'Presyo ng Benta (₱) *' : 'Selling Price (₱) *',
                      prefixText: '₱ ',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(tr ? 'Kanselahin' : 'Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                    if (name.isNotEmpty && price > 0) {
                      final db = ref.read(databaseProvider);
                      await db.saveProduct(
                        ProductsCompanion(
                          id: drift.Value(const Uuid().v4()),
                          name: drift.Value(name),
                          category: const drift.Value('Tingi'),
                          costPrice: drift.Value(price * 0.8),
                          sellingPrice: drift.Value(price),
                          currentStock: const drift.Value(100.0),
                          isTingi: const drift.Value(true),
                          createdAt: drift.Value(DateTime.now()),
                          updatedAt: drift.Value(DateTime.now()),
                          isDeleted: const drift.Value(false),
                        ),
                      );
                      await FeedbackHelper.triggerSuccessFeedback();
                      if (context.mounted) {
                        Navigator.of(dialogCtx).pop();
                      }
                    }
                  },
                  child: Text(tr ? 'I-save' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = widget.isTaglish;
    final db = ref.watch(databaseProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header with Multipliers (+1, +5, +10)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                tr ? 'MABILISANG TINGI (Walang Barcode — Pindutin Agad):' : 'QUICK TINGI (No Barcode — 1-Tap):',
                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Quick Quantity Multipliers (+1, +5, +10)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [1, 5, 10].map((multiplier) {
                  final isSelected = _selectedMultiplier == multiplier;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedMultiplier = multiplier);
                      FeedbackHelper.triggerSuccessFeedback();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        multiplier == 1 ? '1x' : '+$multiplier',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2. StreamBuilder from SQLite Drift
        StreamBuilder<List<Product>>(
          stream: db.watchTingiProducts(),
          builder: (context, snapshot) {
            final dbProducts = snapshot.data ?? [];

            // Combine database tingi items with default master items
            final List<TingiItemData> displayItems = [];

            if (dbProducts.isNotEmpty) {
              for (final p in dbProducts) {
                displayItems.add(
                  TingiItemData(
                    id: p.id,
                    emoji: _detectEmoji(p.name),
                    name: p.name,
                    price: p.sellingPrice,
                  ),
                );
              }
            } else {
              displayItems.addAll(_defaultTingiItems);
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayItems.length + 1, // +1 for "Add Tingi" button
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                // Last item is the "+ Dagdag Tingi" button
                if (index == displayItems.length) {
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _showAddCustomTingiDialog,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 28),
                            const SizedBox(height: 6),
                            Text(
                              tr ? '+ Tingi' : '+ Custom',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final item = displayItems[index];

                return Container(
                  decoration: SoftDecorations.card(context, radius: 14),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        widget.onAddTingi(item.name, item.price, _selectedMultiplier);
                        FeedbackHelper.triggerSuccessFeedback();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(item.emoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 4),
                            Text(
                              item.name,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₱ ${item.price.toStringAsFixed(item.price % 1 == 0 ? 0 : 2)}',
                              style: GoogleFonts.outfit(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
