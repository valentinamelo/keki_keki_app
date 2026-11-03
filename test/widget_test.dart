// Pruebas de formato, modelos, controladores y de los recorridos principales
// del cliente y del administrador. Usan los servicios en memoria, que
// cumplen el mismo contrato que Firebase.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keki_keki/core/format.dart';
import 'package:keki_keki/data/memory_services.dart';
import 'package:keki_keki/data/products_data.dart';
import 'package:keki_keki/main.dart';
import 'package:keki_keki/models/order.dart';
import 'package:keki_keki/models/product.dart';
import 'package:keki_keki/state/admin_orders_controller.dart';
import 'package:keki_keki/state/cart_controller.dart';
import 'package:keki_keki/state/catalog_controller.dart';
import 'package:keki_keki/state/dashboard_stats.dart';
import 'package:keki_keki/widgets/product_widgets.dart';

/// Deja pasar varios cuadros para que lleguen los datos de los streams.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

void main() {
  // Verifica que los importes se presenten con separadores colombianos.
  test('cop formatea pesos colombianos', () {
    expect(cop(65000), '\$65.000');
    expect(cop(1284000), '\$1.284.000');
    expect(cop(900), '\$900');
  });

  // Verifica los textos de fecha y hora en español.
  test('fechas relativas y horas en español', () {
    final now = DateTime(2026, 9, 24, 10);
    expect(relativeDay(DateTime(2026, 9, 24, 15), now: now), 'Hoy');
    expect(relativeDay(DateTime(2026, 9, 25), now: now), 'Mañana');
    expect(relativeDay(DateTime(2026, 9, 23), now: now), 'Ayer');
    expect(relativeDay(DateTime(2026, 9, 27), now: now), 'dom 27 sept.');
    expect(clock(DateTime(2026, 9, 24, 15, 5)), '3:05 PM');
    expect(clock(DateTime(2026, 9, 24, 0, 30)), '12:30 AM');
  });

  // Un producto guardado y leído de Firestore conserva precio y opciones.
  test('Product se convierte a mapa y de vuelta sin perder datos', () {
    final original = kProducts.firstWhere((p) => p.id == 'torta-chocolate');
    final copy = Product.fromMap(original.id, original.toMap(order: 6));
    expect(copy.name, original.name);
    expect(copy.category, ProductCategory.tortas);
    expect(copy.art, ArtKind.chocolateCake);
    expect(copy.defaultPrice, original.defaultPrice);
    final big = {'tamano': 3, 'sabor': 2, 'relleno': 2};
    expect(copy.priceFor(big), original.priceFor(big));
    expect(copy.summaryFor(big), original.summaryFor(big));
  });

  // El carrito exige entrega completa y calcula domicilio y total.
  test('CartController valida la entrega y arma el pedido', () {
    final cart = CartController();
    final cupcakes = kProducts.firstWhere((p) => p.id == 'cupcakes-duo-pastel');
    cart.add(cupcakes, cupcakes.defaultSelection, quantity: 2);
    expect(cart.missingInfo, contains('fecha'));

    cart.setDelivery(
      mode: DeliveryMode.domicilio,
      date: DateTime(2026, 9, 25),
      slot: kDeliverySlots[3],
      address: '',
      notes: '',
    );
    expect(cart.missingInfo, contains('dirección'));

    cart.setDelivery(
      mode: DeliveryMode.recoger,
      date: DateTime(2026, 9, 25),
      slot: kDeliverySlots[3],
      address: '',
      notes: '',
    );
    expect(cart.missingInfo, isNull);
    expect(cart.total, 44000);

    final order = cart.buildOrder(kDemoClient);
    expect(order.deliveryDate, DateTime(2026, 9, 25, 15));
    expect(order.total, 44000);
    expect(order.toMap()['estado'], 'pendiente');
    expect(Order.fromMap('x', order.toMap()).itemsSummary,
        'Cupcakes duo pastel x2');
  });

  // El aviso en vivo solo salta para pedidos que llegan después de cargar.
  test('AdminOrdersController avisa solo de pedidos nuevos', () async {
    final source = StreamController<List<Order>>();
    final announced = <String>[];
    final controller = AdminOrdersController(
      source.stream,
      onNewOrder: (o) => announced.add(o.id),
    );
    Order make(String id, OrderStatus status) => Order(
          id: id,
          clientId: 'c',
          clientName: 'Cliente',
          clientPhone: '',
          items: const [],
          deliveryFee: 0,
          deliveryMode: DeliveryMode.recoger,
          deliveryDate: DateTime(2026),
          deliverySlot: '',
          status: status,
        );

    source.add([make('a', OrderStatus.pendiente)]);
    await Future<void>.delayed(Duration.zero);
    expect(announced, isEmpty);

    source.add([
      make('b', OrderStatus.pendiente),
      make('a', OrderStatus.listo),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(announced, ['b']);
    expect(controller.pendingCount, 1);
    controller.setFilter(OrderStatus.listo);
    expect(controller.visible.single.id, 'a');

    controller.dispose();
    await source.close();
  });

  // Comprueba filtros, apertura del detalle y agregado de un producto.
  testWidgets(
      'Explorar filtra por categoría, abre el detalle y agrega al carrito',
      (tester) async {
    await tester
        .pumpWidget(KekiApp(services: memoryServices(signedIn: kDemoClient)));
    await settle(tester);

    // La app del cliente abre en Inicio.
    expect(find.text('Hola, Valentina'), findsOneWidget);
    expect(find.text('Destacados de la semana'), findsOneWidget);
    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    expect(find.text('Descubre nuestros productos'), findsOneWidget);
    expect(find.text('Torta fresa silvestre'), findsOneWidget);

    await tester.tap(find.text('Cupcakes'));
    await tester.pumpAndSettle();
    expect(find.text('Cupcakes duo pastel'), findsOneWidget);
    expect(find.text('Torta fresa silvestre'), findsNothing);

    await tester.tap(find.text('Cupcakes duo pastel'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Agregar al carrito'), findsOneWidget);
    expect(find.text('Presentación'), findsOneWidget);
    expect(find.text('Caja x6'), findsOneWidget);
    expect(tester.getSize(find.byType(GradientButton)).height, lessThan(100));
    expect(
        tester.getTopLeft(find.text('Cupcakes duo pastel')).dy, lessThan(280));

    await tester.tap(find.textContaining('Agregar al carrito'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('agregado al carrito'), findsOneWidget);
  });

  // El login muestra errores y, con datos correctos, abre la interfaz del rol.
  testWidgets('El login envía a cada rol a su interfaz', (tester) async {
    await tester.pumpWidget(KekiApp(services: memoryServices()));
    await settle(tester);
    expect(find.text('Iniciar sesión'), findsWidgets);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'admin@keki.co');
    await tester.enterText(fields.at(1), 'incorrecta');
    await tester.tap(find.byType(GradientButton));
    await settle(tester);
    expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);

    await tester.enterText(fields.at(1), '123456');
    await tester.tap(find.byType(GradientButton));
    await settle(tester);
    // El admin abre en el Panel general.
    expect(find.text('Ventas de hoy'), findsOneWidget);
    expect(find.text('Pedidos'), findsOneWidget);
  });

  // Recorrido completo: el cliente confirma un pedido y el admin lo ve en
  // vivo, abre el detalle y lo pasa a «En preparación».
  testWidgets('El cliente confirma un pedido y el admin cambia su estado',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final services = memoryServices(signedIn: kDemoClient);
    await tester.pumpWidget(KekiApp(services: services));
    await settle(tester);

    // Agregar rápido una caja de brownies y abrir el carrito.
    await tester.tap(find.text('Explorar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'brownie');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.add_rounded).first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3)); // se oculta el aviso
    await tester.pumpAndSettle();
    await tester.tap(find.text('Carrito'));
    await tester.pumpAndSettle();
    expect(find.text('Tu carrito'), findsOneWidget);

    // Sin fecha, confirmar abre la hoja de entrega.
    await tester.tap(find.text('Confirmar pedido'));
    await tester.pumpAndSettle();
    expect(find.text('Guardar entrega'), findsOneWidget);
    await tester.tap(find.textContaining('Mañana ·'));
    await tester.tap(find.text('3:00–5:00 PM'));
    await tester.enterText(
        find.byType(TextField).first, 'Carrera 7 # 45-10, apto 302');
    await tester.tap(find.text('Guardar entrega'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3:00–5:00 PM'), findsOneWidget);
    expect(find.text('\$24.000'), findsOneWidget); // 18.000 + domicilio

    await tester.tap(find.text('Confirmar pedido'));
    await settle(tester);
    expect(find.text('¡Pedido enviado!'), findsOneWidget);
    await tester.tap(find.text('Ver mis pedidos'));
    await settle(tester);
    expect(find.text('Mis pedidos'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);

    // Cambia la sesión al administrador.
    await services.auth.signOut();
    await settle(tester);
    await services.auth.signIn(email: 'admin@keki.co', password: '123456');
    await settle(tester);
    // El panel ya cuenta el pedido pendiente; al tocarlo se abre Pedidos.
    expect(find.text('Pedidos pendientes'), findsOneWidget);
    await tester.tap(find.text('Pedidos pendientes'));
    await settle(tester);
    expect(find.text('Valentina Ortiz'), findsOneWidget);
    expect(find.text('Pendientes · 1'), findsOneWidget);

    await tester.tap(find.text('Valentina Ortiz'));
    await settle(tester);
    expect(find.text('Carrera 7 # 45-10, apto 302'), findsOneWidget);
    await tester.tap(find.text('Marcar como En preparación'));
    await settle(tester);
    expect(find.text('Marcar como Listo'), findsOneWidget);

    await tester.pageBack();
    await settle(tester);
    expect(find.text('En preparación · 1'), findsOneWidget);
    expect(find.text('Pendientes · 0'), findsOneWidget);

    // Pasar a «En preparación» descontó una caja del stock (26 → 25).
    final products = await services.products.watchProducts().first;
    expect(products.firstWhere((p) => p.id == 'brownie-doble-cacao').stock, 25);
  });

  // Las cifras del panel salen de los pedidos reales.
  test('DashboardStats calcula ventas, entregas y más vendidos', () {
    final now = DateTime(2026, 11, 4, 15); // miércoles
    final brownie = kProducts.firstWhere((p) => p.id == 'brownie-doble-cacao');
    final cupcakes = kProducts.firstWhere((p) => p.id == 'cupcakes-duo-pastel');
    OrderItem item(Product p, int qty) => OrderItem(
          productId: p.id,
          name: p.name,
          art: p.art,
          options: '',
          unitPrice: p.basePrice,
          quantity: qty,
        );
    Order order(
      DateTime created,
      List<OrderItem> items, {
      OrderStatus status = OrderStatus.pendiente,
      DateTime? deliveredAt,
    }) =>
        Order(
          id: '$created',
          clientId: 'c',
          clientName: 'Cliente',
          clientPhone: '',
          items: items,
          deliveryFee: 0,
          deliveryMode: DeliveryMode.recoger,
          deliveryDate: created,
          deliverySlot: '',
          status: status,
          createdAt: created,
          history: {
            if (deliveredAt != null) OrderStatus.entregado: deliveredAt,
          },
        );

    final stats = DashboardStats.from([
      order(DateTime(2026, 11, 4, 9), [item(brownie, 2)]), // hoy: 36.000
      order(DateTime(2026, 11, 4, 10), [item(cupcakes, 1)],
          status: OrderStatus.cancelado), // no cuenta
      order(DateTime(2026, 11, 3, 9), [item(cupcakes, 1)],
          status: OrderStatus.entregado,
          deliveredAt: DateTime(2026, 11, 3, 16)), // ayer: 22.000
      order(DateTime(2026, 10, 28, 9), [item(brownie, 5)],
          status: OrderStatus.entregado,
          deliveredAt: DateTime(2026, 10, 28, 16)), // semana pasada
    ], now: now);

    expect(stats.salesToday, 36000);
    expect(stats.salesYesterday, 22000);
    expect(stats.salesTrend, 64); // (36 - 22) / 22 ≈ 64 %
    expect(stats.pending, 1);
    expect(stats.deliveredThisWeek, 1);
    expect(stats.deliveredLastWeek, 1);
    expect(stats.weekSales, [0, 22000, 36000, 0, 0, 0, 0]);
    expect(stats.topProducts.map((t) => t.name),
        ['Brownie doble cacao', 'Cupcakes duo pastel']);
    expect(stats.aiOrdersThisWeek, 0);
  });

  // El stock se descuenta al preparar y vuelve si el pedido se cancela.
  test('El stock baja al preparar y se devuelve al cancelar', () async {
    final services = memoryServices();
    final cart = CartController();
    final torta = kProducts.firstWhere((p) => p.id == 'torta-azul-vainilla');
    cart.add(torta, torta.defaultSelection, quantity: 2);
    cart.setDelivery(
      mode: DeliveryMode.recoger,
      date: DateTime(2026, 12, 1),
      slot: kDeliverySlots.first,
      address: '',
      notes: '',
    );
    final id = await cart.placeOrder(services.orders, kDemoClient);
    Future<int> stock() async => (await services.products.watchProducts().first)
        .firstWhere((p) => p.id == torta.id)
        .stock;

    expect(await stock(), 3);
    await services.orders.updateStatus(id, OrderStatus.enPreparacion);
    expect(await stock(), 1);
    await services.orders.updateStatus(id, OrderStatus.cancelado);
    expect(await stock(), 3);
  });

  // Los favoritos se guardan en la cuenta y vuelven al iniciar sesión.
  test('Los favoritos se guardan en la cuenta', () async {
    final services = memoryServices();
    await services.auth.signIn(email: 'cliente@keki.co', password: '123456');
    var user = (await services.auth.userChanges.first)!;
    final catalog = CatalogController(
      services.products.watchProducts(),
      favorites: user.favorites,
      saveFavorite: (id, fav) => services.users.setFavorite(user.uid, id, fav),
    );
    await catalog.toggleFavorite('torta-chocolate');
    expect(catalog.isFavorite('torta-chocolate'), isTrue);
    catalog.dispose();

    await services.auth.signOut();
    await services.auth.signIn(email: 'cliente@keki.co', password: '123456');
    user = (await services.auth.userChanges.first)!;
    expect(user.favorites, {'torta-chocolate'});
  });

  // El admin crea un producto y el cliente lo recibe; si lo desactiva,
  // desaparece del catálogo del cliente.
  testWidgets('El admin crea y desactiva un producto', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final services = memoryServices(signedIn: kDemoAdmin);
    await tester.pumpWidget(KekiApp(services: services));
    await settle(tester);
    await tester.tap(find.text('Productos'));
    await settle(tester);
    expect(find.textContaining('con stock bajo'), findsOneWidget);
    expect(find.textContaining('Torta azul vainilla (3)'), findsOneWidget);

    await tester.tap(find.text('Nuevo'));
    await settle(tester);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Nombre'), 'Cheesecake de maracuyá');
    await tester.enterText(find.widgetWithText(TextFormField, 'Descripción'),
        'Base de galleta y crema de maracuyá.');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Precio base'), '54000');
    await tester.tap(find.text('Crear producto'));
    await settle(tester);
    expect(find.text('Cheesecake de maracuyá creado'), findsOneWidget);
    expect(find.textContaining('8 activos'), findsOneWidget);

    Future<List<String>> clientNames() async =>
        [for (final p in await services.products.watchProducts().first) p.name];
    expect(await clientNames(), contains('Cheesecake de maracuyá'));

    await services.products.setActive(
      (await services.products.watchProducts().first)
          .firstWhere((p) => p.name == 'Cheesecake de maracuyá')
          .id,
      false,
    );
    expect(await clientNames(), isNot(contains('Cheesecake de maracuyá')));
  });

  // Pedido manual: el admin lo registra y aparece en la gestión de pedidos.
  testWidgets('El admin registra un pedido manual', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final services = memoryServices(signedIn: kDemoAdmin);
    await tester.pumpWidget(KekiApp(services: services));
    await settle(tester);

    await tester.tap(find.byTooltip('Nuevo pedido'));
    await settle(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Nombre del cliente'), 'Julián Pardo');
    await tester.tap(find.text('Agregar producto'));
    await settle(tester);
    await tester.tap(find.text('Galletas de mantequilla'));
    await settle(tester);
    await tester.tap(find.textContaining('Agregar al pedido'));
    await settle(tester);
    expect(find.text('Galletas de mantequilla'), findsOneWidget);

    await tester.tap(find.text('Crear pedido'));
    await settle(tester);
    await tester.tap(find.textContaining('Hoy ·'));
    await tester.tap(find.text('5:00–7:00 PM'));
    await tester.tap(find.text('Recoger en tienda · Gratis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar entrega'));
    await settle(tester);
    await tester.tap(find.text('Crear pedido'));
    await settle(tester);

    final orders = await services.orders.watchAll().first;
    expect(orders.single.clientName, 'Julián Pardo');
    expect(orders.single.origin, OrderOrigin.manual);
    expect(orders.single.total, 15000);
  });
}
