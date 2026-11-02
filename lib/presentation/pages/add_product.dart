import 'package:flutter/material.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/presentation/components/empty_results.dart';
import 'package:proyecto_dam/presentation/components/product_details_dialog.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({required this.productProvider, super.key});

  final ProductProvider productProvider;

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  static const _categories = [
    'Todos',
    'Cereales',
    'Avena',
    'Lacteos',
    'Chía',
    'Miel',
    'Matcha',
  ];
  final _queryController = TextEditingController();
  List<Product> _results = [];
  bool _isSearching = false;
  String _selectedCategory = 'Todos';
  String? _error;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_queryController.text.trim().isEmpty) {
      setState(
        () => _error = 'Escribe un alimento para buscar en el catálogo.',
      );
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
      _results = [];
    });
    try {
      final results = await widget.productProvider.searchOpenFoodFacts(
        _queryController.text,
      );
      if (mounted) setState(() => _results = results);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _add(Product product) async {
    final values = await showDialog<(int, int)>(
      context: context,
      builder: (context) => ProductDetailsDialog(
        product: product,
        title: 'Agregar al catálogo',
        actionLabel: 'Agregar producto',
        initialStock: 0,
      ),
    );
    if (values == null) return;
    try {
      await widget.productProvider.addProduct(
        Product(
          id: product.id,
          name: product.name,
          priceClp: values.$1,
          stock: values.$2,
          imageUrl: product.imageUrl,
          description: product.description,
          calories: product.calories,
          proteins: product.proteins,
          carbohydrates: product.carbohydrates,
          brand: product.brand,
          category: product.category,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto agregado al catálogo local.')),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _selectedCategory == 'Todos'
        ? _results
        : _results.where((product) {
            final query = _selectedCategory.toLowerCase();
            return product.name.toLowerCase().contains(query) ||
                (product.category?.toLowerCase().contains(query) ?? false);
          }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar producto')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.eco_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catálogo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Agrega alimentos saludables a tu tienda',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _queryController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Buscar en el catálogo (ej. Quinoa, Avena, Tofu)',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Buscar productos',
                  onPressed: _isSearching ? null : _search,
                  icon: _isSearching
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return ChoiceChip(
                    label: Text(category),
                    selected: category == _selectedCategory,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                    showCheckmark: false,
                  );
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (!_isSearching && _results.isEmpty && _error == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Text(
                  'Busca un alimento para ver los productos encontrados en Open Food Facts.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (!_isSearching &&
                _results.isNotEmpty &&
                filteredProducts.isEmpty)
              EmptyResults(
                isFiltered: true,
                onRetry: _search,
                object: 'productos',
              ),
            ...filteredProducts.map(
              (product) => _CatalogProductTile(
                product: product,
                onAdd: () => _add(product),
              ),
            ),
            if (_results.isNotEmpty) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Productos activos en tienda: ${widget.productProvider.products.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Listo'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CatalogProductTile extends StatelessWidget {
  const _CatalogProductTile({required this.product, required this.onAdd});

  final Product product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final nutrition = [
      if (product.calories != null) '${product.calories!.round()} kcal',
      if (product.proteins != null)
        '${product.proteins!.toStringAsFixed(1)} g prot',
    ].join('  ·  ');
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            _ProductImage(url: product.imageUrl),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brand != null)
                    Text(
                      product.brand!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (nutrition.isNotEmpty)
                    Text(
                      nutrition,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final uri = url == null ? null : Uri.tryParse(url!);
    final placeholder = Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.inventory_2_outlined, size: 24),
    );
    if (uri == null || uri.scheme != 'https') return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        url!,
        width: 48,
        height: 56,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}
