import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/data/repositories/local_catalog.dart';
import 'package:proyecto_dam/data/services/open_food_facts_service.dart';
import 'package:proyecto_dam/data/services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({required this._store, required this._service});

  final ProductStore _store;
  final OpenFoodFactsService _service;
  StreamSubscription<List<Product>>? _subscription;
  List<Product> _products = [];
  bool isLoading = true;
  bool isRefreshing = false;
  bool isBackupCatalog = false;
  String? errorMessage;

  List<Product> get products => List.unmodifiable(_products);

  /// Escucha el catálogo de Firestore. Cada cambio del admin o compra llega solo.
  /// El Future termina con la primera carga.
  Future<void> initialize() {
    final firstLoad = Completer<void>();
    _subscription?.cancel();
    isLoading = true;
    errorMessage = null;
    _subscription = _store.watchActive().listen(
      (products) {
        _products = products;
        isBackupCatalog = false;
        isLoading = false;
        notifyListeners();
        if (!firstLoad.isCompleted) firstLoad.complete();
      },
      onError: (Object error) {
        errorMessage = 'No se pudo cargar el catálogo de la tienda: $error';
        // Sin conexión y sin nada cargado se muestra el catálogo de respaldo.
        if (_products.isEmpty) {
          _products = List.of(localCatalog);
          isBackupCatalog = true;
        }
        isLoading = false;
        notifyListeners();
        if (!firstLoad.isCompleted) firstLoad.complete();
      },
    );
    return firstLoad.future;
  }

  /// Importa a la tienda los productos orgánicos nuevos de Open Food Facts.
  /// No trae de vuelta los que el admin eliminó.
  Future<void> refreshCatalog() async {
    if (isRefreshing) return;
    isRefreshing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final remoteProducts = await _service.fetchOrganicProducts();
      final knownIds = await _store.knownIds();
      final names = _products
          .map((product) => _normalize(product.name))
          .toSet();
      final newProducts = <Product>[];
      for (final remote in remoteProducts) {
        final name = _normalize(remote.name);
        if (knownIds.contains(remote.id) || names.contains(name)) continue;
        names.add(name);
        newProducts.add(remote);
      }
      if (newProducts.isNotEmpty) await _store.saveAll(newProducts);
    } catch (error) {
      errorMessage = error.toString();
    } finally {
      isRefreshing = false;
      notifyListeners();
    }
  }

  Future<List<Product>> searchOpenFoodFacts(String query) =>
      _service.searchProducts(query);

  Future<void> setStock(String id, int stock) async {
    if (stock < 0) throw ArgumentError.value(stock, 'stock');
    await _store.updateDetails(id, stock: stock);
  }

  Future<void> updateDetails(
    String id, {
    required int priceClp,
    required int stock,
  }) async {
    if (priceClp < 0 || stock < 0) {
      throw ArgumentError('Price and stock must be non-negative.');
    }
    await _store.updateDetails(id, priceClp: priceClp, stock: stock);
  }

  Future<void> addProduct(Product product) async {
    final isDuplicate = _products.any(
      (existing) =>
          existing.id == product.id ||
          _normalize(existing.name) == _normalize(product.name),
    );
    if (isDuplicate) throw StateError('Este producto ya está en el catálogo.');
    await _store.saveAll([product]);
  }

  Future<void> deleteProduct(String id) => _store.deactivate(id);

  /// Descuenta del stock de la tienda lo comprado. Los productos que no están
  /// en el catálogo (por ejemplo los de demostración) se ignoran.
  Future<void> reserveStock(Map<String, int> quantities) async {
    final catalogIds = _products.map((product) => product.id).toSet();
    final inCatalog = {
      for (final entry in quantities.entries)
        if (catalogIds.contains(entry.key) && entry.value > 0)
          entry.key: entry.value,
    };
    if (inCatalog.isEmpty) return;
    await _store.decrementStock(inCatalog);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
