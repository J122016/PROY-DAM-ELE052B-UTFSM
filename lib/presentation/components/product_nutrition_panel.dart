import 'package:flutter/material.dart';
import 'package:proyecto_dam/constants.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/presentation/components/nutri_score.dart';

const _novaInfo = {
  1: ('Sin procesar o mínimamente procesado', Color(0xFF038141)),
  2: ('Ingrediente culinario procesado', Color(0xFFC9A000)),
  3: ('Alimento procesado', Color(0xFFEE8100)),
  4: ('Ultraprocesado', Color(0xFFE63E11)),
};

const _nutrientNames = {
  'fat': ('Grasas', 'GRASAS'),
  'saturated-fat': ('Grasas sat.', 'GRASAS SATURADAS'),
  'sugars': ('Azúcares', 'AZÚCARES'),
  'salt': ('Sal', 'SAL'),
};

const _levelInfo = {
  'low': ('Bajo', Color(0xFF16A34A)),
  'moderate': ('Medio', Color(0xFFD97706)),
  'high': ('Alto', Color(0xFFDC2626)),
};

String _grams(double? value, double factor) {
  if (value == null) return '-';
  final total = value * factor;
  // Bajo 1 g se usan dos decimales para que la sal no aparezca como 0,0.
  final digits = total > 0 && total < 1 ? 2 : 1;
  return '${total.toStringAsFixed(digits).replaceAll('.', ',')} g';
}

class ProductNutritionPanel extends StatelessWidget {
  const ProductNutritionPanel({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final levels = product.levels;
    final highs = Product.nutrientKeys.where((key) => levels[key] == 'high');
    final serving = product.servingGrams;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
    );
    final tileDecoration = BoxDecoration(
      color: isDark
          ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
          : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: isDark ? kDarkBorder : kLightBorder),
    );

    final rows = [
      ('Energía', product.calories, true, false),
      ('Proteínas', product.proteins, false, false),
      ('Carbohidratos', product.carbohydrates, false, false),
      ('Azúcares', product.sugars, false, true),
      ('Grasas totales', product.fat, false, false),
      ('Grasas saturadas', product.saturatedFat, false, true),
      ('Fibra', product.fiber, false, false),
      ('Sal', product.salt, false, false),
    ];

    String format(double? value, bool isEnergy, double factor) => isEnergy
        ? value == null
              ? '-'
              : '${(value * factor).round()} kcal'
        : _grams(value, factor);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco_outlined, size: 18, color: colors.primary),
                const SizedBox(width: 6),
                Text(
                  'Resumen nutricional',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: tileDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Nutri-Score', style: muted),
                          const SizedBox(height: 6),
                          product.nutriScore != null
                              ? NutriScoreScale(grade: product.nutriScore!)
                              : Text('Sin dato', style: muted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: tileDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Procesamiento (NOVA)', style: muted),
                          const SizedBox(height: 6),
                          if (_novaInfo[product.novaGroup] case final nova?)
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: nova.$2,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${product.novaGroup}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    nova.$1,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Text('Sin dato', style: muted),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (highs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final key in highs)
                    _HighInSeal(nutrient: _nutrientNames[key]!.$2),
                ],
              ),
            ],
            if (levels.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final key in Product.nutrientKeys)
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: key == Product.nutrientKeys.last ? 0 : 6,
                        ),
                        child: _LevelTile(
                          name: _nutrientNames[key]!.$1,
                          level: levels[key],
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Table(
              columnWidths: {
                0: const FlexColumnWidth(2),
                1: const FlexColumnWidth(1.2),
                if (serving != null) 2: const FlexColumnWidth(1.4),
              },
              children: [
                TableRow(
                  children: [
                    Text('NUTRIENTE', style: muted),
                    Text('100 G', style: muted, textAlign: TextAlign.right),
                    if (serving != null)
                      Text(
                        'PORCIÓN (${serving.round()} G)',
                        style: muted,
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
                for (final row in rows)
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          top: 6,
                          bottom: 6,
                          left: row.$4 ? 12 : 0,
                        ),
                        child: Text(
                          row.$1,
                          style: row.$4
                              ? theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                )
                              : theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          format(row.$2, row.$3, 1),
                          textAlign: TextAlign.right,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (serving != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            format(row.$2, row.$3, serving / 100),
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (product.servingSize != null) ...[
              const SizedBox(height: 6),
              Text('Porción sugerida: ${product.servingSize}', style: muted),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({required this.name, required this.level});

  final String name;
  final String? level;

  @override
  Widget build(BuildContext context) {
    final info = _levelInfo[level];
    final color = info?.$2 ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: color),
          ),
          Text(
            info?.$1 ?? '-',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighInSeal extends StatelessWidget {
  const _HighInSeal({required this.nutrient});

  final String nutrient;

  @override
  Widget build(BuildContext context) => ClipPath(
    clipper: _OctagonClipper(),
    child: Container(
      width: 64,
      height: 64,
      color: Colors.black,
      padding: const EdgeInsets.all(4),
      alignment: Alignment.center,
      child: Text(
        'ALTO EN\n$nutrient',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          height: 1.15,
        ),
      ),
    ),
  );
}

class _OctagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final cut = size.width * 0.3;
    return Path()
      ..moveTo(cut, 0)
      ..lineTo(size.width - cut, 0)
      ..lineTo(size.width, cut)
      ..lineTo(size.width, size.height - cut)
      ..lineTo(size.width - cut, size.height)
      ..lineTo(cut, size.height)
      ..lineTo(0, size.height - cut)
      ..lineTo(0, cut)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
