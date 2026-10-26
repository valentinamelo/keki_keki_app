// Puerta de acceso: muestra el login o la interfaz que corresponde al rol.

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/services.dart';
import '../models/app_user.dart';
import '../state/app_scope.dart';
import '../state/cart_controller.dart';
import '../state/catalog_controller.dart';
import '../widgets/keki_nav.dart';
import 'admin/admin_shell.dart';
import 'home_shell.dart';
import 'login_screen.dart';

/// Escucha la sesión y decide la pantalla: sin sesión, el login; con rol
/// `admin`, el panel de administración; con rol `cliente`, la tienda.
///
/// Cada sesión tiene su propio [MaterialApp] envuelto en [AppScope]; así las
/// pantallas que se abren con `Navigator.push` también ven el scope, y al
/// cerrar sesión se descarta todo el historial de navegación.
class AuthGate extends StatefulWidget {
  /// Crea la puerta con los [services] de la app.
  const AuthGate({super.key, required this.services, this.demo = false});

  final AppServices services;

  /// `true` cuando la app corre con servicios en memoria.
  final bool demo;

  /// Crea el estado que conserva la suscripción a la sesión.
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// Se crea una sola vez para no volver a suscribirse en cada reconstrucción.
  late final Stream<AppUser?> _users = widget.services.auth.userChanges;

  /// Crea la aplicación Material con el tema de Keki Keki.
  Widget _app(Widget home, {Key? key}) => MaterialApp(
        key: key,
        title: 'Keki Keki',
        debugShowCheckedModeBanner: false,
        theme: buildKekiTheme(),
        home: home,
      );

  /// Reconstruye la interfaz cada vez que cambia el usuario o su rol.
  @override
  Widget build(BuildContext context) {
    final services = widget.services;
    return StreamBuilder<AppUser?>(
      stream: _users,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _app(
            Scaffold(
              body: InfoPlaceholder(
                icon: Icons.cloud_off_rounded,
                title: 'No pudimos conectarnos',
                message: '${snapshot.error}',
                action: TextButton(
                  onPressed: services.auth.signOut,
                  child: const Text('Volver al inicio de sesión'),
                ),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _app(
            const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: KekiColors.blueDeep),
              ),
            ),
          );
        }
        final user = snapshot.data;
        if (user == null) {
          return _app(
            LoginScreen(auth: services.auth, showDemoAccounts: widget.demo),
            key: const ValueKey('login'),
          );
        }
        // La clave reinicia carrito, catálogo y navegación si cambia la
        // cuenta o el rol.
        final key = ValueKey('${user.uid}-${user.role.name}');
        return SessionScope(
          key: key,
          user: user,
          services: services,
          child: _app(
            user.isAdmin ? const AdminShell() : const HomeShell(),
            key: key,
          ),
        );
      },
    );
  }
}

/// Crea los controladores de una sesión y los comparte con [AppScope].
/// Se destruyen al cerrar sesión, así el carrito no pasa a otra cuenta.
class SessionScope extends StatefulWidget {
  /// Crea el alcance de la sesión de [user].
  const SessionScope({
    super.key,
    required this.user,
    required this.services,
    required this.child,
  });

  final AppUser user;
  final AppServices services;
  final Widget child;

  /// Crea el estado que conserva los controladores de la sesión.
  @override
  State<SessionScope> createState() => _SessionScopeState();
}

class _SessionScopeState extends State<SessionScope> {
  late final CatalogController _catalog =
      CatalogController(widget.services.products.watchProducts());
  final CartController _cart = CartController();

  /// Libera los controladores y sus suscripciones a la base de datos.
  @override
  void dispose() {
    _catalog.dispose();
    _cart.dispose();
    super.dispose();
  }

  /// Comparte usuario, servicios y controladores con las pantallas.
  @override
  Widget build(BuildContext context) {
    return AppScope(
      user: widget.user,
      services: widget.services,
      catalog: _catalog,
      cart: _cart,
      child: widget.child,
    );
  }
}
