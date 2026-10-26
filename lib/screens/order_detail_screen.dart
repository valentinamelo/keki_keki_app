// Detalle de un pedido en tiempo real. El cliente lo ve en solo lectura y el
// administrador puede avanzar o cancelar su estado.

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/snack.dart';
import '../core/theme.dart';
import '../models/order.dart';
import '../state/app_scope.dart';
import '../widgets/keki_nav.dart';
import '../widgets/order_widgets.dart';
import '../widgets/product_art.dart';
import '../widgets/product_widgets.dart';

/// Detalle del pedido [orderId]. Las acciones solo aparecen para el admin.
class OrderDetailScreen extends StatefulWidget {
  /// Crea el detalle del pedido indicado.
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  /// Crea el estado que conserva la suscripción al pedido.
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Stream<Order?>? _order;
  bool _busy = false;

  /// Crea la suscripción la primera vez que la pantalla tiene acceso al scope.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _order ??= AppScope.of(context).services.orders.watchOrder(widget.orderId);
  }

  /// Guarda el nuevo [status]; la pantalla se actualiza sola con el stream.
  Future<void> _setStatus(OrderStatus status) async {
    setState(() => _busy = true);
    try {
      await AppScope.of(context)
          .services
          .orders
          .updateStatus(widget.orderId, status);
      if (mounted) {
        showKekiSnack(context, 'Pedido marcado como ${status.label}');
      }
    } catch (e) {
      if (mounted) showKekiSnack(context, 'No se pudo actualizar: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Pide confirmación antes de cancelar el pedido.
  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cancelar este pedido?'),
        content: const Text('El cliente verá el pedido como cancelado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFC24E4E)),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (ok == true) await _setStatus(OrderStatus.cancelado);
  }

  /// Construye el detalle y, para el admin, la barra de acciones.
  @override
  Widget build(BuildContext context) {
    final isAdmin = AppScope.of(context).user.isAdmin;

    return StreamBuilder<Order?>(
      stream: _order,
      builder: (context, snapshot) {
        final order = snapshot.data;
        return Scaffold(
          backgroundColor: KekiColors.bg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: Text(
              'Pedido #${shortOrderId(widget.orderId)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            actions: [
              if (order != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: StatusChip(status: order.status),
                ),
            ],
          ),
          bottomNavigationBar: isAdmin && order != null && order.status.isOpen
              ? _AdminActions(
                  status: order.status,
                  busy: _busy,
                  onAdvance: (s) => _setStatus(s),
                  onCancel: _cancel,
                )
              : null,
          body: snapshot.hasError
              ? InfoPlaceholder(
                  icon: Icons.cloud_off_rounded,
                  title: 'No pudimos cargar el pedido',
                  message: '${snapshot.error}',
                )
              : !snapshot.hasData &&
                      snapshot.connectionState == ConnectionState.waiting
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: KekiColors.blueDeep),
                    )
                  : order == null
                      ? const InfoPlaceholder(
                          icon: Icons.search_off_rounded,
                          title: 'Pedido no encontrado',
                          message: 'Es posible que haya sido eliminado.',
                        )
                      : _Body(order: order, showClient: isAdmin),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  /// Crea el contenido del pedido; [showClient] añade los datos de contacto.
  const _Body({required this.order, required this.showClient});

  final Order order;
  final bool showClient;

  /// Ordena las secciones: progreso, cliente, entrega, productos y totales.
  @override
  Widget build(BuildContext context) {
    final created = order.createdAt;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: [
        _Section(
          title: 'Estado',
          trailing: created == null
              ? null
              : 'Creado ${relativeDay(created).toLowerCase()} · ${clock(created)}',
          child: _Progress(order: order),
        ),
        if (showClient)
          _Section(
            title: 'Cliente',
            child: Row(
              children: [
                InitialAvatar(
                  initial: order.clientName.isEmpty
                      ? '?'
                      : order.clientName[0].toUpperCase(),
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.clientName,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        order.clientPhone.isEmpty
                            ? 'Sin teléfono'
                            : order.clientPhone,
                        style: const TextStyle(
                            fontSize: 12, color: KekiColors.text2),
                      ),
                    ],
                  ),
                ),
                _Tag(order.origin.label),
              ],
            ),
          ),
        _Section(
          title: 'Entrega',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoRow(
                icon: order.deliveryMode == DeliveryMode.domicilio
                    ? Icons.local_shipping_outlined
                    : Icons.storefront_outlined,
                text: order.deliveryMode.label,
              ),
              _InfoRow(
                icon: Icons.event_outlined,
                text:
                    '${relativeDay(order.deliveryDate)} · ${shortDate(order.deliveryDate)} · ${order.deliverySlot}',
              ),
              if (order.address.isNotEmpty)
                _InfoRow(icon: Icons.place_outlined, text: order.address),
              if (order.notes.isNotEmpty)
                _InfoRow(icon: Icons.sticky_note_2_outlined, text: order.notes),
            ],
          ),
        ),
        _Section(
          title: 'Productos',
          trailing: '${order.itemCount} '
              '${order.itemCount == 1 ? 'unidad' : 'unidades'}',
          child: Column(
            children: [
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 46,
                          height: 46,
                          child: ProductArt(kind: item.art),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${item.options.isEmpty ? '' : '${item.options} · '}'
                              '${item.quantity} x ${cop(item.unitPrice)}',
                              style: const TextStyle(
                                  fontSize: 10.5, color: KekiColors.text2),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        cop(item.subtotal),
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24, color: Color(0xFFF1F3F5)),
              _TotalRow('Subtotal', cop(order.subtotal)),
              _TotalRow(
                'Domicilio',
                order.deliveryFee == 0 ? 'Gratis' : cop(order.deliveryFee),
              ),
              const SizedBox(height: 4),
              _TotalRow('Total', cop(order.total), bold: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  /// Crea una tarjeta blanca con [title], texto opcional a la derecha y [child].
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final String? trailing;
  final Widget child;

  /// Dibuja la tarjeta con el estilo de los paneles del mockup.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF2F4F6)),
        boxShadow: KekiShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(fontSize: 11, color: KekiColors.text2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  /// Crea la línea de pasos pendiente → entregado del [order].
  const _Progress({required this.order});

  final Order order;

  /// Dibuja cada paso con su hora, o un aviso si el pedido se canceló.
  @override
  Widget build(BuildContext context) {
    if (order.status == OrderStatus.cancelado) {
      final at = order.history[OrderStatus.cancelado];
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBEDED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          at == null
              ? 'Este pedido fue cancelado.'
              : 'Este pedido fue cancelado ${relativeDay(at).toLowerCase()} a las ${clock(at)}.',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFFC24E4E)),
        ),
      );
    }
    final current = OrderStatus.flow.indexOf(order.status);
    return Column(
      children: [
        for (var i = 0; i < OrderStatus.flow.length; i++)
          _Step(
            status: OrderStatus.flow[i],
            done: i <= current,
            isLast: i == OrderStatus.flow.length - 1,
            at: order.history[OrderStatus.flow[i]],
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  /// Crea un paso del progreso con su estado y hora.
  const _Step({
    required this.status,
    required this.done,
    required this.isLast,
    this.at,
  });

  final OrderStatus status;
  final bool done;
  final bool isLast;
  final DateTime? at;

  /// Dibuja el círculo, la línea hacia el siguiente paso y el texto.
  @override
  Widget build(BuildContext context) {
    final color = done ? KekiColors.blueDeep : const Color(0xFFD5DBE0);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: done ? KekiColors.blueDeep : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: color,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                        color: done ? KekiColors.text : KekiColors.text2,
                      ),
                    ),
                  ),
                  if (done && at != null)
                    Text(
                      '${relativeDay(at!)} · ${clock(at!)}',
                      style: const TextStyle(
                          fontSize: 11, color: KekiColors.text2),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  /// Crea una fila de información con icono.
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  /// Dibuja el icono gris y el texto.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: KekiColors.blueDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  /// Crea una fila de totales; [bold] resalta el total final.
  const _TotalRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  /// Dibuja la etiqueta a la izquierda y el valor a la derecha.
  @override
  Widget build(BuildContext context) {
    final style = bold
        ? const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)
        : const TextStyle(fontSize: 12, color: KekiColors.text2);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            value,
            style: bold ? style.copyWith(color: KekiColors.blueDeep) : style,
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  /// Crea una etiqueta suave, por ejemplo el origen del pedido.
  const _Tag(this.label);

  final String label;

  /// Dibuja el texto sobre fondo rosado.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: KekiColors.pinkTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: KekiColors.text),
      ),
    );
  }
}

class _AdminActions extends StatelessWidget {
  /// Crea la barra con el botón para avanzar y la opción de cancelar.
  const _AdminActions({
    required this.status,
    required this.busy,
    required this.onAdvance,
    required this.onCancel,
  });

  final OrderStatus status;
  final bool busy;
  final ValueChanged<OrderStatus> onAdvance;
  final VoidCallback onCancel;

  /// Muestra «Marcar como …» con el siguiente estado del flujo.
  @override
  Widget build(BuildContext context) {
    final next = status.next;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F3F5))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
          // Altura fija: sin ella el botón ocuparía toda la pantalla.
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                if (status.canCancel) ...[
                  TextButton(
                    onPressed: busy ? null : onCancel,
                    style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFC24E4E)),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (next != null)
                  Expanded(
                    child: GradientButton(
                      label: busy ? 'Guardando…' : 'Marcar como ${next.label}',
                      onPressed: () {
                        if (!busy) onAdvance(next);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
