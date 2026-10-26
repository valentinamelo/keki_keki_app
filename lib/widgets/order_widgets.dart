// Componentes visuales de pedidos: chip de estado, avatar y tarjeta de lista.

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/order.dart';

/// Colores de fondo y texto de cada estado (variables .status-chip del mockup).
(Color, Color) statusColors(OrderStatus status) {
  switch (status) {
    case OrderStatus.pendiente:
      return (const Color(0xFFFFF6E8), const Color(0xFFB8801F));
    case OrderStatus.enPreparacion:
      return (KekiColors.blueTint, KekiColors.blueDeep);
    case OrderStatus.listo:
      return (const Color(0xFFEAF7EF), const Color(0xFF3D8F63));
    case OrderStatus.entregado:
      return (const Color(0xFFF1F3F5), KekiColors.text2);
    case OrderStatus.cancelado:
      return (const Color(0xFFFBEDED), const Color(0xFFC24E4E));
  }
}

/// Texto de la entrega, por ejemplo «Hoy · 3:00–5:00 PM».
String deliveryText(Order order) =>
    '${relativeDay(order.deliveryDate)} · ${order.deliverySlot}';

/// Etiqueta redondeada con un punto y el nombre del estado.
class StatusChip extends StatelessWidget {
  /// Crea la etiqueta del [status] indicado.
  const StatusChip({super.key, required this.status});

  final OrderStatus status;

  /// Dibuja el chip con los colores del estado.
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = statusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style:
                TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Cuadro con la inicial de una persona sobre el degradado de la marca.
class InitialAvatar extends StatelessWidget {
  /// Crea el avatar con la letra [initial] y el tamaño [size].
  const InitialAvatar({super.key, required this.initial, this.size = 38});

  final String initial;
  final double size;

  /// Dibuja el cuadro redondeado con la inicial centrada.
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [KekiColors.pink, KekiColors.blue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
        ),
      ),
    );
  }
}

/// Tarjeta de un pedido en las listas. Con [showClient] muestra los datos
/// del cliente (vista del administrador); si no, el número del pedido.
class OrderCard extends StatelessWidget {
  /// Crea la tarjeta para [order] y ejecuta [onTap] al tocarla.
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.showClient = true,
  });

  final Order order;
  final VoidCallback onTap;
  final bool showClient;

  /// Dibuja cliente o número, productos, entrega, estado y total.
  @override
  Widget build(BuildContext context) {
    final created = order.createdAt;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: KekiShadows.card,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF2F4F6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (showClient) ...[
                      InitialAvatar(
                        initial: order.clientName.isEmpty
                            ? '?'
                            : order.clientName[0].toUpperCase(),
                        size: 34,
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            showClient
                                ? order.clientName
                                : 'Pedido #${shortOrderId(order.id)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            created == null
                                ? 'Enviando…'
                                : 'Creado ${relativeDay(created).toLowerCase()} · ${clock(created)}',
                            style: const TextStyle(
                                fontSize: 10.5, color: KekiColors.text2),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  order.itemsSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      order.deliveryMode == DeliveryMode.domicilio
                          ? Icons.local_shipping_outlined
                          : Icons.storefront_outlined,
                      size: 15,
                      color: KekiColors.text2,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        deliveryText(order),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11.5, color: KekiColors.text2),
                      ),
                    ),
                    Text(
                      cop(order.total),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: KekiColors.blueDeep,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Últimos seis caracteres del id, en mayúsculas, para mostrar al usuario.
String shortOrderId(String id) =>
    (id.length > 6 ? id.substring(id.length - 6) : id).toUpperCase();
