import 'package:flutter/material.dart';
import 'package:proyecto_dam/pages/components/example_component.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('NutriMarket')),
      body: Center(child: ExampleComponent())
    );
  }
}
