// Contratos de acceso a datos. Las pantallas dependen de estas interfaces y
// no de Firebase directamente; así las pruebas usan versiones en memoria.

import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';

/// Error de autenticación con un mensaje listo para mostrar al usuario.
class AuthFailure implements Exception {
  /// Crea el error con su [message] en español.
  const AuthFailure(this.message);

  final String message;

  /// Devuelve el mensaje para poder mostrar el error directamente.
  @override
  String toString() => message;
}

/// Registro, inicio y cierre de sesión.
abstract class AuthService {
  /// Emite el perfil del usuario (con su rol) o `null` si no hay sesión.
  Stream<AppUser?> get userChanges;

  /// Inicia sesión; lanza [AuthFailure] si los datos no son válidos.
  Future<void> signIn({required String email, required String password});

  /// Crea una cuenta de cliente y su documento en `usuarios`.
  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  });

  /// Cierra la sesión actual.
  Future<void> signOut();
}

/// Lectura y carga de la colección `productos`.
abstract class ProductRepository {
  /// Emite el catálogo cada vez que cambia. Con [onlyActive] se omiten los
  /// productos desactivados por el administrador.
  Stream<List<Product>> watchProducts({bool onlyActive = true});

  /// Guarda [products] en la base de datos (carga del catálogo inicial).
  Future<void> seed(List<Product> products);
}

/// Creación, consulta en tiempo real y cambio de estado de `pedidos`.
abstract class OrderRepository {
  /// Guarda un pedido nuevo y devuelve su identificador.
  Future<String> create(Order order);

  /// Todos los pedidos, del más reciente al más antiguo (administrador).
  Stream<List<Order>> watchAll();

  /// Pedidos del cliente [clientId], del más reciente al más antiguo.
  Stream<List<Order>> watchForClient(String clientId);

  /// Un pedido concreto; emite `null` si no existe.
  Stream<Order?> watchOrder(String id);

  /// Cambia el estado del pedido [id] (solo administradores).
  Future<void> updateStatus(String id, OrderStatus status);
}

/// Agrupa los servicios que usa la aplicación.
class AppServices {
  /// Crea el grupo de servicios con sus implementaciones concretas.
  const AppServices({
    required this.auth,
    required this.products,
    required this.orders,
  });

  final AuthService auth;
  final ProductRepository products;
  final OrderRepository orders;
}

/// Ordena pedidos del más reciente al más antiguo. Los que aún no tienen
/// fecha del servidor (recién creados) quedan primero.
List<Order> sortNewestFirst(Iterable<Order> orders) {
  final list = orders.toList();
  list.sort((a, b) {
    final ta = a.createdAt, tb = b.createdAt;
    if (ta == null) return tb == null ? 0 : -1;
    if (tb == null) return 1;
    return tb.compareTo(ta);
  });
  return list;
}
