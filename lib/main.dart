import 'package:flutter/material.dart';
import 'package:proyecto_dam/constants.dart';
import 'package:proyecto_dam/presentation/pages/home.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';
import 'package:proyecto_dam/data/repositories/product_repository.dart';
import 'package:proyecto_dam/data/services/open_food_facts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
  
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(MainApp(preferences: preferences));
}

class MainApp extends StatefulWidget {
  const MainApp({required this.preferences, super.key});

  final SharedPreferences preferences;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final ThemeProvider _themeProvider;
  late final ProductProvider _productProvider;

  @override
  void initState() {
    super.initState();
    _themeProvider = ThemeProvider(widget.preferences);
    _productProvider = ProductProvider(
      repository: ProductRepository(widget.preferences),
      service: OpenFoodFactsService(),
    );
  }

  @override
  void dispose() {
    _themeProvider.dispose();
    _productProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _themeProvider,
    builder: (context, child) => MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NutriMarket',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Home(
        productProvider: _productProvider,
        themeProvider: _themeProvider,
      ),
    ),
  );

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? kDarkSurface : kLightSurface;
    final scheme =
        ColorScheme.fromSeed(
          seedColor: kBrandColor,
          brightness: brightness,
        ).copyWith(
          primary: isDark ? const Color(0xFF72D5AB) : kBrandColor,
          secondary: kAccentColor,
          surface: surface,
          onSurface: isDark ? kDarkText : kLightText,
          error: kErrorColor,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? kDarkBackground : kLightBackground,
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? kDarkBackground : kLightBackground,
        foregroundColor: isDark ? kDarkText : kLightText,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isDark ? kDarkBorder : kLightBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? kDarkBorder : kLightBorder,
      ),
    );
  }
}
