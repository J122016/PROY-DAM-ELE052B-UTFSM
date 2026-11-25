import 'package:flutter/material.dart';
import 'package:proyecto_dam/constants.dart';
import 'package:proyecto_dam/data/models/order_receipt.dart';
import 'package:proyecto_dam/presentation/components/theme_toggle_button.dart';
import 'package:proyecto_dam/presentation/pages/order_receipt_page.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';
import 'package:proyecto_dam/presentation/providers/order_history_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';

enum _HistoryFilter {
  all('Todos'),
  pending('Pendientes'),
  delivered('Entregados');

  const _HistoryFilter(this.label);
  final String label;
}

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({
    required this.orderHistoryProvider,
    required this.themeProvider,
    super.key,
  });

  final OrderHistoryProvider orderHistoryProvider;
  final ThemeProvider themeProvider;

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final _searchController = TextEditingController();
  _HistoryFilter _filter = _HistoryFilter.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (!widget.orderHistoryProvider.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.orderHistoryProvider.refresh();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year • $hour:$minute';
  }

  void _openReceipt(OrderReceipt order) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => OrderReceiptPage(
          receipt: order,
          themeProvider: widget.themeProvider,
          isSynced: widget.orderHistoryProvider.isSynced(order.orderNumber),
          fromHistory: true,
        ),
      ),
    );
  }

  List<OrderReceipt> _applyFilter(List<OrderReceipt> all) {
    final cleanQuery = _query.trim().toLowerCase();
    return all.where((order) {
      final matchesStatus = switch (_filter) {
        _HistoryFilter.all => true,
        _HistoryFilter.pending => !order.isDelivered,
        _HistoryFilter.delivered => order.isDelivered,
      };
      if (!matchesStatus) return false;
      if (cleanQuery.isEmpty) return true;
      return order.orderNumber.toLowerCase().contains(cleanQuery) ||
          order.buyerName.toLowerCase().contains(cleanQuery) ||
          order.items.any(
            (item) => item.product.name.toLowerCase().contains(cleanQuery),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.orderHistoryProvider,
    builder: (context, child) {
      final provider = widget.orderHistoryProvider;
      final allOrders = provider.orders;
      final filtered = _applyFilter(allOrders);
      final theme = Theme.of(context);
      final colors = theme.colorScheme;

      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Pedidos'),
          actions: [
            ListenableBuilder(
              listenable: widget.themeProvider,
              builder: (context, child) => ThemeToggleButton(
                isDark: widget.themeProvider.isDarkMode,
                onPressed: widget.themeProvider.toggle,
              ),
            ),
            IconButton(
              tooltip: 'Actualizar estado de pedidos',
              onPressed: provider.isRefreshing ? null : provider.refresh,
              icon: provider.isRefreshing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: allOrders.isEmpty
              ? const _EmptyHistoryView()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                      child: _HistoryOverviewBanner(
                        totalOrders: allOrders.length,
                        pendingOrders: provider.pendingCount,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => setState(() => _query = value),
                        decoration: InputDecoration(
                          hintText: 'Buscar por N° de pedido o alimento...',
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
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        itemCount: _HistoryFilter.values.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final filter = _HistoryFilter.values[index];
                          return ChoiceChip(
                            label: Text(filter.label),
                            selected: _filter == filter,
                            onSelected: (_) =>
                                setState(() => _filter = filter),
                          );
                        },
                      ),
                    ),
                    if (provider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                        child: Text(
                          provider.errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'No hay pedidos que coincidan con el filtro.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                6,
                                16,
                                20,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final order = filtered[index];
                                return _OrderHistoryCard(
                                  order: order,
                                  formattedDate: _formatDate(order.createdAt),
                                  isSynced: provider.isSynced(
                                    order.orderNumber,
                                  ),
                                  onTap: () => _openReceipt(order),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      );
    },
  );
}

class _HistoryOverviewBanner extends StatelessWidget {
  const _HistoryOverviewBanner({
    required this.totalOrders,
    required this.pendingOrders,
  });

  final int totalOrders;
  final int pendingOrders;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                color: colors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial de Compras Orgánicas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '$totalOrders pedidos registrados • $pendingOrders pendientes de retiro',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({
    required this.order,
    required this.formattedDate,
    required this.isSynced,
    required this.onTap,
  });

  final OrderReceipt order;
  final String formattedDate;
  final bool isSynced;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDelivered = order.isDelivered;
    final itemNames = order.items
        .map((item) => '${item.quantity}x ${item.product.name}')
        .join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'N° ${order.orderNumber}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isSynced)
                    Tooltip(
                      message: 'Pendiente de sincronizar con la nube',
                      child: Icon(
                        Icons.cloud_off_outlined,
                        size: 16,
                        color: kAccentColor,
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.payments_outlined,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    order.paymentMethod.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (itemNames.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  itemNames,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.totalCalories.round()} kcal • ${order.totalProteins.toStringAsFixed(1)} g prot',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Total: ${formatClp(order.totalClp)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: onTap,
                    icon: const Icon(Icons.qr_code_2_outlined, size: 18),
                    label: const Text('Ver QR'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aún no tienes pedidos registrados',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando confirmes una compra en NutriMarket, aquí podrás revisar tus pedidos y abrir su código QR de retiro.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
