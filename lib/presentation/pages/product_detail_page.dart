import 'package:flutter/material.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/presentation/components/product_card.dart';
import 'package:proyecto_dam/presentation/components/product_nutrition_panel.dart';
import 'package:proyecto_dam/presentation/components/theme_toggle_button.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';
import 'package:proyecto_dam/presentation/providers/product_filter.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    required this.product,
    required this.cartProvider,
    required this.themeProvider,
    required this.onOpenCart,
    super.key,
  });

  final Product product;
  final CartProvider cartProvider;
  final ThemeProvider themeProvider;
  final VoidCallback onOpenCart;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;

  Product get _product => widget.product;

  Future<void> _add() async {
    final messenger = ScaffoldMessenger.of(context);
    await widget.cartProvider.addProduct(_product, quantity: _quantity);
    setState(() => _quantity = 1);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${_product.name} añadido a la canasta.'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                onPressed: widget.onOpenCart,
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.shopping_bag_outlined),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          SizedBox(height: 240, child: ProductImage(url: _product.imageUrl)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_product.brand != null)
                  Text(
                    _product.brand!.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  _product.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_product.quantity != null || _product.labels.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (_product.quantity != null)
                          Chip(
                            label: Text(_product.quantity!),
                            visualDensity: VisualDensity.compact,
                          ),
                        for (final label in _product.labels)
                          Chip(
                            avatar: Icon(
                              Icons.check,
                              size: 16,
                              color: colors.primary,
                            ),
                            label: Text(productLabelNames[label] ?? label),
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _product.priceClp > 0
                          ? formatClp(_product.priceClp)
                          : 'Precio por definir',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (_product.stock > 0 ? colors.primary : colors.error)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _product.stock > 0
                            ? '${_product.stock} un. disponibles'
                            : 'Sin stock',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _product.stock > 0
                              ? colors.primary
                              : colors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_product.description != null) ...[
                  const SizedBox(height: 14),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Descripción',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _product.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ProductNutritionPanel(product: _product),
                if (_product.ingredients != null ||
                    _product.allergens.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _IngredientsCard(product: _product),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: widget.cartProvider,
        builder: (context, child) {
          final inCart = widget.cartProvider.quantityOf(_product.id);
          return Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: SafeArea(
              top: false,
              child: inCart > 0
                  ? _InCartBar(
                      quantity: inCart,
                      subtotal: _product.priceClp * inCart,
                      canIncrement: inCart < _product.stock,
                      onIncrement: () =>
                          widget.cartProvider.increment(_product.id),
                      onDecrement: () =>
                          widget.cartProvider.decrement(_product.id),
                      onRemove: () =>
                          widget.cartProvider.removeProduct(_product.id),
                      onOpenCart: widget.onOpenCart,
                    )
                  : Row(
                      children: [
                        _QuantityStepper(
                          quantity: _quantity,
                          onDecrement: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                          onIncrement: _quantity < _product.stock
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _product.isAvailable ? _add : null,
                            icon: const Icon(Icons.add),
                            label: Text(
                              _product.isAvailable
                                  ? 'Agregar (${formatClp(_product.priceClp * _quantity)})'
                                  : 'No disponible',
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _InCartBar extends StatelessWidget {
  const _InCartBar({
    required this.quantity,
    required this.subtotal,
    required this.canIncrement,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    required this.onOpenCart,
  });

  final int quantity;
  final int subtotal;
  final bool canIncrement;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tienes $quantity en la canasta, ${formatClp(subtotal)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextButton.icon(
              onPressed: onRemove,
              style: TextButton.styleFrom(foregroundColor: colors.error),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Quitar de la canasta'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _QuantityStepper(
              quantity: quantity,
              onDecrement: onDecrement,
              onIncrement: canIncrement ? onIncrement : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: onOpenCart,
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Ver canasta'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onDecrement,
          tooltip: 'Quitar uno',
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 24,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          onPressed: onIncrement,
          tooltip: 'Agregar uno',
          icon: const Icon(Icons.add),
        ),
      ],
    ),
  );
}

class _IngredientsCard extends StatelessWidget {
  const _IngredientsCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final warning = isDark ? const Color(0xFFFFD27A) : const Color(0xFF8A5A00);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredientes',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (product.allergens.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: warning.withValues(alpha: 0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'Contiene o puede contener: ',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(text: product.allergens.join(', ')),
                          ],
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (product.ingredients != null) ...[
              const SizedBox(height: 8),
              Text(
                product.ingredients!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
