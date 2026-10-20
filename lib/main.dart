// Punto de entrada y composición raíz de la aplicación Keki Keki.

import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/products_data.dart';
import 'screens/home_shell.dart';
import 'state/app_scope.dart';
import 'state/cart_controller.dart';
import 'state/catalog_controller.dart';

/// Arranca Flutter y monta el widget principal de la aplicación.
void main() => runApp(const KekiApp());

/// Inicializa el estado compartido y configura la aplicación Material.
class KekiApp extends StatefulWidget {
  /// Crea la raíz con estado que conserva los controladores.
  const KekiApp({super.key});

  /// Crea el estado que mantiene vivos el catálogo y el carrito.
  @override
  State<KekiApp> createState() => _KekiAppState();
}

class _KekiAppState extends State<KekiApp> {
  final CatalogController _catalog = CatalogController(kProducts);
  final CartController _cart = CartController();

  /// Libera los controladores cuando se desmonta la aplicación.
  @override
  void dispose() {
    _catalog.dispose();
    _cart.dispose();
    super.dispose();
  }

  /// Proporciona el estado global y construye el tema y la pantalla inicial.
  @override
  Widget build(BuildContext context) {
    return AppScope(
      catalog: _catalog,
      cart: _cart,
      child: MaterialApp(
        title: 'Keki Keki',
        debugShowCheckedModeBanner: false,
        theme: buildKekiTheme(),
        home: const HomeShell(),
      ),
    );
  }
}
