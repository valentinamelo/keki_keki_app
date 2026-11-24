// Servicios en memoria con el mismo contrato que los de Firebase. Se usan en
// las pruebas y en el modo demo (`--dart-define=KEKI_DEMO=true`).

import 'dart:async';

import '../models/app_user.dart';
import '../models/assistant.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'products_data.dart';
import 'services.dart';

/// Crea servicios en memoria con el catálogo de ejemplo y dos cuentas demo:
/// `cliente@keki.co` y `admin@keki.co`, ambas con la contraseña `123456`.
/// Si se indica [signedIn], la app arranca con esa sesión iniciada.
AppServices memoryServices({AppUser? signedIn}) {
  final auth = MemoryAuthService(signedIn: signedIn);
  final products = MemoryProductRepository(kProducts);
  return AppServices(
    auth: auth,
    users: auth,
    products: products,
    orders: MemoryOrderRepository(products: products),
    assistant: MemoryAssistantRepository(),
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

/// Autenticación simulada con cuentas guardadas en un mapa. También guarda
/// los favoritos de cada cuenta, como el documento `usuarios/{uid}`.
class MemoryAuthService implements AuthService, UserRepository {
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

  @override
  Future<void> setFavorite(String uid, String productId, bool favorite) async {
    for (final entry in _accounts.entries) {
      final (user, password) = entry.value;
      if (user.uid != uid) continue;
      final favorites = {...user.favorites};
      favorite ? favorites.add(productId) : favorites.remove(productId);
      final updated = user.copyWith(favorites: favorites);
      _accounts[entry.key] = (updated, password);
      if (_user?.uid == uid) _user = updated;
      _changes.add(null);
      return;
    }
  }
}

/// Catálogo en memoria.
class MemoryProductRepository implements ProductRepository {
  /// Crea el repositorio con los productos iniciales.
  MemoryProductRepository(List<Product> initial) : _products = [...initial];

  List<Product> _products;
  int _nextId = 1;
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
  Future<void> seed(List<Product> products,
      {List<String> remove = const []}) async {
    _products.removeWhere((p) => remove.contains(p.id));
    // Igual que en Firestore: reemplaza los de ejemplo y conserva los demás.
    final ids = {for (final p in products) p.id};
    _products = [...products, ..._products.where((p) => !ids.contains(p.id))];
    _changes.add(null);
  }

  @override
  Future<String> save(Product product) async {
    final id = product.id.isNotEmpty ? product.id : 'producto-${_nextId++}';
    final saved = Product.fromMap(id, product.toMap());
    final i = _products.indexWhere((p) => p.id == id);
    if (i >= 0) {
      _products[i] = saved;
    } else {
      _products.add(saved);
    }
    _changes.add(null);
    return id;
  }

  @override
  Future<void> setActive(String id, bool active) async {
    _update(id, (map) => map['activo'] = active);
  }

  @override
  Future<void> delete(String id) async {
    _products.removeWhere((p) => p.id == id);
    _changes.add(null);
  }

  /// Suma [delta] al stock de [id] sin bajar de cero.
  void adjustStock(String id, int delta) {
    _update(id, (map) {
      final next = (map['stock'] as int) + delta;
      map['stock'] = next < 0 ? 0 : next;
    });
  }

  /// Modifica el producto [id] a través de su mapa, como haría Firestore.
  void _update(String id, void Function(Map<String, dynamic> map) change) {
    final i = _products.indexWhere((p) => p.id == id);
    if (i < 0) return;
    final map = _products[i].toMap();
    change(map);
    _products[i] = Product.fromMap(id, map);
    _changes.add(null);
  }
}

/// Pedidos en memoria; cada cambio se emite a todos los que escuchan.
class MemoryOrderRepository implements OrderRepository {
  /// Crea el repositorio; con [products] también ajusta el stock.
  MemoryOrderRepository({this.products});

  final MemoryProductRepository? products;
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
    final sign = order.status.stockSignTo(status);
    if (sign != 0) {
      unitsByProduct(order).forEach(
          (productId, units) => products?.adjustStock(productId, sign * units));
    }
    _orders[i] = order.copyWith(
      status: status,
      history: {...order.history, status: DateTime.now()},
    );
    _changes.add(null);
  }
}

/// Ajustes y conversaciones del asistente en memoria.
class MemoryAssistantRepository implements AssistantRepository {
  AssistantSettings _settings = const AssistantSettings();
  final List<Conversation> _conversations = [];
  final StreamController<void> _changes = StreamController.broadcast();
  int _nextId = 1;

  @override
  Stream<AssistantSettings> watchSettings() =>
      _current(() => _settings, _changes.stream);

  @override
  Future<void> saveSettings(AssistantSettings settings) async {
    _settings = settings;
    _changes.add(null);
  }

  @override
  Future<String> logConversation(Conversation conversation) async {
    final saved = conversation.copyWith(
      id: 'conversacion-${_nextId++}',
      createdAt: DateTime.now(),
    );
    _conversations.add(saved);
    _changes.add(null);
    return saved.id;
  }

  @override
  Future<void> updateConversation(
    String id, {
    ConversationResult? result,
    String? orderId,
    String? productId,
    String? productName,
    int? price,
  }) async {
    final i = _conversations.indexWhere((c) => c.id == id);
    if (i < 0) return;
    _conversations[i] = _conversations[i].copyWith(
      result: result,
      orderId: orderId,
      productId: productId,
      productName: productName,
      price: price,
    );
    _changes.add(null);
  }

  @override
  Stream<List<Conversation>> watchConversations() => _current(
        () => _conversations.reversed.toList(),
        _changes.stream,
      );
}
