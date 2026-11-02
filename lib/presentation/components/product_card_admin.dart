import 'package:flutter/material.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/constants.dart';

class ProductCardAdmin extends StatelessWidget {
  const ProductCardAdmin({
    required this.product,
    required this.onStockChanged,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Product product;
  final ValueChanged<int> onStockChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textStyle = theme.textTheme.labelLarge;

    final warningStock = 5;
    final outOfStock = 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductImage(url: product.imageUrl),
                const SizedBox(width: 10),
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
                      if (product.brand != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          product.brand!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        '${product.priceClp == 0 ? 'Precio sin definir' : '\$${product.priceClp} CLP'}'
                        '${product.calories == null ? '' : ' · ${product.calories!.round()} kcal'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: product.stock > warningStock ? colors.primaryContainer
                        : product.stock > outOfStock ? kAccentColor
                        : kdisabledContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.stock > warningStock ? 'DISPONIBLE'
                    : product.stock > outOfStock ? 'CRITICO'
                    : 'SIN STOCK',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: product.stock > warningStock ? colors.onPrimaryContainer
                          : product.stock > outOfStock ? Colors.white 
                          : kdisabledText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                border: Border.all(color: colors.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 2,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Stock:',
                        style: textStyle?.copyWith(color: colors.primary),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onEdit,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 38),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border.all(color: colors.outlineVariant),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${product.stock}',
                            textAlign: TextAlign.center,
                            style: textStyle?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('un.', style: theme.textTheme.labelSmall),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _QuickStockButton(
                        label: '-1',
                        tooltip: 'Disminuir stock en una unidad',
                        onPressed: product.stock == 0
                            ? null
                            : () => onStockChanged(product.stock - 1),
                        color: colors.inverseSurface,
                        foreground: colors.onInverseSurface,
                      ),
                      _QuickStockButton(
                        label: '+1',
                        tooltip: 'Aumentar stock en una unidad',
                        onPressed: () => onStockChanged(product.stock + 1),
                        color: colors.inverseSurface,
                        foreground: colors.onInverseSurface,
                      ),
                      _QuickStockButton(
                        label: '+5',
                        tooltip: 'Aumentar stock en cinco unidades',
                        onPressed: () => onStockChanged(product.stock + 5),
                        color: colors.primary,
                        foreground: colors.onPrimary,
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Modificar precio y stock',
                        visualDensity: VisualDensity.compact,
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 19),
                      ),
                      IconButton(
                        tooltip: 'Eliminar producto',
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 19,
                          color: colors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStockButton extends StatelessWidget {
  const _QuickStockButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
    required this.color,
    required this.foreground,
  });

  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 2),
    child: Tooltip(
      message: tooltip,
      child: SizedBox(
        height: 30,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(32, 30),
            padding: const EdgeInsets.symmetric(horizontal: 7),
            backgroundColor: color,
            foregroundColor: foreground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          child: Text(label),
        ),
      ),
    ),
  );
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final uri = url == null ? null : Uri.tryParse(url!);
    if (uri == null || uri.scheme != 'https') return _placeholder(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Image.network(
        url!,
        width: 54,
        height: 60,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => Container(
    width: 54,
    height: 60,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(7),
    ),
    child: const Icon(Icons.inventory_2_outlined, size: 26),
  );
}
