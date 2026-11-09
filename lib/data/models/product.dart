class Product {
  const Product({
    required this.id,
    required this.name,
    required this.priceClp,
    required this.stock,
    this.imageUrl,
    this.description,
    this.calories,
    this.proteins,
    this.carbohydrates,
    this.brand,
    this.category,
    this.nutriScore,
    this.novaGroup,
    this.fat,
    this.saturatedFat,
    this.sugars,
    this.fiber,
    this.salt,
    this.nutrientLevels = const {},
    this.labels = const [],
    this.ingredients,
    this.allergens = const [],
    this.quantity,
    this.servingSize,
    this.servingGrams,
  });

  final String id;
  final String name;
  final int priceClp;
  final int stock;
  final String? imageUrl;
  final String? description;
  final double? calories;
  final double? proteins;
  final double? carbohydrates;
  final String? brand;
  final String? category;
  final String? nutriScore;
  final int? novaGroup;
  final double? fat;
  final double? saturatedFat;
  final double? sugars;
  final double? fiber;
  final double? salt;
  final Map<String, String> nutrientLevels;
  final List<String> labels;
  final String? ingredients;
  final List<String> allergens;
  final String? quantity;
  final String? servingSize;
  final double? servingGrams;

  static const nutrientKeys = ['fat', 'saturated-fat', 'sugars', 'salt'];
  static const labelKeys = ['vegan', 'vegetarian', 'gluten-free', 'palm-oil-free'];

  static const _pnnsCategories = {
    'Cereals and potatoes': 'Cereales y granos',
    'Fruits and vegetables': 'Frutas y verduras',
    'Salty snacks': 'Snacks salados',
    'Sugary snacks': 'Dulces',
    'Fat and sauces': 'Aceites y untables',
    'Beverages': 'Bebidas',
    'Milk and dairy products': 'Lácteos',
    'Fish Meat Eggs': 'Proteínas',
    'Composite foods': 'Platos preparados',
  };

  static const _allergenNames = {
    'gluten': 'Gluten',
    'milk': 'Leche',
    'eggs': 'Huevo',
    'nuts': 'Frutos secos',
    'peanuts': 'Maní',
    'sesame-seeds': 'Sésamo',
    'soybeans': 'Soya',
    'fish': 'Pescado',
    'crustaceans': 'Crustáceos',
    'molluscs': 'Moluscos',
    'celery': 'Apio',
    'mustard': 'Mostaza',
    'lupin': 'Lupino',
    'sulphur-dioxide-and-sulphites': 'Sulfitos',
  };

  // Umbrales por 100 g (bajo, alto) de Open Food Facts; en líquidos se usa la mitad.
  static const _levelThresholds = {
    'fat': (3.0, 17.5),
    'saturated-fat': (1.5, 5.0),
    'sugars': (5.0, 22.5),
    'salt': (0.3, 1.5),
  };

  bool get isAvailable => priceClp > 0 && stock > 0;

  bool get hasHighNutrient => levels.values.contains('high');

  double? nutrientValue(String key) => switch (key) {
    'fat' => fat,
    'saturated-fat' => saturatedFat,
    'sugars' => sugars,
    'salt' => salt,
    _ => null,
  };

  /// Niveles bajo/medio/alto. Usa los de la API y, si no vienen, los calcula.
  Map<String, String> get levels {
    if (nutrientLevels.isNotEmpty) return nutrientLevels;
    final isLiquid = RegExp(r'\d\s*(ml|cl|l)\b', caseSensitive: false)
        .hasMatch(quantity ?? '');
    final factor = isLiquid ? 0.5 : 1.0;
    final computed = <String, String>{};
    for (final key in nutrientKeys) {
      final value = nutrientValue(key);
      final limits = _levelThresholds[key]!;
      if (value == null) continue;
      computed[key] = value > limits.$2 * factor
          ? 'high'
          : value <= limits.$1 * factor
          ? 'low'
          : 'moderate';
    }
    return computed;
  }

  Product copyWith({int? priceClp, int? stock}) => Product(
    id: id,
    name: name,
    priceClp: priceClp ?? this.priceClp,
    stock: stock ?? this.stock,
    imageUrl: imageUrl,
    description: description,
    calories: calories,
    proteins: proteins,
    carbohydrates: carbohydrates,
    brand: brand,
    category: category,
    nutriScore: nutriScore,
    novaGroup: novaGroup,
    fat: fat,
    saturatedFat: saturatedFat,
    sugars: sugars,
    fiber: fiber,
    salt: salt,
    nutrientLevels: nutrientLevels,
    labels: labels,
    ingredients: ingredients,
    allergens: allergens,
    quantity: quantity,
    servingSize: servingSize,
    servingGrams: servingGrams,
  );

  factory Product.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final price = json['priceClp'];
    final stock = json['stock'];
    if (id is! String ||
        id.trim().isEmpty ||
        name is! String ||
        name.trim().isEmpty ||
        price is! int ||
        price < 0 ||
        stock is! int ||
        stock < 0) {
      throw const FormatException('Invalid product data.');
    }

    final levels = json['nutrientLevels'];
    return Product(
      id: id,
      name: name,
      priceClp: price,
      stock: stock,
      imageUrl: _optionalString(json['imageUrl']),
      description: _optionalString(json['description']),
      calories: _optionalNumber(json['calories']),
      proteins: _optionalNumber(json['proteins']),
      carbohydrates: _optionalNumber(json['carbohydrates']),
      brand: _optionalString(json['brand']),
      category: _optionalString(json['category']),
      nutriScore: _nutriScore(json['nutriScore']),
      novaGroup: _novaGroup(json['novaGroup']),
      fat: _optionalNumber(json['fat']),
      saturatedFat: _optionalNumber(json['saturatedFat']),
      sugars: _optionalNumber(json['sugars']),
      fiber: _optionalNumber(json['fiber']),
      salt: _optionalNumber(json['salt']),
      nutrientLevels: levels is Map
          ? {
              for (final entry in levels.entries)
                if (entry.key is String && entry.value is String)
                  entry.key as String: entry.value as String,
            }
          : const {},
      labels: _stringList(json['labels']),
      ingredients: _optionalString(json['ingredients']),
      allergens: _stringList(json['allergens']),
      quantity: _optionalString(json['quantity']),
      servingSize: _optionalString(json['servingSize']),
      servingGrams: _optionalNumber(json['servingGrams']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'priceClp': priceClp,
    'stock': stock,
    'imageUrl': imageUrl,
    'description': description,
    'calories': calories,
    'proteins': proteins,
    'carbohydrates': carbohydrates,
    'brand': brand,
    'category': category,
    'nutriScore': nutriScore,
    'novaGroup': novaGroup,
    'fat': fat,
    'saturatedFat': saturatedFat,
    'sugars': sugars,
    'fiber': fiber,
    'salt': salt,
    'nutrientLevels': nutrientLevels,
    'labels': labels,
    'ingredients': ingredients,
    'allergens': allergens,
    'quantity': quantity,
    'servingSize': servingSize,
    'servingGrams': servingGrams,
  };

  static Product? fromOpenFoodFacts(Map<String, dynamic> json) {
    final id = json['code'];
    final name =
        _optionalString(json['product_name_es']) ??
        _optionalString(json['product_name']);
    if (id is! String || id.trim().isEmpty || name == null) return null;

    final nutrition = json['nutriments'];
    final nutriments = nutrition is Map<String, dynamic> ? nutrition : const {};
    final apiLevels = json['nutrient_levels'];
    final tags = [
      ..._stringList(json['labels_tags']),
      ..._stringList(json['ingredients_analysis_tags']),
    ].map(_withoutPrefix).toSet();

    return Product(
      id: id,
      name: name,
      priceClp: 0,
      stock: 0,
      imageUrl: _httpsUrl(json['image_front_url']),
      description: _optionalString(json['generic_name']),
      calories: _optionalNumber(
        nutriments['energy-kcal_100g'] ?? nutriments['energy-kcal'],
      ),
      proteins: _optionalNumber(
        nutriments['proteins_100g'] ?? nutriments['proteins'],
      ),
      carbohydrates: _optionalNumber(
        nutriments['carbohydrates_100g'] ?? nutriments['carbohydrates'],
      ),
      brand: _optionalString(json['brands']),
      category: _categoryFromOpenFoodFacts(json),
      nutriScore: _nutriScore(json['nutriscore_grade']),
      novaGroup: _novaGroup(json['nova_group']),
      fat: _optionalNumber(nutriments['fat_100g']),
      saturatedFat: _optionalNumber(nutriments['saturated-fat_100g']),
      sugars: _optionalNumber(nutriments['sugars_100g']),
      fiber: _optionalNumber(nutriments['fiber_100g']),
      salt: _optionalNumber(nutriments['salt_100g']),
      nutrientLevels: apiLevels is Map
          ? {
              for (final key in nutrientKeys)
                if (apiLevels[key] is String) key: apiLevels[key] as String,
            }
          : const {},
      labels: [
        if (tags.contains('vegan')) 'vegan',
        if (tags.contains('vegan') || tags.contains('vegetarian')) 'vegetarian',
        if (tags.contains('no-gluten') ||
            tags.contains('gluten-free') ||
            tags.contains('certified-gluten-free'))
          'gluten-free',
        if (tags.contains('palm-oil-free')) 'palm-oil-free',
      ],
      ingredients:
          _optionalString(json['ingredients_text_es']) ??
          _optionalString(json['ingredients_text']),
      allergens: _stringList(json['allergens_tags'])
          .map(_withoutPrefix)
          .map((tag) => _allergenNames[tag] ?? tag)
          .toList(growable: false),
      quantity: _optionalString(json['quantity']),
      servingSize: _optionalString(json['serving_size']),
      servingGrams: _optionalNumber(
        json['serving_quantity'] is String
            ? double.tryParse(json['serving_quantity'] as String)
            : json['serving_quantity'],
      ),
    );
  }

  static String? _categoryFromOpenFoodFacts(Map<String, dynamic> json) {
    final pnns = _pnnsCategories[json['pnns_groups_1']];
    if (pnns != null) return pnns;
    final tags = _stringList(json['categories_tags'])
        .map((tag) => _withoutPrefix(tag).toLowerCase())
        .toList();
    if (tags.any((tag) => tag.contains('spices') || tag.contains('herbs'))) {
      return 'Especias';
    }
    if (tags.any((tag) => tag.contains('supplement') || tag.contains('seeds'))) {
      return 'Superalimentos';
    }
    if (tags.any((tag) => tag == 'beverages' || tag.contains('teas'))) {
      return 'Bebidas';
    }
    return tags.isEmpty ? null : 'Otros';
  }

  static String _withoutPrefix(String tag) =>
      tag.replaceFirst(RegExp(r'^[a-z]{2}:'), '');

  static String? _nutriScore(Object? value) =>
      value is String && const ['a', 'b', 'c', 'd', 'e'].contains(value)
      ? value
      : null;

  static int? _novaGroup(Object? value) =>
      value is num && value >= 1 && value <= 4 ? value.toInt() : null;

  static List<String> _stringList(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const [];

  static String? _httpsUrl(Object? value) {
    if (value is! String || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' ? value : null;
  }

  static String? _optionalString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  static double? _optionalNumber(Object? value) {
    if (value is! num || !value.isFinite || value < 0) return null;
    return value.toDouble();
  }
}
