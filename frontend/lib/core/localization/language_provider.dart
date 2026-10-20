import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLanguage {
  taglish,
  english,
}

class AppStrings {
  final AppLanguage language;
  const AppStrings(this.language);

  bool get isTaglish => language == AppLanguage.taglish;

  // Global & Status
  String get appName => 'TindaGrid';
  String get offlineSafe => isTaglish ? 'Ligtas (Offline)' : 'Safe (Offline)';
  String get onlineSynced => isTaglish ? 'Naka-sync' : 'Cloud Synced';
  String get switchLang => isTaglish ? 'English' : 'Taglish';

  // Navigation
  String get navPos => isTaglish ? 'POS' : 'POS';
  String get navInventory => isTaglish ? 'Paninda' : 'Inventory';
  String get navDebts => isTaglish ? 'Utang' : 'Debts';
  String get navGcash => isTaglish ? 'GCash' : 'GCash';
  String get navSettings => isTaglish ? 'Settings' : 'Settings';

  // POS Screen
  String get searchPlaceholder =>
      isTaglish ? 'I-type ang paninda o barcode...' : 'Search product or barcode...';
  String get scanButton => 'SCAN';
  String get quickTingiTitle =>
      isTaglish ? 'MABILISANG TINGI (Walang Barcode — Pindutin Agad):' : 'QUICK TINGI (No Barcode — Quick Tap):';
  String get recentCartTitle =>
      isTaglish ? 'HULING NAIDAGDAG SA KART:' : 'RECENTLY ADDED TO CART:';
  String get cartLabel => isTaglish ? 'KART' : 'CART';
  String get itemsCountLabel => isTaglish ? 'Bagay' : 'Items';
  String get totalLabel => isTaglish ? 'KABUUAN' : 'TOTAL';
  String get checkoutButton => isTaglish ? 'BAYARAN / MANINGIL' : 'COLLECT / PAY';
  String get eachPrice => isTaglish ? 'bawat isa' : 'each';
  String get liveTicketTitle =>
      isTaglish ? 'KASALUKUYANG KART (Live Ticket)' : 'CURRENT CART (Live Ticket)';
  String get emptyCartPrompt =>
      isTaglish ? 'Walang laman ang kart. Pumili sa paninda.' : 'Cart is empty. Select products.';
  String get estProfit => isTaglish ? 'Tinatayang Tubo (Kita):' : 'Estimated Profit:';

  // Checkout Modal
  String get checkoutModalTitle => isTaglish ? 'Bayaran at Sukli' : 'Payment & Change';
  String get totalPayable => isTaglish ? 'KABUUANG BABAYARAN:' : 'TOTAL AMOUNT DUE:';
  String get cashTendered =>
      isTaglish ? 'PERANG INABOT NG MAMIMILI:' : 'CASH RECEIVED FROM CUSTOMER:';
  String get exactBill => isTaglish ? 'Eksakto' : 'Exact';
  String get customerChange =>
      isTaglish ? '🟢 SUKLI SA MAMIMILI:' : '🟢 CHANGE DUE TO CUSTOMER:';
  String get returnToCustomer => isTaglish ? 'Ibalik sa Tao' : 'Return to Customer';
  String get insufficientCash =>
      isTaglish ? '⚠️ KULANG PA NG PERA:' : '⚠️ INSUFFICIENT CASH:';
  String get completeSale =>
      isTaglish ? 'TAPOS NA ANG BENTA' : 'CONFIRM & COMPLETE SALE';
  String get saleRecorded =>
      isTaglish ? '✅ Benta naitala! Ligtas sa lokal database.' : '✅ Sale recorded! Saved to local database.';

  // Inventory Screen
  String get inventoryTitle => isTaglish ? 'Talaan ng mga Paninda' : 'Product Inventory';
  String get totalProducts => isTaglish ? 'Kabuuang Paninda' : 'Total Products';
  String get lowStockWarning => isTaglish ? 'Kulang sa Stock' : 'Low Stock Alert';
  String get addProduct => isTaglish ? 'Magdagdag ng Paninda' : 'Add Product';
  String get inStock => isTaglish ? 'piraso natitira' : 'items left';
  String get costPrice => isTaglish ? 'Puhunan' : 'Cost';
  String get sellingPrice => isTaglish ? 'Presyo' : 'Price';

  // Debts Screen
  String get debtsTitle => isTaglish ? 'Kwaderno ng Pautang' : 'Customer Debt Ledger';
  String get totalCollectibles => isTaglish ? 'Kabuuang Sisingilin' : 'Total Collectibles';
  String get activeDebtors => isTaglish ? 'Mga May Utang' : 'Active Borrowers';
  String get recordNewDebt => isTaglish ? 'Maglista ng Bagong Utang' : 'Record New Debt';
  String get dueDate => isTaglish ? 'Petsa ng Bayaran' : 'Due Date';
  String get settleDebt => isTaglish ? 'Maningil / Magbayad' : 'Settle Payment';

  // GCash Screen
  String get gcashTitle => isTaglish ? 'GCash Float & Transaksyon' : 'GCash Float & Ledger';
  String get ewalletFloat => isTaglish ? 'GCash E-Wallet Balance' : 'GCash E-Wallet Balance';
  String get cashBoxDrawer => isTaglish ? 'Pera sa Kahon (Cash Box)' : 'Cash Drawer (Physical Cash)';
  String get cashInAction => isTaglish ? 'Cash-In (Pasa Pera)' : 'Cash-In (Deposit/Send)';
  String get cashOutAction => isTaglish ? 'Cash-Out (Pera Palit)' : 'Cash-Out (Withdraw)';
  String get feeSchedule => isTaglish ? 'Talaan ng Patong (Fee Brackets)' : 'Fee Schedule';

  // Settings Screen
  String get settingsTitle => isTaglish ? 'Pag-aayos ng Tindahan' : 'Store Settings';
  String get themeSection => isTaglish ? 'Tema (Anyo ng Screen)' : 'Display Theme';
  String get themeLight => isTaglish ? 'Maliwanag' : 'Light';
  String get themeDark => isTaglish ? 'Madilim' : 'Dark';
  String get themeSystem => isTaglish ? 'System' : 'System';
  String get languageSection => isTaglish ? 'Piliin ang Wika' : 'Display Language';
  String get cloudBackupTitle => isTaglish ? 'Cloud Backup & Sync' : 'Cloud Backup & Sync';
  String get cloudBackupSubtitle => isTaglish
      ? 'Awtomatikong backup sa Neon Cloud tuwing may internet'
      : 'Automatic backup to Neon Cloud when online';
  String get syncNowButton => isTaglish ? 'I-sync Ngayon' : 'Sync Now';
  String get securitySection => isTaglish ? 'Seguridad at PIN' : 'Security & Store PIN';
  String get storeProfile => isTaglish ? 'Detalye ng Tindahan' : 'Store Profile';
  String get aboutTindaGrid =>
      isTaglish ? 'Tungkol sa TindaGrid' : 'About TindaGrid';
  String get systemStatusSubtitle => isTaglish
      ? '100% Offline-First | Walang Bayad Kada Buwan (\$0/mo)'
      : '100% Offline-First | \$0/mo Free Cloud Architecture';
}

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() => AppLanguage.taglish;

  void toggleLanguage() {
    state = state == AppLanguage.taglish ? AppLanguage.english : AppLanguage.taglish;
  }

  void setLanguage(AppLanguage language) {
    state = language;
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(() {
  return LanguageNotifier();
});

final stringsProvider = Provider<AppStrings>((ref) {
  final lang = ref.watch(languageProvider);
  return AppStrings(lang);
});
