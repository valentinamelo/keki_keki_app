// Gestión de pedidos del administrador (mockup admin 02 — Gestión de pedidos).

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/order.dart';
import '../../state/admin_orders_controller.dart';
import '../../widgets/keki_nav.dart';
import '../../widgets/order_widgets.dart';
import '../order_detail_screen.dart';
import 'admin_shell.dart';

/// Lista de pedidos en tiempo real con filtros por estado. Los pedidos nuevos
/// aparecen solos, sin recargar, gracias a `snapshots()` de Firestore.
class AdminOrdersScreen extends StatelessWidget {
  /// Crea la pantalla usando el [controller] del contenedor del admin.
  const AdminOrdersScreen({super.key, required this.controller});

  final AdminOrdersController controller;

  /// Filtros que se muestran como chips, en el orden del flujo.
  static const List<OrderStatus?> _filters = [
    null,
    OrderStatus.pendiente,
    OrderStatus.enPreparacion,
    OrderStatus.listo,
    OrderStatus.entregado,
    OrderStatus.cancelado,
  ];

  /// Texto de cada chip de filtro.
  static String _filterLabel(OrderStatus? s) {
    switch (s) {
      case null:
        return 'Todos';
      case OrderStatus.pendiente:
        return 'Pendientes';
      case OrderStatus.enPreparacion:
        return 'En preparación';
      case OrderStatus.listo:
        return 'Listos';
      case OrderStatus.entregado:
        return 'Entregados';
      case OrderStatus.cancelado:
        return 'Cancelados';
    }
  }

  /// Abre el detalle donde se cambia el estado.
  void _open(BuildContext context, Order order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(orderId: order.id),
      ),
    );
  }

  /// Construye la barra superior, los filtros y la lista.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final total = controller.countOf(null);
        final pending = controller.pendingCount;
        final visible = controller.visible;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminTopBar(
              title: 'Pedidos',
              subtitle: controller.loading
                  ? 'Conectando…'
                  : '$total ${total == 1 ? 'pedido' : 'pedidos'} · '
                      '$pending ${pending == 1 ? 'requiere' : 'requieren'} atención',
              extra: controller.error == null && !controller.loading
                  ? const _LiveBadge()
                  : null,
            ),
            SizedBox(
              height: 62,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final s = _filters[i];
                  return _FilterChip(
                    label: '${_filterLabel(s)} · ${controller.countOf(s)}',
                    selected: controller.filter == s,
                    onTap: () => controller.setFilter(s),
                  );
                },
              ),
            ),
            Expanded(
              child: controller.error != null
                  ? InfoPlaceholder(
                      icon: Icons.cloud_off_rounded,
                      title: 'No pudimos cargar los pedidos',
                      message: '${controller.error}',
                    )
                  : controller.loading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: KekiColors.blueDeep),
                        )
                      : visible.isEmpty
                          ? InfoPlaceholder(
                              icon: Icons.receipt_long_outlined,
                              title: controller.filter == null
                                  ? 'Aún no hay pedidos'
                                  : 'Sin pedidos en este estado',
                              message: 'Los pedidos nuevos aparecerán aquí '
                                  'en tiempo real.',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                              itemCount: visible.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) => OrderCard(
                                key: ValueKey(visible[i].id),
                                order: visible[i],
                                onTap: () => _open(context, visible[i]),
                              ),
                            ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  /// Crea un chip de filtro con su contador.
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Dibuja el chip azul si está activo (estilo .chip del mockup).
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? KekiColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? KekiColors.blue : const Color(0xFFEEF1F4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : KekiColors.text2,
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  /// Crea el indicador de que la lista está conectada en tiempo real.
  const _LiveBadge();

  /// Dibuja un punto verde con el texto «En vivo».
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: KekiColors.green),
          SizedBox(width: 5),
          Text(
            'En vivo',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF3D8F63),
            ),
          ),
        ],
      ),
    );
  }
}
