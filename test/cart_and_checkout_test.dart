import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/data/repositories/cart_repository.dart';
import 'package:proyecto_dam/data/repositories/product_repository.dart';
import 'package:proyecto_dam/data/services/open_food_facts_service.dart';
import 'package:proyecto_dam/presentation/pages/cart_page.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cart provider calculates totals and persists items', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cartProvider = CartProvider(CartRepository(preferences));

    const product = Product(
      id: 'avena-1',
      name: 'Avena Integral Bio',
      priceClp: 3450,
      stock: 10,
      calories: 379,
      proteins: 13.5,
      carbohydrates: 60.0,
    );

    await cartProvider.addProduct(product, quantity: 2);
    expect(cartProvider.totalItemsCount, 2);
    expect(cartProvider.totalPriceClp, 6900);
    expect(cartProvider.totalCalories, 758);
    expect(cartProvider.totalProteins, 27.0);
    expect(cartProvider.totalCarbohydrates, 120.0);

    final reloaded = CartProvider(CartRepository(preferences));
    expect(reloaded.totalItemsCount, 2);
    expect(reloaded.totalPriceClp, 6900);

    cartProvider.dispose();
    reloaded.dispose();
  });

  testWidgets('cart view, checkout flow and pickup QR receipt work end-to-end', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final service = OpenFoodFactsService(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'products': []}), 200),
      ),
    );
    final productProvider = ProductProvider(
      repository: ProductRepository(preferences),
      service: service,
    );
    final cartProvider = CartProvider(CartRepository(preferences));
    final themeProvider = ThemeProvider(preferences);

    await productProvider.initialize();
    const product = Product(
      id: 'quinoa-1',
      name: 'Quinoa Real Orgánica',
      priceClp: 4890,
      stock: 5,
      calories: 368,
      proteins: 14.1,
      carbohydrates: 64.2,
    );
    await productProvider.addProduct(product);
    await cartProvider.addProduct(product);

    await tester.pumpWidget(
      MaterialApp(
        home: CartPage(
          cartProvider: cartProvider,
          productProvider: productProvider,
          themeProvider: themeProvider,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Canasta de Alimentos'), findsOneWidget);
    expect(find.text('Resumen Nutricional del Pedido'), findsOneWidget);
    expect(find.text('Quinoa Real Orgánica'), findsOneWidget);

    await tester.tap(find.text('Ir a Pagar'));
    await tester.pumpAndSettle();

    expect(find.text('Caja y Retiro'), findsOneWidget);
    expect(find.text('1. DATOS DEL COMPRADOR'), findsOneWidget);
    expect(find.text('2. MEDIO DE PAGO'), findsOneWidget);

    final submitFinder = find.textContaining('Confirmar Pedido');
    await tester.scrollUntilVisible(
      submitFinder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(submitFinder);
    await tester.pumpAndSettle();

    expect(find.text('Comprobante de Retiro'), findsOneWidget);
    expect(find.text('¡COMPRA EXITOSA!'), findsOneWidget);
    expect(find.text('Código QR de Retiro'), findsOneWidget);
    expect(cartProvider.isEmpty, isTrue);
    expect(productProvider.products.first.stock, 4);

    service.close();
    productProvider.dispose();
    cartProvider.dispose();
    themeProvider.dispose();
  });
}
