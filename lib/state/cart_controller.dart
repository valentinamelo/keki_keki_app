// Modelos de las líneas y controlador del carrito: productos, entrega y
// confirmación del pedido.

import 'package:flutter/foundation.dart';

import '../data/services.dart';
import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';

/// Valor del domicilio que se suma cuando el pedido se entrega en casa.
const int kDeliveryFee = 6000;

/// Franja horaria de entrega: [label] se muestra y [startHour] fija la hora.
class DeliverySlot {
  /// Crea una franja que empieza a la hora [startHour] (formato 24 h).
  const DeliverySlot(this.label, this.startHour);

  final String label;
  final int startHour;
}

/// Franjas que la pastelería ofrece cada día.
const List<DeliverySlot> kDeliverySlots = [
  DeliverySlot('9:00–11:00 AM', 9),
  DeliverySlot('11:00 AM–1:00 PM', 11),
  DeliverySlot('1:00–3:00 PM', 13),
  DeliverySlot('3:00–5:00 PM', 15),
  DeliverySlot('5:00–7:00 PM', 17),
];

class CartLine {
  /// Crea una línea con producto, personalización y cantidad.
  CartLine({
    required this.product,
    required this.selection,
    required this.quantity,
  });

  final Product product;
  final Map<String, int> selection;
  int quantity;

  /// Precio unitario con los recargos de la personalización.
  int get unitPrice => product.priceFor(selection);

  /// Precio unitario multiplicado por la cantidad de esta línea.
  int get subtotal => unitPrice * quantity;

  /// Texto que resume las opciones seleccionadas.
  String get summary => product.summaryFor(selection);

  /// Comprueba si [other] y sus opciones coinciden con esta línea.
  bool matches(Product other, Map<String, int> otherSelection) =>
      other.id == product.id && mapEquals(selection, otherSelection);

  /// Copia la línea como producto de un pedido, con precio y opciones fijos.
  OrderItem toOrderItem() => OrderItem(
        productId: product.id,
        name: product.name,
        art: product.art,
        options: summary,
        unitPrice: unitPrice,
        quantity: quantity,
      );
}

/// Carrito de la sesión actual y datos de entrega del pedido (mockup 05).
class CartController extends ChangeNotifier {
  /// Máximo de unidades por línea.
  static const int maxQuantity = 20;

  final List<CartLine> _lines = [];
  DeliveryMode _mode = DeliveryMode.domicilio;
  DateTime? _date;
  DeliverySlot? _slot;
  String _address = '';
  String _notes = '';
  bool _submitting = false;

  /// Devuelve las líneas como lista no modificable desde fuera del controlador.
  List<CartLine> get lines => List.unmodifiable(_lines);

  /// Cantidad total de unidades que hay en el carrito.
  int get count => _lines.fold(0, (sum, l) => sum + l.quantity);

  /// Suma de los subtotales de todas las líneas.
  int get subtotal => _lines.fold(0, (sum, l) => sum + l.subtotal);

  /// Domicilio según la forma de entrega elegida.
  int get deliveryFee => _mode == DeliveryMode.domicilio ? kDeliveryFee : 0;

  /// Subtotal más domicilio.
  int get total => subtotal + deliveryFee;

  /// Forma de entrega elegida.
  DeliveryMode get mode => _mode;

  /// Día de entrega elegido (sin hora), o `null` si aún no se elige.
  DateTime? get date => _date;

  /// Franja de entrega elegida, o `null` si aún no se elige.
  DeliverySlot? get slot => _slot;

  /// Dirección de entrega (solo para domicilio).
  String get address => _address;

  /// Indicaciones adicionales para la pastelería.
  String get notes => _notes;

  /// `true` mientras se guarda el pedido en la base de datos.
  bool get submitting => _submitting;

  /// Explica qué falta para poder confirmar, o `null` si todo está listo.
  String? get missingInfo {
    if (_lines.isEmpty) return 'Agrega productos al carrito.';
    if (_date == null || _slot == null) {
      return 'Elige la fecha y hora de entrega.';
    }
    if (_mode == DeliveryMode.domicilio && _address.trim().isEmpty) {
      return 'Escribe la dirección de entrega.';
    }
    return null;
  }

  /// Agrega producto y opciones; acumula cantidad si ya existe una línea igual.
  void add(Product product, Map<String, int> selection, {int quantity = 1}) {
    for (final line in _lines) {
      if (line.matches(product, selection)) {
        line.quantity = (line.quantity + quantity).clamp(1, maxQuantity);
        notifyListeners();
        return;
      }
    }
    _lines.add(CartLine(
      product: product,
      selection: Map<String, int>.of(selection),
      quantity: quantity,
    ));
    notifyListeners();
  }

  /// Cambia la cantidad de [line]; si llega a cero, la quita del carrito.
  void setQuantity(CartLine line, int quantity) {
    if (quantity <= 0) {
      _lines.remove(line);
    } else {
      line.quantity = quantity.clamp(1, maxQuantity);
    }
    notifyListeners();
  }

  /// Guarda los datos de entrega elegidos en la hoja de entrega.
  void setDelivery({
    required DeliveryMode mode,
    required DateTime? date,
    required DeliverySlot? slot,
    required String address,
    required String notes,
  }) {
    _mode = mode;
    _date = date == null ? null : DateTime(date.year, date.month, date.day);
    _slot = slot;
    _address = address.trim();
    _notes = notes.trim();
    notifyListeners();
  }

  /// Elimina todos los productos y notifica a las pantallas que escuchan.
  void clear() {
    _lines.clear();
    notifyListeners();
  }

  /// Construye el pedido de [user] con el contenido actual del carrito.
  Order buildOrder(AppUser user) {
    final day = _date!;
    return Order(
      clientId: user.uid,
      clientName: user.name,
      clientPhone: user.phone,
      items: [for (final l in _lines) l.toOrderItem()],
      deliveryFee: deliveryFee,
      deliveryMode: _mode,
      deliveryDate: DateTime(day.year, day.month, day.day, _slot!.startHour),
      deliverySlot: _slot!.label,
      address: _mode == DeliveryMode.domicilio ? _address : '',
      notes: _notes,
    );
  }

  /// Crea el pedido en [orders] y, si se guarda, vacía el carrito y la
  /// fecha elegida. Devuelve el identificador del pedido.
  Future<String> placeOrder(OrderRepository orders, AppUser user) async {
    final missing = missingInfo;
    if (missing != null) throw StateError(missing);
    _submitting = true;
    notifyListeners();
    try {
      final id = await orders.create(buildOrder(user));
      _lines.clear();
      _date = null;
      _slot = null;
      _notes = '';
      return id;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }
}
