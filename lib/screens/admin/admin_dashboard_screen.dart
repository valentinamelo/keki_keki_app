// Panel general del administrador (mockup admin 01 — Panel general).

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/admin_orders_controller.dart';
import '../../state/app_scope.dart';
import '../../state/dashboard_stats.dart';
import '../../widgets/keki_nav.dart';
import '../../widgets/product_art.dart';
import 'admin_shell.dart';

/// Cifras del negocio calculadas en vivo con los pedidos de Firestore: cada
/// pedido nuevo o cambio de estado actualiza el panel al instante.
class AdminDashboardScreen extends StatelessWidget {
  /// Crea el panel. [onOpenPending] lleva a Pedidos filtrando pendientes.
  const AdminDashboardScreen({
    super.key,
    required this.controller,
    required this.onOpenPending,
  });

  final AdminOrdersController controller;
  final VoidCallback onOpenPending;

  /// Construye la barra superior, las tarjetas y los dos paneles.
  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).user;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final stats = DashboardStats.from(controller.all);
        return Column(
          children: [
            AdminTopBar(
              title: '${greeting()}, ${user.firstName} 👋',
              subtitle: 'Esto es lo que pasa hoy en tu pastelería',
            ),
            Expanded(
              child: controller.loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: KekiColors.blueDeep),
                    )
                  : controller.error != null
                      ? InfoPlaceholder(
                          icon: Icons.cloud_off_rounded,
                          title: 'No pudimos cargar los pedidos',
                          message: '${controller.error}',
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                          children: [
                            _StatGrid(
                              stats: stats,
                              onOpenPending: onOpenPending,
                            ),
                            const SizedBox(height: 12),
                            _WeekSalesPanel(stats: stats),
                            const SizedBox(height: 12),
                            _TopProductsPanel(stats: stats),
                          ],
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _StatGrid extends StatelessWidget {
  /// Crea la cuadrícula de 2 x 2 con las cifras principales.
  const _StatGrid({required this.stats, required this.onOpenPending});

  final DashboardStats stats;
  final VoidCallback onOpenPending;

  /// Dibuja las cuatro tarjetas del mockup en dos filas.
  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(
        icon: Icons.attach_money_rounded,
        tint: KekiColors.blueTint,
        iconColor: KekiColors.blueDeep,
        value: cop(stats.salesToday),
        label: 'Ventas de hoy',
        trend: stats.salesTrend,
        trendHint: 'frente a ayer',
      ),
      StatCard(
        icon: Icons.shopping_bag_outlined,
        tint: KekiColors.pinkTint,
        iconColor: KekiColors.pinkDeep,
        value: '${stats.pending}',
        label: 'Pedidos pendientes',
        onTap: onOpenPending,
      ),
      StatCard(
        icon: Icons.check_rounded,
        tint: const Color(0xFFEAF7EF),
        iconColor: KekiColors.green,
        value: '${stats.deliveredThisWeek}',
        label: 'Entregados esta semana',
        trend: stats.deliveredTrend,
        trendHint: 'frente a la semana pasada',
      ),
      StatCard(
        icon: Icons.auto_awesome_outlined,
        tint: const Color(0xFFFFF6E8),
        iconColor: const Color(0xFFB8801F),
        value: '${stats.aiOrdersThisWeek}',
        label: 'Pedidos vía Asistente IA',
        footnote: 'Esta semana',
      ),
    ];
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[row * 2]),
                const SizedBox(width: 10),
                Expanded(child: cards[row * 2 + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Tarjeta de cifra del panel (.stat-card); también la usa la pestaña IA.
class StatCard extends StatelessWidget {
  /// Crea una tarjeta con icono, tendencia opcional, valor y etiqueta.
  const StatCard({
    super.key,
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.value,
    required this.label,
    this.trend,
    this.trendHint,
    this.footnote,
    this.onTap,
  });

  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String value;
  final String label;

  /// Variación porcentual; `null` la oculta (no hay base de comparación).
  final int? trend;
  final String? trendHint;
  final String? footnote;
  final VoidCallback? onTap;

  /// Dibuja la tarjeta blanca del mockup (.stat-card).
  @override
  Widget build(BuildContext context) {
    final t = trend;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: const Color(0xFFF2F4F6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: tint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 17, color: iconColor),
                  ),
                  const Spacer(),
                  if (t != null)
                    Tooltip(
                      message: trendHint ?? '',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // El icono acompaña al color: la tendencia no
                          // depende solo del verde o el rojo.
                          Icon(
                            t >= 0
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 12,
                            color: t >= 0
                                ? KekiColors.green
                                : const Color(0xFFC24E4E),
                          ),
                          Text(
                            '${t.abs()}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: t >= 0
                                  ? KekiColors.green
                                  : const Color(0xFFC24E4E),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 10.5, color: KekiColors.text2),
              ),
              if (footnote != null)
                Text(
                  footnote!,
                  style: const TextStyle(
                      fontSize: 9.5, color: KekiColors.pinkDeep),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel blanco con título (.panel); también lo usa la pestaña IA.
class DashboardPanel extends StatelessWidget {
  /// Crea un panel blanco con título, subtítulo y contenido.
  const DashboardPanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// Acción opcional a la derecha del título (por ejemplo «Ver todas»).
  final Widget? trailing;

  /// Dibuja el panel con el estilo .panel del mockup.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                          fontSize: 11, color: KekiColors.text2),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// Gráfico de barras de las ventas de lunes a domingo. Una sola serie en el
/// azul de la marca; el día con más ventas lleva su valor escrito y al tocar
/// cualquier barra se muestra el suyo.
class _WeekSalesPanel extends StatefulWidget {
  /// Crea el panel con las ventas de [stats].
  const _WeekSalesPanel({required this.stats});

  final DashboardStats stats;

  /// Crea el estado que recuerda la barra seleccionada.
  @override
  State<_WeekSalesPanel> createState() => _WeekSalesPanelState();
}

class _WeekSalesPanelState extends State<_WeekSalesPanel> {
  static const _days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  static const double _plotHeight = 120;

  int? _selected;

  /// Dibuja las siete barras con su día y, si aplica, su valor.
  @override
  Widget build(BuildContext context) {
    final sales = widget.stats.weekSales;
    final max = sales.fold(0, (m, v) => v > m ? v : m);
    final peak = max == 0 ? -1 : sales.indexOf(max);
    final today = DateTime.now().weekday - 1;

    return DashboardPanel(
      title: 'Ventas de la semana',
      subtitle: 'Lunes a domingo · total ${cop(widget.stats.weekTotal)}',
      child: max == 0
          ? const SizedBox(
              height: _plotHeight,
              child: Center(
                child: Text(
                  'Aún no hay ventas esta semana',
                  style: TextStyle(fontSize: 12, color: KekiColors.text2),
                ),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          setState(() => _selected = _selected == i ? null : i),
                      child: Semantics(
                        label: '${_days[i]}: ${cop(sales[i])}',
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: 16,
                              child: (i == _selected ||
                                      (i == peak && _selected == null))
                                  ? FittedBox(
                                      child: Text(
                                        cop(sales[i]),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: KekiColors.text,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 22,
                              // Altura mínima de 3 px para que un día con
                              // ventas pequeñas no desaparezca.
                              height: sales[i] == 0
                                  ? 0
                                  : (sales[i] / max * _plotHeight)
                                      .clamp(3, _plotHeight)
                                      .toDouble(),
                              decoration: BoxDecoration(
                                color: i == _selected
                                    ? KekiColors.blueDeep
                                    : KekiColors.blue,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                            Container(
                                height: 1, color: const Color(0xFFE7ECEF)),
                            const SizedBox(height: 6),
                            Text(
                              _days[i],
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: i == today
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: i == today
                                    ? KekiColors.text
                                    : KekiColors.text2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _TopProductsPanel extends StatelessWidget {
  /// Crea el panel «Más vendidos» de la semana.
  const _TopProductsPanel({required this.stats});

  final DashboardStats stats;

  /// Lista hasta cuatro productos con unidades y dinero vendido.
  @override
  Widget build(BuildContext context) {
    final top = stats.topProducts;
    return DashboardPanel(
      title: 'Más vendidos',
      subtitle: 'Esta semana · sin pedidos cancelados',
      child: top.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Cuando haya pedidos esta semana aparecerán aquí.',
                style: TextStyle(fontSize: 12, color: KekiColors.text2),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < top.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF4F6F8)),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: ProductArt(
                                kind: top[i].art, image: top[i].image),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                top[i].name,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${top[i].units} '
                                '${top[i].units == 1 ? 'unidad' : 'unidades'}',
                                style: const TextStyle(
                                    fontSize: 10.5, color: KekiColors.text2),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          cop(top[i].revenue),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: KekiColors.blueDeep,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
