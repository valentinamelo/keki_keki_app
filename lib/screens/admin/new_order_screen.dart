// Pedido manual: el administrador registra un pedido que llegó por teléfono
// o en la tienda (botón central «Nuevo pedido» del mockup admin).

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/snack.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../state/app_scope.dart';
import '../../state/cart_controller.dart';
import '../../widgets/order_widgets.dart';
import '../../widgets/product_art.dart';
import '../cart_screen.dart';
import '../product_detail_screen.dart';

/// Formulario de pedido manual. Usa su propio [CartController] (no el de la
/// sesión) y reutiliza las piezas del carrito del cliente. El pedido queda
/// con origen «Pedido manual» y entra al mismo flujo de estados.
class NewOrderScreen extends StatefulWidget {
  /// Crea la pantalla de pedido manual.
  const NewOrderScreen({super.key});

  /// Crea el estado con el carrito del pedido y los datos del cliente.
  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final CartController _cart = CartController();
  final _name = TextEditingController();
  final _phone = TextEditingController();

  /// Libera el carrito y los campos.
  @override
  void dispose() {
    _cart.dispose();
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  /// Muestra los productos activos; al elegir uno se abre su detalle para
  /// personalizarlo y agregarlo a este pedido.
  Future<void> _pickProduct() async {
    final products = AppScope.of(context).catalog.results;
    final picked = await showModalBottomSheet<Product>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7),
          child: products.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No hay productos activos en el catálogo.'),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
                      child: Text(
                        'Agregar producto',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    for (final p in products)
                      ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: ProductArt(kind: p.art),
                          ),
                        ),
                        title: Text(p.name,
                            style: const TextStyle(fontSize: 13.5)),
                        subtitle: Text(
                          '${p.category.label} · stock ${p.stock}',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                        trailing: Text(
                          cop(p.defaultPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: KekiColors.blueDeep,
                          ),
                        ),
                        onTap: () => Navigator.of(sheetContext).pop(p),
                      ),
                  ],
                ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          product: picked,
          onAdd: (selection, qty) =>
              _cart.add(picked, selection, quantity: qty),
        ),
      ),
    );
  }

  /// Valida cliente, productos y entrega, y crea el pedido.
  Future<void> _create() async {
    if (_cart.submitting) return;
    final name = _name.text.trim();
    if (name.length < 3) {
      showKekiSnack(context, 'Escribe el nombre del cliente');
      return;
    }
    final missing = _cart.missingInfo;
    if (missing != null) {
      if (_cart.lines.isEmpty) {
        showKekiSnack(context, missing);
      } else {
        await showDeliverySheet(context, _cart,
            hint: missing, allowToday: true);
      }
      return;
    }
    final scope = AppScope.of(context);
    try {
      // El pedido queda a nombre del admin en `clienteId` (lo exigen las
      // reglas), pero con el nombre y teléfono del cliente real.
      final id = await _cart.placeOrder(
        scope.services.orders,
        AppUser(
          uid: scope.user.uid,
          name: name,
          email: '',
          phone: _phone.text.trim(),
        ),
        origin: OrderOrigin.manual,
      );
      if (!mounted) return;
      showKekiSnack(context, 'Pedido #${shortOrderId(id)} creado para $name');
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showKekiSnack(context, 'No se pudo crear el pedido: $e');
    }
  }

  /// Decoración de los campos del cliente.
  InputDecoration _decoration(String label, IconData icon) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      labelText: label,
      isDense: true,
      filled: true,
      fillColor: KekiColors.bg,
      prefixIcon: Icon(icon, size: 19, color: KekiColors.text2),
      labelStyle: const TextStyle(fontSize: 13, color: KekiColors.text2),
      border: border(KekiColors.border),
      enabledBorder: border(KekiColors.border),
      focusedBorder: border(KekiColors.blue),
    );
  }

  /// Construye cliente, productos, entrega y el resumen fijo.
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _cart,
      builder: (context, _) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text(
            'Nuevo pedido',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
                children: [
                  const Text(
                    'Cliente',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration(
                        'Nombre del cliente', Icons.person_outline_rounded),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration:
                        _decoration('Celular (opcional)', Icons.phone_outlined),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Productos',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _pickProduct,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Agregar producto'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_cart.lines.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Aún no hay productos en este pedido.',
                        style:
                            TextStyle(fontSize: 12.5, color: KekiColors.text2),
                      ),
                    ),
                  for (final line in _cart.lines) ...[
                    CartItemTile(line: line, cart: _cart),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 8),
                  DeliveryCard(
                    cart: _cart,
                    onTap: () =>
                        showDeliverySheet(context, _cart, allowToday: true),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: CartSummary(
                cart: _cart,
                onConfirm: _create,
                label: 'Crear pedido',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
