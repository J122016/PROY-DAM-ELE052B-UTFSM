import 'package:flutter/material.dart';

class ExampleComponent extends StatefulWidget {
  const ExampleComponent({super.key});

  @override
  State<ExampleComponent> createState() => _ExampleComponentState();
}

class _ExampleComponentState extends State<ExampleComponent> {
  @override
  Widget build(BuildContext context) {
    return Text("Example text");
  }
}