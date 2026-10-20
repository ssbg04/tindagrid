import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants/app_colors.dart';
import 'core/database/app_database.dart';
import 'core/localization/language_provider.dart';
import 'core/sync/sync_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/responsive_layout.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/feedback_helper.dart';
import 'core/utils/web_storage_helper.dart';
import 'features/debts/debts_screen.dart';
import 'features/gcash/gcash_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/pos/scanner_screen.dart';
import 'features/pos/companion_scanner_dialog.dart';
import 'features/pos/webcam_scanner_dialog.dart';
import 'features/settings/settings_screen.dart';
import 'core/catalog/catalog_client.dart';
import 'core/sync/companion_scanner_service.dart';
import 'core/utils/barcode_keyboard_listener.dart';
import 'features/inventory/quick_add_product_dialog.dart';
import 'features/pos/tingi_visual_grid.dart';
import 'features/assistant/assistant_drawer.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Storage Eviction Defense for Web PWA
  await WebStorageHelper.requestPersistentStorage();

  runApp(
    const ProviderScope(
      child: TindaGridApp(),
    ),
  );
}

class TindaGridApp extends ConsumerWidget {
  const TindaGridApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'TindaGrid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Full multi-screen navigation shell for both Web & Mobile
      home: const MainNavigationShell(),
    );
  }
}

// ---------------------------------------------------------------------------
// Main Navigation Shell (Responsive: NavigationRail on Web/Desktop, NavigationBar on Mobile)
// ---------------------------------------------------------------------------

class MainNavigationShell extends ConsumerStatefulWidget {
  const MainNavigationShell({super.key});

  @override
  ConsumerState<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends ConsumerState<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    PosDashboardScreen(isEmbeddedInNav: true),
    InventoryScreen(),
    DebtsScreen(),
    GcashScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(stringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;
    final useRail = ResponsiveLayout.useNavigationRail(context);
    final isShortScreen = ResponsiveLayout.isShortLandscape(context) || MediaQuery.of(context).size.height < 520;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            // Left Navigation Rail for Web / Desktop / Landscape Phone & Tablet
            NavigationRail(
              backgroundColor: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              labelType: isShortScreen ? NavigationRailLabelType.none : NavigationRailLabelType.all,
              minWidth: isShortScreen ? 60 : 78,
              leading: Padding(
                padding: EdgeInsets.symmetric(vertical: isShortScreen ? 8 : 14),
                child: isShortScreen
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                      )
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TindaGrid',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: Tooltip(
                    message: tr.navPos,
                    child: const Icon(Icons.point_of_sale_outlined),
                  ),
                  selectedIcon: Tooltip(
                    message: tr.navPos,
                    child: const Icon(Icons.point_of_sale_rounded, color: AppColors.primary),
                  ),
                  label: Text(tr.navPos, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                NavigationRailDestination(
                  icon: Tooltip(
                    message: tr.navInventory,
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
                  selectedIcon: Tooltip(
                    message: tr.navInventory,
                    child: const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
                  ),
                  label: Text(tr.navInventory, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                NavigationRailDestination(
                  icon: Tooltip(
                    message: tr.navDebts,
                    child: const Icon(Icons.menu_book_outlined),
                  ),
                  selectedIcon: Tooltip(
                    message: tr.navDebts,
                    child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                  ),
                  label: Text(tr.navDebts, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                NavigationRailDestination(
                  icon: Tooltip(
                    message: tr.navGcash,
                    child: const Icon(Icons.payments_outlined),
                  ),
                  selectedIcon: Tooltip(
                    message: tr.navGcash,
                    child: const Icon(Icons.payments_rounded, color: AppColors.primary),
                  ),
                  label: Text(tr.navGcash, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                NavigationRailDestination(
                  icon: Tooltip(
                    message: tr.navSettings,
                    child: const Icon(Icons.settings_outlined),
                  ),
                  selectedIcon: Tooltip(
                    message: tr.navSettings,
                    child: const Icon(Icons.settings_rounded, color: AppColors.primary),
                  ),
                  label: Text(tr.navSettings, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
              trailing: Padding(
                padding: EdgeInsets.symmetric(vertical: isShortScreen ? 6 : 14),
                child: IconButton(
                  onPressed: () => AssistantDrawer.show(context),
                  icon: const Icon(Icons.auto_awesome_rounded, color: Colors.purple, size: 22),
                  tooltip: 'TindaBot Offline AI',
                ),
              ),
            ),
            VerticalDivider(width: 1, thickness: 1, color: borderColor),
            // Active Screen Content
            Expanded(
              child: _screens[_currentIndex],
            ),
          ],
        ),
      );
    }

    // Mobile View: Bottom Navigation Bar + FAB
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => AssistantDrawer.show(context),
        backgroundColor: Colors.purple.shade700,
        tooltip: 'TindaBot Offline AI',
        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
          border: Border(top: BorderSide(color: borderColor, width: 1.0)),
          boxShadow: [
            BoxShadow(
              color: isLight ? const Color(0x060F172A) : const Color(0x1F000000),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.point_of_sale_outlined),
              selectedIcon: const Icon(Icons.point_of_sale_rounded, color: AppColors.primary),
              label: tr.navPos,
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined),
              selectedIcon: const Icon(Icons.inventory_2_rounded, color: AppColors.primary),
              label: tr.navInventory,
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_book_outlined),
              selectedIcon: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
              label: tr.navDebts,
            ),
            NavigationDestination(
              icon: const Icon(Icons.payments_outlined),
              selectedIcon: const Icon(Icons.payments_rounded, color: AppColors.primary),
              label: tr.navGcash,
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded, color: AppColors.primary),
              label: tr.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// POS Dashboard Screen (All-Ages Soft UI Counter Interface)
// ---------------------------------------------------------------------------

class PosDashboardScreen extends ConsumerStatefulWidget {
  final bool isEmbeddedInNav;

  const PosDashboardScreen({
    super.key,
    this.isEmbeddedInNav = false,
  });

  @override
  ConsumerState<PosDashboardScreen> createState() => _PosDashboardScreenState();
}

class _PosDashboardScreenState extends ConsumerState<PosDashboardScreen> {
  // Simple in-memory cart state with real-time profit tracking
  final List<CartItem> _cart = [
    CartItem(name: 'Coca-Cola Mismo 300ml', price: 20.0, costPrice: 16.0, quantity: 1),
    CartItem(name: 'SkyFlakes Crackers', price: 9.0, costPrice: 7.0, quantity: 2),
  ];

  // Hardware Scanner & Companion Services
  late final BarcodeKeyboardListener _hardwareKeyboardListener;
  final CompanionScannerService _companionService = CompanionScannerService();
  final CatalogClient _catalogClient = CatalogClient();

  // Instant Predictive Search & 2-Digit PLU State
  final TextEditingController _searchController = TextEditingController();
  List<Product> _predictiveSearchResults = [];
  ({String name, double price})? _matchedPlu;

  static const Map<String, ({String name, double price})> _pluShortcuts = {
    '01': (name: 'Itlog (Fresh Egg)', price: 10.0),
    '02': (name: 'Yelo (Tube Ice)', price: 5.0),
    '03': (name: 'Kopiko 78 / Black 3in1', price: 14.0),
    '04': (name: 'Lucky Me Pancit Canton', price: 18.0),
    '05': (name: 'Bear Brand Fortified 33g', price: 15.0),
    '06': (name: 'Datu Puti Vinegar Sachet', price: 6.0),
    '07': (name: 'Silver Swan Soy Sauce', price: 6.0),
    '08': (name: 'Alaska Evaporada 250ml', price: 32.0),
    '09': (name: 'Lucky Me Beef / Chicken', price: 16.0),
    '10': (name: 'Marlboro Red (1 stick)', price: 10.0),
  };

  @override
  void initState() {
    super.initState();
    // Start listening to USB/Wireless handheld barcode scanner guns
    _hardwareKeyboardListener = BarcodeKeyboardListener(
      onBarcodeScanned: (barcode) {
        final tr = AppStrings(ref.read(languageProvider));
        _handleBarcodeDetected(barcode, tr);
      },
    );
    _hardwareKeyboardListener.start();

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _hardwareKeyboardListener.stop();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      if (mounted) {
        setState(() {
          _predictiveSearchResults = [];
          _matchedPlu = null;
        });
      }
      return;
    }

    // 1. Check for 2-digit PLU shortcut
    if (query.length == 2 && _pluShortcuts.containsKey(query)) {
      setState(() => _matchedPlu = _pluShortcuts[query]);
    } else {
      if (_matchedPlu != null) {
        setState(() => _matchedPlu = null);
      }
    }

    // 2. Query instant predictive search
    if (query.length >= 2) {
      final db = ref.read(databaseProvider);
      final results = await db.searchProducts(query);
      if (mounted) {
        setState(() => _predictiveSearchResults = results);
      }
    } else {
      if (_predictiveSearchResults.isNotEmpty) {
        setState(() => _predictiveSearchResults = []);
      }
    }
  }

  double get _totalPrice =>
      _cart.fold(0.0, (sum, item) => sum + item.subtotal);

  double get _totalProfit =>
      _cart.fold(0.0, (sum, item) => sum + item.profit);

  int get _totalItems =>
      _cart.fold(0, (sum, item) => sum + item.quantity);

  void _addTingiItem(
    String name,
    double price,
    int qty, {
    String? productId,
    double? costPrice,
  }) {
    setState(() {
      final index = _cart.indexWhere((item) => item.name == name);
      if (index >= 0) {
        _cart[index].quantity += qty;
      } else {
        _cart.add(CartItem(
          productId: productId,
          name: name,
          price: price,
          costPrice: costPrice ?? (price * 0.8),
          quantity: qty,
        ));
      }
    });
  }

  Future<void> _handleBarcodeDetected(String scannedCode, AppStrings tr) async {
    final db = ref.read(databaseProvider);
    final product = await db.getProductByBarcode(scannedCode);

    if (product != null) {
      _addTingiItem(
        product.name,
        product.sellingPrice,
        1,
        productId: product.id,
        costPrice: product.costPrice,
      );
      await FeedbackHelper.triggerSuccessFeedback();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr.isTaglish
                  ? '✅ Naidagdag sa Kart: ${product.name} (₱${product.sellingPrice.toStringAsFixed(2)})'
                  : '✅ Added to Cart: ${product.name} (₱${product.sellingPrice.toStringAsFixed(2)})',
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // 1. Trigger warning feedback
      await FeedbackHelper.triggerFailureFeedback();

      // 2. Query Crowdsourced NestJS / Master Philippine Catalog API
      final catalogMatch = await _catalogClient.lookupBarcode(scannedCode);

      if (mounted) {
        // 3. Auto-open "Quick-Add Product" Modal with pre-filled barcode & crowdsourced data
        showDialog(
          context: context,
          builder: (_) => QuickAddProductDialog(
            barcode: scannedCode,
            initialMatch: catalogMatch,
            isTaglish: tr.isTaglish,
            onProductSaved: (newProduct) {
              _addTingiItem(
                newProduct.name,
                newProduct.sellingPrice,
                1,
                productId: newProduct.id,
                costPrice: newProduct.costPrice,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      tr.isTaglish
                          ? '🎉 Narehistro at naidagdag sa Kart: ${newProduct.name}'
                          : '🎉 Registered & added to Cart: ${newProduct.name}',
                    ),
                    backgroundColor: AppColors.primary,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        );
      }
    }
  }

  Future<void> _openScanner(AppStrings tr) async {
    if (kIsWeb) {
      _openWebcamScanner(tr);
      return;
    }

    final scannedCode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null && mounted) {
      await _handleBarcodeDetected(scannedCode, tr);
    }
  }

  void _openCompanionScanner(AppStrings tr) {
    showDialog(
      context: context,
      builder: (_) => CompanionScannerDialog(
        service: _companionService,
        isTaglish: tr.isTaglish,
        onBarcodeReceived: (code) => _handleBarcodeDetected(code, tr),
      ),
    );
  }

  void _openWebcamScanner(AppStrings tr) {
    showDialog(
      context: context,
      builder: (_) => WebcamScannerDialog(
        isTaglish: tr.isTaglish,
        onBarcodeScanned: (code) => _handleBarcodeDetected(code, tr),
        onOpenCompanionMode: () => _openCompanionScanner(tr),
      ),
    );
  }

  void _showCheckoutDialog(AppStrings tr) {
    double tendered = _totalPrice > 0 ? _totalPrice : 100.0;
    String paymentMethod = 'CASH'; // 'CASH' or 'GCASH'
    final gcashRefController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final sukli = tendered - _totalPrice;
            final isLight = Theme.of(context).brightness == Brightness.light;
            final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

            final maxHeight = MediaQuery.of(context).size.height * 0.92;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isLight ? Colors.white : AppColors.surfaceDark,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border(top: BorderSide(color: borderColor, width: 1.0)),
                    boxShadow: isLight ? AppColors.softShadowLight : AppColors.softShadowDark,
                  ),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr.checkoutModalTitle,
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Dual Payment Selector (Cash vs GCash)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() {
                              paymentMethod = 'CASH';
                            }),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: paymentMethod == 'CASH'
                                    ? AppColors.primary
                                    : Colors.grey.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.payments_rounded,
                                    color: paymentMethod == 'CASH' ? Colors.white : Colors.grey.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '💵 Cash',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      color: paymentMethod == 'CASH' ? Colors.white : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() {
                              paymentMethod = 'GCASH';
                              tendered = _totalPrice;
                            }),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: paymentMethod == 'GCASH'
                                    ? const Color(0xFF007DFE)
                                    : Colors.grey.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: paymentMethod == 'GCASH' ? Colors.white : Colors.grey.shade700,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '📱 GCash',
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w700,
                                      color: paymentMethod == 'GCASH' ? Colors.white : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Total Payable and Estimated Profit
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr.totalPayable,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                              ),
                            ),
                            Text(
                              '₱ ${_totalPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '✨ Tubo: ₱${_totalProfit.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w700,
                              color: Colors.green.shade800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Cash Mode: Tendered Chips & Auto Change
                    if (paymentMethod == 'CASH') ...[
                      Text(
                        tr.cashTendered,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isLight ? AppColors.textSecondaryLight : AppColors.textSecondaryDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildQuickBillChip(tr.exactBill, _totalPrice, tendered, (val) {
                            setModalState(() => tendered = val);
                          }),
                          _buildQuickBillChip('₱50', 50.0, tendered, (val) {
                            setModalState(() => tendered = val);
                          }),
                          _buildQuickBillChip('₱100', 100.0, tendered, (val) {
                            setModalState(() => tendered = val);
                          }),
                          _buildQuickBillChip('₱200', 200.0, tendered, (val) {
                            setModalState(() => tendered = val);
                          }),
                          _buildQuickBillChip('₱500', 500.0, tendered, (val) {
                            setModalState(() => tendered = val);
                          }),
                          _buildQuickBillChip('₱1,000', 1000.0, tendered, (val) {
                            setModalState(() => tendered = val);
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: sukli >= 0
                              ? AppColors.primaryLight.withAlpha(200)
                              : AppColors.alertLight.withAlpha(200),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: sukli >= 0
                                ? AppColors.primary.withAlpha(120)
                                : AppColors.alert.withAlpha(120),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              sukli >= 0
                                  ? tr.customerChange
                                  : tr.insufficientCash,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: sukli >= 0
                                    ? AppColors.primary
                                    : AppColors.alert,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₱ ${sukli.abs().toStringAsFixed(2)}',
                              style: GoogleFonts.outfit(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: sukli >= 0
                                    ? AppColors.primary
                                    : AppColors.alert,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // GCash Mode
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007DFE).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF007DFE).withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.qr_code_2_rounded, color: Color(0xFF007DFE), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  tr.isTaglish ? 'GCash E-Wallet Payment' : 'GCash E-Wallet Payment',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: const Color(0xFF007DFE),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              tr.isTaglish
                                  ? 'I-scan ng customer ang Tindahan QR o i-send sa GCash. Eksaktong ₱${_totalPrice.toStringAsFixed(2)} ang papasok sa e-wallet.'
                                  : 'Customer scans Store GCash QR. Exactly ₱${_totalPrice.toStringAsFixed(2)} arrives in e-wallet.',
                              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: gcashRefController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: tr.isTaglish ? 'GCash Reference No. (Optional)' : 'GCash Reference No. (Optional)',
                                hintText: 'hal. 1004 8492 1849',
                                prefixIcon: const Icon(Icons.tag_rounded, size: 18),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Complete Sale Button with Atomic Persistence
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: paymentMethod == 'GCASH' ? const Color(0xFF007DFE) : AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (paymentMethod == 'CASH' && sukli < 0)
                          ? null
                          : () async {
                              final db = ref.read(databaseProvider);
                              final saleItems = _cart.map((item) {
                                return SaleItemsCompanion(
                                  id: drift.Value(const Uuid().v4()),
                                  saleId: const drift.Value(''),
                                  productId: drift.Value(item.productId ?? 'tingi-${item.name.hashCode}'),
                                  productName: drift.Value(item.name),
                                  quantity: drift.Value(item.quantity.toDouble()),
                                  costPrice: drift.Value(item.costPrice),
                                  unitPrice: drift.Value(item.price),
                                  subtotal: drift.Value(item.subtotal),
                                  profit: drift.Value(item.profit),
                                );
                              }).toList();

                              final saleId = await db.recordSale(
                                paymentMethod: paymentMethod,
                                totalAmount: _totalPrice,
                                amountReceived: paymentMethod == 'CASH' ? tendered : _totalPrice,
                                sukliAmount: paymentMethod == 'CASH' ? sukli : 0.0,
                                items: saleItems,
                              );

                              if (paymentMethod == 'GCASH') {
                                final refNo = gcashRefController.text.trim();
                                await db.recordGcash(
                                  transactionType: 'STORE_PAYMENT',
                                  amount: _totalPrice,
                                  feeCharged: 0.0,
                                  referenceNumber: refNo.isEmpty ? null : refNo,
                                  notes: 'POS Sale #$saleId',
                                );
                              }

                              await FeedbackHelper.triggerSuccessFeedback();
                              setState(() => _cart.clear());

                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tr.isTaglish
                                          ? '✅ Benta naitala! Ligtas sa lokal database ($paymentMethod).'
                                          : '✅ Sale recorded! Saved to local database ($paymentMethod).',
                                    ),
                                    backgroundColor: AppColors.primary,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            },
                      child: Text(tr.completeSale),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
          },
        );
      },
    );
  }

  Widget _buildQuickBillChip(
    String label,
    double value,
    double selected,
    ValueChanged<double> onSelected,
  ) {
    final isSelected = (selected == value);
    return ChoiceChip(
      elevation: 0,
      pressElevation: 0,
      label: Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimaryLight,
      ),
      onSelected: (_) => onSelected(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(stringsProvider);
    final currentLang = ref.watch(languageProvider);
    final syncState = ref.watch(syncProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leadingWidth: 36,
        leading: const Padding(
          padding: EdgeInsets.only(left: 6),
          child: Icon(Icons.storefront_rounded, color: AppColors.primary, size: 22),
        ),
        title: Text(
          tr.appName,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3),
        ),
        actions: [
          // 1-Tap Theme Switcher Button (Soft Pill)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isLight ? AppColors.surfaceMutedLight : AppColors.surfaceMutedDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Icon(
                isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 16,
                color: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
              ),
            ),
          ),
          const SizedBox(width: 5),

          // 1-Tap Language Switcher Button (Soft Pill)
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              ref.read(languageProvider.notifier).toggleLanguage();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: isLight ? AppColors.primaryLight : AppColors.primaryDark.withAlpha(35),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withAlpha(50), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currentLang == AppLanguage.taglish ? '🇵🇭' : '🇺🇸', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    currentLang == AppLanguage.taglish ? 'Taglish' : 'English',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: isLight ? AppColors.primary : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),

          // Interactive Soft Cloud Sync Badge & Button
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: syncState.isSyncing
                ? null
                : () async {
                    final scaffold = ScaffoldMessenger.of(context);
                    try {
                      final success = await ref.read(syncProvider.notifier).syncNow();
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? (tr.isTaglish ? '☁️ Naka-sync sa Neon Cloud!' : '☁️ Cloud Sync Complete!')
                                : (tr.isTaglish ? 'Naka-offline. Ligtas ang lahat sa lokal SQLite.' : 'Offline. All data safely saved locally.'),
                          ),
                          backgroundColor: success ? AppColors.primary : Colors.amber.shade800,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    } catch (e) {
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text('Sync Error: $e'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              decoration: BoxDecoration(
                color: syncState.isSyncing
                    ? AppColors.primaryLight.withValues(alpha: 0.5)
                    : (syncState.pendingCount > 0
                        ? Colors.amber.withValues(alpha: 0.2)
                        : (isLight ? AppColors.primaryLight : AppColors.primaryDark.withAlpha(35))),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: syncState.pendingCount > 0
                      ? Colors.amber.shade700.withValues(alpha: 0.5)
                      : AppColors.primary.withAlpha(50),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (syncState.isSyncing)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.8, color: AppColors.primary),
                    )
                  else if (syncState.pendingCount > 0)
                    Icon(Icons.cloud_upload_rounded, color: Colors.amber.shade900, size: 13)
                  else
                    Icon(Icons.cloud_done_rounded, color: isLight ? AppColors.primary : AppColors.primaryDark, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    syncState.isSyncing
                        ? (tr.isTaglish ? 'Nagsi-sync...' : 'Syncing...')
                        : (syncState.pendingCount > 0
                            ? '${syncState.pendingCount} ${tr.isTaglish ? "bago" : "pending"}'
                            : (tr.isTaglish ? 'Naka-sync' : 'Synced')),
                    style: GoogleFonts.inter(
                      color: syncState.pendingCount > 0
                          ? Colors.amber.shade900
                          : (isLight ? AppColors.primary : AppColors.primaryDark),
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 5),

          // TindaBot Offline AI Assistant Button
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => AssistantDrawer.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.purple.withAlpha(60), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.purple, size: 14),
                  if (screenWidth >= 440) ...[
                    const SizedBox(width: 4),
                    Text(
                      'AI Bot',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(tr, borderColor),
        desktop: _buildDesktopLayout(tr, borderColor),
      ),
      bottomNavigationBar: ResponsiveLayout.showTwoPaneStation(context)
          ? null
          : _buildMobileCartBottomBar(tr, borderColor),
    );
  }

  // Mobile View
  Widget _buildMobileLayout(AppStrings tr, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(tr),
          if (_matchedPlu != null || _predictiveSearchResults.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildPredictiveSuggestions(tr),
          ],
          const SizedBox(height: 18),
          TingiVisualGrid(
            isTaglish: tr.isTaglish,
            onAddTingi: (name, price, qty) => _addTingiItem(name, price, qty),
          ),
          const SizedBox(height: 22),
          _buildRecentCartList(tr),
          SizedBox(height: _cart.isEmpty ? 16 : 84),
        ],
      ),
    );
  }

  // Desktop & Landscape 2-Column POS Station with Soft UI
  Widget _buildDesktopLayout(AppStrings tr, Color borderColor) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isShort = constraints.maxHeight < 520;
        final cartWidth = (constraints.maxWidth * 0.36).clamp(250.0, 350.0);
        final contentPadding = isShort ? 12.0 : 20.0;
        final cartPadding = isShort ? 12.0 : 18.0;

        return Row(
          children: [
            // Left Column (Catalog & Fast Tingi Grid)
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(contentPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSearchBar(tr),
                    if (_matchedPlu != null || _predictiveSearchResults.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildPredictiveSuggestions(tr),
                    ],
                    SizedBox(height: isShort ? 12 : 20),
                    TingiVisualGrid(
                      isTaglish: tr.isTaglish,
                      onAddTingi: (name, price, qty) => _addTingiItem(name, price, qty),
                    ),
                  ],
                ),
              ),
            ),
            // Right Column (Sticky Soft Live Ticket & Checkout Panel)
            Container(
              width: cartWidth,
              decoration: BoxDecoration(
                color: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
                border: Border(
                  left: BorderSide(color: borderColor, width: 1.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isLight ? const Color(0x060F172A) : const Color(0x1F000000),
                    blurRadius: 12,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              padding: EdgeInsets.all(cartPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '🛒 ${tr.liveTicketTitle}',
                          style: GoogleFonts.outfit(
                            fontSize: isShort ? 14 : 16,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$_totalItems ${tr.itemsCountLabel}',
                        style: GoogleFonts.inter(
                          fontSize: isShort ? 12 : 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isShort ? 8 : 12),
                  Divider(color: borderColor, height: 1),
                  SizedBox(height: isShort ? 8 : 12),
                  Expanded(
                    child: _buildCartItemsList(tr, true),
                  ),
                  SizedBox(height: isShort ? 8 : 12),
                  Divider(color: borderColor, height: 1),
                  SizedBox(height: isShort ? 8 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${tr.totalLabel}:',
                        style: GoogleFonts.inter(
                          fontSize: isShort ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '₱ ${_totalPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: isShort ? 20 : 24,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isShort ? 10 : 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: isShort ? 10 : 14),
                    ),
                    onPressed: _cart.isEmpty ? null : () => _showCheckoutDialog(tr),
                    icon: const Icon(Icons.point_of_sale_rounded, size: 20),
                    label: Text(
                      tr.checkoutButton,
                      style: GoogleFonts.outfit(
                        fontSize: isShort ? 13 : 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(AppStrings tr) {
    final hasText = _searchController.text.isNotEmpty;

    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: tr.isTaglish
            ? 'Maghanap, i-scan, o mag-type ng 2-digit PLU (hal. 01)...'
            : 'Search items, scan barcode, or type 2-digit PLU (e.g. 01)...',
        prefixIcon: const Icon(Icons.search_rounded, size: 22),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasText)
              IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () {
                  _searchController.clear();
                },
              ),
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 22),
              tooltip: tr.isTaglish ? 'Camera / Webcam Scanner' : 'Camera / Webcam Scanner',
              onPressed: () => _openScanner(tr),
            ),
            IconButton(
              icon: const Icon(Icons.phonelink_ring_rounded, color: AppColors.primary, size: 20),
              tooltip: tr.isTaglish ? 'I-pair ang Smartphone' : 'Pair Smartphone Scanner',
              onPressed: () => _openCompanionScanner(tr),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
      onSubmitted: (val) async {
        final query = val.trim();
        if (query.isEmpty) return;

        if (_matchedPlu != null) {
          _addTingiItem(_matchedPlu!.name, _matchedPlu!.price, 1);
          await FeedbackHelper.triggerSuccessFeedback();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  tr.isTaglish
                      ? '⚡ PLU Shortcut: ${_matchedPlu!.name} (₱${_matchedPlu!.price.toStringAsFixed(2)})'
                      : '⚡ PLU Shortcut: ${_matchedPlu!.name} (₱${_matchedPlu!.price.toStringAsFixed(2)})',
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          _searchController.clear();
        } else if (_predictiveSearchResults.isNotEmpty) {
          final top = _predictiveSearchResults.first;
          _addTingiItem(top.name, top.sellingPrice, 1);
          await FeedbackHelper.triggerSuccessFeedback();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  tr.isTaglish
                      ? '✅ Naidagdag: ${top.name} (₱${top.sellingPrice.toStringAsFixed(2)})'
                      : '✅ Added: ${top.name} (₱${top.sellingPrice.toStringAsFixed(2)})',
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          _searchController.clear();
        } else {
          await _handleBarcodeDetected(query, tr);
          _searchController.clear();
        }
      },
    );
  }

  Widget _buildPredictiveSuggestions(AppStrings tr) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. PLU Shortcut Highlight
          if (_matchedPlu != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚡ PLU ${_searchController.text}: ${_matchedPlu!.name} — ₱${_matchedPlu!.price.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        color: Colors.brown.shade900,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      _addTingiItem(_matchedPlu!.name, _matchedPlu!.price, 1);
                      FeedbackHelper.triggerSuccessFeedback();
                      _searchController.clear();
                    },
                    child: Text(tr.isTaglish ? '+ Idagdag (Enter)' : '+ Add (Enter)'),
                  ),
                ],
              ),
            ),
            if (_predictiveSearchResults.isNotEmpty) const SizedBox(height: 8),
          ],

          // 2. Predictive Database Matches
          if (_predictiveSearchResults.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Text(
                tr.isTaglish ? 'Mungkahing Paninda (Hit Enter):' : 'Suggested Items (Hit Enter):',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _predictiveSearchResults.length > 3 ? 3 : _predictiveSearchResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = _predictiveSearchResults[i];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  leading: const Icon(Icons.inventory_2_rounded, color: AppColors.primary, size: 20),
                  title: Text(
                    p.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    '${p.category} • Stock: ${p.currentStock.toInt()}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₱${p.sellingPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
                        onPressed: () {
                          _addTingiItem(p.name, p.sellingPrice, 1);
                          FeedbackHelper.triggerSuccessFeedback();
                          _searchController.clear();
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    _addTingiItem(p.name, p.sellingPrice, 1);
                    FeedbackHelper.triggerSuccessFeedback();
                    _searchController.clear();
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }



  Widget _buildRecentCartList(AppStrings tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.recentCartTitle,
          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _buildCartItemsList(tr),
      ],
    );
  }

  Widget _buildCartItemsList([AppStrings? tr, bool isScrollable = false]) {
    if (_cart.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            tr?.emptyCartPrompt ?? 'Walang laman ang kart.',
            style: GoogleFonts.inter(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: !isScrollable,
      physics: isScrollable ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
      itemCount: _cart.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _cart[index];
        return Container(
          decoration: SoftDecorations.card(context, radius: 12),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              title: Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              subtitle: Text(
                '${item.quantity}x @ ₱${item.price.toStringAsFixed(2)} ${tr?.eachPrice ?? ''}',
                style: GoogleFonts.inter(fontSize: 11),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₱ ${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.alert, size: 18),
                    onPressed: () {
                      setState(() {
                        if (item.quantity > 1) {
                          item.quantity--;
                        } else {
                          _cart.removeAt(index);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileCartBottomBar(AppStrings tr, Color borderColor) {
    if (_cart.isEmpty) return const SizedBox.shrink();

    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLight ? AppColors.surfaceLight : AppColors.surfaceDark,
        border: Border(top: BorderSide(color: borderColor, width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: isLight ? const Color(0x0A0F172A) : const Color(0x28000000),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_totalItems ${tr.itemsCountLabel} sa ${tr.cartLabel.toLowerCase()}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₱ ${_totalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showCheckoutDialog(tr),
                child: Text(tr.checkoutButton, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItem {
  final String? productId;
  final String name;
  final double price;
  final double costPrice;
  int quantity;

  CartItem({
    this.productId,
    required this.name,
    required this.price,
    this.costPrice = 0.0,
    required this.quantity,
  });

  double get subtotal => price * quantity;
  double get profit => (price - costPrice) * quantity;
}
