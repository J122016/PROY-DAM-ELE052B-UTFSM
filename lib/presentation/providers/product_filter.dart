import 'package:proyecto_dam/data/models/product.dart';

enum ProductSort {
  relevance('Relevancia'),
  priceAsc('Menor precio'),
  priceDesc('Mayor precio'),
  caloriesAsc('Menos calorías'),
  proteinsDesc('Más proteína');

  const ProductSort(this.label);

  final String label;
}

enum ProductStockFilter {
  any('Cualquier stock'),
  outOfStock('Sin stock'),
  available('Disponible'),
  critical('Crítico');

  const ProductStockFilter(this.label);

  final String label;
}

const productLabelNames = {
  'vegan': 'Vegano',
  'vegetarian': 'Vegetariano',
  'gluten-free': 'Sin gluten',
  'palm-oil-free': 'Sin aceite de palma',
};

const maxPriceOptions = [3000, 5000, 10000];

class ProductFilter {
  const ProductFilter({
    this.query = '',
    this.category,
    this.stock = ProductStockFilter.any,
    this.labels = const {},
    this.nutriScores = const {},
    this.withoutHighNutrients = false,
    this.maxPrice,
    this.sort = ProductSort.relevance,
  });

  final String query;
  final String? category;
  final ProductStockFilter stock;
  final Set<String> labels;
  final Set<String> nutriScores;
  final bool withoutHighNutrients;
  final int? maxPrice;
  final ProductSort sort;

  int get activeCount =>
      (category != null ? 1 : 0) +
      labels.length +
      nutriScores.length +
      (stock != ProductStockFilter.any ? 1 : 0) +
      (withoutHighNutrients ? 1 : 0) +
      (maxPrice != null ? 1 : 0) +
      (sort != ProductSort.relevance ? 1 : 0);

  ProductFilter copyWith({
    String? query,
    String? Function()? category,
    ProductStockFilter? stock,
    Set<String>? labels,
    Set<String>? nutriScores,
    bool? withoutHighNutrients,
    int? Function()? maxPrice,
    ProductSort? sort,
  }) => ProductFilter(
    query: query ?? this.query,
    category: category != null ? category() : this.category,
    stock: stock ?? this.stock,
    labels: labels ?? this.labels,
    nutriScores: nutriScores ?? this.nutriScores,
    withoutHighNutrients: withoutHighNutrients ?? this.withoutHighNutrients,
    maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
    sort: sort ?? this.sort,
  );

  /// Quita los filtros y conserva la búsqueda actual.
  ProductFilter cleared() => ProductFilter(query: query);

  List<Product> apply(List<Product> products) {
    final text = query.trim().toLowerCase();
    final result = products.where((product) {
      final matchesText =
          text.isEmpty ||
          product.name.toLowerCase().contains(text) ||
          (product.brand ?? '').toLowerCase().contains(text);
      final matchesCategory =
          category == null || (product.category ?? 'Otros') == category;
      final matchesStock = switch (stock) {
        ProductStockFilter.any => true,
        ProductStockFilter.outOfStock => product.stock == 0,
        ProductStockFilter.available => product.stock > 0,
        ProductStockFilter.critical => product.isCriticallyStocked,
      };
      final matchesLabels = labels.every(product.labels.contains);
      final matchesScore =
          nutriScores.isEmpty || nutriScores.contains(product.nutriScore);
      final matchesLevels = !withoutHighNutrients || !product.hasHighNutrient;
      final matchesPrice =
          maxPrice == null ||
          (product.priceClp > 0 && product.priceClp <= maxPrice!);
      return matchesText &&
          matchesCategory &&
          matchesStock &&
          matchesLabels &&
          matchesScore &&
          matchesLevels &&
          matchesPrice;
    }).toList();

    switch (sort) {
      case ProductSort.relevance:
        break;
      case ProductSort.priceAsc:
        result.sort((a, b) => a.priceClp.compareTo(b.priceClp));
      case ProductSort.priceDesc:
        result.sort((a, b) => b.priceClp.compareTo(a.priceClp));
      case ProductSort.caloriesAsc:
        result.sort(
          (a, b) => (a.calories ?? double.infinity).compareTo(
            b.calories ?? double.infinity,
          ),
        );
      case ProductSort.proteinsDesc:
        result.sort((a, b) => (b.proteins ?? 0).compareTo(a.proteins ?? 0));
    }
    return result;
  }

  /// Categorías presentes en el catálogo, de la más a la menos frecuente.
  static List<String> categoriesOf(List<Product> products) {
    final counts = <String, int>{};
    for (final product in products) {
      final category = product.category ?? 'Otros';
      counts[category] = (counts[category] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((entry) => entry.key).toList(growable: false);
  }
}
