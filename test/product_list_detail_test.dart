import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/data/repositories/cart_repository.dart';
import 'package:proyecto_dam/data/repositories/local_catalog.dart';
import 'package:proyecto_dam/data/repositories/product_repository.dart';
import 'package:proyecto_dam/data/services/open_food_facts_service.dart';
import 'package:proyecto_dam/presentation/pages/home.dart';
import 'package:proyecto_dam/presentation/pages/product_detail_page.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';
import 'package:proyecto_dam/presentation/providers/product_filter.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Open Food Facts data is mapped to nutrition fields in Spanish', () {
    final product = Product.fromOpenFoodFacts({
      'code': '0123',
      'product_name': 'Bio Hummus Classic',
      'pnns_groups_1': 'Fat and sauces',
      'nutriscore_grade': 'b',
      'nova_group': 3,
      'nutrient_levels': {'fat': 'high', 'salt': 'moderate'},
      'labels_tags': ['en:vegan', 'en:no-gluten'],
      'ingredients_analysis_tags': ['en:palm-oil-free'],
      'allergens_tags': ['en:sesame-seeds'],
      'quantity': '175 g',
      'serving_quantity': '30',
      'nutriments': {'fat_100g': 25.0, 'salt_100g': 1.2, 'sugars_100g': 0.5},
    })!;

    expect(product.category, 'Aceites y untables');
    expect(product.nutriScore, 'b');
    expect(product.novaGroup, 3);
    expect(product.labels, ['vegan', 'vegetarian', 'gluten-free', 'palm-oil-free']);
    expect(product.allergens, ['Sésamo']);
    expect(product.servingGrams, 30);
    expect(product.hasHighNutrient, isTrue);
    expect(Product.fromJson(product.toJson()).toJson(), product.toJson());
  });

  test('levels are computed when the API does not send them', () {
    const drink = Product(
      id: '1',
      name: 'Bebida',
      priceClp: 1000,
      stock: 1,
      sugars: 12,
      salt: 0.1,
      quantity: '1 L',
    );
    expect(drink.levels['sugars'], 'high');
    expect(drink.levels['salt'], 'low');
  });

  test('filters combine labels, Nutri-Score, levels, price and sort', () {
    final filter = const ProductFilter().copyWith(
      nutriScores: {'a'},
      withoutHighNutrients: true,
      sort: ProductSort.priceAsc,
    );
    final result = filter.apply(localCatalog);
    expect(result.map((p) => p.id), [
      'local-tofu',
      'local-avena',
      'local-quinoa',
    ]);
    expect(filter.activeCount, 3);
    expect(filter.cleared().activeCount, 0);
    expect(ProductFilter.categoriesOf(localCatalog), contains('Bebidas'));
  });

  testWidgets('product list adds, increments and removes items from the cart', (
    tester,
  ) async {
    final setup = await _setup(tester);

    expect(find.text('Quinoa Real Orgánica de los Andes'), findsOneWidget);
    await tester.tap(find.byTooltip('Agregar a la canasta').first);
    await tester.pumpAndSettle();
    expect(setup.cart.totalItemsCount, 1);

    await tester.tap(find.byTooltip('Agregar uno').first);
    await tester.pumpAndSettle();
    expect(setup.cart.totalItemsCount, 2);

    await tester.tap(find.byTooltip('Quitar uno').first);
    await tester.pumpAndSettle();
    expect(setup.cart.totalItemsCount, 1);
    await tester.tap(find.byTooltip('Quitar de la canasta').first);
    await tester.pumpAndSettle();
    expect(setup.cart.isEmpty, isTrue);

    await tester.scrollUntilVisible(
      find.text('Bebidas'),
      120,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bebidas'));
    await tester.pumpAndSettle();
    expect(find.text('Quinoa Real Orgánica de los Andes'), findsNothing);
    expect(find.text('Kombucha Bio Jengibre y Limón'), findsOneWidget);
  });

  testWidgets('product detail shows the nutrition summary and cart controls', (
    tester,
  ) async {
    final setup = await _setup(tester);
    final almond = localCatalog.firstWhere((p) => p.id == 'local-almendras');

    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailPage(
          product: almond,
          cartProvider: setup.cart,
          themeProvider: setup.theme,
          onOpenCart: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Resumen nutricional'), findsOneWidget);
    expect(find.text('ALTO EN\nGRASAS'), findsOneWidget);
    expect(find.text('Sin procesar o mínimamente procesado'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Ingredientes'), 200);
    expect(find.textContaining('Frutos secos'), findsOneWidget);

    await tester.tap(find.textContaining('Agregar ('));
    await tester.pumpAndSettle();
    expect(setup.cart.quantityOf(almond.id), 1);
    expect(find.text('Quitar de la canasta'), findsOneWidget);

    await tester.tap(find.text('Quitar de la canasta'));
    await tester.pumpAndSettle();
    expect(setup.cart.isEmpty, isTrue);
  });
}

Future<({CartProvider cart, ThemeProvider theme})> _setup(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final service = OpenFoodFactsService(
    client: MockClient((_) async => http.Response(jsonEncode({}), 503)),
  );
  final products = ProductProvider(
    repository: ProductRepository(preferences),
    service: service,
  );
  final cart = CartProvider(CartRepository(preferences));
  final theme = ThemeProvider(preferences);

  await tester.pumpWidget(
    MaterialApp(
      home: Home(
        productProvider: products,
        themeProvider: theme,
        cartProvider: cart,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (cart: cart, theme: theme);
}
