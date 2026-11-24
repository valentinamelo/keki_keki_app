// Contenedor de la app del administrador y su barra superior.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/snack.dart';
import '../../core/theme.dart';
import '../../models/assistant.dart';
import '../../models/order.dart';
import '../../state/admin_orders_controller.dart';
import '../../state/app_scope.dart';
import '../../widgets/keki_nav.dart';
import '../../widgets/order_widgets.dart';
import 'admin_assistant_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';
import 'new_order_screen.dart';

/// Panel del administrador (mockups de administración): Panel general,
/// Pedidos, Productos, Asistente IA y el botón central «Nuevo pedido».
class AdminShell extends StatefulWidget {
  /// Crea el contenedor del administrador.
  const AdminShell({super.key});

  /// Crea el estado que conserva la pestaña y el controlador de pedidos.
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const int _dashboardTab = 0;
  static const int _ordersTab = 1;

  int _tab = _dashboardTab;
  AdminOrdersController? _orders;
  StreamSubscription<AssistantSettings>? _settingsSub;
  bool _notifyAiOrders = true;

  /// Empieza a escuchar los pedidos la primera vez que hay acceso al scope.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_orders != null) return;
    final services = AppScope.of(context).services;
    // El ajuste «Notificar pedidos vía IA» de la pestaña IA decide si los
    // pedidos del asistente muestran aviso.
    _settingsSub = services.assistant.watchSettings().listen(
          (s) => _notifyAiOrders = s.notifyOrders,
          onError: (Object _) {},
        );
    _orders = AdminOrdersController(
      services.orders.watchAll(),
      onNewOrder: (order) {
        // Los pedidos manuales los crea el propio admin: no hace falta avisar.
        if (!mounted || order.origin == OrderOrigin.manual) return;
        final ai = order.origin == OrderOrigin.ia;
        if (ai && !_notifyAiOrders) return;
        showKekiSnack(
          context,
          '${ai ? '✨ Nuevo pedido vía Asistente IA' : 'Nuevo pedido'} de '
          '${order.clientName} · ${cop(order.total)}',
        );
      },
    );
  }

  /// Deja de escuchar los pedidos al cerrar sesión.
  @override
  void dispose() {
    _settingsSub?.cancel();
    _orders?.dispose();
    super.dispose();
  }

  /// Construye las pestañas y actualiza el contador de pendientes.
  @override
  Widget build(BuildContext context) {
    final orders = _orders!;
    return ListenableBuilder(
      listenable: orders,
      builder: (context, _) => Scaffold(
        backgroundColor: KekiColors.bg,
        body: IndexedStack(
          index: _tab,
          children: [
            AdminDashboardScreen(
              controller: orders,
              onOpenPending: () {
                orders.setFilter(OrderStatus.pendiente);
                setState(() => _tab = _ordersTab);
              },
            ),
            AdminOrdersScreen(controller: orders),
            const AdminProductsScreen(),
            const AdminAssistantScreen(),
          ],
        ),
        bottomNavigationBar: KekiBottomNav(
          current: _tab,
          items: [
            const NavEntry(Icons.home_outlined, 'Inicio'),
            NavEntry(Icons.receipt_long_outlined, 'Pedidos',
                badge: orders.pendingCount),
            const NavEntry(Icons.inventory_2_outlined, 'Productos'),
            const NavEntry(Icons.auto_awesome_outlined, 'IA'),
          ],
          onSelect: (i) => setState(() => _tab = i),
          fabIcon: Icons.add_rounded,
          fabTooltip: 'Nuevo pedido',
          onFab: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const NewOrderScreen()),
          ),
        ),
      ),
    );
  }
}

/// Barra superior del admin: título, subtítulo y menú de la cuenta.
class AdminTopBar extends StatelessWidget {
  /// Crea la barra con [title], [subtitle] y un elemento opcional [extra].
  const AdminTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.extra,
  });

  final String title;
  final String subtitle;

  /// Widget opcional antes del avatar (por ejemplo, el indicador «En vivo»).
  final Widget? extra;

  /// Dibuja la barra blanca con el avatar que abre «Cerrar sesión».
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF0F2F5))),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: KekiColors.text2),
                    ),
                  ],
                ),
              ),
              if (extra != null) ...[extra!, const SizedBox(width: 10)],
              PopupMenuButton<void>(
                tooltip: 'Cuenta',
                position: PopupMenuPosition.under,
                itemBuilder: (_) => [
                  PopupMenuItem<void>(
                    enabled: false,
                    child: Text(
                      '${scope.user.name}\n${scope.user.email}',
                      style: const TextStyle(
                          fontSize: 12, color: KekiColors.text2),
                    ),
                  ),
                  PopupMenuItem<void>(
                    onTap: scope.services.auth.signOut,
                    child: const Text('Cerrar sesión'),
                  ),
                ],
                child: InitialAvatar(initial: scope.user.initial, size: 36),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
