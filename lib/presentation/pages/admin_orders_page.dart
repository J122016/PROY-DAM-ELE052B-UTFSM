import 'package:flutter/material.dart';
import 'package:proyecto_dam/constants.dart';
import 'package:proyecto_dam/data/models/order_receipt.dart';
import 'package:proyecto_dam/data/services/order_service.dart';
import 'package:proyecto_dam/presentation/components/theme_toggle_button.dart';
import 'package:proyecto_dam/presentation/pages/order_receipt_page.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({
    required this.orderStore,
    required this.themeProvider,
    super.key,
  });

  final OrderStore orderStore;
  final ThemeProvider themeProvider;

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _searchController = TextEditingController();
  OrderStatus? _statusFilter;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleStatus(OrderReceipt order) async {
    final nextStatus = order.isDelivered
        ? OrderStatus.pending
        : OrderStatus.delivered;
    try {
      await widget.orderStore.updateStatus(order.orderNumber, nextStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pedido ${order.orderNumber} marcado como "${nextStatus.label}".',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar el pedido: $error')),
      );
    }
  }

  List<OrderReceipt> _filterOrders(List<OrderReceipt> orders) {
    final cleanQuery = _query.trim().toLowerCase();
    return orders.where((order) {
      if (_statusFilter != null && order.status != _statusFilter) {
        return false;
      }
      if (cleanQuery.isEmpty) return true;
      return order.orderNumber.toLowerCase().contains(cleanQuery) ||
          order.buyerName.toLowerCase().contains(cleanQuery) ||
          order.universityRol.toLowerCase().contains(cleanQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin. Pedidos Campus'),
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
        child: StreamBuilder<List<OrderReceipt>>(
          stream: widget.orderStore.watchAll(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No fue posible cargar los pedidos desde Firebase: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.error),
                  ),
                ),
              );
            }

            final allOrders = snapshot.data ?? const [];
            final filtered = _filterOrders(allOrders);
            final pendingCount = allOrders
                .where((order) => !order.isDelivered)
                .length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_scanner, color: colors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Control de Retiros en Campus',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Total: ${allOrders.length} pedidos • $pendingCount pendientes de entrega',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Buscar por N° orden, nombre o ROL USM...',
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar búsqueda',
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _statusFilter == null,
                        onSelected: (_) => setState(() => _statusFilter = null),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Pendientes'),
                        selected: _statusFilter == OrderStatus.pending,
                        onSelected: (_) => setState(
                          () => _statusFilter = OrderStatus.pending,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Entregados'),
                        selected: _statusFilter == OrderStatus.delivered,
                        onSelected: (_) => setState(
                          () => _statusFilter = OrderStatus.delivered,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              allOrders.isEmpty
                                  ? 'Aún no hay pedidos registrados en Firebase.'
                                  : 'No hay pedidos que coincidan con la búsqueda.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final order = filtered[index];
                            return _AdminOrderCard(
                              order: order,
                              onToggleStatus: () => _toggleStatus(order),
                              onViewReceipt: () => Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => OrderReceiptPage(
                                    receipt: order,
                                    themeProvider: widget.themeProvider,
                                    fromHistory: true,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({
    required this.order,
    required this.onToggleStatus,
    required this.onViewReceipt,
  });

  final OrderReceipt order;
  final VoidCallback onToggleStatus;
  final VoidCallback onViewReceipt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDelivered = order.isDelivered;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'N° ${order.orderNumber}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isDelivered
                        ? colors.primary.withValues(alpha: 0.16)
                        : kAccentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: isDelivered ? colors.primary : kAccentColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${order.buyerName} • ROL: ${order.universityRol}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${order.pickupLocation} • ${order.paymentMethod.label}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${order.totalUnits} un. • ${formatClp(order.totalClp)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onViewReceipt,
                  icon: const Icon(Icons.qr_code_2_outlined, size: 18),
                  label: const Text('Ficha'),
                ),
                const SizedBox(width: 6),
                FilledButton.icon(
                  onPressed: onToggleStatus,
                  icon: Icon(
                    isDelivered ? Icons.undo : Icons.check_circle_outline,
                    size: 18,
                  ),
                  label: Text(
                    isDelivered ? 'Marcar pendiente' : 'Marcar entregado',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
