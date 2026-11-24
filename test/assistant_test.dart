// Pruebas del Asistente Keki IA (entrega 4): cómo entiende los mensajes,
// qué recomienda, el registro de conversaciones y el recorrido completo
// cliente → pedido vía IA → panel del administrador.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keki_keki/data/memory_services.dart';
import 'package:keki_keki/data/products_data.dart';
import 'package:keki_keki/main.dart';
import 'package:keki_keki/models/assistant.dart';
import 'package:keki_keki/models/order.dart';
import 'package:keki_keki/state/assistant_controller.dart';
import 'package:keki_keki/state/assistant_engine.dart';
import 'package:keki_keki/state/assistant_stats.dart';

/// Deja pasar varios cuadros para que lleguen los datos y las respuestas.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 14; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

/// Responde las cuatro preguntas del mockup 04.
AssistantBrief mockupBrief() {
  var brief = const AssistantBrief();
  brief = brief.merge(
      parseMessage('Cumpleaños de mi mamá', step: AssistantStep.occasion));
  brief = brief.merge(parseMessage('Unas 20', step: AssistantStep.people));
  brief = brief.merge(
      parseMessage('Entre \$70.000 y \$90.000', step: AssistantStep.budget));
  brief = brief.merge(
      parseMessage('Chocolate y frutos rojos', step: AssistantStep.flavors));
  return brief;
}

void main() {
  test('entiende ocasión, personas, presupuesto y sabores', () {
    final brief = mockupBrief();
    expect(brief.occasion, Occasion.cumpleanos);
    expect(brief.people, 20);
    expect((brief.budgetMin, brief.budgetMax), (70000, 90000));
    expect(brief.flavors, ['Chocolate', 'Frutos rojos']);
    expect(brief.complete, isTrue);
  });

  test('reconoce distintas formas de decir el presupuesto', () {
    expect(parseBudget('entre 70 y 90 mil'), (70000, 90000));
    expect(parseBudget('hasta 60 mil'), (null, 60000));
    expect(parseBudget('Más de \$90.000'), (90000, null));
    expect(parseBudget('unos 80k'), (68000, 92000));
    expect(parseBudget('50', expected: true), (42000, 57000));
    expect(parseBudget('No tengo presupuesto', expected: true), (null, null));
    expect(
        parseBudget('de chocolate, sin límite de presupuesto'), (null, null));
    // Las personas no se confunden con dinero.
    expect(parseBudget('para 20 personas'), isNull);
    final brief = parseMessage('Torta para 20 personas, unos 80 mil');
    expect(brief.people, 20);
    expect((brief.budgetMin, brief.budgetMax), (68000, 92000));
  });

  test('un mensaje largo responde varias preguntas a la vez', () {
    final brief = parseMessage(
      'Es para el baby shower de mi hermana, unas 12 personas, de vainilla',
      step: AssistantStep.occasion,
    );
    expect(brief.occasion, Occasion.babyShower);
    expect(brief.people, 12);
    expect(brief.flavors, ['Vainilla']);
    expect(brief.budgetAnswered, isFalse);
  });

  test('recomienda la torta de chocolate del mockup', () {
    final recs = recommend(kProducts, mockupBrief());
    final best = recs.first;
    expect(best.product.id, 'torta-chocolate');
    // Con la lista de precios real, la de 18-20 personas cuesta $58.000.
    expect(best.total, 58000);
    expect(best.summary, '18-20 pers.');
    expect(best.reasons, contains('Alcanza para 20 personas'));
  });

  test('para una reunión con poco presupuesto sugiere cajas', () {
    var brief = const AssistantBrief();
    brief = brief.merge(
        parseMessage('Reunión de la oficina', step: AssistantStep.occasion));
    brief = brief.merge(parseMessage('24', step: AssistantStep.people));
    brief =
        brief.merge(parseMessage('hasta 60 mil', step: AssistantStep.budget));
    brief =
        brief.merge(parseMessage('me da igual', step: AssistantStep.flavors));
    final best = recommend(kProducts, brief).first;
    expect(best.product.category.name, isNot('tortas'));
    expect(best.total, lessThanOrEqualTo(60000));
  });

  test('respeta el presupuesto mínimo del administrador', () {
    var brief = const AssistantBrief();
    brief = brief.merge(parseMessage('reunión', step: AssistantStep.occasion));
    brief = brief.merge(parseMessage('4', step: AssistantStep.people));
    brief = brief.merge(
        parseMessage('no tengo presupuesto', step: AssistantStep.budget));
    brief =
        brief.merge(parseMessage('me da igual', step: AssistantStep.flavors));
    final recs = recommend(kProducts, brief,
        settings: const AssistantSettings(minBudget: 50000));
    expect(recs, isNotEmpty);
    expect(recs.every((r) => r.total >= 50000), isTrue);
  });

  test('la conversación pregunta, recomienda y se registra', () async {
    final services = memoryServices();
    final chat = AssistantController(
      user: kDemoClient,
      repository: services.assistant,
      catalog: () => kProducts,
      settings: () => const AssistantSettings(),
      replyDelay: Duration.zero,
    );
    Future<void> say(String text) async {
      chat.send(text);
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    expect(chat.messages.last.text, '¿Para qué ocasión es?');
    await say('hola');
    expect(chat.pendingStep, AssistantStep.occasion);
    await say('Cumpleaños de mi mamá');
    expect(chat.messages.last.text, '¿Para cuántas personas?');
    await say('ni idea');
    expect(chat.messages.last.text, contains('número'));
    await say('Unas 20');
    await say('Entre \$70.000 y \$90.000');
    await say('Chocolate y frutos rojos');

    expect(chat.current!.product.id, 'torta-chocolate');
    expect(chat.messages.any((m) => m.recommendation != null), isTrue);
    expect(chat.conversationId, isNotNull);

    await say('Ver otra opción');
    expect(chat.current!.product.id, isNot('torta-chocolate'));

    var logged = await services.assistant.watchConversations().first;
    expect(logged.single.occasion, Occasion.cumpleanos);
    expect(logged.single.result, ConversationResult.enChat);

    // Se va sin comprar: queda «Sin compra».
    chat.dispose();
    await Future<void>.delayed(Duration.zero);
    logged = await services.assistant.watchConversations().first;
    expect(logged.single.result, ConversationResult.sinCompra);
  });

  test('AssistantStats calcula conversión y producto más recomendado', () {
    final now = DateTime(2026, 11, 23, 15);
    Conversation c(String product, ConversationResult r, int s, DateTime d) =>
        Conversation(
          clientId: 'x',
          clientName: 'Ana',
          occasion: Occasion.cumpleanos,
          occasionLabel: 'Cumpleaños',
          productId: product,
          productName: product,
          price: 1000,
          result: r,
          seconds: s,
          createdAt: d,
        );
    final stats = AssistantStats.from([
      c('Torta de chocolate', ConversationResult.compro, 40, now),
      c('Torta de chocolate', ConversationResult.compro, 50, now),
      c('Brownie', ConversationResult.sinCompra, 60, DateTime(2026, 11, 20)),
    ], now: now);
    expect(stats.today, 2);
    expect(stats.conversionRate, 67);
    expect(stats.averageLabel, '50 seg');
    expect(stats.topProduct, 'Torta de chocolate');
  });

  testWidgets('El cliente pide con el asistente y el admin lo ve en IA',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final services = memoryServices(signedIn: kDemoClient);
    await tester.pumpWidget(KekiApp(services: services));
    await settle(tester);

    // Botón central del cliente → chat del asistente.
    await tester.tap(find.byTooltip('Asistente Keki IA'));
    await settle(tester);
    expect(find.text('Asistente Keki'), findsOneWidget);
    expect(find.text('¿Para qué ocasión es?'), findsOneWidget);

    await tester.tap(find.text('Cumpleaños'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Unas 20');
    await tester.tap(find.byTooltip('Enviar'));
    await settle(tester);
    await tester.tap(find.text('Entre \$50.000 y \$90.000'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Chocolate y frutos rojos');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await settle(tester);

    expect(find.text('Encontré una opción para ti'), findsOneWidget);
    expect(find.text('Torta de chocolate'), findsOneWidget);
    await tester.tap(find.text('Agregar al carrito'));
    await settle(tester);
    await tester.tap(find.byTooltip('Volver'));
    await settle(tester);

    // Carrito → entrega → confirmar.
    await tester.tap(find.text('Carrito'));
    await settle(tester);
    expect(find.text('Torta de chocolate'), findsOneWidget);
    await tester.tap(find.text('Confirmar pedido'));
    await settle(tester);
    await tester.tap(find.textContaining('Mañana'));
    await tester.tap(find.text('3:00–5:00 PM'));
    await tester.tap(find.text('Recoger en tienda · Gratis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar entrega'));
    await settle(tester);
    await tester.tap(find.text('Confirmar pedido'));
    await settle(tester);
    expect(find.text('¡Pedido enviado!'), findsOneWidget);

    final order = (await services.orders.watchAll().first).single;
    expect(order.origin, OrderOrigin.ia);
    final conversation =
        (await services.assistant.watchConversations().first).single;
    expect(conversation.result, ConversationResult.compro);
    expect(conversation.orderId, order.id);

    // El admin ve la conversación y la conversión en la pestaña IA.
    await tester.tap(find.text('Ver mis pedidos'));
    await settle(tester);
    await services.auth.signOut();
    await settle(tester);
    await services.auth.signIn(email: 'admin@keki.co', password: '123456');
    await settle(tester);
    await tester.tap(find.text('IA'));
    await settle(tester);
    expect(find.text('Conversaciones hoy'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Valentina Ortiz'), findsOneWidget);
    expect(find.text('Compró'), findsOneWidget);

    // Apagar el asistente lo oculta para los clientes.
    await tester.ensureVisible(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first);
    await settle(tester);
    expect((await services.assistant.watchSettings().first).active, isFalse);
  });

  testWidgets('Personalizar con IA ayuda con un producto concreto',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final services = memoryServices(signedIn: kDemoClient);
    await services.assistant
        .saveSettings(const AssistantSettings(active: false));
    await tester.pumpWidget(KekiApp(services: services));
    await settle(tester);

    // Con el asistente apagado se explica que no está disponible.
    await tester.tap(find.byTooltip('Asistente Keki IA'));
    await settle(tester);
    expect(find.text('El asistente está descansando'), findsOneWidget);
    await tester.tap(find.byTooltip('Volver'));
    await settle(tester);
    await services.assistant.saveSettings(const AssistantSettings());

    await tester.tap(find.text('Explorar'));
    await settle(tester);
    await tester.ensureVisible(find.text('Torta red velvet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Torta red velvet'));
    await settle(tester);
    await tester.ensureVisible(find.text('Personalizar con IA'));
    await tester.tap(find.text('Personalizar con IA'));
    await settle(tester);
    expect(
        find.textContaining('personalizar torta red velvet'), findsOneWidget);
    await tester.enterText(find.byType(TextField),
        'Aniversario para 30 personas, de red velvet, sin límite de presupuesto');
    await tester.tap(find.byTooltip('Enviar'));
    await settle(tester);
    expect(find.text('Torta red velvet'), findsWidgets);
    expect(find.textContaining('28-30 pers.'), findsOneWidget);
  });
}
