import 'package:flutter/material.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/presentation/components/empty_results.dart';
import 'package:proyecto_dam/presentation/components/product_card.dart';
import 'package:proyecto_dam/presentation/components/product_filters_sheet.dart';
import 'package:proyecto_dam/presentation/components/theme_toggle_button.dart';
import 'package:proyecto_dam/presentation/pages/admin_products.dart';
import 'package:proyecto_dam/presentation/pages/cart_page.dart';
import 'package:proyecto_dam/presentation/pages/product_detail_page.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';
import 'package:proyecto_dam/presentation/providers/product_filter.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';

class Home extends StatefulWidget {
  const Home({
    required this.productProvider,
    required this.themeProvider,
    required this.cartProvider,
    super.key,
  });

  final ProductProvider productProvider;
  final ThemeProvider themeProvider;
  final CartProvider cartProvider;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _searchController = TextEditingController();
  ProductFilter _filter = const ProductFilter();

  @override
  void initState() {
    super.initState();
    widget.productProvider.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCart(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => CartPage(
        cartProvider: widget.cartProvider,
        productProvider: widget.productProvider,
        themeProvider: widget.themeProvider,
      ),
    ),
  );

  void _openDetail(BuildContext context, Product product) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => ProductDetailPage(
        product: product,
        cartProvider: widget.cartProvider,
        themeProvider: widget.themeProvider,
        onOpenCart: () => _openCart(context),
      ),
    ),
  );

  Future<void> _addToCart(BuildContext context, Product product) async {
    final messenger = ScaffoldMessenger.of(context);
    await widget.cartProvider.addProduct(product);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.name} añadido a la canasta.'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openFilters(BuildContext context) async {
    final products = widget.productProvider.products;
    final selected = await showProductFiltersSheet(
      context,
      initial: _filter,
      countFor: (filter) => filter.apply(products).length,
    );
    if (selected != null) setState(() => _filter = selected);
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
        ListenableBuilder(
          listenable: widget.cartProvider,
          builder: (context, child) {
            final count = widget.cartProvider.totalItemsCount;
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
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.productProvider,
          widget.cartProvider,
        ]),
        builder: (context, child) {
          final provider = widget.productProvider;
          final products = provider.products;
          final categories = ProductFilter.categoriesOf(products);
          final filter =
              _filter.category != null &&
                  !categories.contains(_filter.category)
              ? _filter.copyWith(category: () => null)
              : _filter;
          final visible = filter.apply(products);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(
                          () => _filter = _filter.copyWith(query: value),
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Buscar por nombre o marca',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Badge(
                      isLabelVisible: filter.activeCount > 0,
                      label: Text('${filter.activeCount}'),
                      child: IconButton.filledTonal(
                        onPressed: () => _openFilters(context),
                        tooltip: 'Filtros',
                        icon: const Icon(Icons.tune),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  children: [
                    for (final category in [null, ...categories])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category ?? 'Todos'),
                          selected: filter.category == category,
                          onSelected: (_) => setState(
                            () => _filter = _filter.copyWith(
                              category: () => category,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (filter.activeCount > 0)
                _ActiveFilters(
                  filter: filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
              if (provider.isBackupCatalog)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    'Open Food Facts no responde. Se muestra el catálogo de respaldo.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : visible.isEmpty
                    ? EmptyResults(
                        isFiltered: products.isNotEmpty,
                        object: 'catálogo',
                        onRetry: provider.refreshCatalog,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 240,
                              mainAxisExtent: 268,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          final product = visible[index];
                          final cart = widget.cartProvider;
                          return ProductCard(
                            product: product,
                            quantityInCart: cart.quantityOf(product.id),
                            onTap: () => _openDetail(context, product),
                            onAdd: () => _addToCart(context, product),
                            onIncrement: () => cart.increment(product.id),
                            onDecrement: () => cart.decrement(product.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({required this.filter, required this.onChanged});

  final ProductFilter filter;
  final ValueChanged<ProductFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      if (filter.sort != ProductSort.relevance)
        _chip(
          filter.sort.label,
          () => onChanged(filter.copyWith(sort: ProductSort.relevance)),
        ),
      for (final grade in filter.nutriScores)
        _chip(
          'Nutri-Score ${grade.toUpperCase()}',
          () => onChanged(
            filter.copyWith(nutriScores: {...filter.nutriScores}..remove(grade)),
          ),
        ),
      for (final label in filter.labels)
        _chip(
          productLabelNames[label] ?? label,
          () => onChanged(
            filter.copyWith(labels: {...filter.labels}..remove(label)),
          ),
        ),
      if (filter.withoutHighNutrients)
        _chip(
          'Sin ALTO EN',
          () => onChanged(filter.copyWith(withoutHighNutrients: false)),
        ),
      if (filter.maxPrice != null)
        _chip(
          'Hasta ${formatClp(filter.maxPrice!)}',
          () => onChanged(filter.copyWith(maxPrice: () => null)),
        ),
      TextButton(
        onPressed: () => onChanged(filter.cleared()),
        child: const Text('Limpiar'),
      ),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: chips,
      ),
    );
  }

  Widget _chip(String label, VoidCallback onDeleted) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: InputChip(
      label: Text(label),
      onDeleted: onDeleted,
      visualDensity: VisualDensity.compact,
    ),
  );
}
