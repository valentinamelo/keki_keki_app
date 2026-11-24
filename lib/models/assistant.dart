// Modelos del Asistente Keki IA: ocasiones, ajustes del asistente y
// conversaciones guardadas para el panel del administrador.

/// Ocasiones que el asistente reconoce. [keywords] son las palabras (sin
/// tildes y en minúscula) con las que se detectan en el mensaje del cliente.
enum Occasion {
  cumpleanos('Cumpleaños', ['cumple', 'cumpleanos', 'birthday', 'fiesta']),
  aniversario('Aniversario', [
    'aniversario',
    'boda',
    'novio',
    'novia',
    'pareja',
    'amor',
    'san valentin'
  ]),
  babyShower(
      'Baby shower', ['baby shower', 'baby', 'bebe', 'babyshower', 'bautizo']),
  reunion('Reunión', [
    'reunion',
    'oficina',
    'trabajo',
    'empresa',
    'equipo',
    'amigos',
    'onces',
    'merienda'
  ]),
  grado('Grado', ['grado', 'graduacion', 'graduado']),
  otra('Otra ocasión', []);

  /// Asocia la ocasión con su etiqueta y sus palabras clave.
  const Occasion(this.label, this.keywords);
  final String label;
  final List<String> keywords;

  /// Busca la ocasión guardada en Firestore por su nombre.
  static Occasion fromName(Object? name) =>
      Occasion.values.firstWhere((o) => o.name == name, orElse: () => otra);
}

/// Ajustes del asistente que el administrador cambia desde la pestaña IA
/// (documento `config/asistente`).
class AssistantSettings {
  /// Crea los ajustes; los valores por defecto son los del mockup.
  const AssistantSettings({
    this.active = true,
    this.suggestCustomization = true,
    this.minBudget = 25000,
    this.notifyOrders = true,
  });

  /// Si es `false`, los clientes ven que el asistente no está disponible.
  final bool active;

  /// Ofrecer sabores y decoración según la ocasión.
  final bool suggestCustomization;

  /// Monto mínimo (COP) de lo que el asistente recomienda.
  final int minBudget;

  /// Avisar al administrador cuando llega un pedido hecho con el asistente.
  final bool notifyOrders;

  /// Convierte los ajustes al documento de Firestore.
  Map<String, dynamic> toMap() => {
        'activo': active,
        'sugerirPersonalizacion': suggestCustomization,
        'presupuestoMinimo': minBudget,
        'notificarPedidos': notifyOrders,
      };

  /// Reconstruye los ajustes; un documento vacío da los valores por defecto.
  factory AssistantSettings.fromMap(Map<String, dynamic>? map) {
    const d = AssistantSettings();
    if (map == null) return d;
    return AssistantSettings(
      active: map['activo'] as bool? ?? d.active,
      suggestCustomization:
          map['sugerirPersonalizacion'] as bool? ?? d.suggestCustomization,
      minBudget: (map['presupuestoMinimo'] as num?)?.toInt() ?? d.minBudget,
      notifyOrders: map['notificarPedidos'] as bool? ?? d.notifyOrders,
    );
  }

  /// Copia de los ajustes cambiando solo los campos indicados.
  AssistantSettings copyWith({
    bool? active,
    bool? suggestCustomization,
    int? minBudget,
    bool? notifyOrders,
  }) =>
      AssistantSettings(
        active: active ?? this.active,
        suggestCustomization: suggestCustomization ?? this.suggestCustomization,
        minBudget: minBudget ?? this.minBudget,
        notifyOrders: notifyOrders ?? this.notifyOrders,
      );
}

/// Cómo terminó una conversación con el asistente.
enum ConversationResult {
  enChat('en_chat', 'En chat'),
  compro('compro', 'Compró'),
  sinCompra('sin_compra', 'Sin compra');

  /// Asocia el resultado con su valor en Firestore y su etiqueta.
  const ConversationResult(this.key, this.label);
  final String key;
  final String label;

  /// Interpreta el campo `resultado` de Firestore.
  static ConversationResult fromKey(Object? key) => ConversationResult.values
      .firstWhere((r) => r.key == key, orElse: () => ConversationResult.enChat);
}

/// Documento de la colección `conversaciones`: lo que pidió el cliente, qué
/// le recomendó el asistente y si terminó en un pedido.
class Conversation {
  /// Crea el registro de una conversación.
  const Conversation({
    this.id = '',
    required this.clientId,
    required this.clientName,
    required this.occasion,
    required this.occasionLabel,
    this.people,
    this.budgetMin,
    this.budgetMax,
    this.flavors = const [],
    required this.productId,
    required this.productName,
    required this.price,
    this.result = ConversationResult.enChat,
    this.orderId,
    this.seconds = 0,
    this.createdAt,
  });

  final String id;
  final String clientId;
  final String clientName;
  final Occasion occasion;

  /// Texto de la ocasión (para «Otra ocasión» es lo que escribió el cliente).
  final String occasionLabel;
  final int? people;
  final int? budgetMin;
  final int? budgetMax;
  final List<String> flavors;

  /// Producto recomendado (el último que se mostró).
  final String productId;
  final String productName;
  final int price;
  final ConversationResult result;

  /// Pedido creado con la recomendación, si lo hubo.
  final String? orderId;

  /// Segundos desde el primer mensaje hasta la recomendación.
  final int seconds;

  /// Fecha del servidor (`null` mientras se sincroniza).
  final DateTime? createdAt;

  /// Convierte la conversación al documento de Firestore (sin `creado`, que
  /// lo asigna el repositorio con la hora del servidor).
  Map<String, dynamic> toMap() => {
        'clienteId': clientId,
        'clienteNombre': clientName,
        'ocasion': occasion.name,
        'ocasionTexto': occasionLabel,
        'personas': people,
        'presupuestoMin': budgetMin,
        'presupuestoMax': budgetMax,
        'sabores': flavors,
        'productoId': productId,
        'productoNombre': productName,
        'precio': price,
        'resultado': result.key,
        'pedidoId': orderId,
        'segundos': seconds,
      };

  /// Reconstruye la conversación [id]. Las fechas deben llegar como [DateTime].
  factory Conversation.fromMap(String id, Map<String, dynamic> map) =>
      Conversation(
        id: id,
        clientId: map['clienteId'] as String? ?? '',
        clientName: map['clienteNombre'] as String? ?? '',
        occasion: Occasion.fromName(map['ocasion']),
        occasionLabel: map['ocasionTexto'] as String? ?? '',
        people: (map['personas'] as num?)?.toInt(),
        budgetMin: (map['presupuestoMin'] as num?)?.toInt(),
        budgetMax: (map['presupuestoMax'] as num?)?.toInt(),
        flavors: [for (final f in (map['sabores'] as List? ?? const [])) '$f'],
        productId: map['productoId'] as String? ?? '',
        productName: map['productoNombre'] as String? ?? '',
        price: (map['precio'] as num?)?.toInt() ?? 0,
        result: ConversationResult.fromKey(map['resultado']),
        orderId: map['pedidoId'] as String?,
        seconds: (map['segundos'] as num?)?.toInt() ?? 0,
        createdAt: map['creado'] as DateTime?,
      );

  /// Copia de la conversación cambiando solo los campos indicados.
  Conversation copyWith({
    String? id,
    ConversationResult? result,
    String? orderId,
    String? productId,
    String? productName,
    int? price,
    DateTime? createdAt,
  }) =>
      Conversation(
        id: id ?? this.id,
        clientId: clientId,
        clientName: clientName,
        occasion: occasion,
        occasionLabel: occasionLabel,
        people: people,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        flavors: flavors,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        price: price ?? this.price,
        result: result ?? this.result,
        orderId: orderId ?? this.orderId,
        seconds: seconds,
        createdAt: createdAt ?? this.createdAt,
      );
}
