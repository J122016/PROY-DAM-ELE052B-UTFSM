import 'dart:convert';

import 'package:proyecto_dam/data/models/order_receipt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderHistorySnapshot {
  const OrderHistorySnapshot({required this.orders, required this.unsynced});

  final List<OrderReceipt> orders;

  /// Números de pedido que aún no se han podido subir a Firebase.
  final Set<String> unsynced;
}

/// Copia local de los pedidos hechos desde este teléfono. Identifica
/// "mis pedidos" sin pedir una cuenta al comprador y permite ver el
/// historial (y el QR) aunque no haya conexión.
class OrderHistoryRepository {
  OrderHistoryRepository(this._preferences);

  static const _historyKey = 'nutrimarket_order_history_v1';
  final SharedPreferences _preferences;

  OrderHistorySnapshot load() {
    final stored = _preferences.getString(_historyKey);
    if (stored == null) {
      return const OrderHistorySnapshot(orders: [], unsynced: {});
    }
    final decoded = jsonDecode(stored);
    if (decoded is! Map<String, dynamic> ||
        decoded['version'] != 1 ||
        decoded['orders'] is! List) {
      return const OrderHistorySnapshot(orders: [], unsynced: {});
    }
    final orders = <OrderReceipt>[];
    for (final raw in decoded['orders'] as List) {
      if (raw is! Map) continue;
      try {
        orders.add(OrderReceipt.fromMap(Map<String, dynamic>.from(raw)));
      } on FormatException {
        // Un pedido dañado no debe ocultar el resto del historial.
      }
    }
    final unsynced = decoded['unsynced'] is List
        ? (decoded['unsynced'] as List).whereType<String>().toSet()
        : <String>{};
    return OrderHistorySnapshot(orders: orders, unsynced: unsynced);
  }

  Future<void> save(List<OrderReceipt> orders, Set<String> unsynced) async {
    final saved = await _preferences.setString(
      _historyKey,
      jsonEncode({
        'version': 1,
        'orders': orders.map((order) => order.toMap()).toList(),
        'unsynced': unsynced.toList(),
      }),
    );
    if (!saved) throw StateError('Could not save the order history.');
  }
}
