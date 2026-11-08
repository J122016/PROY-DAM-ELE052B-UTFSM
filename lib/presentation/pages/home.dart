import 'package:flutter/material.dart';
import 'package:proyecto_dam/presentation/components/theme_toggle_button.dart';
import 'package:proyecto_dam/presentation/pages/admin_products.dart';
import 'package:proyecto_dam/presentation/pages/cart_page.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';

class Home extends StatefulWidget {
  const Home({
    required this.productProvider,
    required this.themeProvider,
    this.cartProvider,
    super.key,
  });

  final ProductProvider productProvider;
  final ThemeProvider themeProvider;
  final CartProvider? cartProvider;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    widget.productProvider.initialize();
  }

  void _openCart(BuildContext context) {
    final cartProvider = widget.cartProvider;
    if (cartProvider == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CartPage(
          cartProvider: cartProvider,
          productProvider: widget.productProvider,
          themeProvider: widget.themeProvider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('NutriMarket'),
      actions: [
        ListenableBuilder(
          listenable: widget.themeProvider,
          builder: (context, child) => ThemeToggleButton(
            isDark: widget.themeProvider.isDarkMode,
            onPressed: widget.themeProvider.toggle,
          ),
        ),
        if (widget.cartProvider != null)
          ListenableBuilder(
            listenable: widget.cartProvider!,
            builder: (context, child) {
              final count = widget.cartProvider!.totalItemsCount;
              return IconButton(
                tooltip: 'Canasta de Alimentos',
                onPressed: () => _openCart(context),
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              );
            },
          ),
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => AdminProductsPage(
                productProvider: widget.productProvider,
                themeProvider: widget.themeProvider,
              ),
            ),
          ),
          icon: const Icon(Icons.storefront_outlined),
          tooltip: 'Admin',
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.storefront_outlined,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Nutrimarket',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tienda integral que provee información nutricional y de sostenibilidad de sus productos disponibles',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                if (widget.cartProvider != null)
                  FilledButton.icon(
                    onPressed: () => _openCart(context),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: const Text('Abrir Canasta de Alimentos'),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
