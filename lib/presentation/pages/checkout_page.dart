import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:proyecto_dam/data/models/order_receipt.dart';
import 'package:proyecto_dam/presentation/components/nutrition_summary_card.dart';
import 'package:proyecto_dam/presentation/components/theme_toggle_button.dart';
import 'package:proyecto_dam/presentation/pages/order_receipt_page.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({
    required this.cartProvider,
    required this.productProvider,
    required this.themeProvider,
    super.key,
  });

  final CartProvider cartProvider;
  final ProductProvider productProvider;
  final ThemeProvider themeProvider;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static final _rolRegex = RegExp(r'^\d{6,9}-[\dkK]$');

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Jaime Guzmán');
  final _rolController = TextEditingController(text: '202348115-9');
  final _phoneController = TextEditingController(text: '+56 9 8765 4321');
  final _emailController = TextEditingController(text: 'usuario@usm.cl');
  final _pickupController = TextEditingController(
    text: 'Campus Universitario - Punto Limpio / Casillero',
  );
  final _cardNumberController = TextEditingController(
    text: '4532 •••• •••• 8891',
  );
  final _cardExpiryController = TextEditingController(text: '08/28');
  final _cardCvvController = TextEditingController(text: '342');
  final _cashAmountController = TextEditingController(text: '20000');

  PaymentMethod _selectedPayment = PaymentMethod.card;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rolController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pickupController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _cashAmountController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (widget.cartProvider.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final items = List.of(widget.cartProvider.items);
      final totalClp = widget.cartProvider.totalPriceClp;
      final totalCalories = widget.cartProvider.totalCalories;
      final totalProteins = widget.cartProvider.totalProteins;
      final totalCarbohydrates = widget.cartProvider.totalCarbohydrates;

      // Descontar stock en catálogo local si el producto existe allí
      for (final item in items) {
        final catalogMatch = widget.productProvider.products
            .where((p) => p.id == item.product.id)
            .toList();
        if (catalogMatch.isNotEmpty) {
          final currentStock = catalogMatch.first.stock;
          final nextStock = max(0, currentStock - item.quantity);
          await widget.productProvider.setStock(item.product.id, nextStock);
        }
      }

      final randomSuffix = 100000 + Random().nextInt(900000);
      final receipt = OrderReceipt(
        orderNumber: 'NM-$randomSuffix',
        buyerName: _nameController.text.trim(),
        universityRol: _rolController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        pickupLocation: _pickupController.text.trim(),
        paymentMethod: _selectedPayment,
        cashAmount: _selectedPayment == PaymentMethod.cash
            ? int.tryParse(_cashAmountController.text.trim())
            : null,
        totalClp: totalClp,
        totalCalories: totalCalories,
        totalProteins: totalProteins,
        totalCarbohydrates: totalCarbohydrates,
        createdAt: DateTime.now(),
        items: items,
      );

      await widget.cartProvider.clear();
      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (context) => OrderReceiptPage(
            receipt: receipt,
            themeProvider: widget.themeProvider,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cart = widget.cartProvider;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Caja y Retiro'),
            Text(
              'Completa tus datos para retiro y boleta',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
              ),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: widget.themeProvider,
            builder: (context, child) => ThemeToggleButton(
              isDark: widget.themeProvider.isDarkMode,
              onPressed: widget.themeProvider.toggle,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            children: [
              NutritionSummaryCard(
                title: 'Aporte Nutricional del Pedido',
                subtitle: null,
                totalPriceClp: cart.totalPriceClp,
                calories: cart.totalCalories,
                proteins: cart.totalProteins,
                carbohydrates: cart.totalCarbohydrates,
              ),
              const SizedBox(height: 14),
              // Sección 1: Datos del comprador
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '1. DATOS DEL COMPRADOR',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo *',
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Ingresa tu nombre completo'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _rolController,
                        decoration: const InputDecoration(
                          labelText: 'ROL Universitario *',
                          hintText: 'Ej: 202373019-4',
                          helperText:
                              'Identificación universitaria de estudiante (ej: 202373019-4)',
                          prefixIcon: Icon(Icons.school_outlined, size: 18),
                        ),
                        validator: (value) {
                          final clean = value?.trim() ?? '';
                          if (clean.isEmpty) {
                            return 'Ingresa tu ROL universitario';
                          }
                          if (!_rolRegex.hasMatch(clean)) {
                            return 'Formato inválido (ej: 202373019-4)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final phoneField = TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Teléfono / WhatsApp *',
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Ingresa un teléfono de contacto'
                                : null,
                          );
                          final emailField = TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email (Boleta)',
                            ),
                          );
                          if (constraints.maxWidth < 360) {
                            return Column(
                              children: [
                                phoneField,
                                const SizedBox(height: 12),
                                emailField,
                              ],
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: phoneField),
                              const SizedBox(width: 10),
                              Expanded(child: emailField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pickupController,
                        decoration: const InputDecoration(
                          labelText: 'Punto de Entrega / Retiro *',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Indica el punto de retiro en el campus'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Sección 2: Medio de pago (Mock)
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.credit_card_outlined,
                            size: 18,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '2. MEDIO DE PAGO',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _PaymentMethodOption(
                              icon: Icons.credit_card_outlined,
                              label: PaymentMethod.card.label,
                              selected: _selectedPayment == PaymentMethod.card,
                              onTap: () => setState(
                                () => _selectedPayment = PaymentMethod.card,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PaymentMethodOption(
                              icon: Icons.payments_outlined,
                              label: PaymentMethod.cash.label,
                              selected: _selectedPayment == PaymentMethod.cash,
                              onTap: () => setState(
                                () => _selectedPayment = PaymentMethod.cash,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _PaymentMethodOption(
                              icon: Icons.qr_code_2_outlined,
                              label: PaymentMethod.transfer.label,
                              selected:
                                  _selectedPayment == PaymentMethod.transfer,
                              onTap: () => setState(
                                () => _selectedPayment = PaymentMethod.transfer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_selectedPayment == PaymentMethod.card) ...[
                        TextFormField(
                          controller: _cardNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Número de Tarjeta (Débito o Crédito)',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Ingresa el número de tarjeta'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cardExpiryController,
                                decoration: const InputDecoration(
                                  labelText: 'Vencimiento',
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _cardCvvController,
                                obscureText: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().length < 3)
                                    ? 'CVV inválido'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ] else if (_selectedPayment == PaymentMethod.cash) ...[
                        TextFormField(
                          controller: _cashAmountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText:
                                '¿Con cuánto efectivo abonarás? (Para vuelto)',
                            prefixText: '\$ ',
                          ),
                          validator: (value) {
                            final parsed = int.tryParse(value ?? '');
                            if (parsed == null || parsed < cart.totalPriceClp) {
                              return 'Ingresa un monto igual o mayor a ${formatClp(cart.totalPriceClp)}';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Datos para Transferencia Electrónica',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text('Banco: Banco Estado / Cuenta Vista'),
                              const Text('RUT: 76.890.123-4'),
                              const Text('Alias: nutrimarket.organico'),
                              const Text('Correo: pagos@nutrimarket.usm.cl'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  icon: const Icon(Icons.qr_code_2_outlined),
                  label: Text(
                    'Confirmar Pedido y Generar Código QR (${formatClp(cart.totalPriceClp)})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodOption extends StatelessWidget {
  const _PaymentMethodOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? colors.primary : theme.dividerColor,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? colors.onPrimary : colors.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: selected ? colors.onPrimary : colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
