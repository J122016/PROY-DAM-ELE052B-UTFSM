import 'dart:convert';

import 'package:proyecto_dam/data/models/cart_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartRepository {
  CartRepository(this._preferences);

  static const _cartKey = 'nutrimarket_cart_v1';
  final SharedPreferences _preferences;

  List<CartItem> load() {
    final stored = _preferences.getString(_cartKey);
    if (stored == null) return const [];
    final decoded = jsonDecode(stored);
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['items'] is! List) {
      return const [];
    }
    return (decoded['items'] as List)
        .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(growable: false);
  }

  Future<void> save(List<CartItem> items) async {
    final saved = await _preferences.setString(
      _cartKey,
      jsonEncode({
        'version': 1,
        'items': items.map((item) => item.toJson()).toList(),
      }),
    );
    if (!saved) throw StateError('Could not save the shopping cart.');
  }
}
