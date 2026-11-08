import 'package:flutter/foundation.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/data/repositories/local_catalog.dart';
import 'package:proyecto_dam/data/repositories/product_repository.dart';
import 'package:proyecto_dam/data/services/open_food_facts_service.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider({required this._repository, required this._service});

  final ProductRepository _repository;
  final OpenFoodFactsService _service;
  List<Product> _products = [];
  Set<String> _deletedIds = {};
  bool isLoading = true;
  bool isRefreshing = false;
  bool isLocalCatalog = false;
  bool isBackupCatalog = false;
  String? errorMessage;

  List<Product> get products => List.unmodifiable(_products);

  Future<void> initialize() async {
    try {
      final snapshot = _repository.load();
      if (snapshot != null) {
        _products = snapshot.products;
        _deletedIds = snapshot.deletedIds;
        isLocalCatalog = true;
        return;
      }
      _products = await _service.fetchOrganicProducts();
      await _repository.save(_products, _deletedIds);
      isLocalCatalog = false;
    } catch (error) {
      errorMessage = error.toString();
      // Sin catálogo guardado y sin API se muestra el de respaldo, sin guardarlo,
      // para que la próxima apertura vuelva a consultar Open Food Facts.
      if (_products.isEmpty) {
        _products = List.of(localCatalog);
        isLocalCatalog = true;
        isBackupCatalog = true;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCatalog() async {
    if (isRefreshing) return;
    isRefreshing = true;
    errorMessage = null;
    notifyListeners();
    try {
      final remoteProducts = await _service.fetchOrganicProducts();
      final merged = [..._products];
      for (final remote in remoteProducts) {
        final duplicate = merged.any(
          (product) =>
              product.id == remote.id ||
              _normalize(product.name) == _normalize(remote.name),
        );
        if (!duplicate && !_deletedIds.contains(remote.id)) merged.add(remote);
      }
      await _repository.save(merged, _deletedIds);
      _products = merged;
      isLocalCatalog = true;
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
    final updated = _products
        .map(
          (product) =>
              product.id == id ? _copy(product, stock: stock) : product,
        )
        .toList();
    await _repository.save(updated, _deletedIds);
    _products = updated;
    isLocalCatalog = true;
    notifyListeners();
  }

  Future<void> updateLocalDetails(
    String id, {
    required int priceClp,
    required int stock,
  }) async {
    if (priceClp < 0 || stock < 0) {
      throw ArgumentError('Price and stock must be non-negative.');
    }
    final updated = _products
        .map(
          (product) => product.id == id
              ? product.copyWith(priceClp: priceClp, stock: stock)
              : product,
        )
        .toList();
    await _repository.save(updated, _deletedIds);
    _products = updated;
    isLocalCatalog = true;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final isDuplicate = _products.any(
      (existing) =>
          existing.id == product.id ||
          _normalize(existing.name) == _normalize(product.name),
    );
    if (isDuplicate) throw StateError('Este producto ya está en el catálogo.');
    final updated = [..._products, product];
    final deleted = {..._deletedIds}..remove(product.id);
    await _repository.save(updated, deleted);
    _products = updated;
    _deletedIds = deleted;
    isLocalCatalog = true;
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    final updated = _products.where((product) => product.id != id).toList();
    final deleted = {..._deletedIds, id};
    await _repository.save(updated, deleted);
    _products = updated;
    _deletedIds = deleted;
    isLocalCatalog = true;
    notifyListeners();
  }

  static String _normalize(String value) => value.trim().toLowerCase();

  static Product _copy(Product product, {required int stock}) =>
      product.copyWith(stock: stock);
}
