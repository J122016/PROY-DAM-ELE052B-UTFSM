import 'package:flutter/material.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/data/services/auth_service.dart';
import 'package:proyecto_dam/presentation/pages/add_product.dart';
import 'package:proyecto_dam/presentation/components/empty_results.dart';
import 'package:proyecto_dam/presentation/components/product_details_dialog.dart';
import 'package:proyecto_dam/presentation/components/product_card_admin.dart';
import 'package:proyecto_dam/presentation/components/product_filters_sheet.dart';
import 'package:proyecto_dam/presentation/components/theme_toggle_button.dart';
import 'package:proyecto_dam/presentation/providers/product_filter.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({
    required this.productProvider,
    required this.themeProvider,
    super.key,
  });

  final ProductProvider productProvider;
  final ThemeProvider themeProvider;

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final _searchController = TextEditingController();
  ProductFilter _filter = const ProductFilter();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar ${product.name} del catálogo local?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.productProvider.deleteProduct(product.id);
    } catch (error) {
      _showMessage('No se pudo guardar la eliminación: $error');
    }
  }

  Future<void> _setStock(Product product, int stock) async {
    try {
      await widget.productProvider.setStock(product.id, stock);
    } catch (error) {
      _showMessage('No se pudo guardar el stock: $error');
    }
  }

  Future<void> _signOut() async {
    try {
      await const AuthService().signOut();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      _showMessage('No se pudo cerrar sesión: $error');
    }
  }

  Future<void> _openFilters(
    BuildContext context,
    List<Product> products,
  ) async {
    final selected = await showProductFiltersSheet(
      context,
      initial: _filter,
      categories: ProductFilter.categoriesOf(products),
      showCriticalStock: true,
      countFor: (filter) => filter.apply(products).length,
    );
    if (selected != null) setState(() => _filter = selected);
  }

  // Modal to edit stock and price of product
  Future<void> _edit(Product product) async {
    final values = await showDialog<(int, int)>(
      context: context,
      builder: (context) => ProductDetailsDialog(
        product: product,
        title: 'Ajustar precio y stock',
        actionLabel: 'Guardar',
        initialPrice: product.priceClp == 0 ? null : product.priceClp,
        initialStock: product.stock,
        titleIcon: Icons.eco_outlined,
      ),
    );
    if (values == null) return;
    try {
      await widget.productProvider.updateDetails(
        product.id,
        priceClp: values.$1,
        stock: values.$2,
      );
    } catch (error) {
      _showMessage('No se pudieron guardar los cambios: $error');
    }
  }

  void _showMessage(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Admin. Productos'),
      actions: [
        ListenableBuilder(
          listenable: widget.themeProvider,
          builder: (context, child) => ThemeToggleButton(
            isDark: widget.themeProvider.isDarkMode,
            onPressed: widget.themeProvider.toggle,
          ),
        ),
        ListenableBuilder(
          listenable: widget.productProvider,
          builder: (context, child) => IconButton(
            tooltip: 'Actualizar desde Open Food Facts',
            onPressed: widget.productProvider.isRefreshing
                ? null
                : widget.productProvider.refreshCatalog,
            icon: widget.productProvider.isRefreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
        ),
        IconButton(
          tooltip: 'Cerrar sesión',
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: widget.productProvider,
        builder: (context, child) {
          final provider = widget.productProvider;
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final products = _filter.apply(provider.products);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Modificación de Stock',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Panel Administrador Activo',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              AddProductPage(productProvider: provider),
                        ),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nuevo'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(
                          () => _filter = _filter.copyWith(query: value),
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Buscar por nombre o marca',
                          suffixIcon: _filter.query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(
                                      () =>
                                          _filter = _filter.copyWith(query: ''),
                                    );
                                  },
                                  icon: const Icon(Icons.close),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Badge(
                      isLabelVisible: _filter.activeCount > 0,
                      label: Text('${_filter.activeCount}'),
                      child: IconButton.filledTonal(
                        tooltip: 'Filtros',
                        onPressed: () =>
                            _openFilters(context, provider.products),
                        icon: const Icon(Icons.tune),
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.errorMessage != null)
                MaterialBanner(
                  content: Text(provider.errorMessage!),
                  leading: const Icon(Icons.cloud_off_outlined),
                  actions: [
                    TextButton(
                      onPressed: provider.refreshCatalog,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    provider.isBackupCatalog
                        ? 'Sin conexión con Firebase: catálogo de respaldo, los cambios no se guardan'
                        : 'Catálogo de la tienda en Firebase, compartido con todos los clientes',
                  ),
                ),
              ),
              Padding(
                // Status bar with total products and out of stock count
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 9),
                child: Row(
                  children: [
                    Text('Total: ${provider.products.length} productos'),
                    const Spacer(),
                    Text(
                      '${provider.products.where((product) => product.stock == 0).length} sin stock',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
              // Products list available in nutrimarket
              Expanded(
                child: products.isEmpty
                    ? EmptyResults(
                        isFiltered: _filter.activeCount > 0,
                        onRetry: provider.refreshCatalog,
                        object: 'catálogo',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ProductCardAdmin(
                            product: product,
                            onStockChanged: (stock) =>
                                _setStock(product, stock),
                            onEdit: () => _edit(product),
                            onDelete: () => _delete(product),
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
