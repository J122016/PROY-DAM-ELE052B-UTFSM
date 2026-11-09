import 'package:flutter/material.dart';
import 'package:proyecto_dam/data/models/cart_item.dart';
import 'package:proyecto_dam/presentation/components/nutrition_summary_card.dart';
import 'package:proyecto_dam/presentation/components/theme_toggle_button.dart';
import 'package:proyecto_dam/presentation/pages/checkout_page.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';

class CartPage extends StatelessWidget {
  const CartPage({
    required this.cartProvider,
    required this.productProvider,
    required this.themeProvider,
    super.key,
  });

  final CartProvider cartProvider;
  final ProductProvider productProvider;
  final ThemeProvider themeProvider;

  Future<void> _confirmClearCart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Vaciar canasta orgánica?'),
        content: const Text(
          'Se eliminarán todos los alimentos seleccionados de tu canasta actual.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar canasta'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cartProvider.clear();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: cartProvider,
    builder: (context, child) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      final items = cartProvider.items;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Canasta de Alimentos'),
          actions: [
            ListenableBuilder(
              listenable: themeProvider,
              builder: (context, child) => ThemeToggleButton(
                isDark: themeProvider.isDarkMode,
                onPressed: themeProvider.toggle,
              ),
            ),
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => _confirmClearCart(context),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: colors.error,
                  ),
                  label: Text(
                    'Vaciar',
                    style: TextStyle(
                      color: colors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: items.isEmpty
              ? _EmptyCartView(
                  onLoadDemo: () =>
                      cartProvider.loadDemoItems(productProvider.products),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: NutritionSummaryCard(
                        calories: cartProvider.totalCalories,
                        proteins: cartProvider.totalProteins,
                        carbohydrates: cartProvider.totalCarbohydrates,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _CartItemCard(
                            item: item,
                            onIncrement: () =>
                                cartProvider.increment(item.product.id),
                            onDecrement: () =>
                                cartProvider.decrement(item.product.id),
                            onRemove: () =>
                                cartProvider.removeProduct(item.product.id),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border(
                          top: BorderSide(color: theme.dividerColor),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total a pagar:',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                formatClp(cartProvider.totalPriceClp),
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => CheckoutPage(
                                    cartProvider: cartProvider,
                                    productProvider: productProvider,
                                    themeProvider: themeProvider,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Ir a Pagar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      );
    },
  );
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final product = item.product;
    final maxStock = product.stock > 0 ? product.stock : 99;
    final canIncrement = item.quantity < maxStock;

    final nutritionParts = <String>[
      if (product.calories != null) '${item.totalCalories.round()} kcal',
      if (product.proteins != null)
        '${item.totalProteins.toStringAsFixed(1)}g prot',
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CartProductThumbnail(
              url: product.imageUrl,
              fallbackTitle: product.name,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatClp(product.priceClp)} c/u  •  Subtotal: ${formatClp(item.subtotalClp)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (nutritionParts.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      nutritionParts.join(' • '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Eliminar producto de la canasta',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.delete_outline,
                    size: 19,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QuantityStepButton(
                        label: '-',
                        tooltip: 'Disminuir cantidad',
                        onPressed: onDecrement,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '${item.quantity}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _QuantityStepButton(
                        label: '+',
                        tooltip: 'Aumentar cantidad',
                        onPressed: canIncrement ? onIncrement : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepButton extends StatelessWidget {
  const _QuantityStepButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: onPressed == null
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    ),
  );
}

class _CartProductThumbnail extends StatelessWidget {
  const _CartProductThumbnail({
    required this.fallbackTitle,
    this.url,
  });

  final String? url;
  final String fallbackTitle;

  @override
  Widget build(BuildContext context) {
    final uri = url == null ? null : Uri.tryParse(url!);
    final placeholder = Container(
      width: 56,
      height: 56,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.eco_outlined,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 2),
          Text(
            fallbackTitle.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10,
            ),
          ),
        ],
      ),
    );

    if (uri == null || uri.scheme != 'https') return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        url!,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView({required this.onLoadDemo});

  final VoidCallback onLoadDemo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 36,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu canasta orgánica está vacía',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Agrega alimentos saludables para ver el resumen nutricional acumulado de tu pedido.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonalIcon(
              onPressed: onLoadDemo,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Cargar productos de prueba'),
            ),
          ],
        ),
      ),
    );
  }
}
