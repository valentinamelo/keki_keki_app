// Contenedor de la app del administrador, su barra superior y la carga del
// catálogo inicial.

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/snack.dart';
import '../../core/theme.dart';
import '../../data/products_data.dart';
import '../../state/admin_orders_controller.dart';
import '../../state/app_scope.dart';
import '../../widgets/keki_nav.dart';
import '../../widgets/order_widgets.dart';
import 'admin_orders_screen.dart';

/// Panel del administrador (mockups de administración). En esta entrega está
/// implementada la Gestión de pedidos; Inicio, Productos e IA llegan después.
class AdminShell extends StatefulWidget {
  /// Crea el contenedor del administrador.
  const AdminShell({super.key});

  /// Crea el estado que conserva la pestaña y el controlador de pedidos.
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const int _ordersTab = 1;

  int _tab = _ordersTab;
  AdminOrdersController? _orders;

  /// Empieza a escuchar los pedidos la primera vez que hay acceso al scope.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _orders ??= AdminOrdersController(
      AppScope.of(context).services.orders.watchAll(),
      onNewOrder: (order) {
        if (!mounted) return;
        showKekiSnack(
          context,
          'Nuevo pedido de ${order.clientName} · ${cop(order.total)}',
        );
      },
    );
  }

  /// Deja de escuchar los pedidos al cerrar sesión.
  @override
  void dispose() {
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
            const _Pending(
              icon: Icons.space_dashboard_outlined,
              title: 'Panel general',
              message:
                  'Ventas, gráficos y más vendidos llegan en la entrega 3.',
            ),
            AdminOrdersScreen(controller: orders),
            const _ProductsTab(),
            const _Pending(
              icon: Icons.auto_awesome_outlined,
              title: 'Asistente Keki IA',
              message: 'La configuración del asistente llega en la entrega 4.',
            ),
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
          onFab: () =>
              showKekiSnack(context, 'Asistente Keki IA: próximamente'),
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

class _Pending extends StatelessWidget {
  /// Crea una pestaña del admin que aún no está implementada.
  const _Pending({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Muestra la barra superior y el mensaje del marcador de posición.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AdminTopBar(title: title, subtitle: 'Próximamente'),
        Expanded(
          child: InfoPlaceholder(icon: icon, title: title, message: message),
        ),
      ],
    );
  }
}

/// Pestaña Productos provisional: permite subir el catálogo de ejemplo a
/// Firestore. La administración completa llega en la entrega 3.
class _ProductsTab extends StatefulWidget {
  /// Crea la pestaña de productos.
  const _ProductsTab();

  /// Crea el estado que indica si se está cargando el catálogo.
  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  bool _busy = false;

  /// Escribe los productos de ejemplo en la colección `productos`.
  Future<void> _seed() async {
    final scope = AppScope.of(context);
    if (scope.catalog.totalCount > 0) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Restablecer el catálogo?'),
          content: Text(
            'Se volverán a escribir los ${kProducts.length} productos de '
            'ejemplo con sus precios y opciones originales.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Volver'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Restablecer'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy = true);
    try {
      await scope.services.products.seed(kProducts);
      if (mounted) showKekiSnack(context, 'Catálogo cargado en Firestore');
    } catch (e) {
      if (mounted) showKekiSnack(context, 'No se pudo cargar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Muestra cuántos productos hay y el botón para cargar el catálogo.
  @override
  Widget build(BuildContext context) {
    final catalog = AppScope.of(context).catalog;
    return ListenableBuilder(
      listenable: catalog,
      builder: (context, _) {
        final count = catalog.totalCount;
        return Column(
          children: [
            AdminTopBar(
              title: 'Productos',
              subtitle: catalog.loading
                  ? 'Cargando…'
                  : '$count ${count == 1 ? 'producto activo' : 'productos activos'}',
            ),
            Expanded(
              child: InfoPlaceholder(
                icon: Icons.inventory_2_outlined,
                title: count == 0
                    ? 'El catálogo está vacío'
                    : 'Catálogo en la base de datos',
                message: count == 0
                    ? 'Carga los productos de ejemplo para que los clientes '
                        'puedan verlos en Explorar.'
                    : 'Crear, editar y desactivar productos llega en la '
                        'entrega 3.',
                action: TextButton.icon(
                  onPressed: _busy || catalog.loading ? null : _seed,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(_busy
                      ? 'Cargando…'
                      : count == 0
                          ? 'Cargar catálogo de ejemplo'
                          : 'Restablecer catálogo de ejemplo'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
