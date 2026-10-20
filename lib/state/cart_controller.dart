import 'package:flutter/foundation.dart';

import '../models/product.dart';

class CartLine {
  CartLine({
    required this.product,
    required this.selection,
    required this.quantity,
  });

  final Product product;
  final Map<String, int> selection;
  int quantity;

  int get unitPrice => product.priceFor(selection);
  int get subtotal => unitPrice * quantity;
  String get summary => product.summaryFor(selection);

  bool matches(Product other, Map<String, int> otherSelection) =>
      other.id == product.id && mapEquals(selection, otherSelection);
}

/// Carrito mínimo en memoria: lo necesario para que "Agregar" funcione.
class CartController extends ChangeNotifier {
  final List<CartLine> _lines = [];

  List<CartLine> get lines => List.unmodifiable(_lines);
  int get count => _lines.fold(0, (sum, l) => sum + l.quantity);
  int get total => _lines.fold(0, (sum, l) => sum + l.subtotal);

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

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
