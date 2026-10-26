// Carrito y confirmación del pedido (mockup 05 — Carrito / Pedido).

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/snack.dart';
import '../core/theme.dart';
import '../models/order.dart';
import '../state/app_scope.dart';
import '../state/cart_controller.dart';
import '../widgets/keki_nav.dart';
import '../widgets/order_widgets.dart';
import '../widgets/product_art.dart';
import '../widgets/product_widgets.dart';

/// Pestaña Carrito: cantidades, datos de entrega, resumen y confirmación.
/// Al confirmar se crea un documento en la colección `pedidos`.
class CartScreen extends StatelessWidget {
  /// Crea el carrito. [onExplore] vuelve al catálogo y [onOrderPlaced] se
  /// llama cuando el cliente quiere ver el pedido que acaba de hacer.
  const CartScreen({
    super.key,
    required this.onExplore,
    required this.onOrderPlaced,
  });

  final VoidCallback onExplore;
  final VoidCallback onOrderPlaced;

  /// Abre la hoja para elegir forma, fecha y hora de entrega. [hint]
  /// explica qué dato falta cuando se intentó confirmar sin completarlos.
  static Future<void> _editDelivery(
    BuildContext context,
    CartController cart, {
    String? hint,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _DeliverySheet(cart: cart, hint: hint),
    );
  }

  /// Valida los datos, guarda el pedido y muestra la confirmación.
  Future<void> _confirm(BuildContext context) async {
    final scope = AppScope.of(context);
    final cart = scope.cart;
    if (cart.submitting) return;
    final missing = cart.missingInfo;
    if (missing != null) {
      await _editDelivery(context, cart, hint: missing);
      return;
    }
    try {
      final id = await cart.placeOrder(scope.services.orders, scope.user);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded,
              size: 44, color: KekiColors.green),
          title: const Text('¡Pedido enviado!'),
          content: Text(
            'Tu pedido #${shortOrderId(id)} quedó pendiente de confirmación. '
            'Puedes seguir su estado en Perfil › Mis pedidos.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Ver mis pedidos'),
            ),
          ],
        ),
      );
      onOrderPlaced();
    } catch (e) {
      if (context.mounted) {
        showKekiSnack(context, 'No se pudo enviar el pedido: $e');
      }
    }
  }

  /// Muestra el carrito vacío o las líneas, la entrega y el resumen.
  @override
  Widget build(BuildContext context) {
    final cart = AppScope.of(context).cart;

    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        if (cart.lines.isEmpty) {
          return InfoPlaceholder(
            icon: Icons.shopping_cart_outlined,
            title: 'Tu carrito está vacío',
            message: 'Agrega productos desde Explorar.',
            action: TextButton(
              onPressed: onExplore,
              child: const Text('Ir a Explorar'),
            ),
          );
        }
        return SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tu carrito',
                            style: TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${cart.count} ${cart.count == 1 ? 'producto seleccionado' : 'productos seleccionados'}',
                            style: const TextStyle(
                                fontSize: 12, color: KekiColors.text2),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                        onPressed: cart.clear, child: const Text('Vaciar')),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                  children: [
                    for (final line in cart.lines) ...[
                      _CartItem(line: line, cart: cart),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 2),
                    _DeliveryCard(
                      cart: cart,
                      onTap: () => _editDelivery(context, cart),
                    ),
                  ],
                ),
              ),
              _Summary(cart: cart, onConfirm: () => _confirm(context)),
            ],
          ),
        );
      },
    );
  }
}

class _CartItem extends StatelessWidget {
  /// Crea la fila de [line] con su selector de cantidad.
  const _CartItem({required this.line, required this.cart});

  final CartLine line;
  final CartController cart;

  /// Dibuja ilustración, nombre, opciones, precio y cantidad.
  @override
  Widget build(BuildContext context) {
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
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  line.summary,
                  style:
                      const TextStyle(fontSize: 10.5, color: KekiColors.text2),
                ),
                const SizedBox(height: 6),
                Text(
                  cop(line.subtotal),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: KekiColors.blueDeep,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: KekiColors.bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QtyButton(
                  icon: line.quantity == 1
                      ? Icons.delete_outline_rounded
                      : Icons.remove_rounded,
                  tooltip: line.quantity == 1 ? 'Quitar' : 'Menos',
                  onTap: () => cart.setQuantity(line, line.quantity - 1),
                ),
                SizedBox(
                  width: 20,
                  child: Text(
                    '${line.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                _QtyButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Más',
                  onTap: line.quantity < CartController.maxQuantity
                      ? () => cart.setQuantity(line, line.quantity + 1)
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  /// Crea un botón pequeño para cambiar la cantidad.
  const _QtyButton({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  /// Dibuja el icono; queda gris si [onTap] es `null`.
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(
            icon,
            size: 15,
            color: onTap == null ? const Color(0xFFB9C0C6) : KekiColors.text,
          ),
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  /// Crea la tarjeta azul con la entrega elegida.
  const _DeliveryCard({required this.cart, required this.onTap});

  final CartController cart;
  final VoidCallback onTap;

  /// Muestra forma de entrega, fecha y franja, o invita a elegirlas.
  @override
  Widget build(BuildContext context) {
    final date = cart.date;
    final slot = cart.slot;
    final when = date == null || slot == null
        ? 'Toca para elegir fecha y hora'
        : '${relativeDay(date)} · ${shortDate(date)} · ${slot.label}';
    final where = cart.mode == DeliveryMode.domicilio
        ? (cart.address.isEmpty ? 'Falta la dirección' : cart.address)
        : 'Lo recoges en la pastelería';
    final incomplete = cart.missingInfo != null;

    return Material(
      color: KekiColors.blueTint,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                cart.mode == DeliveryMode.domicilio
                    ? Icons.local_shipping_outlined
                    : Icons.storefront_outlined,
                size: 20,
                color: KekiColors.blueDeep,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cart.mode.label,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      when,
                      style: TextStyle(
                        fontSize: 11,
                        color: incomplete && date == null
                            ? KekiColors.pinkDeep
                            : KekiColors.text2,
                        fontWeight: incomplete && date == null
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    Text(
                      where,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: KekiColors.text2),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: KekiColors.text2),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  /// Crea el resumen fijo con subtotal, domicilio, total y botón.
  const _Summary({required this.cart, required this.onConfirm});

  final CartController cart;
  final VoidCallback onConfirm;

  /// Construye una fila de etiqueta y valor del resumen.
  Widget _row(String label, String value, {bool total = false}) {
    final style = total
        ? const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)
        : const TextStyle(fontSize: 12, color: KekiColors.text2);
    return Padding(
      padding: EdgeInsets.only(bottom: total ? 14 : 8, top: total ? 4 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            value,
            style: total ? style.copyWith(color: KekiColors.blueDeep) : style,
          ),
        ],
      ),
    );
  }

  /// Dibuja el resumen y el botón «Confirmar pedido».
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F3F5))),
      ),
      child: Column(
        children: [
          _row('Subtotal', cop(cart.subtotal)),
          _row(
            'Domicilio',
            cart.deliveryFee == 0 ? 'Gratis' : cop(cart.deliveryFee),
          ),
          _row('Total', cop(cart.total), total: true),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: cart.submitting ? 'Enviando pedido…' : 'Confirmar pedido',
              onPressed: onConfirm,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hoja para elegir forma de entrega, día, franja, dirección e indicaciones.
class _DeliverySheet extends StatefulWidget {
  /// Crea la hoja con los valores actuales de [cart] y un aviso opcional.
  const _DeliverySheet({required this.cart, this.hint});

  final CartController cart;
  final String? hint;

  /// Crea el estado con una copia editable de los datos de entrega.
  @override
  State<_DeliverySheet> createState() => _DeliverySheetState();
}

class _DeliverySheetState extends State<_DeliverySheet> {
  /// Días que se pueden elegir, empezando mañana (las tortas se hornean
  /// el día de la entrega y necesitan un día de anticipación).
  static const int _daysAhead = 14;

  late DeliveryMode _mode = widget.cart.mode;
  late DateTime? _date = widget.cart.date;
  late DeliverySlot? _slot = widget.cart.slot;
  late final TextEditingController _address =
      TextEditingController(text: widget.cart.address);
  late final TextEditingController _notes =
      TextEditingController(text: widget.cart.notes);

  /// Libera los controladores de texto.
  @override
  void dispose() {
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  /// Guarda los datos en el carrito y cierra la hoja.
  void _save() {
    widget.cart.setDelivery(
      mode: _mode,
      date: _date,
      slot: _slot,
      address: _address.text,
      notes: _notes.text,
    );
    Navigator.of(context).pop();
  }

  /// Decoración de los campos de texto de la hoja.
  InputDecoration _decoration(String hint) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: KekiColors.text2),
      filled: true,
      fillColor: KekiColors.bg,
      isDense: true,
      contentPadding: const EdgeInsets.all(14),
      border: border(KekiColors.border),
      enabledBorder: border(KekiColors.border),
      focusedBorder: border(KekiColors.blue),
    );
  }

  /// Título de cada sección de la hoja.
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 9),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
      );

  /// Construye las secciones y el botón para guardar.
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [
      for (var i = 1; i <= _daysAhead; i++)
        DateTime(today.year, today.month, today.day + i),
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Entrega',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (widget.hint != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          widget.hint!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: KekiColors.pinkDeep,
                          ),
                        ),
                      ),
                    _label('¿Cómo lo recibes?'),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        for (final m in DeliveryMode.values)
                          _Choice(
                            label: m == DeliveryMode.domicilio
                                ? '${m.label} · ${cop(kDeliveryFee)}'
                                : '${m.label} · Gratis',
                            selected: _mode == m,
                            onTap: () => setState(() => _mode = m),
                          ),
                      ],
                    ),
                    _label('Fecha'),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: days.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 9),
                        itemBuilder: (context, i) {
                          final d = days[i];
                          return _Choice(
                            label: i == 0 ? 'Mañana · ${d.day}' : shortDate(d),
                            selected:
                                _date != null && DateUtils.isSameDay(_date, d),
                            onTap: () => setState(() => _date = d),
                          );
                        },
                      ),
                    ),
                    _label('Hora'),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        for (final s in kDeliverySlots)
                          _Choice(
                            label: s.label,
                            selected: _slot == s,
                            onTap: () => setState(() => _slot = s),
                          ),
                      ],
                    ),
                    if (_mode == DeliveryMode.domicilio) ...[
                      _label('Dirección'),
                      TextField(
                        controller: _address,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(fontSize: 13),
                        decoration:
                            _decoration('Ej. Carrera 7 # 45-10, apto 302'),
                      ),
                    ],
                    _label('Indicaciones (opcional)'),
                    TextField(
                      controller: _notes,
                      maxLines: 2,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(fontSize: 13),
                      decoration:
                          _decoration('Ej. Escribir «Feliz cumpleaños, mamá»'),
                    ),
                  ],
                ),
              ),
            ),
            // El botón queda fijo debajo de los campos desplazables.
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              child: SizedBox(
                width: double.infinity,
                child:
                    GradientButton(label: 'Guardar entrega', onPressed: _save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  /// Crea una opción seleccionable con el estilo de las opciones del detalle.
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Dibuja la etiqueta resaltada si está seleccionada.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? KekiColors.blueTint : KekiColors.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? KekiColors.blue : const Color(0xFFEEF1F4),
            width: 1.3,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? KekiColors.blueDeep : KekiColors.text,
          ),
        ),
      ),
    );
  }
}
