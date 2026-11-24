// Estado de una conversación con el Asistente Keki IA (mockup 04): mensajes,
// preguntas pendientes, respuestas rápidas y recomendaciones.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../data/services.dart';
import '../models/app_user.dart';
import '../models/assistant.dart';
import '../models/product.dart';
import 'assistant_engine.dart';

/// Un mensaje del chat: texto del cliente o del asistente, o la tarjeta con
/// una recomendación.
class ChatMessage {
  /// Mensaje de texto; [fromUser] lo alinea a la derecha.
  const ChatMessage.text(this.text, {this.fromUser = false})
      : recommendation = null;

  /// Tarjeta «Encontré una opción para ti».
  const ChatMessage.card(Recommendation this.recommendation)
      : text = '',
        fromUser = false;

  final String text;
  final bool fromUser;
  final Recommendation? recommendation;
}

/// Lleva la conversación: entiende cada mensaje con [parseMessage], pregunta
/// lo que falta y, con las cuatro respuestas, recomienda productos del
/// catálogo. La primera recomendación se registra en `conversaciones`.
class AssistantController extends ChangeNotifier {
  /// Crea la conversación de [user]. [catalog] devuelve los productos
  /// actuales y [settings] los ajustes del administrador. Con [focus] solo se
  /// personaliza ese producto («Personalizar con IA» desde el detalle).
  AssistantController({
    required this.user,
    required this.repository,
    required this.catalog,
    required this.settings,
    this.focus,
    this.replyDelay = const Duration(milliseconds: 550),
  }) {
    _startedAt = DateTime.now();
    _say(focus == null
        ? '¡Hola, ${user.firstName}! Cuéntame sobre tu pedido y te ayudo a '
            'encontrar la torta perfecta ✨'
        : '¡Hola, ${user.firstName}! Te ayudo a personalizar '
            '${focus!.name.toLowerCase()} ✨');
    _say(_question(AssistantStep.occasion));
  }

  final AppUser user;
  final AssistantRepository repository;
  final List<Product> Function() catalog;
  final AssistantSettings Function() settings;
  final Product? focus;

  /// Pausa antes de cada respuesta, para que se vea «escribiendo…».
  final Duration replyDelay;

  final List<ChatMessage> _messages = [];
  AssistantBrief _brief = const AssistantBrief();
  List<Recommendation> _options = const [];
  int _shown = 0;
  bool _typing = false;
  bool _disposed = false;
  bool _addedToCart = false;
  String? _conversationId;
  late DateTime _startedAt;
  Timer? _timer;

  /// Mensajes en orden de llegada.
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// `true` mientras el asistente «escribe» la respuesta.
  bool get typing => _typing;

  /// Lo que el asistente sabe del pedido.
  AssistantBrief get brief => _brief;

  /// Id del registro en `conversaciones` (después de recomendar).
  String? get conversationId => _conversationId;

  /// Recomendación que se está mostrando, si ya hay una.
  Recommendation? get current =>
      _shown > 0 && _shown <= _options.length ? _options[_shown - 1] : null;

  /// `true` si quedan otras opciones por mostrar.
  bool get hasMoreOptions => _shown < _options.length && _shown < 3;

  /// Siguiente pregunta sin responder, o `null` si ya están todas.
  AssistantStep? get pendingStep {
    if (_brief.occasion == null) return AssistantStep.occasion;
    if (_brief.people == null) return AssistantStep.people;
    if (!_brief.budgetAnswered) return AssistantStep.budget;
    if (!_brief.flavorsAnswered) return AssistantStep.flavors;
    return null;
  }

  /// Respuestas rápidas para la pregunta actual (chips bajo el chat).
  List<String> get quickReplies {
    if (_typing) return const [];
    switch (pendingStep) {
      case AssistantStep.occasion:
        return const ['Cumpleaños', 'Aniversario', 'Baby shower', 'Reunión'];
      case AssistantStep.people:
        return const [
          '8 personas',
          '15 personas',
          '20 personas',
          '30 personas'
        ];
      case AssistantStep.budget:
        return const [
          'Hasta \$50.000',
          'Entre \$50.000 y \$90.000',
          'Más de \$90.000',
          'No tengo presupuesto',
        ];
      case AssistantStep.flavors:
        return const ['Chocolate', 'Vainilla', 'Tres leches', 'Me da igual'];
      case null:
        return [
          if (hasMoreOptions) 'Ver otra opción',
          'Empezar de nuevo',
        ];
    }
  }

  /// Procesa un mensaje del cliente y programa la respuesta.
  void send(String text) {
    final clean = text.trim();
    if (clean.isEmpty || _typing) return;
    _messages.add(ChatMessage.text(clean, fromUser: true));
    _typing = true;
    notifyListeners();
    _timer = Timer(replyDelay, () {
      if (_disposed) return;
      _typing = false;
      _reply(clean);
      notifyListeners();
    });
  }

  /// Decide qué contestar a [text].
  void _reply(String text) {
    final t = normalize(text);
    if (RegExp(r'empezar de nuevo|reiniciar|otra vez|desde cero|nueva busqueda')
        .hasMatch(t)) {
      _restart();
      return;
    }
    final step = pendingStep;
    if (RegExp(
            r'^(hola|holi|buenas|buenos dias|buenas tardes|buenas noches|hey|hi)\W*$')
        .hasMatch(t)) {
      _say('¡Hola! 😊 ${step == null ? _hint(null) : _question(step)}');
      return;
    }
    if (step == null &&
        RegExp(r'otra|otro|diferente|alternativa|siguiente|mas opciones')
            .hasMatch(t)) {
      _showNext();
      return;
    }
    if (RegExp(r'^(gracias|muchas gracias|ok|listo|perfecto|genial)\b')
            .hasMatch(t) &&
        step == null) {
      _say('¡Con gusto! Si quieres, toca «Agregar al carrito» en la tarjeta '
          'o escríbeme para buscar otra opción 🎂');
      return;
    }

    final parsed = parseMessage(text, step: step);
    final before = _brief;
    _brief = _brief.merge(parsed);
    final learned = _brief.occasion != before.occasion ||
        _brief.people != before.people ||
        _brief.budgetMin != before.budgetMin ||
        _brief.budgetMax != before.budgetMax ||
        _brief.budgetAnswered != before.budgetAnswered ||
        _brief.flavorsAnswered != before.flavorsAnswered ||
        !listEquals(_brief.flavors, before.flavors);

    if (!learned) {
      _say(_hint(step));
      return;
    }
    final next = pendingStep;
    if (next != null) {
      _say(_question(next));
      return;
    }
    // Ya están las cuatro respuestas (o el cliente cambió alguna después de
    // una recomendación): se recalcula.
    _recommend();
  }

  /// Calcula las opciones y muestra la mejor.
  void _recommend() {
    _options = recommend(
      catalog(),
      _brief,
      settings: settings(),
      onlyProduct: focus?.id,
    );
    _shown = 0;
    if (_options.isEmpty) {
      _say('Por ahora no tengo productos disponibles para recomendarte. '
          'Vuelve a intentarlo en un rato 🙏');
      return;
    }
    _showNext(first: true);
  }

  /// Muestra la siguiente opción del ranking.
  void _showNext({bool first = false}) {
    if (!first && !hasMoreOptions) {
      _say('Esas son mis mejores opciones. Puedes cambiar algún dato '
          '(por ejemplo «para 30 personas» o «hasta 100 mil») o '
          'escribir «empezar de nuevo».');
      return;
    }
    final rec = _options[_shown++];
    _say(first
        ? recommendationIntro(rec, _brief)
        : 'Otra opción que te puede gustar:');
    _messages.add(ChatMessage.card(rec));
    if (first && settings().suggestCustomization && focus == null) {
      final tip = _tipFor(_brief.occasion);
      if (tip != null) _say(tip);
    }
    _log(rec);
  }

  /// Registra la conversación la primera vez y luego actualiza el producto.
  void _log(Recommendation rec) {
    final id = _conversationId;
    if (id != null) {
      unawaited(repository.updateConversation(
        id,
        productId: rec.product.id,
        productName: rec.product.name,
        price: rec.total,
      ));
      return;
    }
    final conversation = Conversation(
      clientId: user.uid,
      clientName: user.name,
      occasion: _brief.occasion ?? Occasion.otra,
      occasionLabel: _brief.occasionLabel ?? Occasion.otra.label,
      people: _brief.people,
      budgetMin: _brief.budgetMin,
      budgetMax: _brief.budgetMax,
      flavors: _brief.flavors,
      productId: rec.product.id,
      productName: rec.product.name,
      price: rec.total,
      seconds: DateTime.now().difference(_startedAt).inSeconds,
    );
    repository.logConversation(conversation).then((id) {
      _conversationId = id;
      if (_disposed && !_addedToCart) {
        // El cliente se fue antes de que terminara el registro.
        unawaited(repository.updateConversation(id,
            result: ConversationResult.sinCompra));
      }
      if (!_disposed) notifyListeners();
    }, onError: (Object e) {
      debugPrint('Keki: no se pudo registrar la conversación: $e');
    });
  }

  /// Avisa que el cliente agregó la recomendación al carrito.
  void markAddedToCart() => _addedToCart = true;

  /// Vuelve a empezar la conversación (se conserva el historial visible).
  void _restart() {
    _closeConversation();
    _brief = const AssistantBrief();
    _options = const [];
    _shown = 0;
    _addedToCart = false;
    _conversationId = null;
    _startedAt = DateTime.now();
    _say('¡Empecemos de nuevo!');
    _say(_question(AssistantStep.occasion));
  }

  /// Si no se agregó nada al carrito, la conversación queda «Sin compra».
  void _closeConversation() {
    final id = _conversationId;
    if (id != null && !_addedToCart) {
      unawaited(repository.updateConversation(id,
          result: ConversationResult.sinCompra));
    }
  }

  /// Agrega un mensaje del asistente.
  void _say(String text) => _messages.add(ChatMessage.text(text));

  /// Texto de cada pregunta.
  String _question(AssistantStep step) {
    switch (step) {
      case AssistantStep.occasion:
        return '¿Para qué ocasión es?';
      case AssistantStep.people:
        return '¿Para cuántas personas?';
      case AssistantStep.budget:
        final min = settings().minBudget;
        return min > 0
            ? '¿Cuál es tu presupuesto? (nuestros pedidos parten de ${cop(min)})'
            : '¿Cuál es tu presupuesto?';
      case AssistantStep.flavors:
        return '¿Qué sabores te gustan?';
    }
  }

  /// Ayuda cuando no se entendió la respuesta.
  String _hint(AssistantStep? step) {
    switch (step) {
      case AssistantStep.occasion:
        return 'Cuéntame la ocasión, por ejemplo «cumpleaños de mi mamá».';
      case AssistantStep.people:
        return 'No entendí cuántas personas. Escríbeme un número, por ejemplo «20».';
      case AssistantStep.budget:
        return 'No entendí el presupuesto. Prueba con «entre 70 y 90 mil» o '
            '«hasta \$60.000».';
      case AssistantStep.flavors:
        return 'Puedo buscar chocolate, vainilla, tres leches, frutas, '
            'naranja o red velvet. ¿Cuál prefieres? También puedes decir «me da igual».';
      case null:
        return 'Puedo mostrarte otra opción, o puedes cambiar un dato: '
            '«para 30 personas», «hasta 100 mil», «de vainilla»…';
    }
  }

  /// Sugerencia de personalización según la ocasión (ajuste del admin).
  static String? _tipFor(Occasion? occasion) {
    switch (occasion) {
      case Occasion.cumpleanos:
        return 'Tip: en «Indicaciones» del carrito puedes pedir un mensaje '
            'escrito, como «Feliz cumpleaños, mamá» 🎉';
      case Occasion.aniversario:
        return 'Tip: con flores naturales y un mensaje en «Indicaciones» '
            'queda perfecta para un aniversario 💐';
      case Occasion.babyShower:
        return 'Tip: puedes pedir la decoración en azul o rosa pastel en '
            '«Indicaciones» del carrito 👶';
      case Occasion.reunion:
        return 'Tip: para reuniones, las cajas de galletas o de rollos de canela se '
            'reparten fácil y sin cubiertos ☕';
      default:
        return null;
    }
  }

  /// Al salir del chat, una conversación sin compra queda «Sin compra».
  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _closeConversation();
    super.dispose();
  }
}
