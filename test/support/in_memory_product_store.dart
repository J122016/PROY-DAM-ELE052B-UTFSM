import 'dart:async';

import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/data/services/product_service.dart';

/// Catálogo en memoria con el mismo comportamiento que Firestore, para pruebas.
class InMemoryProductStore implements ProductStore {
  InMemoryProductStore([List<Product> initial = const []]) {
    for (final product in initial) {
      _products[product.id] = product;
      _active[product.id] = true;
    }
  }

  final Map<String, Product> _products = {};
  final Map<String, bool> _active = {};
  final _watchers = <StreamController<List<Product>>>{};
  bool failNextWatch = false;

  List<Product> get activeProducts =>
      _products.values.where((product) => _active[product.id] == true).toList()
        ..sort((a, b) => a.name.compareTo(b.name));

  Product? byId(String id) => _products[id];

  bool isActive(String id) => _active[id] == true;

  void _notify() {
    for (final watcher in _watchers) {
      watcher.add(activeProducts);
    }
  }

  @override
  Stream<List<Product>> watchActive() {
    late final StreamController<List<Product>> controller;
    controller = StreamController<List<Product>>(
      onListen: () {
        if (failNextWatch) {
          failNextWatch = false;
          controller.addError(StateError('sin conexión'));
          return;
        }
        controller.add(activeProducts);
        _watchers.add(controller);
      },
      onCancel: () => _watchers.remove(controller),
    );
    return controller.stream;
  }

  @override
  Future<Set<String>> knownIds() async => _products.keys.toSet();

  @override
  Future<void> saveAll(List<Product> products) async {
    for (final product in products) {
      _products[product.id] = product;
      _active[product.id] = true;
    }
    _notify();
  }

  @override
  Future<void> updateDetails(String id, {int? priceClp, int? stock}) async {
    final product = _products[id];
    if (product == null) throw StateError('No existe el producto $id.');
    _products[id] = product.copyWith(priceClp: priceClp, stock: stock);
    _notify();
  }

  @override
  Future<void> deactivate(String id) async {
    _active[id] = false;
    _notify();
  }

  @override
  Future<void> decrementStock(Map<String, int> quantities) async {
    for (final entry in quantities.entries) {
      final product = _products[entry.key];
      final available = product != null && isActive(entry.key)
          ? product.stock
          : 0;
      if (available < entry.value) {
        throw OutOfStockException(product?.name ?? entry.key, available);
      }
    }
    for (final entry in quantities.entries) {
      final product = _products[entry.key]!;
      _products[entry.key] = product.copyWith(
        stock: product.stock - entry.value,
      );
    }
    _notify();
  }
}
