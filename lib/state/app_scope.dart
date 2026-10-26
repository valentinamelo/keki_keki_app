// Acceso compartido a la sesión, los servicios y los controladores desde
// cualquier pantalla descendiente.

import 'package:flutter/widgets.dart';

import '../data/services.dart';
import '../models/app_user.dart';
import 'cart_controller.dart';
import 'catalog_controller.dart';

/// Expone los controladores a todo el árbol sin depender de paquetes externos.
class AppScope extends InheritedWidget {
  /// Crea el alcance de la sesión de [user] con sus servicios y controladores.
  const AppScope({
    super.key,
    required this.user,
    required this.services,
    required this.catalog,
    required this.cart,
    required super.child,
  });

  /// Usuario que inició sesión, con su rol.
  final AppUser user;
  final AppServices services;
  final CatalogController catalog;
  final CartController cart;

  /// Busca este alcance en el árbol y devuelve sus controladores.
  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No se encontró un AppScope en el árbol de widgets');
    return scope!;
  }

  /// Avisa a los descendientes si cambió el usuario o algún controlador.
  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      user != oldWidget.user ||
      services != oldWidget.services ||
      catalog != oldWidget.catalog ||
      cart != oldWidget.cart;
}
