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
  };

  static Product? fromOpenFoodFacts(Map<String, dynamic> json) {
    final id = json['code'];
    final name = _optionalString(json['product_name']);
    if (id is! String || id.trim().isEmpty || name == null) return null;

    final nutrition = json['nutriments'];
    final nutriments = nutrition is Map<String, dynamic> ? nutrition : const {};
    final categories = json['categories'];
    final category = categories is String
        ? categories.split(',').first.trim()
        : categories is List && categories.isNotEmpty
        ? categories.first.toString()
        : null;

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
      category: category?.isEmpty == true ? null : category,
    );
  }

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
