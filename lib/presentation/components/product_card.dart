import 'package:flutter/material.dart';
import 'package:proyecto_dam/constants.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/presentation/components/nutri_score.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.quantityInCart,
    required this.onTap,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    super.key,
  });

  final Product product;
  final int quantityInCart;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.45,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: product.imageUrl),
                  if (product.nutriScore != null)
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: NutriScoreBadge(grade: product.nutriScore!),
                    ),
                  if (product.calories != null)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.calories!.round()} kcal',
                          style: const TextStyle(
                            color: kAccentColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brand != null)
                      Text(
                        product.brand!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.priceClp > 0
                                ? formatClp(product.priceClp)
                                : 'Precio por definir',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: product.priceClp > 0
                                ? theme.textTheme.titleMedium?.copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w800,
                                  )
                                : theme.textTheme.labelSmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                          ),
                        ),
                        _CartControl(
                          product: product,
                          quantity: quantityInCart,
                          onAdd: onAdd,
                          onIncrement: onIncrement,
                          onDecrement: onDecrement,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartControl extends StatelessWidget {
  const _CartControl({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (quantity == 0) {
      if (!product.isAvailable) {
        return Text(
          product.priceClp > 0 ? 'Agotado' : '',
          style: TextStyle(
            color: colors.error,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        );
      }
      return IconButton.filled(
        onPressed: onAdd,
        tooltip: 'Agregar a la canasta',
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.add, size: 20),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrement,
            tooltip: quantity == 1 ? 'Quitar de la canasta' : 'Quitar uno',
            visualDensity: VisualDensity.compact,
            color: colors.onPrimary,
            iconSize: 18,
            icon: Icon(quantity == 1 ? Icons.delete_outline : Icons.remove),
          ),
          Text(
            '$quantity',
            style: TextStyle(
              color: colors.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(
            onPressed: quantity < product.stock ? onIncrement : null,
            tooltip: 'Agregar uno',
            visualDensity: VisualDensity.compact,
            color: colors.onPrimary,
            disabledColor: colors.onPrimary.withValues(alpha: 0.4),
            iconSize: 18,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class ProductImage extends StatelessWidget {
  const ProductImage({required this.url, super.key});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: colors.primary.withValues(alpha: 0.08),
      child: Icon(Icons.eco_outlined, size: 40, color: colors.primary),
    );
    if (url == null) return placeholder;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
