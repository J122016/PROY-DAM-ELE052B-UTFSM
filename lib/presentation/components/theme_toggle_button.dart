import 'package:flutter/material.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({
    required this.isDark,
    required this.onPressed,
    super.key,
  });

  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    onPressed: onPressed,
    tooltip: isDark ? 'Cambiar a tema claro' : 'Cambiar a tema oscuro',
    icon: Icon(isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
  );
}
