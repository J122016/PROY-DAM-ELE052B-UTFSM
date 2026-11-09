import 'package:flutter/material.dart';
import 'package:proyecto_dam/constants.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';

class NutritionSummaryCard extends StatelessWidget {
  const NutritionSummaryCard({
    required this.calories,
    required this.proteins,
    required this.carbohydrates,
    this.title = 'Resumen Nutricional del Pedido',
    this.subtitle = 'Aporte biológico acumulado en tu canasta',
    this.totalPriceClp,
    super.key,
  });

  final double calories;
  final double proteins;
  final double carbohydrates;
  final String title;
  final String? subtitle;
  final int? totalPriceClp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.eco_outlined,
                    size: 18,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (totalPriceClp != null)
                  Text(
                    formatClp(totalPriceClp!),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MacroMetricTile(
                    label: 'Energía',
                    value: '${calories.round()}',
                    unit: 'kcal',
                    accentColor: kAccentColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroMetricTile(
                    label: 'Proteínas',
                    value: '${proteins.toStringAsFixed(1)}g',
                    unit: 'aporte puro',
                    accentColor: const Color(0xFF7C8BFF),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroMetricTile(
                    label: 'Carbos',
                    value: '${carbohydrates.toStringAsFixed(1)}g',
                    unit: 'energía lenta',
                    accentColor: const Color(0xFF2DD4BF),
                    isDark: isDark,
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

class _MacroMetricTile extends StatelessWidget {
  const _MacroMetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
    required this.isDark,
  });

  final String label;
  final String value;
  final String unit;
  final Color accentColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? kDarkBorder : kLightBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
