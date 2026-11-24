import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:proyecto_dam/data/models/cart_item.dart';
import 'package:proyecto_dam/data/models/order_receipt.dart';
import 'package:proyecto_dam/data/models/product.dart';
import 'package:proyecto_dam/data/repositories/cart_repository.dart';
import 'package:proyecto_dam/data/repositories/order_history_repository.dart';
import 'package:proyecto_dam/data/services/open_food_facts_service.dart';
import 'package:proyecto_dam/data/services/order_service.dart';
import 'package:proyecto_dam/presentation/pages/admin_orders_page.dart';
import 'package:proyecto_dam/presentation/pages/home.dart';
import 'package:proyecto_dam/presentation/pages/order_history_page.dart';
import 'package:proyecto_dam/presentation/providers/cart_provider.dart';
import 'package:proyecto_dam/presentation/providers/order_history_provider.dart';
import 'package:proyecto_dam/presentation/providers/product_provider.dart';
import 'package:proyecto_dam/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_product_store.dart';

class _FakeOrderStore implements OrderStore {
  final Map<String, OrderReceipt> _orders = {};
  final _controller = StreamController<List<OrderReceipt>>.broadcast();
  bool shouldFail = false;

  void _emit() {
    final sorted = _orders.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _controller.add(sorted);
  }

  @override
  Future<void> save(OrderReceipt order) async {
    if (shouldFail) throw StateError('Simulated network error');
    _orders.putIfAbsent(order.orderNumber, () => order);
    _emit();
  }

  @override
  Future<List<OrderReceipt>> fetchByNumbers(List<String> orderNumbers) async {
    if (shouldFail) throw StateError('Simulated network error');
    return [
      for (final number in orderNumbers)
        if (_orders.containsKey(number)) _orders[number]!,
    ];
  }

  @override
  Stream<List<OrderReceipt>> watchAll() async* {
    final sorted = _orders.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield sorted;
    yield* _controller.stream;
  }

  @override
  Future<void> updateStatus(String orderNumber, OrderStatus status) async {
    final current = _orders[orderNumber];
    if (current == null) return;
    _orders[orderNumber] = current.copyWith(
      status: status,
      deliveredAt: status == OrderStatus.delivered ? DateTime.now() : null,
    );
    _emit();
  }

  void dispose() => _controller.close();
}

OrderReceipt _sampleOrder({
  String number = 'NM-100200',
  OrderStatus status = OrderStatus.pending,
}) => OrderReceipt(
  orderNumber: number,
  buyerName: 'Jaime Guzmán',
  universityRol: '202348115-9',
  phone: '+56 9 8765 4321',
  email: 'usuario@usm.cl',
  pickupLocation: 'Campus Universitario - Punto Limpio',
  paymentMethod: PaymentMethod.card,
  totalClp: 4890,
  totalCalories: 368,
  totalProteins: 14.1,
  totalCarbohydrates: 64.2,
  createdAt: DateTime(2026, 11, 18, 12, 30),
  status: status,
  items: const [
    CartItem(
      product: Product(
        id: 'quinoa-1',
        name: 'Quinoa Real Orgánica',
        priceClp: 4890,
        stock: 10,
      ),
      quantity: 1,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('order history persists locally and syncs status from store', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = _FakeOrderStore();
    final provider = OrderHistoryProvider(
      repository: OrderHistoryRepository(preferences),
      store: store,
    );

    final order = _sampleOrder();
    final synced = await provider.placeOrder(order);
    expect(synced, isTrue);
    expect(provider.orders.single.orderNumber, 'NM-100200');
    expect(provider.pendingCount, 1);

    await store.updateStatus('NM-100200', OrderStatus.delivered);
    await provider.refresh();
    expect(provider.orders.single.isDelivered, isTrue);
    expect(provider.pendingCount, 0);

    provider.dispose();
    store.dispose();
  });

  testWidgets(
    'opening Mis Pedidos from Home with an active order does not throw during build',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final store = _FakeOrderStore();
      final orderHistoryProvider = OrderHistoryProvider(
        repository: OrderHistoryRepository(preferences),
        store: store,
      );
      final service = OpenFoodFactsService(
        client: MockClient(
          (_) async => http.Response(jsonEncode({'products': []}), 200),
        ),
      );
      final productProvider = ProductProvider(
        store: InMemoryProductStore(),
        service: service,
      );
      final cartProvider = CartProvider(CartRepository(preferences));
      final themeProvider = ThemeProvider(preferences);

      await orderHistoryProvider.placeOrder(_sampleOrder(number: 'NM-999111'));

      await tester.pumpWidget(
        MaterialApp(
          home: Home(
            productProvider: productProvider,
            themeProvider: themeProvider,
            cartProvider: cartProvider,
            orderHistoryProvider: orderHistoryProvider,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Badge '1' is rendered by Home's ListenableBuilder; tapping 'Mis Pedidos'
      // pushes OrderHistoryPage while Home is still listening to orderHistoryProvider.
      expect(find.byTooltip('Mis Pedidos'), findsOneWidget);
      await tester.tap(find.byTooltip('Mis Pedidos'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Mis Pedidos'), findsOneWidget);
      expect(find.text('N° NM-999111'), findsOneWidget);

      service.close();
      productProvider.dispose();
      cartProvider.dispose();
      orderHistoryProvider.dispose();
      themeProvider.dispose();
      store.dispose();
    },
  );

  testWidgets('buyer order history page lists orders and opens QR receipt', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = _FakeOrderStore();
    final provider = OrderHistoryProvider(
      repository: OrderHistoryRepository(preferences),
      store: store,
    );
    final themeProvider = ThemeProvider(preferences);
    await provider.placeOrder(_sampleOrder(number: 'NM-777888'));

    await tester.pumpWidget(
      MaterialApp(
        home: OrderHistoryPage(
          orderHistoryProvider: provider,
          themeProvider: themeProvider,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mis Pedidos'), findsOneWidget);
    expect(find.text('N° NM-777888'), findsOneWidget);
    expect(find.textContaining('Quinoa Real Orgánica'), findsOneWidget);

    await tester.tap(find.text('Ver QR'));
    await tester.pumpAndSettle();

    expect(find.text('Comprobante de Retiro'), findsOneWidget);
    expect(find.text('Código QR de Retiro'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Volver a Mis Pedidos'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Volver a Mis Pedidos'), findsOneWidget);

    provider.dispose();
    themeProvider.dispose();
    store.dispose();
  });

  testWidgets('admin orders page marks an order as delivered', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = _FakeOrderStore();
    final themeProvider = ThemeProvider(preferences);
    await store.save(_sampleOrder(number: 'NM-555111'));

    await tester.pumpWidget(
      MaterialApp(
        home: AdminOrdersPage(orderStore: store, themeProvider: themeProvider),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('N° NM-555111'), findsOneWidget);
    expect(find.text('Pendiente de retiro'), findsOneWidget);

    await tester.tap(find.text('Marcar entregado'));
    await tester.pumpAndSettle();

    expect(find.text('Entregado'), findsOneWidget);

    themeProvider.dispose();
    store.dispose();
  });
}
