// Perfil del cliente: datos de la cuenta, pedidos en tiempo real y salida.

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/order.dart';
import '../state/app_scope.dart';
import '../widgets/keki_nav.dart';
import '../widgets/order_widgets.dart';
import 'order_detail_screen.dart';

/// Pestaña Perfil: muestra la cuenta y «Mis pedidos». La lista escucha la
/// base de datos, así el cliente ve cuando el admin cambia el estado.
class ProfileScreen extends StatefulWidget {
  /// Crea la pantalla de perfil.
  const ProfileScreen({super.key});

  /// Crea el estado que conserva la suscripción a los pedidos.
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Stream<List<Order>>? _orders;

  /// Crea la suscripción la primera vez que la pantalla tiene acceso al scope.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = AppScope.of(context);
    _orders ??= scope.services.orders.watchForClient(scope.user.uid);
  }

  /// Abre el detalle del pedido en modo de solo lectura.
  void _open(Order order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(orderId: order.id),
      ),
    );
  }

  /// Construye la cabecera del usuario y la lista de pedidos.
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final user = scope.user;

    return SafeArea(
      bottom: false,
      child: StreamBuilder<List<Order>>(
        stream: _orders,
        builder: (context, snapshot) {
          final orders = snapshot.data ?? const <Order>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            children: [
              Row(
                children: [
                  InitialAvatar(initial: user.initial, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${user.firstName}',
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          [user.email, if (user.phone.isNotEmpty) user.phone]
                              .join(' · '),
                          style: const TextStyle(
                              fontSize: 12, color: KekiColors.text2),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    icon: const Icon(Icons.logout_rounded,
                        color: KekiColors.text2),
                    onPressed: scope.services.auth.signOut,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mis pedidos',
                      style: TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (orders.any((o) => o.status.isOpen))
                    Text(
                      '${orders.where((o) => o.status.isOpen).length} en curso',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: KekiColors.blueDeep,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.hasError)
                InfoPlaceholder(
                  icon: Icons.cloud_off_rounded,
                  title: 'No pudimos cargar tus pedidos',
                  message: '${snapshot.error}',
                )
              else if (!snapshot.hasData)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: KekiColors.blueDeep),
                  ),
                )
              else if (orders.isEmpty)
                const InfoPlaceholder(
                  icon: Icons.receipt_long_outlined,
                  title: 'Aún no tienes pedidos',
                  message: 'Cuando confirmes tu carrito, verás aquí su estado.',
                )
              else
                for (final order in orders) ...[
                  OrderCard(
                    order: order,
                    showClient: false,
                    onTap: () => _open(order),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          );
        },
      ),
    );
  }
}
