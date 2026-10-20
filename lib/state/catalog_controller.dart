import 'package:flutter/foundation.dart';

import '../models/product.dart';

enum SortMode {
  relevance('Relevancia'),
  priceAsc('Precio: menor a mayor'),
  priceDesc('Precio: mayor a menor'),
  rating('Mejor calificados');

  const SortMode(this.label);
  final String label;
}

/// Estado del módulo Explorar: búsqueda, categoría, orden y favoritos.
class CatalogController extends ChangeNotifier {
  CatalogController(this._all);

  final List<Product> _all;
  String _query = '';
  ProductCategory? _category;
  SortMode _sort = SortMode.relevance;
  final Set<String> _favorites = <String>{};

  String get query => _query;
  ProductCategory? get category => _category;
  SortMode get sort => _sort;

  /// Productos que cumplen búsqueda + categoría, ya ordenados.
  List<Product> get results {
    final q = _normalize(_query.trim());
    final list = _all.where((p) {
      final inCategory = _category == null || p.category == _category;
      final matches = q.isEmpty ||
          _normalize(p.name).contains(q) ||
          _normalize(p.category.label).contains(q);
      return inCategory && matches;
    }).toList();

    switch (_sort) {
      case SortMode.relevance:
        break;
      case SortMode.priceAsc:
        list.sort((a, b) => a.defaultPrice.compareTo(b.defaultPrice));
        break;
      case SortMode.priceDesc:
        list.sort((a, b) => b.defaultPrice.compareTo(a.defaultPrice));
        break;
      case SortMode.rating:
        list.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
    }
    return list;
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  void setCategory(ProductCategory? value) {
    if (value == _category) return;
    _category = value;
    notifyListeners();
  }

  void setSort(SortMode value) {
    if (value == _sort) return;
    _sort = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _category = null;
    notifyListeners();
  }

  bool isFavorite(String productId) => _favorites.contains(productId);

  void toggleFavorite(String productId) {
    if (!_favorites.remove(productId)) _favorites.add(productId);
    notifyListeners();
  }

  /// Minúsculas y sin tildes, para que "torta" encuentre "Tórtá".
  static String _normalize(String s) {
    const from = 'áàäâéèëêíìïîóòöôúùüûñ';
    const to = 'aaaaeeeeiiiioooouuuun';
    final buffer = StringBuffer();
    for (final ch in s.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      buffer.write(i >= 0 ? to[i] : ch);
    }
    return buffer.toString();
  }
}
