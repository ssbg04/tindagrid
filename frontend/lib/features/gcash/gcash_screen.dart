import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/localization/language_provider.dart';
import '../../core/theme/app_theme.dart';

class GcashScreen extends ConsumerWidget {
  const GcashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(stringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

    final feeBrackets = [
      {'range': '₱ 1 - ₱ 500', 'fee': '₱ 10.00'},
      {'range': '₱ 501 - ₱ 1,000', 'fee': '₱ 15.00'},
      {'range': '₱ 1,001 - ₱ 1,500', 'fee': '₱ 20.00'},
      {'range': '₱ 1,501 - ₱ 2,000', 'fee': '₱ 25.00'},
      {'range': '₱ 2,001 - ₱ 3,000', 'fee': '₱ 35.00'},
      {'range': '₱ 3,001 - ₱ 5,000', 'fee': '₱ 50.00'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr.gcashTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Soft UI Dual Balances (GCash vs Cash Box)
          Row(
            children: [
              Expanded(
                child: _buildSoftBalanceCard(
                  context,
                  title: tr.ewalletFloat,
                  amount: '₱ 8,450.00',
                  icon: Icons.account_balance_wallet_outlined,
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSoftBalanceCard(
                  context,
                  title: tr.cashBoxDrawer,
                  amount: '₱ 4,120.00',
                  icon: Icons.payments_outlined,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Quick Action Buttons (Soft Tactile)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showSoftGcashModal(context, tr, isCashIn: true);
                  },
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  label: Text(tr.cashInAction, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showSoftGcashModal(context, tr, isCashIn: false);
                  },
                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  label: Text(tr.cashOutAction, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Fee Scheduler Table (Soft UI Card)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: SoftDecorations.card(context, radius: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr.feeSchedule,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const Icon(Icons.receipt_long_rounded, color: Colors.blue, size: 22),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: borderColor, height: 1),
                Table(
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            tr.isTaglish ? 'Halaga ng Transaksyon' : 'Transaction Range',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            tr.isTaglish ? 'Patong / Tubo' : 'Fee / Profit',
                            textAlign: TextAlign.end,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...feeBrackets.map((f) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              f['range']!,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              f['fee']!,
                              textAlign: TextAlign.end,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSoftGcashModal(BuildContext context, AppStrings tr, {required bool isCashIn}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isLight = Theme.of(ctx).brightness == Brightness.light;
        final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : AppColors.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: isLight ? AppColors.softShadowLight : AppColors.softShadowDark,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isCashIn ? tr.cashInAction : tr.cashOutAction,
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: tr.isTaglish ? 'Numero ng GCash (09xx...)' : 'GCash Phone Number',
                    prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: tr.isTaglish ? 'Halaga (Halimbawa: 500)' : 'Amount (e.g. 500)',
                    prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withAlpha(200),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr.isTaglish ? 'Awtomatikong Patong (Fee):' : 'Calculated Convenience Fee:',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary),
                      ),
                      Text(
                        '₱ 10.00',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr.isTaglish ? '✅ GCash transaksyon naitala!' : '✅ GCash transaction recorded!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: Text(tr.isTaglish ? 'I-REHISTRO ANG TRANSAKSYON' : 'RECORD TRANSACTION'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoftBalanceCard(
    BuildContext context, {
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: SoftDecorations.card(context, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(25),
                radius: 17,
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
