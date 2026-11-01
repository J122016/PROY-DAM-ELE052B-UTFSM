import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/presentation/pages/add_product.dart';
import 'package:proyecto_dam/presentation/pages/admin_products.dart';
import 'package:proyecto_dam/presentation/components/product_details_dialog.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';
import 'package:proyecto_dam/data/repositories/product_repository.dart';
import 'package:proyecto_dam/data/services/open_food_facts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('product details dialog fits narrow screens without an image', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const product = Product(
      id: 'no-image',
      name: 'Product without image',
      priceClp: 0,
      stock: 0,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => const ProductDetailsDialog(
                    product: product,
                    title: 'Edit product',
                    actionLabel: 'Save',
                    initialStock: 0,
                  ),
                ),
                child: const Text('Open dialog'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('admin controls adjust stock and confirm product removal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = OpenFoodFactsService(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'products': [
              {'code': '123', 'product_name': 'Avena'},
            ],
          }),
          200,
        ),
      ),
    );
    final provider = ProductProvider(
      repository: ProductRepository(preferences),
      service: service,
    );
    final themeProvider = ThemeProvider(preferences);
    await provider.initialize();

    await tester.pumpWidget(
      MaterialApp(
        home: AdminProductsPage(
          productProvider: provider,
          themeProvider: themeProvider,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Avena'), findsOneWidget);

    await tester.tap(find.byTooltip('Aumentar stock en una unidad'));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byTooltip('Modificar precio y stock'));
    await tester.pumpAndSettle();
    final editFields = find.byType(TextFormField);
    await tester.enterText(editFields.first, '3250');
    await tester.enterText(editFields.last, '8');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(provider.products.single.priceClp, 3250);
    expect(provider.products.single.stock, 8);

    await tester.tap(find.byTooltip('Eliminar producto'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('Avena'), findsNothing);

    service.close();
    provider.dispose();
    themeProvider.dispose();
  });

  testWidgets(
    'Open Food Facts import requires local price and saves the product',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final service = OpenFoodFactsService(
        client: MockClient((request) async {
          final products = request.url.path.endsWith('search.pl')
              ? [
                  {
                    'code': '456',
                    'product_name': 'Avena integral',
                    'nutriments': {'proteins_100g': 12.5},
                  },
                ]
              : <Map<String, dynamic>>[];
          return http.Response(jsonEncode({'products': products}), 200);
        }),
      );
      final provider = ProductProvider(
        repository: ProductRepository(preferences),
        service: service,
      );
      await provider.initialize();

      await tester.pumpWidget(
        MaterialApp(home: AddProductPage(productProvider: provider)),
      );
      await tester.enterText(find.byType(TextField).first, 'avena');
      await tester.tap(find.byTooltip('Buscar productos'));
      await tester.pumpAndSettle();
      expect(find.text('Avena integral'), findsOneWidget);

      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Agregar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '2990');
      await tester.tap(find.widgetWithText(FilledButton, 'Agregar producto'));
      await tester.pumpAndSettle();

      expect(provider.products.single.priceClp, 2990);
      expect(provider.products.single.stock, 0);
      expect(provider.products.single.proteins, 12.5);

      service.close();
      provider.dispose();
    },
  );
}
