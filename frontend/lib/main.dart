import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/localization/language_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/responsive_layout.dart';
import 'core/theme/theme_provider.dart';
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
      // Web is strictly POS counter terminal; Android/Mobile includes full navigation
      home: kIsWeb ? const PosDashboardScreen() : const MainNavigationShell(),
    );
  }
}

// ---------------------------------------------------------------------------
// Main Navigation Shell for Android / Mobile (Flat Styling)
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

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor, width: 1.0)),
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
// POS Dashboard Screen (All-Ages Touch-Driven Flat Counter Interface)
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
      elevation: 0,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final sukli = tendered - _totalPrice;
            final isLight = Theme.of(context).brightness == Brightness.light;
            final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isLight ? Colors.white : AppColors.surfaceDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(top: BorderSide(color: borderColor, width: 1.0)),
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
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 22),
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
                    const SizedBox(height: 18),
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: sukli >= 0
                            ? AppColors.primaryLight
                            : AppColors.alertLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sukli >= 0
                              ? AppColors.primary
                              : AppColors.alert,
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            sukli >= 0
                                ? tr.customerChange
                                : tr.insufficientCash,
                            style: TextStyle(
                              fontSize: 14,
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
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: sukli >= 0
                                  ? AppColors.primary
                                  : AppColors.alert,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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
      elevation: 0,
      pressElevation: 0,
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      selected: isSelected,
      selectedColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
    final isLight = Theme.of(context).brightness == Brightness.light;
    final borderColor = isLight ? AppColors.borderLight : AppColors.borderDark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const Icon(Icons.storefront, color: AppColors.primary, size: 24),
        title: Text(
          tr.appName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // 1-Tap Theme Switcher Button (Flat)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isLight ? AppColors.backgroundLight : Colors.white10,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Icon(
                isLight ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 16,
                color: isLight ? AppColors.textPrimaryLight : AppColors.textPrimaryDark,
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 1-Tap Language Switcher Button (Flat)
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              ref.read(languageProvider.notifier).toggleLanguage();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLight ? AppColors.primaryLight : AppColors.primaryDark.withAlpha(35),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withAlpha(60), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(currentLang == AppLanguage.taglish ? '🇵🇭' : '🇺🇸', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 4),
                  Text(
                    currentLang == AppLanguage.taglish ? 'Taglish' : 'English',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: isLight ? AppColors.primary : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Flat Offline Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: isLight ? AppColors.primaryLight : AppColors.primaryDark.withAlpha(35),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withAlpha(60), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: isLight ? AppColors.primary : AppColors.primaryDark, size: 13),
                const SizedBox(width: 4),
                Text(
                  tr.offlineSafe,
                  style: TextStyle(
                    color: isLight ? AppColors.primary : AppColors.primaryDark,
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
        mobile: _buildMobileLayout(tr, borderColor),
        desktop: _buildDesktopLayout(tr, borderColor),
      ),
      bottomNavigationBar: ResponsiveLayout.isDesktop(context)
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
          const SizedBox(height: 18),
          _buildTingiGridHeader(tr),
          const SizedBox(height: 10),
          _buildTingiTiles(borderColor),
          const SizedBox(height: 20),
          _buildRecentCartList(tr, borderColor),
        ],
      ),
    );
  }

  // Desktop View (Split-Screen 2-Column POS Station)
  Widget _buildDesktopLayout(AppStrings tr, Color borderColor) {
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
                _buildTingiTiles(borderColor),
              ],
            ),
          ),
        ),
        // Right Column (Sticky Flat Live Ticket & Checkout Panel)
        Container(
          width: 340,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              left: BorderSide(color: borderColor, width: 1.0),
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
              const SizedBox(height: 12),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 12),
              Expanded(child: _buildCartItemsList(tr, borderColor)),
              const SizedBox(height: 12),
              Divider(color: borderColor, height: 1),
              const SizedBox(height: 12),
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
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _cart.isEmpty ? null : () => _showCheckoutDialog(tr),
                icon: const Icon(Icons.point_of_sale, size: 20),
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
        prefixIcon: const Icon(Icons.search, size: 22),
        suffixIcon: IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 22),
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
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTingiTiles(Color borderColor) {
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item['name'] as String;
        final price = item['price'] as double;
        final emoji = item['emoji'] as String;

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: borderColor, width: 1.0),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _addTingiItem(name, price, 1),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '₱ ${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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

  Widget _buildRecentCartList(AppStrings tr, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.recentCartTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildCartItemsList(tr, borderColor),
      ],
    );
  }

  Widget _buildCartItemsList([AppStrings? tr, Color? borderColor]) {
    final border = borderColor ?? AppColors.borderLight;

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
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = _cart[index];
        return Card(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: border, width: 1.0),
          ),
          child: ListTile(
            dense: true,
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: Text(
              '${item.quantity}x @ ₱${item.price.toStringAsFixed(2)} ${tr?.eachPrice ?? ''}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₱ ${(item.price * item.quantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.alert, size: 18),
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

  Widget _buildMobileCartBottomBar(AppStrings tr, Color borderColor) {
    if (_cart.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: borderColor, width: 1.0)),
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
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₱ ${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
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
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _showCheckoutDialog(tr),
                child: Text(tr.checkoutButton, style: const TextStyle(fontSize: 14)),
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
