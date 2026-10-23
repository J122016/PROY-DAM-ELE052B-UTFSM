import 'package:flutter/material.dart';
import 'package:proyecto_dam/constants.dart';
import 'package:proyecto_dam/pages/home.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NutriMarket',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: kFontFamily,
        scaffoldBackgroundColor: kBackgroundColor,
        
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          primary: kPrimaryColor,
          secondary: kSecondaryColor,
          surface: kCardBackgroundColor,
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: kBackgroundColor,
          foregroundColor: kTextColor, 
          elevation: 0,
          centerTitle: false,
        ),

        searchBarTheme: SearchBarThemeData(
          backgroundColor: WidgetStateProperty.all(kSurfaceColor),
          elevation: WidgetStateProperty.all(0),
          hintStyle: WidgetStateProperty.all(const TextStyle(color: kMutedTextColor)),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: kSurfaceColor,
          selectedColor: kPrimaryColor,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),

        cardTheme: CardThemeData(
          color: kCardBackgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: kBorderColor, width: 1),
          ),
        ),
      ),
      home: const Home(),
    );
  }
}
