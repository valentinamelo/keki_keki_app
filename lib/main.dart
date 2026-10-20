import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'data/products_data.dart';
import 'screens/home_shell.dart';
import 'state/app_scope.dart';
import 'state/cart_controller.dart';
import 'state/catalog_controller.dart';

void main() => runApp(const KekiApp());

class KekiApp extends StatefulWidget {
  const KekiApp({super.key});

  @override
  State<KekiApp> createState() => _KekiAppState();
}

class _KekiAppState extends State<KekiApp> {
  final CatalogController _catalog = CatalogController(kProducts);
  final CartController _cart = CartController();

  @override
  void dispose() {
    _catalog.dispose();
    _cart.dispose();
    super.dispose();
  }

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
