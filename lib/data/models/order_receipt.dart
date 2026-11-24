import 'package:proyecto_dam/data/models/cart_item.dart';
import 'package:proyecto_dam/data/models/product.dart';

enum PaymentMethod {
  card('Tarjeta'),
  cash('Efectivo'),
  transfer('Transferencia');

  const PaymentMethod(this.label);
  final String label;

  static PaymentMethod fromName(Object? value) => PaymentMethod.values
      .firstWhere((method) => method.name == value, orElse: () => card);
}

enum OrderStatus {
  pending('Pendiente de retiro'),
  delivered('Entregado');

  const OrderStatus(this.label);
  final String label;

  static OrderStatus fromName(Object? value) => OrderStatus.values
      .firstWhere((status) => status.name == value, orElse: () => pending);
}

class OrderReceipt {
  const OrderReceipt({
    required this.orderNumber,
    required this.buyerName,
    required this.universityRol,
    required this.phone,
    required this.email,
    required this.pickupLocation,
    required this.paymentMethod,
    required this.totalClp,
    required this.totalCalories,
    required this.totalProteins,
    required this.totalCarbohydrates,
    required this.createdAt,
    required this.items,
    this.cashAmount,
    this.status = OrderStatus.pending,
    this.deliveredAt,
  });

  final String orderNumber;
  final String buyerName;
  final String universityRol;
  final String phone;
  final String email;
  final String pickupLocation;
  final PaymentMethod paymentMethod;
  final int? cashAmount;
  final int totalClp;
  final double totalCalories;
  final double totalProteins;
  final double totalCarbohydrates;
  final DateTime createdAt;
  final List<CartItem> items;
  final OrderStatus status;
  final DateTime? deliveredAt;

  String get qrPayload =>
      'NUTRIMARKET:$orderNumber|COMPRADOR:$buyerName|ROL:$universityRol|TOTAL:$totalClp';

  int get totalUnits => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isDelivered => status == OrderStatus.delivered;

  OrderReceipt copyWith({OrderStatus? status, DateTime? deliveredAt}) =>
      OrderReceipt(
        orderNumber: orderNumber,
        buyerName: buyerName,
        universityRol: universityRol,
        phone: phone,
        email: email,
        pickupLocation: pickupLocation,
        paymentMethod: paymentMethod,
        cashAmount: cashAmount,
        totalClp: totalClp,
        totalCalories: totalCalories,
        totalProteins: totalProteins,
        totalCarbohydrates: totalCarbohydrates,
        createdAt: createdAt,
        items: items,
        status: status ?? this.status,
        deliveredAt: deliveredAt ?? this.deliveredAt,
      );

  /// Mapa plano compatible con Firestore y con SharedPreferences (JSON).
  /// Los productos se guardan como una copia resumida: el pedido debe
  /// conservar el precio y el nombre del momento de la compra aunque el
  /// catálogo cambie después.
  Map<String, dynamic> toMap() => {
    'orderNumber': orderNumber,
    'buyerName': buyerName,
    'universityRol': universityRol,
    'phone': phone,
    'email': email,
    'pickupLocation': pickupLocation,
    'paymentMethod': paymentMethod.name,
    'cashAmount': cashAmount,
    'totalClp': totalClp,
    'totalCalories': totalCalories,
    'totalProteins': totalProteins,
    'totalCarbohydrates': totalCarbohydrates,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'status': status.name,
    'deliveredAt': deliveredAt?.millisecondsSinceEpoch,
    'items': items
        .map(
          (item) => {
            'productId': item.product.id,
            'name': item.product.name,
            'brand': item.product.brand,
            'imageUrl': item.product.imageUrl,
            'priceClp': item.product.priceClp,
            'quantity': item.quantity,
            'calories': item.product.calories,
            'proteins': item.product.proteins,
            'carbohydrates': item.product.carbohydrates,
          },
        )
        .toList(),
  };

  factory OrderReceipt.fromMap(Map<String, dynamic> map) {
    final orderNumber = map['orderNumber'];
    final createdAt = map['createdAt'];
    if (orderNumber is! String || orderNumber.isEmpty || createdAt is! int) {
      throw const FormatException('Invalid order data.');
    }
    final rawItems = map['items'];
    final deliveredAt = map['deliveredAt'];

    return OrderReceipt(
      orderNumber: orderNumber,
      buyerName: _string(map['buyerName']),
      universityRol: _string(map['universityRol']),
      phone: _string(map['phone']),
      email: _string(map['email']),
      pickupLocation: _string(map['pickupLocation']),
      paymentMethod: PaymentMethod.fromName(map['paymentMethod']),
      cashAmount: (map['cashAmount'] as num?)?.toInt(),
      totalClp: (map['totalClp'] as num?)?.toInt() ?? 0,
      totalCalories: (map['totalCalories'] as num?)?.toDouble() ?? 0,
      totalProteins: (map['totalProteins'] as num?)?.toDouble() ?? 0,
      totalCarbohydrates: (map['totalCarbohydrates'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      status: OrderStatus.fromName(map['status']),
      deliveredAt: deliveredAt is int
          ? DateTime.fromMillisecondsSinceEpoch(deliveredAt)
          : null,
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map((raw) => _itemFromMap(Map<String, dynamic>.from(raw)))
                .toList(growable: false)
          : const [],
    );
  }

  static CartItem _itemFromMap(Map<String, dynamic> map) => CartItem(
    product: Product(
      id: _string(map['productId']),
      name: _string(map['name']),
      brand: map['brand'] as String?,
      imageUrl: map['imageUrl'] as String?,
      priceClp: (map['priceClp'] as num?)?.toInt() ?? 0,
      stock: 0,
      calories: (map['calories'] as num?)?.toDouble(),
      proteins: (map['proteins'] as num?)?.toDouble(),
      carbohydrates: (map['carbohydrates'] as num?)?.toDouble(),
    ),
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
  );

  static String _string(Object? value) => value is String ? value : '';
}
