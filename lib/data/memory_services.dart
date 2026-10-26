// Servicios en memoria con el mismo contrato que los de Firebase. Se usan en
// las pruebas y en el modo demo (`--dart-define=KEKI_DEMO=true`).

import 'dart:async';

import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'products_data.dart';
import 'services.dart';

/// Crea servicios en memoria con el catálogo de ejemplo y dos cuentas demo:
/// `cliente@keki.co` y `admin@keki.co`, ambas con la contraseña `123456`.
/// Si se indica [signedIn], la app arranca con esa sesión iniciada.
AppServices memoryServices({AppUser? signedIn}) {
  return AppServices(
    auth: MemoryAuthService(signedIn: signedIn),
    products: MemoryProductRepository(kProducts),
    orders: MemoryOrderRepository(),
  );
}

/// Usuarios de demostración disponibles en el modo en memoria.
const kDemoClient = AppUser(
  uid: 'demo-cliente',
  name: 'Valentina Ortiz',
  email: 'cliente@keki.co',
  phone: '+57 300 412 8890',
);

const kDemoAdmin = AppUser(
  uid: 'demo-admin',
  name: 'Andrea Ríos',
  email: 'admin@keki.co',
  role: UserRole.admin,
);

/// Emite el valor actual al suscribirse y luego cada cambio, como Firestore.
Stream<T> _current<T>(T Function() read, Stream<void> changes) async* {
  yield read();
  yield* changes.map((_) => read());
}

/// Autenticación simulada con cuentas guardadas en un mapa.
class MemoryAuthService implements AuthService {
  /// Crea el servicio, opcionalmente con una sesión [signedIn] ya iniciada.
  MemoryAuthService({AppUser? signedIn}) : _user = signedIn;

  final Map<String, (AppUser, String)> _accounts = {
    kDemoClient.email: (kDemoClient, '123456'),
    kDemoAdmin.email: (kDemoAdmin, '123456'),
  };
  final StreamController<void> _changes = StreamController.broadcast();
  AppUser? _user;

  @override
  Stream<AppUser?> get userChanges => _current(() => _user, _changes.stream);

  @override
  Future<void> signIn({required String email, required String password}) async {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.$2 != password) {
      throw const AuthFailure('Correo o contraseña incorrectos.');
    }
    _user = account.$1;
    _changes.add(null);
  }

  @override
  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthFailure('Ya existe una cuenta con este correo.');
    }
    if (password.length < 6) {
      throw const AuthFailure(
          'La contraseña debe tener al menos 6 caracteres.');
    }
    final user = AppUser(
      uid: 'user-${_accounts.length + 1}',
      name: name.trim(),
      email: key,
      phone: phone.trim(),
    );
    _accounts[key] = (user, password);
    _user = user;
    _changes.add(null);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _changes.add(null);
  }
}

/// Catálogo en memoria.
class MemoryProductRepository implements ProductRepository {
  /// Crea el repositorio con los productos iniciales.
  MemoryProductRepository(List<Product> initial) : _products = [...initial];

  List<Product> _products;
  final StreamController<void> _changes = StreamController.broadcast();

  @override
  Stream<List<Product>> watchProducts({bool onlyActive = true}) => _current(
        () => [
          for (final p in _products)
            if (!onlyActive || p.active) p,
        ],
        _changes.stream,
      );

  @override
  Future<void> seed(List<Product> products) async {
    _products = [...products];
    _changes.add(null);
  }
}

/// Pedidos en memoria; cada cambio se emite a todos los que escuchan.
class MemoryOrderRepository implements OrderRepository {
  final List<Order> _orders = [];
  final StreamController<void> _changes = StreamController.broadcast();
  int _nextId = 1;

  @override
  Future<String> create(Order order) async {
    final now = DateTime.now();
    final saved = order.copyWith(
      id: 'pedido-${_nextId++}',
      status: OrderStatus.pendiente,
      createdAt: now,
      history: {OrderStatus.pendiente: now},
    );
    _orders.add(saved);
    _changes.add(null);
    return saved.id;
  }

  @override
  Stream<List<Order>> watchAll() =>
      _current(() => sortNewestFirst(_orders), _changes.stream);

  @override
  Stream<List<Order>> watchForClient(String clientId) => _current(
        () => sortNewestFirst(_orders.where((o) => o.clientId == clientId)),
        _changes.stream,
      );

  @override
  Stream<Order?> watchOrder(String id) => _current(
        () => _orders.where((o) => o.id == id).firstOrNull,
        _changes.stream,
      );

  @override
  Future<void> updateStatus(String id, OrderStatus status) async {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i < 0) return;
    final order = _orders[i];
    _orders[i] = order.copyWith(
      status: status,
      history: {...order.history, status: DateTime.now()},
    );
    _changes.add(null);
  }
}
