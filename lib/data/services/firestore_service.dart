// Archivo de ejemplo (desde clase) para integrar Firestore
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {

  // EJEMPLO Método para obtener una colección desde Firestore
  Stream<QuerySnapshot> collection() {
    return FirebaseFirestore.instance.collection('collection_example').snapshots();
  }

  // EJEMPLO Método para agregar un documento a la colección en Firestore
  Future collectionAdd(String value1, String value2, int value3, int value4) {
    return FirebaseFirestore.instance.collection('collection_example').doc().set({
      'value1': value1,
      'value2': value2,
      'value3': value3,
      'value4': value4,
    });
  }
}
