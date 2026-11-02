import 'dart:convert';
import 'dart:io' show HttpDate;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_dam/data/services/open_food_facts_service.dart';

void main() {
  test(
    'maps only Open Food Facts data and leaves missing nutrition unknown',
    () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'world.openfoodfacts.org');
        expect(request.url.queryParameters['fields'], contains('nutriments'));
        expect(request.headers['User-Agent'], contains('NutriMarket/0.1'));
        return http.Response(
          jsonEncode({
            'products': [
              {
                'code': '1234567890123',
                'product_name': 'Avena integral',
                'generic_name': 'Avena en hojuelas',
                'image_front_url': 'https://images.example.test/oats.png',
                'nutriments': {'proteins_100g': 13.2},
                'brands': 'Marca local',
              },
            ],
          }),
          200,
        );
      });
      final service = OpenFoodFactsService(client: client);

      final products = await service.searchProducts('avena');

      expect(products, hasLength(1));
      expect(products.single.name, 'Avena integral');
      expect(products.single.priceClp, 0);
      expect(products.single.stock, 0);
      expect(products.single.calories, isNull);
      expect(products.single.proteins, 13.2);
      expect(products.single.carbohydrates, isNull);
      service.close();
    },
  );

  test(
    '503 honors Retry-After and suppresses further requests during cooldown',
    () async {
      var requests = 0;
      final service = OpenFoodFactsService(
        client: MockClient((request) async {
          requests++;
          return http.Response(
            'Service Unavailable',
            503,
            headers: {'retry-after': '3600'},
          );
        }),
      );

      await expectLater(
        service.searchProducts('leche'),
        throwsA(
          isA<OpenFoodFactsException>().having(
            (error) => error.message,
            'message',
            contains('no se reintentará automáticamente'),
          ),
        ),
      );
      await expectLater(
        service.searchProducts('arroz'),
        throwsA(
          isA<OpenFoodFactsException>().having(
            (error) => error.message,
            'message',
            contains('está en pausa'),
          ),
        ),
      );
      expect(requests, 1);
      service.close();
    },
  );

  test('503 accepts an HTTP-date Retry-After header', () async {
    final service = OpenFoodFactsService(
      client: MockClient(
        (request) async => http.Response(
          'Service Unavailable',
          503,
          headers: {
            'retry-after': HttpDate.format(
              DateTime.now().toUtc().add(const Duration(days: 2)),
            ),
          },
        ),
      ),
    );

    await expectLater(
      service.searchProducts('leche'),
      throwsA(
        isA<OpenFoodFactsException>().having(
          (error) => error.message,
          'message',
          contains('86400 segundos'),
        ),
      ),
    );
    service.close();
  });
}
