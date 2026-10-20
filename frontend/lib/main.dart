import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/responsive_layout.dart';
import 'core/utils/web_storage_helper.dart';

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
      home: const PosDashboardScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// POS Demo Dashboard (All-Ages Touch-Driven Interface)
// ---------------------------------------------------------------------------

class PosDashboardScreen extends ConsumerStatefulWidget {
  const PosDashboardScreen({super.key});

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

  void _showCheckoutDialog() {
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
                          'Bayaran at Sukli',
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
                      'KABUUANG BABAYARAN:',
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
                      'PERANG INABOT NG MAMIMILI:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildQuickBillChip('Eksakto', _totalPrice, tendered, (val) {
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
                                ? '🟢 SUKLI SA MAMIMILI:'
                                : '⚠️ KULANG PA NG PERA:',
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
                                const SnackBar(
                                  content: Text('✅ Benta naitala! Ligtas sa lokal database.'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                      child: const Text('TAPOS NA ANG BENTA'),
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.storefront, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Text(
              'TindaGrid',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                SizedBox(width: 4),
                Text(
                  'Ligtas (Offline)',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
      bottomNavigationBar: ResponsiveLayout.isDesktop(context)
          ? null
          : _buildMobileCartBottomBar(),
    );
  }

  // Mobile View
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          _buildTingiGridHeader(),
          const SizedBox(height: 12),
          _buildTingiTiles(),
          const SizedBox(height: 24),
          _buildRecentCartList(),
        ],
      ),
    );
  }

  // Desktop View (Split-Screen 2-Column POS Station)
  Widget _buildDesktopLayout() {
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
                _buildSearchBar(),
                const SizedBox(height: 20),
                _buildTingiGridHeader(),
                const SizedBox(height: 12),
                _buildTingiTiles(),
              ],
            ),
          ),
        ),
        // Right Column (Sticky Live Ticket & Checkout Panel)
        Container(
          width: 320,
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
                      '🛒 Kasalukuyang Kart',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('$_totalItems item',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const Divider(height: 24),
              Expanded(child: _buildCartItemsList()),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('KABUUAN:', style: Theme.of(context).textTheme.titleMedium),
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
                onPressed: _cart.isEmpty ? null : _showCheckoutDialog,
                icon: const Icon(Icons.point_of_sale, size: 24),
                label: const Text('BAYARAN / MANINGIL'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'I-type ang paninda o i-scan ang barcode...',
        prefixIcon: const Icon(Icons.search, size: 24),
        suffixIcon: IconButton(
          icon: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('📷 Binubuksan ang scanner...')),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTingiGridHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Mabilisan Tingi Grid',
            style: Theme.of(context).textTheme.titleMedium,
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

  Widget _buildRecentCartList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mga Bagay sa Kart',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        _buildCartItemsList(),
      ],
    );
  }

  Widget _buildCartItemsList() {
    if (_cart.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Walang laman ang kart. Pindutin ang paninda sa itaas.'),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: _cart.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _cart[index];
        return Card(
          child: ListTile(
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('₱ ${item.price.toStringAsFixed(2)} bawat isa'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
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
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  onPressed: () {
                    setState(() => item.quantity++);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileCartBottomBar() {
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
                    '$_totalItems bagay sa kart',
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
                onPressed: _showCheckoutDialog,
                child: const Text('MANINGIL'),
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
