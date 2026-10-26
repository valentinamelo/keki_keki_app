// Implementaciones de los servicios con Firebase Authentication y Firestore.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'services.dart';

/// Crea los servicios conectados al proyecto de Firebase ya inicializado.
AppServices firebaseServices() {
  final db = FirebaseFirestore.instance;
  return AppServices(
    auth: FirebaseAuthService(FirebaseAuth.instance, db),
    products: FirestoreProductRepository(db),
    orders: FirestoreOrderRepository(db),
  );
}

/// Convierte los [Timestamp] de Firestore (también dentro de mapas y listas)
/// en [DateTime], para que los modelos no dependan de Firebase.
Object? _plain(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is Map) {
    return {for (final e in value.entries) e.key as String: _plain(e.value)};
  }
  if (value is List) return [for (final v in value) _plain(v)];
  return value;
}

/// Datos del documento con las fechas ya convertidas.
Map<String, dynamic> _dataOf(DocumentSnapshot<Map<String, dynamic>> doc) =>
    _plain(doc.data() ?? const <String, dynamic>{}) as Map<String, dynamic>;

/// Autenticación con correo y contraseña; el rol vive en `usuarios/{uid}`.
class FirebaseAuthService implements AuthService {
  /// Crea el servicio a partir de las instancias de Auth y Firestore.
  FirebaseAuthService(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('usuarios').doc(uid);

  /// Combina el estado de la sesión con el documento del usuario: cada vez
  /// que cambia la sesión se deja de escuchar el perfil anterior y se escucha
  /// el nuevo. Si el documento aún no existe (por ejemplo, justo al
  /// registrarse) se emite `null` y la app sigue en la pantalla de acceso.
  @override
  Stream<AppUser?> get userChanges {
    late final StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? profileSub;

    controller = StreamController<AppUser?>(
      onListen: () {
        authSub = _auth.authStateChanges().listen((user) {
          profileSub?.cancel();
          profileSub = null;
          if (user == null) {
            controller.add(null);
            return;
          }
          profileSub = _userDoc(user.uid).snapshots().listen(
                (doc) => controller.add(
                    doc.exists ? AppUser.fromMap(doc.id, _dataOf(doc)) : null),
                onError: controller.addError,
              );
        }, onError: controller.addError);
      },
      onCancel: () async {
        await profileSub?.cancel();
        await authSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Cuentas creadas desde la consola de Firebase no tienen perfil:
      // se les crea uno como cliente para que puedan entrar.
      final user = cred.user!;
      final doc = await _userDoc(user.uid).get();
      if (!doc.exists) {
        await _userDoc(user.uid).set({
          ...AppUser(
            uid: user.uid,
            name: user.displayName ?? user.email?.split('@').first ?? '',
            email: user.email ?? email.trim(),
          ).toMap(),
          'creado': FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  @override
  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      // El registro siempre crea clientes; el rol admin se asigna a mano
      // desde la consola de Firebase (las reglas impiden auto-asignarlo).
      await _userDoc(user.uid).set({
        ...AppUser(
          uid: user.uid,
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
        ).toMap(),
        'creado': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  /// Traduce los códigos de error de Firebase a mensajes para el usuario.
  static String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'network-request-failed':
        return 'Sin conexión. Revisa tu internet e inténtalo de nuevo.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e inténtalo de nuevo.';
      case 'operation-not-allowed':
        return 'El inicio de sesión con correo no está activado en Firebase.';
      default:
        return 'No se pudo completar la operación ($code).';
    }
  }
}

/// Catálogo guardado en la colección `productos`.
class FirestoreProductRepository implements ProductRepository {
  /// Crea el repositorio sobre la base de datos [_db].
  FirestoreProductRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('productos');

  /// Escucha la colección y ordena por el campo `orden` en el dispositivo,
  /// así la consulta no necesita índices compuestos.
  @override
  Stream<List<Product>> watchProducts({bool onlyActive = true}) {
    final Query<Map<String, dynamic>> query =
        onlyActive ? _col.where('activo', isEqualTo: true) : _col;
    return query.snapshots().map((snap) {
      final docs = snap.docs.toList()
        ..sort((a, b) => ((a.data()['orden'] as num?) ?? 0)
            .compareTo((b.data()['orden'] as num?) ?? 0));
      return [for (final d in docs) Product.fromMap(d.id, _dataOf(d))];
    });
  }

  /// Escribe todos los productos en un solo lote, usando su id como clave.
  @override
  Future<void> seed(List<Product> products) async {
    final batch = _db.batch();
    for (var i = 0; i < products.length; i++) {
      batch.set(_col.doc(products[i].id), products[i].toMap(order: i));
    }
    await batch.commit();
  }
}

/// Pedidos guardados en la colección `pedidos`.
class FirestoreOrderRepository implements OrderRepository {
  /// Crea el repositorio sobre la base de datos [_db].
  FirestoreOrderRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('pedidos');

  Order _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Order.fromMap(doc.id, _dataOf(doc));

  /// Agrega la fecha del servidor como creación y primer paso del historial.
  @override
  Future<String> create(Order order) async {
    final ref = _col.doc();
    await ref.set({
      ...order.toMap(),
      'estado': OrderStatus.pendiente.key,
      'creado': FieldValue.serverTimestamp(),
      'actualizado': FieldValue.serverTimestamp(),
      'historial': {OrderStatus.pendiente.key: FieldValue.serverTimestamp()},
    });
    return ref.id;
  }

  @override
  Stream<List<Order>> watchAll() => _col
      .orderBy('creado', descending: true)
      .limit(200)
      .snapshots()
      .map((snap) => [for (final d in snap.docs) _fromDoc(d)]);

  /// Filtra solo por `clienteId` (lo exigen las reglas de seguridad) y ordena
  /// en el dispositivo para no requerir un índice compuesto.
  @override
  Stream<List<Order>> watchForClient(String clientId) => _col
      .where('clienteId', isEqualTo: clientId)
      .snapshots()
      .map((snap) => sortNewestFirst(snap.docs.map(_fromDoc)));

  @override
  Stream<Order?> watchOrder(String id) =>
      _col.doc(id).snapshots().map((doc) => doc.exists ? _fromDoc(doc) : null);

  /// Actualiza solo los campos que las reglas permiten modificar.
  @override
  Future<void> updateStatus(String id, OrderStatus status) {
    return _col.doc(id).update({
      'estado': status.key,
      'actualizado': FieldValue.serverTimestamp(),
      'historial.${status.key}': FieldValue.serverTimestamp(),
    });
  }
}
