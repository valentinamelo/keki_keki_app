import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/snack.dart';
import '../core/theme.dart';
import '../state/app_scope.dart';
import '../widgets/product_art.dart';
import 'explore_screen.dart';

/// Contenedor con la barra inferior del mockup. Solo Explorar (y su detalle)
/// están implementados; Inicio y Perfil son marcadores de posición y Carrito
/// es una vista provisional para comprobar que "Agregar" funciona.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 1; // Explorar

  @override
  Widget build(BuildContext context) {
    final cart = AppScope.of(context).cart;

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => Scaffold(
        body: IndexedStack(
          index: _tab,
          children: const [
            _Placeholder(
              icon: Icons.home_outlined,
              title: 'Inicio',
              message: 'Este módulo no está incluido en esta entrega.',
            ),
            ExploreScreen(),
            _CartTab(),
            _Placeholder(
              icon: Icons.person_outline_rounded,
              title: 'Perfil',
              message: 'Este módulo no está incluido en esta entrega.',
            ),
          ],
        ),
        bottomNavigationBar: _KekiBottomNav(
          current: _tab,
          cartCount: cart.count,
          onSelect: (i) => setState(() => _tab = i),
          onAi: () => showKekiSnack(context, 'Asistente Keki IA: próximamente'),
        ),
      ),
    );
  }
}

class _KekiBottomNav extends StatelessWidget {
  const _KekiBottomNav({
    required this.current,
    required this.cartCount,
    required this.onSelect,
    required this.onAi,
  });

  final int current;
  final int cartCount;
  final ValueChanged<int> onSelect;
  final VoidCallback onAi;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F3F5))),
      ),
      child: SafeArea(
        top: false,
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
          height: 66,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'Inicio',
                selected: current == 0,
                onTap: () => onSelect(0),
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                label: 'Explorar',
                selected: current == 1,
                onTap: () => onSelect(1),
              ),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: _AiFab(onTap: onAi),
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.shopping_cart_outlined,
                label: 'Carrito',
                selected: current == 2,
                badge: cartCount,
                onTap: () => onSelect(2),
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                label: 'Perfil',
                selected: current == 3,
                onTap: () => onSelect(3),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final color = selected ? KekiColors.blueDeep : const Color(0xFFB9C0C6);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (badge > 0)
                  Positioned(
                    right: -9,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: KekiColors.pinkDeep,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiFab extends StatelessWidget {
  const _AiFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(15);
    return Tooltip(
      message: 'Asistente Keki IA',
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [KekiColors.blue, KekiColors.pink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0xB392C7E1),
              blurRadius: 20,
              spreadRadius: -8,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: KekiColors.blue),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: KekiColors.text2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vista provisional del carrito (solo lectura) para validar "Agregar".
class _CartTab extends StatelessWidget {
  const _CartTab();

  @override
  Widget build(BuildContext context) {
    final cart = AppScope.of(context).cart;

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        if (cart.lines.isEmpty) {
          return const _Placeholder(
            icon: Icons.shopping_cart_outlined,
            title: 'Tu carrito está vacío',
            message: 'Agrega productos desde Explorar.',
          );
        }
        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tu carrito',
                            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${cart.count} ${cart.count == 1 ? 'producto' : 'productos'} · vista provisional',
                            style: const TextStyle(fontSize: 12, color: KekiColors.text2),
                          ),
                        ],
                      ),
                    ),
                    TextButton(onPressed: cart.clear, child: const Text('Vaciar')),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                  itemCount: cart.lines.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final line = cart.lines[i];
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFF2F4F6)),
                        boxShadow: KekiShadows.card,
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: SizedBox(
                              width: 58,
                              height: 58,
                              child: ProductArt(kind: line.product.art),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  line.product.name,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  line.summary,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: KekiColors.text2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cop(line.unitPrice),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: KekiColors.blueDeep,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'x${line.quantity}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      cop(cart.total),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: KekiColors.blueDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
