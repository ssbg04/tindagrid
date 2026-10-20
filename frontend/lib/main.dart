import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/localization/language_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/responsive_layout.dart';
import 'core/utils/web_storage_helper.dart';
import 'features/debts/debts_screen.dart';
import 'features/gcash/gcash_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/settings/settings_screen.dart';

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

class TindaGridApp extends StatelessWidget {
  const TindaGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TindaGrid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      // Web is strictly POS counter terminal; Android/Mobile includes full navigation
      home: kIsWeb ? const PosDashboardScreen() : const MainNavigationShell(),
    );
  }
}

// ---------------------------------------------------------------------------
// Main Navigation Shell for Android / Mobile
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

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
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
    );
  }
}

// ---------------------------------------------------------------------------
// POS Dashboard Screen (All-Ages Touch-Driven Counter Interface)
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
  // Simple in-memory cart state for setup validation
  final List<CartItem> _cart = [
    CartItem(name: 'Coca-Cola Mismo 300ml', price: 20.0, quantity: 1),
    CartItem(name: 'SkyFlakes Crackers', price: 9.0, quantity: 2),
  ];

  double get _totalPrice =>
      _cart.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  int get _totalItems =>
      _cart.fold(0, (sum, item) => sum + item.quantity);

  void _addTingiItem(String name, double price, int qty) {
    setState(() {
      final index = _cart.indexWhere((item) => item.name == name);
      if (index >= 0) {
        _cart[index].quantity += qty;
      } else {
        _cart.add(CartItem(name: name, price: price, quantity: qty));
      }
    });
  }

  void _showCheckoutDialog(AppStrings tr) {
    double tendered = 100.0;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final sukli = tendered - _totalPrice;
            final isLight = Theme.of(context).brightness == Brightness.light;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : AppColors.surfaceDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr.checkoutModalTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr.totalPayable,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '₱ ${_totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: AppColors.primary,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      tr.cashTendered,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: sukli >= 0
                            ? AppColors.primaryLight
                            : AppColors.alertLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sukli >= 0
                              ? AppColors.primary
                              : AppColors.alert,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            sukli >= 0
                                ? tr.customerChange
                                : tr.insufficientCash,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: sukli >= 0
                                  ? AppColors.primary
                                  : AppColors.alert,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₱ ${sukli.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: sukli >= 0
                                  ? AppColors.primary
                                  : AppColors.alert,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: sukli < 0
                          ? null
                          : () {
                              setState(() => _cart.clear());
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(tr.saleRecorded),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                      child: Text(tr.completeSale),
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

  Widget _buildQuickBillChip(
    String label,
    double value,
    double selected,
    ValueChanged<double> onSelected,
  ) {
    final isSelected = (selected == value);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      selected: isSelected,
      selectedColor: AppColors.primary,
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

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Icon(Icons.storefront, color: AppColors.primary, size: 24),
        title: Text(
          tr.appName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // 1-Tap Language Switcher Button
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              ref.read(languageProvider.notifier).toggleLanguage();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currentLang == AppLanguage.taglish ? '🇵🇭' : '🇺🇸', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    currentLang == AppLanguage.taglish ? 'Taglish' : 'English',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Offline Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text(
                  tr.offlineSafe,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(tr),
        desktop: _buildDesktopLayout(tr),
      ),
      bottomNavigationBar: ResponsiveLayout.isDesktop(context)
          ? null
          : _buildMobileCartBottomBar(tr),
    );
  }

  // Mobile View
  Widget _buildMobileLayout(AppStrings tr) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(tr),
          const SizedBox(height: 20),
          _buildTingiGridHeader(tr),
          const SizedBox(height: 12),
          _buildTingiTiles(),
          const SizedBox(height: 24),
          _buildRecentCartList(tr),
        ],
      ),
    );
  }

  // Desktop View (Split-Screen 2-Column POS Station)
  Widget _buildDesktopLayout(AppStrings tr) {
    return Row(
      children: [
        // Left Column (Catalog & Fast Tingi Grid)
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSearchBar(tr),
                const SizedBox(height: 20),
                _buildTingiGridHeader(tr),
                const SizedBox(height: 12),
                _buildTingiTiles(),
              ],
            ),
          ),
        ),
        // Right Column (Sticky Live Ticket & Checkout Panel)
        Container(
          width: 340,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: const Border(
              left: BorderSide(color: AppColors.borderLight, width: 1.5),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '🛒 ${tr.liveTicketTitle}',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('$_totalItems ${tr.itemsCountLabel}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const Divider(height: 24),
              Expanded(child: _buildCartItemsList(tr)),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${tr.totalLabel}:', style: Theme.of(context).textTheme.titleMedium),
                  Flexible(
                    child: Text(
                      '₱ ${_totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cart.isEmpty ? null : () => _showCheckoutDialog(tr),
                icon: const Icon(Icons.point_of_sale, size: 24),
                label: Text(tr.checkoutButton),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(AppStrings tr) {
    return TextField(
      decoration: InputDecoration(
        hintText: tr.searchPlaceholder,
        prefixIcon: const Icon(Icons.search, size: 24),
        suffixIcon: IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(tr.isTaglish ? '📷 Binubuksan ang scanner...' : '📷 Opening camera scanner...'),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTingiGridHeader(AppStrings tr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            tr.quickTingiTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Text(
          '1-Tap Add',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTingiTiles() {
    final items = [
      {'emoji': '🥚', 'name': 'Itlog', 'price': 10.0},
      {'emoji': '🧊', 'name': 'Yelo', 'price': 5.0},
      {'emoji': '☕', 'name': 'Kopiko 78', 'price': 14.0},
      {'emoji': '🍬', 'name': 'Kendi', 'price': 2.0},
      {'emoji': '🍜', 'name': 'Pancit', 'price': 18.0},
      {'emoji': '🚬', 'name': 'Yosi', 'price': 10.0},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item['name'] as String;
        final price = item['price'] as double;
        final emoji = item['emoji'] as String;

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _addTingiItem(name, price, 1),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₱ ${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentCartList(AppStrings tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.recentCartTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildCartItemsList(tr),
      ],
    );
  }

  Widget _buildCartItemsList([AppStrings? tr]) {
    if (_cart.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            tr?.emptyCartPrompt ?? 'Walang laman ang kart.',
            style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _cart.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _cart[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            dense: true,
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${item.quantity}x @ ₱${item.price.toStringAsFixed(2)} ${tr?.eachPrice ?? ''}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₱ ${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.alert, size: 20),
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
        );
      },
    );
  }

  Widget _buildMobileCartBottomBar(AppStrings tr) {
    if (_cart.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
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
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₱ ${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _showCheckoutDialog(tr),
                child: Text(tr.checkoutButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartItem {
  final String name;
  final double price;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
  });
}
