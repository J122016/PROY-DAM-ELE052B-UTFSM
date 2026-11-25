import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/data/services/open_food_facts_service.dart';
import 'package:proyecto_dam/data/services/product_service.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';

import 'support/in_memory_product_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'catalog changes are shared through the store and refresh does not restore deleted products',
    () async {
      final store = InMemoryProductStore();
      var requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        final products = requestCount == 1
            ? [_apiProduct('100', 'Avena'), _apiProduct('200', 'Arroz')]
            : [
                _apiProduct('100', 'Avena'),
                _apiProduct('200', 'Arroz'),
                _apiProduct('300', 'Lentejas'),
              ];
        return http.Response(jsonEncode({'products': products}), 200);
      });
      final service = OpenFoodFactsService(client: client);
      final provider = ProductProvider(store: store, service: service);

      await provider.initialize();
      expect(provider.products, isEmpty);

      await provider.refreshCatalog();
      await pumpEventQueue();
      await provider.setStock('200', 7);
      await provider.addProduct(_localProduct('400', 'Quinoa'));
      await provider.deleteProduct('100');
      await pumpEventQueue();
      await expectLater(
        provider.addProduct(_localProduct('500', ' quinoa ')),
        throwsA(isA<StateError>()),
      );
      await provider.refreshCatalog();
      await pumpEventQueue();

      expect(provider.products.map((product) => product.id), [
        '200',
        '300',
        '400',
      ]);
      expect(provider.products.first.stock, 7);
      expect(store.isActive('100'), isFalse);

      // Otro dispositivo que abre la app ve el mismo catálogo.
      final otherDevice = ProductProvider(
        store: store,
        service: OpenFoodFactsService(
          client: MockClient((_) async {
            fail('Opening the store must not call Open Food Facts.');
          }),
        ),
      );
      await otherDevice.initialize();
      expect(otherDevice.products.map((product) => product.id), [
        '200',
        '300',
        '400',
      ]);

      service.close();
      provider.dispose();
      otherDevice.dispose();
    },
  );

  test('reserveStock discounts every item or none of them', () async {
    final store = InMemoryProductStore([
      const Product(id: 'a', name: 'Avena', priceClp: 3000, stock: 5),
      const Product(id: 'b', name: 'Chía', priceClp: 4000, stock: 1),
    ]);
    final provider = ProductProvider(
      store: store,
      service: OpenFoodFactsService(),
    );
    await provider.initialize();

    await provider.reserveStock({'a': 2, 'demo-fuera-del-catalogo': 3});
    expect(store.byId('a')!.stock, 3);

    await expectLater(
      provider.reserveStock({'a': 1, 'b': 2}),
      throwsA(
        isA<OutOfStockException>()
            .having((error) => error.available, 'available', 1)
            .having((error) => error.productName, 'productName', 'Chía'),
      ),
    );
    expect(store.byId('a')!.stock, 3);
    expect(store.byId('b')!.stock, 1);

    provider.dispose();
  });

  test('a store error shows the backup catalog', () async {
    final store = InMemoryProductStore()..failNextWatch = true;
    final provider = ProductProvider(
      store: store,
      service: OpenFoodFactsService(),
    );
    await provider.initialize();

    expect(provider.isBackupCatalog, isTrue);
    expect(provider.products, isNotEmpty);
    expect(provider.errorMessage, contains('sin conexión'));

    provider.dispose();
  });
}

Map<String, dynamic> _apiProduct(String id, String name) => {
  'code': id,
  'product_name': name,
  'nutriments': <String, Object>{},
};

Product _localProduct(String id, String name) =>
    Product(id: id, name: name, priceClp: 2500, stock: 0);
