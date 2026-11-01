import 'package:flutter_test/flutter_test.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'product JSON round trip preserves optional nutrition and local fields',
    () {
      const product = Product(
        id: '1234567890123',
        name: 'Avena',
        priceClp: 2990,
        stock: 4,
        calories: 370,
        proteins: 13.2,
        brand: 'Campo',
      );

      expect(Product.fromJson(product.toJson()).toJson(), product.toJson());
    },
  );

  test(
    'invalid id, price, or stock is rejected at the persistence boundary',
    () {
      expect(
        () => Product.fromJson({
          'id': '',
          'name': 'Avena',
          'priceClp': 100,
          'stock': 0,
        }),
        throwsFormatException,
      );
      expect(
        () => Product.fromJson({
          'id': '123',
          'name': 'Avena',
          'priceClp': -1,
          'stock': 0,
        }),
        throwsFormatException,
      );
      expect(
        () => Product.fromJson({
          'id': '123',
          'name': 'Avena',
          'priceClp': 100,
          'stock': -1,
        }),
        throwsFormatException,
      );
    },
  );

  test('theme defaults to light and restores the saved selection', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final initialTheme = ThemeProvider(preferences);
    expect(initialTheme.isDarkMode, isFalse);
    await initialTheme.toggle();
    initialTheme.dispose();

    final restoredTheme = ThemeProvider(preferences);
    expect(restoredTheme.isDarkMode, isTrue);
    restoredTheme.dispose();
  });
}
