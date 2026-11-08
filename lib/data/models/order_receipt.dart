import 'package:proyecto_dam/data/models/cart_item.dart';

enum PaymentMethod {
  card('Tarjeta'),
  cash('Efectivo'),
  transfer('Transferencia');

  const PaymentMethod(this.label);
  final String label;
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

  String get qrPayload =>
      'NUTRIMARKET:$orderNumber|COMPRADOR:$buyerName|ROL:$universityRol|TOTAL:$totalClp';
}
