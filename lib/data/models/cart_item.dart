import 'package:proyecto_dam/data/models/product.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
  });

  final Product product;
  final int quantity;

  int get subtotalClp => product.priceClp * quantity;

  double get totalCalories => (product.calories ?? 0) * quantity;

  double get totalProteins => (product.proteins ?? 0) * quantity;

  double get totalCarbohydrates => (product.carbohydrates ?? 0) * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) => CartItem(
    product: product ?? this.product,
    quantity: quantity ?? this.quantity,
  );

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final productJson = json['product'];
    final quantity = json['quantity'];
    if (productJson is! Map || quantity is! int || quantity <= 0) {
      throw const FormatException('Invalid cart item data.');
    }
    return CartItem(
      product: Product.fromJson(Map<String, dynamic>.from(productJson)),
      quantity: quantity,
    );
  }

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };
}
