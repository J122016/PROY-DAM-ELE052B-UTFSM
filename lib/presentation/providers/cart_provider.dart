import 'package:flutter/foundation.dart';
import 'package:proyecto_dam/data/models/cart_item.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/data/repositories/cart_repository.dart';

class CartProvider extends ChangeNotifier {
  CartProvider(this._repository) {
    _items = List<CartItem>.from(_repository.load());
  }

  final CartRepository _repository;
  List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  int get totalItemsCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  int get totalPriceClp =>
      _items.fold(0, (sum, item) => sum + item.subtotalClp);

  double get totalCalories =>
      _items.fold(0, (sum, item) => sum + item.totalCalories);

  double get totalProteins =>
      _items.fold(0, (sum, item) => sum + item.totalProteins);

  double get totalCarbohydrates =>
      _items.fold(0, (sum, item) => sum + item.totalCarbohydrates);

  int quantityOf(String productId) {
    for (final item in _items) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }

  Future<void> addProduct(Product product, {int quantity = 1}) async {
    if (quantity <= 0) return;
    final maxStock = product.stock > 0 ? product.stock : 99;
    final index = _items.indexWhere((item) => item.product.id == product.id);
    final updated = List<CartItem>.from(_items);

    if (index >= 0) {
      final current = updated[index];
      final nextQty = (current.quantity + quantity).clamp(1, maxStock);
      updated[index] = current.copyWith(product: product, quantity: nextQty);
    } else {
      final initialQty = quantity.clamp(1, maxStock);
      updated.add(CartItem(product: product, quantity: initialQty));
    }

    await _repository.save(updated);
    _items = updated;
    notifyListeners();
  }

  Future<void> setQuantity(String productId, int quantity) async {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    final updated = List<CartItem>.from(_items);
    if (quantity <= 0) {
      updated.removeAt(index);
    } else {
      final product = updated[index].product;
      final maxStock = product.stock > 0 ? product.stock : 99;
      updated[index] = updated[index].copyWith(
        quantity: quantity.clamp(1, maxStock),
      );
    }

    await _repository.save(updated);
    _items = updated;
    notifyListeners();
  }

  Future<void> increment(String productId) async {
    final current = quantityOf(productId);
    if (current == 0) return;
    await setQuantity(productId, current + 1);
  }

  Future<void> decrement(String productId) async {
    final current = quantityOf(productId);
    if (current == 0) return;
    await setQuantity(productId, current - 1);
  }

  Future<void> removeProduct(String productId) async {
    final updated = _items
        .where((item) => item.product.id != productId)
        .toList();
    await _repository.save(updated);
    _items = updated;
    notifyListeners();
  }

  Future<void> clear() async {
    await _repository.save(const []);
    _items = [];
    notifyListeners();
  }

  Future<void> loadDemoItems([List<Product> catalogProducts = const []]) async {
    final validCatalog = catalogProducts
        .where((p) => p.priceClp > 0 && p.stock > 0)
        .take(3)
        .toList();

    if (validCatalog.isNotEmpty) {
      for (final product in validCatalog) {
        await addProduct(product);
      }
      return;
    }

    const demoProducts = [
      Product(
        id: 'bio-avena-01',
        name: 'Avena Integral Biológica Sin Gluten',
        brand: 'EcoVital',
        category: 'Desayunos',
        priceClp: 3450,
        stock: 24,
        calories: 379,
        proteins: 13.5,
        carbohydrates: 60.0,
        description:
            'Hojuelas de avena integral orgánica certificada libre de gluten.',
      ),
      Product(
        id: 'bio-quinoa-02',
        name: 'Quinoa Real Orgánica de los Andes',
        brand: 'BioAndes Organics',
        category: 'Granos y Cereales',
        priceClp: 4890,
        stock: 18,
        calories: 368,
        proteins: 14.1,
        carbohydrates: 64.2,
        description: 'Grano andino 100% orgánico de alto valor biológico.',
      ),
      Product(
        id: 'bio-chia-03',
        name: 'Semillas de Chía Negra Bio Raw',
        brand: 'Tierra Sana',
        category: 'Superalimentos',
        priceClp: 3990,
        stock: 30,
        calories: 486,
        proteins: 16.5,
        carbohydrates: 42.1,
        description: 'Semillas de chía orgánica ricas en Omega-3 y fibra.',
      ),
    ];

    for (final product in demoProducts) {
      await addProduct(product);
    }
  }
}

String formatClp(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[i]);
  }
  return '${amount < 0 ? '-' : ''}\$$buffer';
}
