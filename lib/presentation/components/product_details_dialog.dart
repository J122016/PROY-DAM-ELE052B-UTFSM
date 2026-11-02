import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_dam/data/models/product.dart';

class ProductDetailsDialog extends StatefulWidget {
  const ProductDetailsDialog({
    required this.product,
    required this.title,
    required this.actionLabel,
    required this.initialStock,
    this.initialPrice,
    this.titleIcon,
    super.key,
  });

  final Product product;
  final String title;
  final String actionLabel;
  final int initialStock;
  final int? initialPrice;
  final IconData? titleIcon;

  @override
  State<ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<ProductDetailsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _priceController = TextEditingController(
    text: widget.initialPrice?.toString() ?? '',
  );
  late final _stockController = TextEditingController(
    text: '${widget.initialStock}',
  );

  @override
  void dispose() {
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(
      context,
    ).pop((int.parse(_priceController.text), int.parse(_stockController.text)));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: widget.titleIcon == null
        ? Text(widget.title)
        : Row(
            children: [
              Icon(
                widget.titleIcon,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(widget.title)),
            ],
          ),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: _ProductImage(url: widget.product.imageUrl),
              title: Text(
                widget.product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                widget.product.brand ?? 'Producto del catálogo local',
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final fields = [
                  _NumberField(
                    controller: _priceController,
                    label: 'Precio local (CLP) *',
                    allowZero: false,
                  ),
                  _NumberField(
                    controller: _stockController,
                    label: 'Stock disponible *',
                    allowZero: true,
                  ),
                ];
                if (constraints.maxWidth <= 360) {
                  return Column(
                    children: [
                      fields[0],
                      const SizedBox(height: 12),
                      fields[1],
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: fields[0]),
                    const SizedBox(width: 12),
                    Expanded(child: fields[1]),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _submit, child: Text(widget.actionLabel)),
    ],
  );
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.allowZero,
  });

  final TextEditingController controller;
  final String label;
  final bool allowZero;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final parsed = int.tryParse(value ?? '');
      if (parsed == null || (!allowZero && parsed == 0)) {
        return allowZero ? 'Ingresa un entero' : 'Debe ser mayor que cero';
      }
      return null;
    },
  );
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final uri = url == null ? null : Uri.tryParse(url!);
    final placeholder = Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: const Icon(Icons.inventory_2_outlined),
    );
    if (uri == null || uri.scheme != 'https') return placeholder;
    return Image.network(
      url!,
      width: 56,
      height: 56,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
