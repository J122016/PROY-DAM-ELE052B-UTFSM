import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';
import 'package:proyecto_dam/data/repositories/product_repository.dart';
import 'package:proyecto_dam/data/services/open_food_facts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'catalog changes persist and refresh does not restore deleted products',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
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
      final provider = ProductProvider(
        repository: ProductRepository(preferences),
        service: service,
      );

      await provider.initialize();
      await provider.setStock('200', 7);
      await provider.addProduct(_localProduct('400', 'Quinoa'));
      await provider.deleteProduct('100');
      await expectLater(
        provider.addProduct(_localProduct('500', ' quinoa ')),
        throwsA(isA<StateError>()),
      );
      await provider.refreshCatalog();

      expect(provider.products.map((product) => product.id), [
        '200',
        '400',
        '300',
      ]);
      expect(provider.products.first.stock, 7);

      final restarted = ProductProvider(
        repository: ProductRepository(preferences),
        service: OpenFoodFactsService(
          client: MockClient((_) async {
            fail('A saved catalog must load without making a network request.');
          }),
        ),
      );
      await restarted.initialize();
      expect(restarted.isLocalCatalog, isTrue);
      expect(restarted.products.map((product) => product.id), [
        '200',
        '400',
        '300',
      ]);
      expect(restarted.products.first.stock, 7);

      service.close();
      provider.dispose();
      restarted.dispose();
    },
  );
}

Map<String, dynamic> _apiProduct(String id, String name) => {
  'code': id,
  'product_name': name,
  'nutriments': <String, Object>{},
};

Product _localProduct(String id, String name) =>
    Product(id: id, name: name, priceClp: 2500, stock: 0);
