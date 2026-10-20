import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

    final sampleDebts = [
      {'name': 'Aling Marites (Kapitbahay)', 'phone': '0917-123-4567', 'amount': 385.00, 'date': 'Oct 18, 2026', 'items': 'Bear Brand, Bigas 2kg, Itlog'},
      {'name': 'Mang Boy Tricycle Driver', 'phone': '0928-888-9999', 'amount': 150.00, 'date': 'Oct 19, 2026', 'items': 'Marlboro Red, Cobra Energy'},
      {'name': 'Kuya Jun (Tubero)', 'phone': '0939-555-1234', 'amount': 520.00, 'date': 'Oct 15, 2026', 'items': 'San Miguel Pale, Yosi, Chicharon'},
      {'name': 'Ate Gina (Sari-Sari sukli)', 'phone': '0945-333-7777', 'amount': 45.00, 'date': 'Oct 20, 2026', 'items': 'Kopiko Blanca, SkyFlakes'},
    ];

    final double totalCollectibles = sampleDebts.fold(0.0, (sum, d) => sum + (d['amount'] as double));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr.debtsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: tr.recordNewDebt,
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary, size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(tr.isTaglish ? 'Magbubukas ang form para sa bagong pautang...' : 'Opening new debt recording form...'),
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
          // Total Collectibles Banner (Flat Card)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isLight ? AppColors.warningLight : AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLight ? AppColors.warning : AppColors.warningDark,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.totalCollectibles.toUpperCase(),
                      style: TextStyle(
                        color: isLight ? AppColors.warning : AppColors.warningDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Icon(
                      Icons.menu_book_rounded,
                      color: isLight ? AppColors.warning : AppColors.warningDark,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₱ ${totalCollectibles.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sampleDebts.length} ${tr.activeDebtors}',
                  style: TextStyle(
                    color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Flat Search bar
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppColors.primary, size: 22),
              hintText: tr.isTaglish ? 'Hanapin ang pangalan ng may utang...' : 'Search customer name...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Debt Customer Cards (Flat)
          ...sampleDebts.map((debt) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: borderColor, width: 1.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          debt['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '₱ ${(debt['amount'] as double).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.alert,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📞 ${debt['phone']} • ${debt['date']}',
                      style: TextStyle(fontSize: 12, color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isLight ? AppColors.backgroundLight : Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Text(
                        'Paninda: ${debt['items']}',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr.isTaglish ? 'Sisingilin si ${debt['name']}...' : 'Sending SMS reminder to ${debt['name']}...'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 14),
                          label: Text(tr.isTaglish ? 'I-text Paalala' : 'Send Reminder', style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr.isTaglish ? 'Naitalang bayad ang utang!' : 'Payment marked as settled!'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check, size: 14),
                          label: Text(tr.settleDebt, style: const TextStyle(fontSize: 12)),
                        ),
                      ],
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
}
