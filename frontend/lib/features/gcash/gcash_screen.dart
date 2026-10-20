import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/localization/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/feedback_helper.dart';
import 'rate_card_pdf_service.dart';
import 'gcash_receipt_ocr_service.dart';

class GcashScreen extends ConsumerStatefulWidget {
  const GcashScreen({super.key});

  @override
  ConsumerState<GcashScreen> createState() => _GcashScreenState();
}

class _GcashScreenState extends ConsumerState<GcashScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Seed default fee brackets if empty
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(databaseProvider).seedDefaultFeeBrackets();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(stringsProvider);
    final db = ref.watch(databaseProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          tr.gcashTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: tr.isTaglish ? 'I-print ang Rate Card (PDF)' : 'Print Rate Card (PDF)',
            icon: const Icon(Icons.print_rounded),
            onPressed: () => _showPrintRateCardDialog(context, db, tr),
          ),
        ],
      ),
      body: StreamBuilder<DualFloatBalance>(
        stream: db.watchDualFloatBalance(),
        builder: (context, balanceSnapshot) {
          final balance = balanceSnapshot.data ??
              const DualFloatBalance(
                gcashFloat: 10000.0,
                cashDrawer: 5000.0,
                totalFeesEarned: 0.0,
                totalTransactions: 0,
                cashInCount: 0,
                cashOutCount: 0,
                storePaymentCount: 0,
              );

          final isShort = MediaQuery.of(context).size.height < 520;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, isShort ? 6 : 12, 16, 0),
                    child: Column(
                      children: [
                        // Dual Balances (GCash vs Cash Box Drawer)
                        Row(
                          children: [
                            Expanded(
                              child: _buildSoftBalanceCard(
                                context,
                                title: tr.ewalletFloat,
                                amount: '₱ ${balance.gcashFloat.toStringAsFixed(2)}',
                                subtitle: '${balance.cashInCount} Cash-In | ${balance.cashOutCount} Cash-Out',
                                icon: Icons.account_balance_wallet_outlined,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSoftBalanceCard(
                                context,
                                title: tr.cashBoxDrawer,
                                amount: '₱ ${balance.cashDrawer.toStringAsFixed(2)}',
                                subtitle: '+₱${balance.totalFeesEarned.toStringAsFixed(2)} Fee Profit',
                                icon: Icons.payments_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isShort ? 6 : 12),

                        // Quick Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showTransactionModal(context, db, tr, isCashIn: true),
                                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                                label: Text(
                                  tr.cashInAction,
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: isShort ? 8 : 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showTransactionModal(context, db, tr, isCashIn: false),
                                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                                label: Text(
                                  tr.cashOutAction,
                                  style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: isShort ? 8 : 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isShort ? 6 : 12),

                        // Sub-Tabs Header
                        Container(
                          decoration: BoxDecoration(
                            color: isLight ? Colors.grey.shade100 : Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicatorColor: AppColors.primary,
                            labelColor: isLight ? AppColors.primary : Colors.white,
                            unselectedLabelColor: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                            indicatorSize: TabBarIndicatorSize.tab,
                            tabs: [
                              Tab(text: tr.isTaglish ? 'Kwaderno (Ledger)' : 'Ledger History'),
                              Tab(text: tr.feeSchedule),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sub-Tabs Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLedgerList(db, tr, isLight),
                        _buildFeeScheduleView(db, tr, isLight, borderColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --------------------------------------------------------------------------
  // LEDGER TRANSACTION HISTORY
  // --------------------------------------------------------------------------

  Widget _buildLedgerList(AppDatabase db, AppStrings tr, bool isLight) {
    return StreamBuilder<List<GcashTransaction>>(
      stream: db.watchGcashTransactions(),
      builder: (context, snapshot) {
        final transactions = snapshot.data ?? [];
        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 10),
                Text(
                  tr.isTaglish ? 'Wala pang naitalang GCash transaction.' : 'No GCash transactions recorded yet.',
                  style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isCashOut = tx.transactionType == 'CASH_OUT';
            final isStorePayment = tx.transactionType == 'STORE_PAYMENT';

            Color typeColor = Colors.blue.shade600;
            String typeLabel = 'Cash-In';
            IconData typeIcon = Icons.arrow_upward_rounded;

            if (isCashOut) {
              typeColor = AppColors.primary;
              typeLabel = 'Cash-Out';
              typeIcon = Icons.arrow_downward_rounded;
            } else if (isStorePayment) {
              typeColor = Colors.purple.shade600;
              typeLabel = 'Store Sale';
              typeIcon = Icons.shopping_bag_outlined;
            }

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: SoftDecorations.card(context, radius: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: typeColor.withAlpha(25),
                    radius: 20,
                    child: Icon(typeIcon, color: typeColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                typeLabel,
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: typeColor),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₱ ${tx.amount.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (tx.customerName != null && tx.customerName!.isNotEmpty)
                              Text(
                                '${tx.customerName!} • ',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            if (tx.customerPhone != null && tx.customerPhone!.isNotEmpty)
                              Text(
                                tx.customerPhone!,
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            const Spacer(),
                            if (tx.feeCharged > 0)
                              Text(
                                '+₱${tx.feeCharged.toStringAsFixed(2)} Fee',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                          ],
                        ),
                        if (tx.referenceNumber != null && tx.referenceNumber!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Ref: ${tx.referenceNumber!}',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 10,
                              color: isLight ? Colors.blue.shade900 : Colors.blue.shade300,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // CUSTOMIZABLE FEE SCHEDULE BRACKETS VIEW
  // --------------------------------------------------------------------------

  Widget _buildFeeScheduleView(AppDatabase db, AppStrings tr, bool isLight, Color borderColor) {
    return StreamBuilder<List<GcashFeeBracket>>(
      stream: db.watchFeeBrackets(),
      builder: (context, snapshot) {
        final brackets = snapshot.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr.feeSchedule,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                TextButton.icon(
                  onPressed: () => _showEditBracketModal(context, db, tr),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    tr.isTaglish ? 'Magdagdag ng Bracket' : 'Add Bracket',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: SoftDecorations.card(context, radius: 14),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr.isTaglish ? 'Saklaw ng Halaga' : 'Amount Range',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                          ),
                        ),
                        Text(
                          tr.isTaglish ? 'Patong (Fee)' : 'Convenience Fee',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(color: borderColor, height: 1),
                  if (brackets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        tr.isTaglish ? 'Walang fee brackets.' : 'No fee brackets found.',
                        style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ),
                  ...brackets.map((b) {
                    final rangeStr = '₱ ${b.minAmount.toStringAsFixed(0)} - ₱ ${b.maxAmount.toStringAsFixed(0)}';
                    final feeStr = b.percentageFee > 0
                        ? '${b.percentageFee.toStringAsFixed(1)}%'
                        : '₱ ${b.fixedFee.toStringAsFixed(2)}';

                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      title: Text(rangeStr, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            feeStr,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            onPressed: () => _showEditBracketModal(context, db, tr, bracket: b),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                            onPressed: () async {
                              await db.deleteFeeBracket(b.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(tr.isTaglish ? 'Naalis ang bracket!' : 'Bracket removed!'),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // EDIT BRACKET MODAL
  // --------------------------------------------------------------------------

  void _showEditBracketModal(BuildContext context, AppDatabase db, AppStrings tr, {GcashFeeBracket? bracket}) {
    final minCtrl = TextEditingController(text: bracket?.minAmount.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(text: bracket?.maxAmount.toStringAsFixed(0) ?? '');
    final fixedCtrl = TextEditingController(text: bracket?.fixedFee.toStringAsFixed(2) ?? '');
    final percentCtrl = TextEditingController(text: bracket?.percentageFee.toStringAsFixed(1) ?? '0.0');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isLight = Theme.of(ctx).brightness == Brightness.light;
        return Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : AppColors.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                bracket == null
                    ? (tr.isTaglish ? 'Magdagdag ng Fee Bracket' : 'Add Fee Bracket')
                    : (tr.isTaglish ? 'I-edit ang Fee Bracket' : 'Edit Fee Bracket'),
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr.isTaglish ? 'Pinakamababa (Min ₱)' : 'Min Amount (₱)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: tr.isTaglish ? 'Pinakamataas (Max ₱)' : 'Max Amount (₱)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fixedCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: tr.isTaglish ? 'Fixed Fee (₱)' : 'Fixed Fee (₱)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: percentCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Percentage (%)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () async {
                  final minAmt = double.tryParse(minCtrl.text.trim()) ?? 0.0;
                  final maxAmt = double.tryParse(maxCtrl.text.trim()) ?? 0.0;
                  final fixedFee = double.tryParse(fixedCtrl.text.trim()) ?? 0.0;
                  final percentage = double.tryParse(percentCtrl.text.trim()) ?? 0.0;

                  if (maxAmt <= minAmt) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr.isTaglish ? 'Dapat mas mataas ang Max kaysa Min!' : 'Max amount must exceed min!'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final id = bracket?.id ?? _uuid.v4();
                  await db.saveFeeBracket(
                    GcashFeeConfigCompanion.insert(
                      id: id,
                      minAmount: minAmt,
                      maxAmount: maxAmt,
                      fixedFee: drift.Value(fixedFee),
                      percentageFee: drift.Value(percentage),
                    ),
                  );

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr.isTaglish ? '✅ Na-save ang Fee Bracket!' : '✅ Fee Bracket saved!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(tr.isTaglish ? 'I-SAVE ANG BRACKET' : 'SAVE BRACKET'),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // CASH-IN & CASH-OUT TRANSACTION MODAL
  // --------------------------------------------------------------------------

  void _showTransactionModal(BuildContext context, AppDatabase db, AppStrings tr, {required bool isCashIn}) {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();

    double calculatedFee = 10.0;
    bool isDuplicateRef = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isLight = Theme.of(ctx).brightness == Brightness.light;
        final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            void updateFee(String val) async {
              final amt = double.tryParse(val.trim()) ?? 0.0;
              final fee = await db.calculateGcashFee(amt);
              setModalState(() {
                calculatedFee = fee;
              });
            }

            void checkDuplicateRef(String val) async {
              if (val.trim().isEmpty) {
                setModalState(() => isDuplicateRef = false);
                return;
              }
              final isUsed = await db.isReferenceNumberUsed(val.trim());
              setModalState(() => isDuplicateRef = isUsed);
            }

            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : AppColors.surfaceDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: (isCashIn ? Colors.blue.shade600 : AppColors.primary).withAlpha(25),
                            radius: 16,
                            child: Icon(
                              isCashIn ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              color: isCashIn ? Colors.blue.shade600 : AppColors.primary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isCashIn ? tr.cashInAction : tr.cashOutAction,
                            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Customer Phone
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: tr.isTaglish ? 'Numero ng GCash (09xx...)' : 'GCash Phone Number',
                          prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Customer Name (Optional)
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: tr.isTaglish ? 'Pangalan ng Customer (Opsyonal)' : 'Customer Name (Optional)',
                          prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Amount Field
                      TextField(
                        controller: amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: updateFee,
                        decoration: InputDecoration(
                          labelText: tr.isTaglish ? 'Halaga (Halimbawa: 500)' : 'Amount (e.g. 500)',
                          prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Quick Amount Chips
                      Wrap(
                        spacing: 6,
                        children: [100.0, 300.0, 500.0, 1000.0, 2000.0, 5000.0].map((quickAmt) {
                          return ActionChip(
                            label: Text('₱${quickAmt.toStringAsFixed(0)}', style: GoogleFonts.inter(fontSize: 11)),
                            onPressed: () {
                              amountCtrl.text = quickAmt.toStringAsFixed(0);
                              updateFee(quickAmt.toStringAsFixed(0));
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Reference Number & OCR Scan Button
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: refCtrl,
                              onChanged: checkDuplicateRef,
                              decoration: InputDecoration(
                                labelText: tr.isTaglish
                                    ? '13-digit Reference No. (Opsyonal)'
                                    : '13-digit Reference No. (Optional)',
                                prefixIcon: const Icon(Icons.receipt_rounded, size: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            tooltip: tr.isTaglish ? 'I-scan ang Resibo (OCR)' : 'Scan Receipt (OCR)',
                            icon: const Icon(Icons.camera_alt_outlined),
                            onPressed: () async {
                              // Simulate or trigger text OCR slotting
                              _showOcrScanDialog(sheetContext, (extractedRef, extractedAmt) {
                                if (extractedRef != null) {
                                  refCtrl.text = extractedRef;
                                  checkDuplicateRef(extractedRef);
                                }
                                if (extractedAmt != null && extractedAmt > 0) {
                                  amountCtrl.text = extractedAmt.toStringAsFixed(0);
                                  updateFee(extractedAmt.toStringAsFixed(0));
                                }
                              });
                            },
                          ),
                        ],
                      ),

                      // Duplicate Reference Warning (Anti-Scam)
                      if (isDuplicateRef) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  tr.isTaglish
                                      ? 'Babala: Naitala na ang Reference No. na ito! Baka ito ay recycled screenshot.'
                                      : 'Warning: This Reference No. was already logged! Potential recycled screenshot.',
                                  style: GoogleFonts.inter(fontSize: 11, color: Colors.red.shade900, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Auto-Calculated Fee Card
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
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '₱ ${calculatedFee.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Submit Button
                      ElevatedButton(
                        onPressed: () async {
                          final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                          if (amt <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr.isTaglish ? 'Maglagay ng wastong halaga!' : 'Please enter a valid amount!'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          final txType = isCashIn ? 'CASH_IN' : 'CASH_OUT';
                          final phone = phoneCtrl.text.trim();
                          final name = nameCtrl.text.trim();
                          final refNo = refCtrl.text.trim();

                          await db.recordGcash(
                            transactionType: txType,
                            amount: amt,
                            feeCharged: calculatedFee,
                            referenceNumber: refNo.isEmpty ? null : refNo,
                            customerName: name.isEmpty ? null : name,
                            customerPhone: phone.isEmpty ? null : phone,
                          );

                          await FeedbackHelper.triggerSuccessFeedback();

                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  tr.isTaglish
                                      ? '✅ ${isCashIn ? "Cash-In" : "Cash-Out"} naitala! (+₱${calculatedFee.toStringAsFixed(2)} tubo)'
                                      : '✅ ${isCashIn ? "Cash-In" : "Cash-Out"} logged! (+₱${calculatedFee.toStringAsFixed(2)} fee)',
                                ),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCashIn ? Colors.blue.shade600 : AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          tr.isTaglish ? 'I-REHISTRO ANG TRANSAKSYON' : 'RECORD TRANSACTION',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // OCR SIMULATION & SCAN DIALOG
  // --------------------------------------------------------------------------

  void _showOcrScanDialog(BuildContext context, Function(String? ref, double? amt) onExtracted) {
    final tr = ref.read(stringsProvider);
    final pasteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.document_scanner_rounded, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              tr.isTaglish ? 'Scan / I-paste ang Resibo' : 'Scan / Paste Receipt',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr.isTaglish
                  ? 'I-paste ang SMS resibo o text mula sa screenshot ng GCash. Awtomatikong kukunin ang 13-digit Reference No. at halaga.'
                  : 'Paste GCash SMS receipt or screenshot text. Automatically extracts 13-digit Reference No. and amount.',
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pasteCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Halimbawa: You have received PHP 500.00 of GCash from... Ref. No. 1002 481 029412',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx),
            child: Text(tr.isTaglish ? 'Kanselahin' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = pasteCtrl.text;
              final result = GcashReceiptOcrService.parseRawText(text);
              Navigator.pop(dlgCtx);
              onExtracted(result.referenceNumber, result.amount);
            },
            child: Text(tr.isTaglish ? 'I-extract' : 'Extract'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PRINT RATE CARD DIALOG
  // --------------------------------------------------------------------------

  void _showPrintRateCardDialog(BuildContext context, AppDatabase db, AppStrings tr) async {
    final brackets = await db.getFeeBrackets();

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isLight = Theme.of(ctx).brightness == Brightness.light;
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isLight ? Colors.white : AppColors.surfaceDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr.isTaglish ? 'I-print ang GCash Rate Card' : 'Print GCash Rate Card',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                tr.isTaglish
                  ? 'Pumili ng format para i-laminate sa tindahan o i-print sa thermal printer:'
                  : 'Choose format to laminate on store grill or print via thermal printer:',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.blue),
                title: Text(tr.isTaglish ? 'Standard A4 Poster (Pang-Laminate)' : 'Standard A4 Poster (Lamination)'),
                subtitle: Text(tr.isTaglish ? 'Buong laki para isabit sa tindahan' : 'Full size for store signage', style: const TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await RateCardPdfService.printOrShareRateCard(
                    storeName: 'Sari-Sari Store',
                    brackets: brackets,
                    format: RateCardFormat.a4Sheet,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.note_rounded, color: Colors.indigo),
                title: Text(tr.isTaglish ? 'A5 Half Sheet Flyer' : 'A5 Half Sheet Flyer'),
                subtitle: Text(tr.isTaglish ? 'Kalahating papel, compact flyer' : 'Half sheet, compact poster', style: const TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await RateCardPdfService.printOrShareRateCard(
                    storeName: 'Sari-Sari Store',
                    brackets: brackets,
                    format: RateCardFormat.a5HalfSheet,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                title: Text(tr.isTaglish ? 'Thermal Receipt (58mm / 80mm)' : 'Thermal Receipt (58mm / 80mm)'),
                subtitle: Text(tr.isTaglish ? 'Bluetooth thermal printer mini receipt' : 'Bluetooth thermal printer mini receipt', style: const TextStyle(fontSize: 11)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await RateCardPdfService.printOrShareRateCard(
                    storeName: 'Sari-Sari Store',
                    brackets: brackets,
                    format: RateCardFormat.posThermal80mm,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // SOFT BALANCE CARD HELPER
  // --------------------------------------------------------------------------

  Widget _buildSoftBalanceCard(
    BuildContext context, {
    required String title,
    required String amount,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: SoftDecorations.card(context, radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(25),
                radius: 15,
                child: Icon(icon, color: color, size: 16),
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
          const SizedBox(height: 8),
          Text(
            amount,
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
