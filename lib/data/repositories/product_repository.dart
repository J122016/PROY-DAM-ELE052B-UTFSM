import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyecto_dam/data/models/product.dart';

class CatalogSnapshot {
  const CatalogSnapshot({required this.products, required this.deletedIds});

  final List<Product> products;
  final Set<String> deletedIds;
}

class ProductRepository {
  ProductRepository(this._preferences);

  static const _catalogKey = 'nutrimarket_catalog_v1';
  final SharedPreferences _preferences;

  CatalogSnapshot? load() {
    final stored = _preferences.getString(_catalogKey);
    if (stored == null) return null;
    final decoded = jsonDecode(stored);
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['products'] is! List ||
        decoded['deletedIds'] is! List) {
      throw const FormatException('Invalid saved catalog.');
    }
    return CatalogSnapshot(
      products: (decoded['products'] as List)
          .map(
            (item) => Product.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false),
      deletedIds: (decoded['deletedIds'] as List).whereType<String>().toSet(),
    );
  }

  Future<void> save(List<Product> products, Set<String> deletedIds) async {
    final saved = await _preferences.setString(
      _catalogKey,
      jsonEncode({
        'version': 1,
        'products': products.map((product) => product.toJson()).toList(),
        'deletedIds': deletedIds.toList(),
      }),
    );
    if (!saved) throw StateError('Could not save the local product catalog.');
  }
}
