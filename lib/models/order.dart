// Modelos de los pedidos: estados, forma de entrega, líneas y documento.

import 'product.dart';

/// Estados por los que pasa un pedido. [key] es el valor guardado en Firestore.
enum OrderStatus {
  pendiente('pendiente', 'Pendiente'),
  enPreparacion('en_preparacion', 'En preparación'),
  listo('listo', 'Listo'),
  entregado('entregado', 'Entregado'),
  cancelado('cancelado', 'Cancelado');

  /// Asocia el estado con su valor en la base de datos y su etiqueta.
  const OrderStatus(this.key, this.label);
  final String key;
  final String label;

  /// Flujo normal del pedido, sin contar la cancelación.
  static const List<OrderStatus> flow = [
    pendiente,
    enPreparacion,
    listo,
    entregado,
  ];

  /// Siguiente estado del flujo, o `null` si el pedido ya terminó.
  OrderStatus? get next {
    final i = flow.indexOf(this);
    return i >= 0 && i < flow.length - 1 ? flow[i + 1] : null;
  }

  /// Un pedido sigue abierto mientras no se entregue ni se cancele.
  bool get isOpen => this != entregado && this != cancelado;

  /// Solo se cancela un pedido que todavía no está listo.
  bool get canCancel => this == pendiente || this == enPreparacion;

  /// Interpreta el campo `estado` de Firestore.
  static OrderStatus fromKey(Object? key) => OrderStatus.values
      .firstWhere((s) => s.key == key, orElse: () => OrderStatus.pendiente);
}

/// Forma en que el cliente recibe el pedido.
enum DeliveryMode {
  domicilio('domicilio', 'Entrega a domicilio'),
  recoger('recoger', 'Recoger en tienda');

  /// Asocia la forma de entrega con su valor en Firestore y su etiqueta.
  const DeliveryMode(this.key, this.label);
  final String key;
  final String label;

  /// Interpreta el campo `tipoEntrega` de Firestore.
  static DeliveryMode fromKey(Object? key) =>
      key == 'recoger' ? DeliveryMode.recoger : DeliveryMode.domicilio;
}

/// Canal desde el que se creó el pedido (el asistente llega en la entrega 4).
enum OrderOrigin {
  catalogo('catalogo', 'Catálogo'),
  ia('ia', 'Asistente IA');

  /// Asocia el origen con su valor en Firestore y su etiqueta.
  const OrderOrigin(this.key, this.label);
  final String key;
  final String label;

  /// Interpreta el campo `origen` de Firestore.
  static OrderOrigin fromKey(Object? key) =>
      key == 'ia' ? OrderOrigin.ia : OrderOrigin.catalogo;
}

/// Producto dentro de un pedido. Guarda una copia del nombre y del precio
/// para que el pedido no cambie si luego se edita el catálogo.
class OrderItem {
  /// Crea una línea de pedido con su personalización y cantidad.
  const OrderItem({
    required this.productId,
    required this.name,
    required this.art,
    required this.options,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId;
  final String name;
  final ArtKind art;

  /// Resumen de la personalización, por ejemplo «15 pers. · Vainilla».
  final String options;
  final int unitPrice;
  final int quantity;

  /// Precio unitario multiplicado por la cantidad.
  int get subtotal => unitPrice * quantity;

  /// Convierte la línea al mapa guardado dentro del pedido.
  Map<String, dynamic> toMap() => {
        'productoId': productId,
        'nombre': name,
        'ilustracion': art.name,
        'opciones': options,
        'precioUnitario': unitPrice,
        'cantidad': quantity,
      };

  /// Reconstruye la línea a partir del mapa guardado en Firestore.
  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        productId: map['productoId'] as String? ?? '',
        name: map['nombre'] as String? ?? '',
        art: ArtKind.fromName(map['ilustracion']),
        options: map['opciones'] as String? ?? '',
        unitPrice: (map['precioUnitario'] as num?)?.toInt() ?? 0,
        quantity: (map['cantidad'] as num?)?.toInt() ?? 1,
      );
}

/// Documento de la colección `pedidos`.
class Order {
  /// Crea un pedido con sus datos de cliente, productos, entrega y estado.
  const Order({
    this.id = '',
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.items,
    required this.deliveryFee,
    required this.deliveryMode,
    required this.deliveryDate,
    required this.deliverySlot,
    this.address = '',
    this.notes = '',
    this.origin = OrderOrigin.catalogo,
    this.status = OrderStatus.pendiente,
    this.createdAt,
    this.history = const {},
  });

  /// Identificador del documento (vacío antes de guardarlo).
  final String id;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final List<OrderItem> items;
  final int deliveryFee;
  final DeliveryMode deliveryMode;

  /// Día y hora de inicio de la franja de entrega.
  final DateTime deliveryDate;

  /// Franja de entrega elegida, por ejemplo «3:00–5:00 PM».
  final String deliverySlot;
  final String address;
  final String notes;
  final OrderOrigin origin;
  final OrderStatus status;

  /// Fecha de creación asignada por el servidor (`null` mientras se sincroniza).
  final DateTime? createdAt;

  /// Momento en que el pedido llegó a cada estado.
  final Map<OrderStatus, DateTime> history;

  /// Suma de los productos, sin domicilio.
  int get subtotal => items.fold(0, (sum, i) => sum + i.subtotal);

  /// Valor a pagar: productos más domicilio.
  int get total => subtotal + deliveryFee;

  /// Unidades totales del pedido.
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  /// Texto corto con los productos, por ejemplo «Torta de chocolate x1, …».
  String get itemsSummary =>
      items.map((i) => '${i.name} x${i.quantity}').join(', ');

  /// Convierte el pedido al documento de Firestore. Las fechas de creación
  /// e historial las asigna el repositorio con la hora del servidor.
  Map<String, dynamic> toMap() => {
        'clienteId': clientId,
        'clienteNombre': clientName,
        'clienteTelefono': clientPhone,
        'items': [for (final i in items) i.toMap()],
        'subtotal': subtotal,
        'domicilio': deliveryFee,
        'total': total,
        'tipoEntrega': deliveryMode.key,
        'entrega': deliveryDate,
        'franja': deliverySlot,
        'direccion': address,
        'notas': notes,
        'origen': origin.key,
        'estado': status.key,
      };

  /// Reconstruye el pedido [id]. Las fechas deben llegar como [DateTime].
  factory Order.fromMap(String id, Map<String, dynamic> map) {
    final history = <OrderStatus, DateTime>{};
    final rawHistory = map['historial'];
    if (rawHistory is Map) {
      rawHistory.forEach((key, value) {
        if (value is DateTime) history[OrderStatus.fromKey(key)] = value;
      });
    }
    return Order(
      id: id,
      clientId: map['clienteId'] as String? ?? '',
      clientName: map['clienteNombre'] as String? ?? '',
      clientPhone: map['clienteTelefono'] as String? ?? '',
      items: [
        for (final i in (map['items'] as List? ?? const []))
          OrderItem.fromMap(Map<String, dynamic>.from(i as Map)),
      ],
      deliveryFee: (map['domicilio'] as num?)?.toInt() ?? 0,
      deliveryMode: DeliveryMode.fromKey(map['tipoEntrega']),
      deliveryDate: map['entrega'] as DateTime? ?? DateTime.now(),
      deliverySlot: map['franja'] as String? ?? '',
      address: map['direccion'] as String? ?? '',
      notes: map['notas'] as String? ?? '',
      origin: OrderOrigin.fromKey(map['origen']),
      status: OrderStatus.fromKey(map['estado']),
      createdAt: map['creado'] as DateTime?,
      history: history,
    );
  }

  /// Copia del pedido cambiando solo los campos indicados.
  Order copyWith({
    String? id,
    OrderStatus? status,
    DateTime? createdAt,
    Map<OrderStatus, DateTime>? history,
  }) =>
      Order(
        id: id ?? this.id,
        clientId: clientId,
        clientName: clientName,
        clientPhone: clientPhone,
        items: items,
        deliveryFee: deliveryFee,
        deliveryMode: deliveryMode,
        deliveryDate: deliveryDate,
        deliverySlot: deliverySlot,
        address: address,
        notes: notes,
        origin: origin,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        history: history ?? this.history,
      );
}
