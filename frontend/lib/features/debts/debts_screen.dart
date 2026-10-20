import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/app_database.dart';
import '../../core/localization/language_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/feedback_helper.dart';

class DebtsScreen extends ConsumerStatefulWidget {
  const DebtsScreen({super.key});

  @override
  ConsumerState<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends ConsumerState<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          tr.debtsTitle,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: isLight ? AppColors.primary : Colors.white,
          unselectedLabelColor: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
          tabs: [
            Tab(text: tr.isTaglish ? 'Pautang sa Tao' : 'Customer Debts'),
            Tab(text: tr.isTaglish ? 'Utang sa Bodega' : 'Supplier Payables'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: tr.recordNewDebt,
            icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
            onPressed: () {
              if (_tabController.index == 0) {
                _showAddCustomerDebtModal(context, db, tr);
              } else {
                _showAddSupplierPayableModal(context, db, tr);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomerDebtsTab(db, tr, isLight, borderColor),
          _buildSupplierPayablesTab(db, tr, isLight, borderColor),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 1: PAUTANG SA TAO (RECEIVABLES)
  // --------------------------------------------------------------------------

  Widget _buildCustomerDebtsTab(AppDatabase db, AppStrings tr, bool isLight, Color borderColor) {
    return StreamBuilder<List<Debt>>(
      stream: db.watchActiveDebts(),
      builder: (context, snapshot) {
        final debtList = snapshot.data ?? [];
        final totalCollectibles = debtList.fold(0.0, (sum, d) => sum + d.remainingBalance);

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Collectibles Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLight ? AppColors.warningLight.withAlpha(220) : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLight ? AppColors.warning.withAlpha(120) : AppColors.warningDark.withAlpha(80),
                  width: 1.0,
                ),
                boxShadow: isLight ? AppColors.softShadowLight : AppColors.softShadowDark,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr.totalCollectibles.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: isLight ? AppColors.warning : AppColors.warningDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.8,
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
                    style: GoogleFonts.outfit(
                      color: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${debtList.length} ${tr.activeDebtors}',
                    style: GoogleFonts.inter(
                      color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Add Customer Debt Action
            ElevatedButton.icon(
              onPressed: () => _showAddCustomerDebtModal(context, db, tr),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                tr.isTaglish ? '+ Maglista ng Bagong Utang' : '+ Record New Customer Debt',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Debtors List
            if (debtList.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, size: 50, color: Colors.green.shade400),
                      const SizedBox(height: 10),
                      Text(
                        tr.isTaglish ? 'Walang aktibong pautang. Bayad lahat!' : 'No active customer debts. All settled!',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...debtList.map((debt) => _buildCustomerDebtCard(context, db, tr, debt, isLight, borderColor)),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildCustomerDebtCard(
    BuildContext context,
    AppDatabase db,
    AppStrings tr,
    Debt debt,
    bool isLight,
    Color borderColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: SoftDecorations.card(context, radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      debt.customerName,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    if (debt.customerPhone != null && debt.customerPhone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        debt.customerPhone!,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱ ${debt.remainingBalance.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.warningDark,
                    ),
                  ),
                  if (debt.status == 'PARTIALLY_PAID')
                    Text(
                      tr.isTaglish ? 'May bawas na' : 'Partially paid',
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ],
          ),
          if (debt.notes != null && debt.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              debt.notes!,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 8),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1-Tap Share Reminder (SMS / WhatsApp)
              TextButton.icon(
                onPressed: () => _shareDebtReminder(context, tr, debt, db),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  tr.isTaglish ? 'I-remind' : 'Remind',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),

              // View Items & Settle Payment Button
              ElevatedButton(
                onPressed: () => _showSettleDebtModal(context, db, tr, debt),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  tr.isTaglish ? 'Maningil / Bawas' : 'Settle Payment',
                  style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TAB 2: UTANG SA BODEGA (SUPPLIER PAYABLES)
  // --------------------------------------------------------------------------

  Widget _buildSupplierPayablesTab(AppDatabase db, AppStrings tr, bool isLight, Color borderColor) {
    return StreamBuilder<List<Payable>>(
      stream: db.watchPendingPayables(),
      builder: (context, snapshot) {
        final payablesList = snapshot.data ?? [];
        final totalPayables = payablesList.fold(
          0.0,
          (sum, p) => sum + (p.totalAmount - p.paidAmount),
        );

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 48-Hour Urgent Banner Alert
            StreamBuilder<List<Payable>>(
              stream: db.watchPayablesDueSoon(threshold: const Duration(hours: 48)),
              builder: (context, alertSnapshot) {
                final urgentPayables = alertSnapshot.data ?? [];
                if (urgentPayables.isEmpty) return const SizedBox.shrink();

                final urgentTotal = urgentPayables.fold(
                  0.0,
                  (sum, p) => sum + (p.totalAmount - p.paidAmount),
                );

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade400, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.red.shade100,
                        radius: 18,
                        child: const Icon(Icons.alarm_rounded, color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.isTaglish
                                  ? 'BABALA: Utang sa Bodega Due sa Loob ng 48 Oras!'
                                  : 'URGENT: Supplier Debts Due within 48 Hours!',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.red.shade900),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tr.isTaglish
                                  ? '${urgentPayables.length} delivery van / bodega ang dapat bayaran (Kabuuang ₱${urgentTotal.toStringAsFixed(2)})'
                                  : '${urgentPayables.length} suppliers due (Total ₱${urgentTotal.toStringAsFixed(2)})',
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.red.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Payables Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isLight ? Colors.blue.shade50 : AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLight ? Colors.blue.shade200 : Colors.blue.shade900,
                  width: 1.0,
                ),
                boxShadow: isLight ? AppColors.softShadowLight : AppColors.softShadowDark,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr.isTaglish ? 'KABUUANG UTANG SA BODEGA' : 'TOTAL SUPPLIER PAYABLES',
                        style: GoogleFonts.inter(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const Icon(Icons.local_shipping_rounded, color: Colors.blue, size: 22),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₱ ${totalPayables.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      color: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${payablesList.length} ${tr.isTaglish ? "nakabinbing bayarin sa ahente/bodega" : "pending supplier invoices"}',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Add Supplier Payable Action
            ElevatedButton.icon(
              onPressed: () => _showAddSupplierPayableModal(context, db, tr),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                tr.isTaglish ? '+ Maglista ng Utang sa Bodega' : '+ Add Supplier / Bodega Payable',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Payables List
            if (payablesList.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 50, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        tr.isTaglish ? 'Walang nakabinbing utang sa bodega!' : 'No pending supplier payables!',
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...payablesList.map((payable) => _buildSupplierPayableCard(context, db, tr, payable, isLight, borderColor)),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildSupplierPayableCard(
    BuildContext context,
    AppDatabase db,
    AppStrings tr,
    Payable payable,
    bool isLight,
    Color borderColor,
  ) {
    final remaining = payable.totalAmount - payable.paidAmount;
    final now = DateTime.now();
    final differenceHours = payable.dueDate.difference(now).inHours;
    final isUrgent = differenceHours <= 48 && remaining > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: SoftDecorations.card(context, radius: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          payable.supplierName,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        if (isUrgent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '48H DUE',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (payable.contactNumber != null && payable.contactNumber!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        payable.contactNumber!,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱ ${remaining.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: isUrgent ? Colors.red.shade700 : AppColors.primary,
                    ),
                  ),
                  Text(
                    'Due: ${payable.dueDate.month}/${payable.dueDate.day}/${payable.dueDate.year}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isUrgent ? Colors.red.shade700 : Colors.grey.shade600,
                      fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (payable.reminderNotes != null && payable.reminderNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              payable.reminderNotes!,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 8),

          // Settle Supplier Payment Button
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _showSettlePayableModal(context, db, tr, payable),
              style: ElevatedButton.styleFrom(
                backgroundColor: isUrgent ? Colors.red.shade600 : Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                tr.isTaglish ? 'Magbayad sa Bodega' : 'Settle Supplier Payment',
                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // MODALS & ACTIONS
  // --------------------------------------------------------------------------

  void _showAddCustomerDebtModal(BuildContext context, AppDatabase db, AppStrings tr) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime? selectedDueDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isLight = Theme.of(ctx).brightness == Brightness.light;
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : AppColors.surfaceDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr.isTaglish ? 'Maglista ng Bagong Utang (Pautang)' : 'Record New Customer Debt',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: tr.isTaglish ? 'Pangalan ng Customer' : 'Customer Name',
                        prefixIcon: const Icon(Icons.person_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: tr.isTaglish ? 'Numero ng Telepono (Opsyonal)' : 'Phone Number (Optional)',
                        prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: tr.isTaglish ? 'Kabuuang Halaga (₱)' : 'Total Amount (₱)',
                        prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      decoration: InputDecoration(
                        labelText: tr.isTaglish ? 'Mga Paninda (e.g. Bigas 2kg, Itlog 3pcs)' : 'Items Description',
                        prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                      title: Text(
                        tr.isTaglish ? 'Petsa ng Bayaran (Due Date)' : 'Due Date',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        selectedDueDate != null
                            ? '${selectedDueDate!.month}/${selectedDueDate!.day}/${selectedDueDate!.year}'
                            : (tr.isTaglish ? 'Walang takdang petsa' : 'No due date set'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: sheetCtx,
                            initialDate: selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDueDate = picked);
                          }
                        },
                        child: Text(tr.isTaglish ? 'Palitan' : 'Change'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                        if (name.isEmpty || amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr.isTaglish ? 'Paki-kumpleto ang pangalan at halaga!' : 'Please enter name and valid amount!'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        final desc = notesCtrl.text.trim().isEmpty ? 'General Grocery Items' : notesCtrl.text.trim();
                        final items = [
                          DebtItemsCompanion.insert(
                            id: _uuid.v4(),
                            debtId: '',
                            description: desc,
                            quantity: const drift.Value(1.0),
                            amount: amt,
                          ),
                        ];

                        await db.recordDebt(
                          customerName: name,
                          customerPhone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                          totalAmount: amt,
                          dueDate: selectedDueDate,
                          notes: desc,
                          items: items,
                        );

                        await FeedbackHelper.triggerSuccessFeedback();

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr.isTaglish ? '✅ Naitala ang bagong pautang!' : '✅ New customer debt logged!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(tr.isTaglish ? 'I-REHISTRO ANG PAUTANG' : 'RECORD DEBT'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSupplierPayableModal(BuildContext context, AppDatabase db, AppStrings tr) {
    final supplierCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDueDate = DateTime.now().add(const Duration(days: 3));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isLight = Theme.of(ctx).brightness == Brightness.light;
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : AppColors.surfaceDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      tr.isTaglish ? 'Maglista ng Utang sa Bodega / Supplier' : 'Add Supplier / Bodega Payable',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: supplierCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Supplier Name (e.g. San Miguel, URC, Delivery Van)',
                        prefixIcon: Icon(Icons.store_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: contactCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Agent Contact Number',
                        prefixIcon: Icon(Icons.phone_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: tr.isTaglish ? 'Halaga ng Invoice (₱)' : 'Invoice Amount (₱)',
                        prefixIcon: const Icon(Icons.attach_money_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Notes / Invoice Number',
                        prefixIcon: Icon(Icons.receipt_long_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_rounded, color: Colors.blue),
                      title: Text(
                        tr.isTaglish ? 'Petsa ng Pagkolekta ng Ahente' : 'Due Date for Delivery Van',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${selectedDueDate.month}/${selectedDueDate.day}/${selectedDueDate.year}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: sheetCtx,
                            initialDate: selectedDueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDueDate = picked);
                          }
                        },
                        child: Text(tr.isTaglish ? 'Palitan' : 'Change'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final supplier = supplierCtrl.text.trim();
                        final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                        if (supplier.isEmpty || amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr.isTaglish ? 'Paki-lagay ang supplier at halaga!' : 'Please enter supplier and valid amount!'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        await db.recordPayable(
                          supplierName: supplier,
                          contactNumber: contactCtrl.text.trim().isEmpty ? null : contactCtrl.text.trim(),
                          totalAmount: amt,
                          dueDate: selectedDueDate,
                          reminderNotes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                        );

                        await FeedbackHelper.triggerSuccessFeedback();

                        if (context.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(tr.isTaglish ? '✅ Naitala ang utang sa bodega!' : '✅ Supplier payable recorded!'),
                              backgroundColor: Colors.blue.shade700,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(tr.isTaglish ? 'I-REHISTRO ANG BAYARIN' : 'RECORD PAYABLE'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSettleDebtModal(BuildContext context, AppDatabase db, AppStrings tr, Debt debt) {
    final paymentCtrl = TextEditingController(text: debt.remainingBalance.toStringAsFixed(2));

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
                tr.isTaglish ? 'Singilin / Bawasan ang Utang' : 'Settle Customer Debt',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Customer: ${debt.customerName} • Natitira: ₱${debt.remainingBalance.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: paymentCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: tr.isTaglish ? 'Halaga ng Ibinayad (₱)' : 'Payment Amount (₱)',
                  prefixIcon: const Icon(Icons.payments_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final payAmt = double.tryParse(paymentCtrl.text.trim()) ?? 0.0;
                  if (payAmt <= 0) return;

                  await db.payDebt(debt.id, payAmt);
                  await FeedbackHelper.triggerSuccessFeedback();

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr.isTaglish
                              ? '✅ Naitala ang bayad na ₱${payAmt.toStringAsFixed(2)}!'
                              : '✅ Payment of ₱${payAmt.toStringAsFixed(2)} recorded!',
                        ),
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
                child: Text(tr.isTaglish ? 'KUMPIRMAHIN ANG BAYAD' : 'CONFIRM PAYMENT'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettlePayableModal(BuildContext context, AppDatabase db, AppStrings tr, Payable payable) {
    final remaining = payable.totalAmount - payable.paidAmount;
    final paymentCtrl = TextEditingController(text: remaining.toStringAsFixed(2));

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
                tr.isTaglish ? 'Magbayad sa Bodega / Delivery Van' : 'Pay Supplier Invoice',
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Supplier: ${payable.supplierName} • Natitirang Bayarin: ₱${remaining.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: paymentCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: tr.isTaglish ? 'Halaga ng Ibinayad (₱)' : 'Payment Amount (₱)',
                  prefixIcon: const Icon(Icons.payments_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final payAmt = double.tryParse(paymentCtrl.text.trim()) ?? 0.0;
                  if (payAmt <= 0) return;

                  await db.paySupplier(payable.id, payAmt);
                  await FeedbackHelper.triggerSuccessFeedback();

                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          tr.isTaglish
                              ? '✅ Naitala ang bayad na ₱${payAmt.toStringAsFixed(2)} sa ${payable.supplierName}!'
                              : '✅ Payment of ₱${payAmt.toStringAsFixed(2)} to ${payable.supplierName} recorded!',
                        ),
                        backgroundColor: Colors.blue.shade700,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(tr.isTaglish ? 'BAYARAN ANG SUPPLIER' : 'PAY SUPPLIER'),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // 1-TAP SHAREABLE DEBT REMINDER (SMS, MESSENGER, WHATSAPP)
  // --------------------------------------------------------------------------

  void _shareDebtReminder(BuildContext context, AppStrings tr, Debt debt, AppDatabase db) async {
    final items = await db.getDebtItems(debt.id);
    final msg = StringBuffer();

    msg.writeln('Magandang araw po, ${debt.customerName}!');
    msg.writeln('Paalala lang po mula sa ating Sari-Sari Store ukol sa inyong natitirang listahan/utang na ₱${debt.remainingBalance.toStringAsFixed(2)}.');
    if (debt.dueDate != null) {
      msg.writeln('Takdang araw ng bayaran: ${debt.dueDate!.month}/${debt.dueDate!.day}/${debt.dueDate!.year}.');
    }
    if (items.isNotEmpty) {
      msg.writeln('\nMga gamit na nakuha:');
      for (final item in items) {
        msg.writeln('- ${item.description}: ₱${item.amount.toStringAsFixed(2)}');
      }
    }
    msg.writeln('\nMaraming salamat po sa inyong tiwala at suporta!');

    final fullMessage = msg.toString();

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
                tr.isTaglish ? 'I-share ang Paalala ng Bayarin' : 'Share Debt Reminder',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isLight ? Colors.grey.shade100 : Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  fullMessage,
                  style: GoogleFonts.inter(fontSize: 12),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullMessage));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr.isTaglish ? '📋 Nakopya sa clipboard!' : '📋 Copied to clipboard!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: Text(tr.isTaglish ? 'Kopyahin' : 'Copy'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final phone = debt.customerPhone ?? '';
                        final uri = Uri(
                          scheme: 'sms',
                          path: phone,
                          queryParameters: {'body': fullMessage},
                        );
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          // Fallback to clipboard
                          Clipboard.setData(ClipboardData(text: fullMessage));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  tr.isTaglish
                                      ? 'Hindi mabuksan ang SMS app. Nakopya sa clipboard!'
                                      : 'Could not launch SMS. Copied to clipboard!',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.sms_rounded, size: 18),
                      label: const Text('SMS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
