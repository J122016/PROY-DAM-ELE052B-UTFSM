import 'package:flutter/material.dart';
import 'package:proyecto_dam/presentation/components/nutri_score.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';
import 'package:proyecto_dam/presentation/providers/product_filter.dart';

/// Abre la hoja y devuelve el filtro elegido, o null si se cierra sin aplicar.
Future<ProductFilter?> showProductFiltersSheet(
  BuildContext context, {
  required ProductFilter initial,
  required int Function(ProductFilter filter) countFor,
}) => showModalBottomSheet<ProductFilter>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) =>
      ProductFiltersSheet(initial: initial, countFor: countFor),
);

class ProductFiltersSheet extends StatefulWidget {
  const ProductFiltersSheet({
    required this.initial,
    required this.countFor,
    super.key,
  });

  final ProductFilter initial;
  final int Function(ProductFilter filter) countFor;

  @override
  State<ProductFiltersSheet> createState() => _ProductFiltersSheetState();
}

class _ProductFiltersSheetState extends State<ProductFiltersSheet> {
  late ProductFilter _filter = widget.initial;

  void _toggleLabel(String label) {
    final labels = {..._filter.labels};
    labels.contains(label) ? labels.remove(label) : labels.add(label);
    setState(() => _filter = _filter.copyWith(labels: labels));
  }

  void _toggleScore(String grade) {
    final scores = {..._filter.nutriScores};
    scores.contains(grade) ? scores.remove(grade) : scores.add(grade);
    setState(() => _filter = _filter.copyWith(nutriScores: scores));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final count = widget.countFor(_filter);
    final sectionStyle = theme.textTheme.labelMedium?.copyWith(
      color: colors.onSurfaceVariant,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Filtros', style: theme.textTheme.titleMedium),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                Text('ORDENAR POR', style: sectionStyle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sort in ProductSort.values)
                      ChoiceChip(
                        label: Text(sort.label),
                        selected: _filter.sort == sort,
                        onSelected: (_) => setState(
                          () => _filter = _filter.copyWith(sort: sort),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('NUTRI-SCORE', style: sectionStyle),
                const SizedBox(height: 2),
                Text(
                  'Nota nutricional de A (mejor) a E.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final entry in nutriScoreColors.entries)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _ScoreToggle(
                          grade: entry.key,
                          color: entry.value,
                          selected: _filter.nutriScores.contains(entry.key),
                          onTap: () => _toggleScore(entry.key),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('PREFERENCIAS', style: sectionStyle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in productLabelNames.entries)
                      FilterChip(
                        label: Text(entry.value),
                        selected: _filter.labels.contains(entry.key),
                        onSelected: (_) => _toggleLabel(entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Sin sellos "ALTO EN"'),
                  subtitle: const Text(
                    'Oculta productos altos en grasas, grasas saturadas, azúcares o sal.',
                  ),
                  value: _filter.withoutHighNutrients,
                  onChanged: (value) => setState(
                    () => _filter = _filter.copyWith(
                      withoutHighNutrients: value,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text('PRECIO MÁXIMO', style: sectionStyle),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final price in [null, ...maxPriceOptions])
                      ChoiceChip(
                        label: Text(
                          price == null
                              ? 'Cualquiera'
                              : 'Hasta ${formatClp(price)}',
                        ),
                        selected: _filter.maxPrice == price,
                        onSelected: (_) => setState(
                          () => _filter = _filter.copyWith(
                            maxPrice: () => price,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () =>
                        setState(() => _filter = _filter.cleared()),
                    child: const Text('Limpiar'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _filter),
                      child: Text(
                        'Ver $count ${count == 1 ? 'producto' : 'productos'}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreToggle extends StatelessWidget {
  const _ScoreToggle({
    required this.grade,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String grade;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Nutri-Score ${grade.toUpperCase()}',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color, width: 2),
        ),
        child: Text(
          grade.toUpperCase(),
          style: TextStyle(
            color: selected ? nutriScoreTextColor(grade) : color,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
    ),
  );
}
