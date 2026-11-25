import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:proyecto_dam/data/models/order_receipt.dart';
import 'package:proyecto_dam/data/repositories/order_history_repository.dart';
import 'package:proyecto_dam/data/services/order_service.dart';

class OrderHistoryProvider extends ChangeNotifier {
  OrderHistoryProvider({
    required OrderHistoryRepository repository,
    required this.store,
    this.remoteTimeout = const Duration(seconds: 10),
  }) {
    _repository = repository;
    final snapshot = _repository.load();
    _orders = _sorted(snapshot.orders);
    _unsynced = {...snapshot.unsynced};
  }

  late final OrderHistoryRepository _repository;

  /// Expuesto para que la vista admin lea todos los pedidos.
  final OrderStore store;
  final Duration remoteTimeout;

  List<OrderReceipt> _orders = [];
  Set<String> _unsynced = {};
  bool isRefreshing = false;
  String? errorMessage;
  bool _disposed = false;

  List<OrderReceipt> get orders => List.unmodifiable(_orders);

  bool get isEmpty => _orders.isEmpty;

  int get pendingCount => _orders.where((order) => !order.isDelivered).length;

  bool isSynced(String orderNumber) => !_unsynced.contains(orderNumber);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Notifica a los widgets oyentes evitando disparar `markNeedsBuild` en
  /// mitad de la fase de construcción de otro árbol de widgets (por ejemplo,
  /// al abrir una nueva ruta mientras `Home` escucha el mismo provider).
  void _notify() {
    if (_disposed) return;
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      binding.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
      return;
    }
    notifyListeners();
  }

  /// Registra un pedido recién confirmado. Siempre queda guardado en el
  /// teléfono; devuelve `true` si además se subió a la nube.
  Future<bool> placeOrder(OrderReceipt order) async {
    _orders = _sorted([
      order,
      ..._orders.where((existing) => existing.orderNumber != order.orderNumber),
    ]);
    _unsynced = {..._unsynced, order.orderNumber};
    await _repository.save(_orders, _unsynced);
    _notify();
    return _upload(order);
  }

  /// Reintenta subir los pedidos pendientes y trae el estado actualizado
  /// (por ejemplo, "Entregado") desde la base de datos.
  Future<void> refresh() async {
    if (isRefreshing || _disposed) return;
    isRefreshing = true;
    errorMessage = null;
    _notify();
    try {
      for (final order in _orders.where(
        (o) => _unsynced.contains(o.orderNumber),
      )) {
        await _upload(order, notify: false);
      }
      final syncedNumbers = _orders
          .map((order) => order.orderNumber)
          .where(isSynced)
          .toList();
      if (syncedNumbers.isNotEmpty) {
        final remote = await store
            .fetchByNumbers(syncedNumbers)
            .timeout(remoteTimeout);
        final byNumber = {for (final order in remote) order.orderNumber: order};
        _orders = _sorted([
          for (final order in _orders) byNumber[order.orderNumber] ?? order,
        ]);
        await _repository.save(_orders, _unsynced);
      }
      if (_unsynced.isNotEmpty) {
        errorMessage =
            'Hay pedidos sin sincronizar. Revisa tu conexión a internet.';
      }
    } catch (_) {
      errorMessage =
          'No se pudo actualizar el estado de tus pedidos. Se muestra la copia guardada en el teléfono.';
    } finally {
      isRefreshing = false;
      _notify();
    }
  }

  Future<bool> _upload(OrderReceipt order, {bool notify = true}) async {
    try {
      await store.save(order).timeout(remoteTimeout);
    } catch (_) {
      return false;
    }
    _unsynced = {..._unsynced}..remove(order.orderNumber);
    await _repository.save(_orders, _unsynced);
    if (notify) _notify();
    return true;
  }

  static List<OrderReceipt> _sorted(List<OrderReceipt> orders) =>
      [...orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}
