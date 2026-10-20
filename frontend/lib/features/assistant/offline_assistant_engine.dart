import 'dart:async';
import '../../core/database/app_database.dart';

enum AssistantIntent {
  topDebtors,
  lowStock,
  salesSummary,
  gcashProfit,
  supplierPayables,
  generalHelp,
  unknown,
}

class AssistantResponse {
  final AssistantIntent intent;
  final String title;
  final String answer;
  final List<String> bulletPoints;
  final String rawQuery;
  final bool isDeterministic;

  const AssistantResponse({
    required this.intent,
    required this.title,
    required this.answer,
    this.bulletPoints = const [],
    required this.rawQuery,
    this.isDeterministic = true,
  });
}

class OfflineAssistantEngine {
  final AppDatabase db;

  OfflineAssistantEngine({required this.db});

  /// Classify natural language Taglish user prompt into structured intent
  static AssistantIntent classifyIntent(String prompt) {
    final lower = prompt.toLowerCase().trim();

    // 1. Debts / Utang / Pautang
    if (lower.contains('utang') ||
        lower.contains('pautang') ||
        lower.contains('sino may utang') ||
        lower.contains('sisingilin') ||
        lower.contains('debt') ||
        lower.contains('collectibles')) {
      return AssistantIntent.topDebtors;
    }

    // 2. Stock / Kulang / Inventory
    if (lower.contains('stock') ||
        lower.contains('kulang') ||
        lower.contains('paubos') ||
        lower.contains('ubos') ||
        lower.contains('inventory') ||
        lower.contains('paninda')) {
      return AssistantIntent.lowStock;
    }

    // 3. Sales / Benta / Kita / Kinita
    if (lower.contains('benta') ||
        lower.contains('sales') ||
        lower.contains('kinita') ||
        lower.contains('kahapon') ||
        lower.contains('ngayon') ||
        lower.contains('revenue')) {
      // Check if specifically asking about GCash fees
      if (lower.contains('gcash') || lower.contains('cash in') || lower.contains('cash out') || lower.contains('patong')) {
        return AssistantIntent.gcashProfit;
      }
      return AssistantIntent.salesSummary;
    }

    // 4. GCash Profit / Fees / Patong
    if (lower.contains('gcash') ||
        lower.contains('cash-in') ||
        lower.contains('cash-out') ||
        lower.contains('cash in') ||
        lower.contains('cash out') ||
        lower.contains('fee') ||
        lower.contains('patong') ||
        lower.contains('float')) {
      return AssistantIntent.gcashProfit;
    }

    // 5. Supplier / Bodega / Delivery Van / Payables
    if (lower.contains('bodega') ||
        lower.contains('supplier') ||
        lower.contains('delivery') ||
        lower.contains('ahente') ||
        lower.contains('payable') ||
        lower.contains('invoice')) {
      return AssistantIntent.supplierPayables;
    }

    // 6. Help / Paano / Ano magagawa
    if (lower.contains('help') ||
        lower.contains('tulong') ||
        lower.contains('ano magagawa') ||
        lower.contains('features') ||
        lower.contains('sino ka')) {
      return AssistantIntent.generalHelp;
    }

    return AssistantIntent.unknown;
  }

  /// Process user query and return deterministic, zero-hallucination Taglish answer
  Future<AssistantResponse> ask(String prompt) async {
    final intent = classifyIntent(prompt);

    switch (intent) {
      case AssistantIntent.topDebtors:
        return _handleTopDebtors(prompt);
      case AssistantIntent.lowStock:
        return _handleLowStock(prompt);
      case AssistantIntent.salesSummary:
        return _handleSalesSummary(prompt);
      case AssistantIntent.gcashProfit:
        return _handleGcashProfit(prompt);
      case AssistantIntent.supplierPayables:
        return _handleSupplierPayables(prompt);
      case AssistantIntent.generalHelp:
        return _handleGeneralHelp(prompt);
      case AssistantIntent.unknown:
        return _handleUnknown(prompt);
    }
  }

  Future<AssistantResponse> _handleTopDebtors(String prompt) async {
    final debtors = await db.getTopDebtors(limit: 5);
    if (debtors.isEmpty) {
      return AssistantResponse(
        intent: AssistantIntent.topDebtors,
        title: 'Walang May Utang 🎉',
        answer: 'Magandang balita! Walang aktibong may utang sa iyong talaan ngayon.',
        rawQuery: prompt,
      );
    }

    final totalDue = debtors.fold(0.0, (sum, d) => sum + d.remainingBalance);
    final bullets = debtors.map((d) {
      return '${d.customerName}: ₱${d.remainingBalance.toStringAsFixed(2)}${d.customerPhone != null ? " (${d.customerPhone})" : ""}';
    }).toList();

    return AssistantResponse(
      intent: AssistantIntent.topDebtors,
      title: 'Mga May Pinakamalaking Utang',
      answer: 'May kabuuang ₱${totalDue.toStringAsFixed(2)} ang sisingilin sa top ${debtors.length} na may utang:',
      bulletPoints: bullets,
      rawQuery: prompt,
    );
  }

  Future<AssistantResponse> _handleLowStock(String prompt) async {
    final lowStock = await db.getLowStockProducts(threshold: 5.0);
    if (lowStock.isEmpty) {
      return AssistantResponse(
        intent: AssistantIntent.lowStock,
        title: 'Sapat ang Lahat ng Stock ✅',
        answer: 'Walang paninda na mababa sa 5 piraso. Kumpleto ang supply ng tindahan!',
        rawQuery: prompt,
      );
    }

    final bullets = lowStock.map((p) {
      return '${p.name}: ${p.currentStock.toStringAsFixed(0)} ${p.unit} na lang';
    }).toList();

    return AssistantResponse(
      intent: AssistantIntent.lowStock,
      title: 'Mababang Stock na Paninda',
      answer: 'May ${lowStock.length} na paninda na dapat nang i-restock o bilhin sa bodega:',
      bulletPoints: bullets,
      rawQuery: prompt,
    );
  }

  Future<AssistantResponse> _handleSalesSummary(String prompt) async {
    final now = DateTime.now();
    final isYesterday = prompt.toLowerCase().contains('kahapon');
    final DateTime start;
    final DateTime end;

    if (isYesterday) {
      final y = now.subtract(const Duration(days: 1));
      start = DateTime(y.year, y.month, y.day);
      end = DateTime(y.year, y.month, y.day, 23, 59, 59);
    } else {
      start = DateTime(now.year, now.month, now.day);
      end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    }

    final summary = await db.getSalesSummaryForAssistant(startDate: start, endDate: end);
    final periodName = isYesterday ? 'Kahapon' : 'Ngayong Araw';

    if (summary.totalSalesCount == 0) {
      return AssistantResponse(
        intent: AssistantIntent.salesSummary,
        title: 'Buod ng Benta ($periodName)',
        answer: 'Wala pang naitalang benta para sa $periodName.',
        rawQuery: prompt,
      );
    }

    final margin = summary.totalRevenue > 0
        ? (summary.totalProfit / summary.totalRevenue) * 100
        : 0.0;

    final bullets = [
      'Kabuuang Benta: ₱${summary.totalRevenue.toStringAsFixed(2)} (${summary.totalSalesCount} transaksyon)',
      'Tinatayang Tubo: ₱${summary.totalProfit.toStringAsFixed(2)} (${margin.toStringAsFixed(1)}% margin)',
      'Benta sa Cash: ₱${summary.cashRevenue.toStringAsFixed(2)}',
      'Benta sa GCash: ₱${summary.gcashRevenue.toStringAsFixed(2)}',
    ];

    return AssistantResponse(
      intent: AssistantIntent.salesSummary,
      title: 'Buod ng Benta ($periodName)',
      answer: 'Narito ang buod ng benta at tubo para sa $periodName:',
      bulletPoints: bullets,
      rawQuery: prompt,
    );
  }

  Future<AssistantResponse> _handleGcashProfit(String prompt) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final summary = await db.getGcashProfitSummaryForAssistant(startDate: startOfDay);

    final bullets = [
      'Kinita sa Service Fee: ₱${summary.totalFees.toStringAsFixed(2)}',
      'Cash-In Transaksyon: ${summary.cashInCount} (₱${summary.cashInVolume.toStringAsFixed(2)} volume)',
      'Cash-Out Transaksyon: ${summary.cashOutCount} (₱${summary.cashOutVolume.toStringAsFixed(2)} volume)',
      'Store GCash QR Payments: ${summary.storePaymentCount} (₱${summary.storePaymentVolume.toStringAsFixed(2)})',
    ];

    return AssistantResponse(
      intent: AssistantIntent.gcashProfit,
      title: 'Talaan ng Tubo sa GCash Ngayong Araw',
      answer: 'Kabuuang ₱${summary.totalFees.toStringAsFixed(2)} ang kinita sa convenience fee ng GCash ngayong araw:',
      bulletPoints: bullets,
      rawQuery: prompt,
    );
  }

  Future<AssistantResponse> _handleSupplierPayables(String prompt) async {
    final payables = await db.getUpcomingPayables(limit: 5);
    if (payables.isEmpty) {
      return AssistantResponse(
        intent: AssistantIntent.supplierPayables,
        title: 'Walang Utang sa Bodega ✅',
        answer: 'Walang nakabinbing bayarin sa mga delivery van o ahente.',
        rawQuery: prompt,
      );
    }

    final totalUnpaid = payables.fold(0.0, (sum, p) => sum + (p.totalAmount - p.paidAmount));
    final bullets = payables.map((p) {
      final rem = p.totalAmount - p.paidAmount;
      return '${p.supplierName}: ₱${rem.toStringAsFixed(2)} (Due: ${p.dueDate.month}/${p.dueDate.day}/${p.dueDate.year})';
    }).toList();

    return AssistantResponse(
      intent: AssistantIntent.supplierPayables,
      title: 'Mga Bayarin sa Bodega / Supplier',
      answer: 'May kabuuang ₱${totalUnpaid.toStringAsFixed(2)} na dapat bayaran sa darating na mga araw:',
      bulletPoints: bullets,
      rawQuery: prompt,
    );
  }

  Future<AssistantResponse> _handleGeneralHelp(String prompt) async {
    return AssistantResponse(
      intent: AssistantIntent.generalHelp,
      title: 'TindaGrid AI Assistant (100% Offline)',
      answer: 'Maaari mo akong tanungin sa Taglish o Ingles ukol sa iyong tindahan:',
      bulletPoints: const [
        '👥 "Sino may pinakamalaking utang?"',
        '📦 "Anong paninda ang paubos na ang stock?"',
        '💰 "Magkano ang benta at tubo ngayong araw?"',
        '📱 "Magkano kinita sa patong ng GCash?"',
        '🚚 "May bayarin ba tayo sa delivery van o bodega?"',
      ],
      rawQuery: prompt,
    );
  }

  Future<AssistantResponse> _handleUnknown(String prompt) async {
    return AssistantResponse(
      intent: AssistantIntent.unknown,
      title: 'Paumanhin, paki-linaw po ang tanong',
      answer: 'Maaari kang pumili sa mga quick suggestion sa ibaba o magtanong tungkol sa benta, utang, kulang na stock, o GCash fees.',
      bulletPoints: const [
        'Subukan: "Sino may utang?"',
        'Subukan: "Kulang na stock"',
        'Subukan: "Benta ngayon"',
        'Subukan: "Tubo sa GCash"',
      ],
      rawQuery: prompt,
    );
  }
}
