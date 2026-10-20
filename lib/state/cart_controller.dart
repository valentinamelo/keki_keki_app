// Modelos de las líneas y controlador en memoria para el carrito de compras.

import 'package:flutter/foundation.dart';

import '../models/product.dart';

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
}

/// Carrito mínimo en memoria: lo necesario para que "Agregar" funcione.
class CartController extends ChangeNotifier {
  final List<CartLine> _lines = [];

  /// Devuelve las líneas como lista no modificable desde fuera del controlador.
  List<CartLine> get lines => List.unmodifiable(_lines);

  /// Cantidad total de unidades que hay en el carrito.
  int get count => _lines.fold(0, (sum, l) => sum + l.quantity);

  /// Suma de los subtotales de todas las líneas.
  int get total => _lines.fold(0, (sum, l) => sum + l.subtotal);

  /// Agrega producto y opciones; acumula cantidad si ya existe una línea igual.
  void add(Product product, Map<String, int> selection, {int quantity = 1}) {
    for (final line in _lines) {
      if (line.matches(product, selection)) {
        line.quantity += quantity;
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

  /// Elimina todos los productos y notifica a las pantallas que escuchan.
  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
