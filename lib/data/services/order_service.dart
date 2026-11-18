import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_dam/data/models/order_receipt.dart';

/// Contrato para guardar y leer pedidos. La app usa [FirestoreOrderStore];
/// las pruebas pueden entregar una implementación en memoria.
abstract class OrderStore {
  /// Guarda (o reemplaza) el pedido completo.
  Future<void> save(OrderReceipt order);

  /// Obtiene los pedidos con esos números. Los que no existan se omiten.
  Future<List<OrderReceipt>> fetchByNumbers(List<String> orderNumbers);

  /// Todos los pedidos, del más reciente al más antiguo (vista admin).
  Stream<List<OrderReceipt>> watchAll();

  /// Cambia el estado de un pedido (por ejemplo, al entregarlo).
  Future<void> updateStatus(String orderNumber, OrderStatus status);
}

class FirestoreOrderStore implements OrderStore {
  FirestoreOrderStore({this.firestore});

  static const collectionName = 'orders';

  final FirebaseFirestore? firestore;

  // Se resuelve recién al usarlo: así crear la clase no exige Firebase
  // inicializado (útil en pruebas que nunca llaman a sus métodos).
  CollectionReference<Map<String, dynamic>> get _orders =>
      (firestore ?? FirebaseFirestore.instance).collection(collectionName);

  @override
  Future<void> save(OrderReceipt order) =>
      _orders.doc(order.orderNumber).set(order.toMap());

  @override
  Future<List<OrderReceipt>> fetchByNumbers(List<String> orderNumbers) async {
    final snapshots = await Future.wait(
      orderNumbers.map((number) => _orders.doc(number).get()),
    );
    return [
      for (final snapshot in snapshots)
        if (snapshot.exists && snapshot.data() != null)
          OrderReceipt.fromMap(snapshot.data()!),
    ];
  }

  @override
  Stream<List<OrderReceipt>> watchAll() => _orders
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (query) => query.docs
            .map((doc) => OrderReceipt.fromMap(doc.data()))
            .toList(growable: false),
      );

  @override
  Future<void> updateStatus(String orderNumber, OrderStatus status) =>
      _orders.doc(orderNumber).update({
        'status': status.name,
        'deliveredAt': status == OrderStatus.delivered
            ? DateTime.now().millisecondsSinceEpoch
            : null,
      });
}
