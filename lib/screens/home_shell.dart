// Contenedor principal de la app del cliente y su navegación inferior.

import 'package:flutter/material.dart';

import '../core/snack.dart';
import '../state/app_scope.dart';
import '../widgets/keki_nav.dart';
import 'cart_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Contenedor con la barra inferior del mockup: Inicio, Explorar, Carrito y
/// Perfil. El botón central del asistente llega en la entrega 4.
class HomeShell extends StatefulWidget {
  /// Crea el contenedor principal de las pestañas.
  const HomeShell({super.key});

  /// Crea el estado que conserva la pestaña seleccionada.
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const int _home = 0;
  static const int _explore = 1;
  static const int _profile = 3;

  int _tab = _home;

  /// Construye las pestañas y escucha el carrito para actualizar el contador.
  @override
  Widget build(BuildContext context) {
    final cart = AppScope.of(context).cart;

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => Scaffold(
        body: IndexedStack(
          index: _tab,
          children: [
            HomeScreen(
              onOpenExplore: () => setState(() => _tab = _explore),
              onOpenProfile: () => setState(() => _tab = _profile),
            ),
            const ExploreScreen(),
            CartScreen(
              onExplore: () => setState(() => _tab = _explore),
              onOrderPlaced: () => setState(() => _tab = _profile),
            ),
            const ProfileScreen(),
          ],
        ),
        bottomNavigationBar: KekiBottomNav(
          current: _tab,
          items: [
            const NavEntry(Icons.home_outlined, 'Inicio'),
            const NavEntry(Icons.explore_outlined, 'Explorar'),
            NavEntry(Icons.shopping_cart_outlined, 'Carrito',
                badge: cart.count),
            const NavEntry(Icons.person_outline_rounded, 'Perfil'),
          ],
          onSelect: (i) => setState(() => _tab = i),
          onFab: () =>
              showKekiSnack(context, 'Asistente Keki IA: próximamente'),
        ),
      ),
    );
  }
}
