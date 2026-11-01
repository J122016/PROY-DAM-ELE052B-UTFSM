import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StockControls extends StatelessWidget {
  const StockControls({
    required this.stock,
    required this.onChanged,
    super.key,
  });

  final int stock;
  final ValueChanged<int> onChanged;

  Future<void> _editStock(BuildContext context) async {
    final controller = TextEditingController(text: '$stock');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajustar stock'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Unidades disponibles'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text);
              if (parsed != null) Navigator.pop(context, parsed);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) onChanged(value);
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Disminuir stock',
        onPressed: stock == 0 ? null : () => onChanged(stock - 1),
        icon: const Icon(Icons.remove_circle_outline),
      ),
      InkWell(
        onTap: () => _editStock(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Text('$stock', style: Theme.of(context).textTheme.titleMedium),
        ),
      ),
      IconButton(
        tooltip: 'Aumentar stock',
        onPressed: () => onChanged(stock + 1),
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}
