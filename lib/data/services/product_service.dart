import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:proyecto_dam/data/models/product.dart';

/// No alcanza el stock para un producto del pedido.
class OutOfStockException implements Exception {
  const OutOfStockException(this.productName, this.available);

  final String productName;
  final int available;

  @override
  String toString() => available == 0
      ? '$productName ya no tiene stock.'
      : 'Solo quedan $available unidades de $productName.';
}

/// Contrato del catálogo de la tienda. La app usa [FirestoreProductStore];
/// las pruebas pueden entregar una implementación en memoria.
abstract class ProductStore {
  /// Productos activos de la tienda, actualizados en vivo.
  Stream<List<Product>> watchActive();

  /// Ids de todos los productos guardados, también los eliminados, para no
  /// volver a importarlos desde Open Food Facts.
  Future<Set<String>> knownIds();

  /// Crea o reemplaza productos y los deja activos.
  Future<void> saveAll(List<Product> products);

  /// Cambia el precio y/o el stock de un producto.
  Future<void> updateDetails(String id, {int? priceClp, int? stock});

  /// Saca el producto de la tienda sin borrar su registro.
  Future<void> deactivate(String id);

  /// Descuenta stock de varios productos de una vez. Si alguno no alcanza,
  /// no descuenta nada y lanza [OutOfStockException].
  Future<void> decrementStock(Map<String, int> quantities);
}

class FirestoreProductStore implements ProductStore {
  FirestoreProductStore({this.firestore});

  static const collectionName = 'products';

  final FirebaseFirestore? firestore;

  FirebaseFirestore get _db => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _products =>
      _db.collection(collectionName);

  @override
  Stream<List<Product>> watchActive() => _products
      .where('active', isEqualTo: true)
      .snapshots()
      .map(
        (query) =>
            query.docs.map(_fromDoc).whereType<Product>().toList()
              ..sort((a, b) => a.name.compareTo(b.name)),
      );

  @override
  Future<Set<String>> knownIds() async {
    final query = await _products.get();
    return query.docs.map((doc) => doc.id).toSet();
  }

  @override
  Future<void> saveAll(List<Product> products) async {
    final batch = _db.batch();
    for (final product in products) {
      batch.set(_products.doc(product.id), {
        ...product.toJson(),
        'active': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> updateDetails(String id, {int? priceClp, int? stock}) =>
      _products.doc(id).update({
        'priceClp': ?priceClp,
        'stock': ?stock,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> deactivate(String id) => _products.doc(id).update({
    'active': false,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> decrementStock(Map<String, int> quantities) =>
      _db.runTransaction((transaction) async {
        final updates = <DocumentReference<Map<String, dynamic>>, int>{};
        for (final entry in quantities.entries) {
          final ref = _products.doc(entry.key);
          final data = (await transaction.get(ref)).data();
          final stock = data?['stock'];
          final available = stock is int && data?['active'] == true ? stock : 0;
          if (available < entry.value) {
            throw OutOfStockException(
              data?['name'] as String? ?? entry.key,
              available,
            );
          }
          updates[ref] = available - entry.value;
        }
        for (final update in updates.entries) {
          transaction.update(update.key, {
            'stock': update.value,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

  static Product? _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      return Product.fromJson({...doc.data(), 'id': doc.id});
    } on FormatException {
      return null;
    }
  }
}
