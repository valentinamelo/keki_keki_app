// Estado de la gestión de pedidos del administrador: lista en tiempo real,
// filtro por estado y aviso de pedidos nuevos.

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/order.dart';

/// Escucha todos los pedidos y los filtra por estado (mockup admin 02).
class AdminOrdersController extends ChangeNotifier {
  /// Empieza a escuchar [source]. [onNewOrder] se llama con cada pedido que
  /// llega después de la primera carga, para mostrar un aviso en vivo.
  AdminOrdersController(
    Stream<List<Order>> source, {
    this.onNewOrder,
  }) {
    _subscription = source.listen(_onData, onError: (Object e) {
      _loading = false;
      _error = e;
      notifyListeners();
    });
  }

  /// Avisa de cada pedido nuevo que aparece mientras el admin está conectado.
  void Function(Order order)? onNewOrder;

  late final StreamSubscription<List<Order>> _subscription;
  List<Order> _orders = const [];
  final Set<String> _knownIds = {};
  OrderStatus? _filter;
  bool _loading = true;
  Object? _error;

  /// `true` hasta que llega la primera respuesta de la base de datos.
  bool get loading => _loading;

  /// Último error al leer los pedidos, o `null` si todo va bien.
  Object? get error => _error;

  /// Estado seleccionado en los chips; `null` muestra todos.
  OrderStatus? get filter => _filter;

  /// Todos los pedidos, del más reciente al más antiguo.
  List<Order> get all => _orders;

  /// Pedidos que coinciden con el filtro activo.
  List<Order> get visible => _filter == null
      ? _orders
      : _orders.where((o) => o.status == _filter).toList();

  /// Cantidad de pedidos en el estado [status] (o todos si es `null`).
  int countOf(OrderStatus? status) => status == null
      ? _orders.length
      : _orders.where((o) => o.status == status).length;

  /// Pedidos que esperan que alguien los acepte.
  int get pendingCount => countOf(OrderStatus.pendiente);

  /// Cambia el filtro por estado.
  void setFilter(OrderStatus? status) {
    if (status == _filter) return;
    _filter = status;
    notifyListeners();
  }

  /// Actualiza la lista y detecta los pedidos que no estaban antes.
  void _onData(List<Order> orders) {
    final firstLoad = _loading;
    _orders = orders;
    _loading = false;
    _error = null;
    for (final o in orders) {
      if (_knownIds.add(o.id) && !firstLoad) onNewOrder?.call(o);
    }
    notifyListeners();
  }

  /// Deja de escuchar la base de datos al cerrar la sesión.
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
