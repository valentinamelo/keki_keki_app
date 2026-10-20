// Estado y operaciones para buscar, filtrar, ordenar y marcar favoritos.

import 'package:flutter/foundation.dart';

import '../models/product.dart';

/// Criterios de ordenamiento disponibles en Explorar.
enum SortMode {
  relevance('Relevancia'),
  priceAsc('Precio: menor a mayor'),
  priceDesc('Precio: mayor a menor'),
  rating('Mejor calificados');

  /// Asocia el criterio de orden con el texto que ve el usuario.
  const SortMode(this.label);
  final String label;
}

/// Estado del módulo Explorar: búsqueda, categoría, orden y favoritos.
class CatalogController extends ChangeNotifier {
  /// Inicializa el catálogo con todos los productos disponibles.
  CatalogController(this._all);

  final List<Product> _all;
  String _query = '';
  ProductCategory? _category;
  SortMode _sort = SortMode.relevance;
  final Set<String> _favorites = <String>{};

  /// Texto de búsqueda actual.
  String get query => _query;

  /// Categoría activa; `null` significa que se muestran todas.
  ProductCategory? get category => _category;

  /// Criterio de ordenamiento activo.
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

  /// Cambia la búsqueda y notifica a la interfaz si el texto es diferente.
  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    notifyListeners();
  }

  /// Selecciona una categoría, o todas si [value] es `null`.
  void setCategory(ProductCategory? value) {
    if (value == _category) return;
    _category = value;
    notifyListeners();
  }

  /// Cambia el orden de los resultados y avisa a la interfaz.
  void setSort(SortMode value) {
    if (value == _sort) return;
    _sort = value;
    notifyListeners();
  }

  /// Borra la búsqueda y la categoría seleccionada.
  void clearFilters() {
    _query = '';
    _category = null;
    notifyListeners();
  }

  /// Indica si el producto identificado por [productId] está en favoritos.
  bool isFavorite(String productId) => _favorites.contains(productId);

  /// Alterna el estado de favorito del producto y notifica a la interfaz.
  void toggleFavorite(String productId) {
    if (!_favorites.remove(productId)) _favorites.add(productId);
    notifyListeners();
  }

  /// Pasa el texto a minúsculas y elimina tildes para facilitar coincidencias.
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
