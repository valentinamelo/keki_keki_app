// Cálculo de las cifras del Panel general a partir de los pedidos reales.

import '../models/order.dart';
import '../models/product.dart';

/// Producto entre los más vendidos de la semana.
class TopProduct {
  /// Crea la fila con las unidades y el dinero vendidos de un producto.
  const TopProduct({
    required this.productId,
    required this.name,
    required this.art,
    this.image,
    required this.units,
    required this.revenue,
  });

  final String productId;
  final String name;
  final ArtKind art;
  final String? image;
  final int units;
  final int revenue;
}

/// Cifras del Panel general (mockup admin 01). Las ventas cuentan todos los
/// pedidos menos los cancelados, según el día en que se hicieron.
class DashboardStats {
  const DashboardStats._({
    required this.salesToday,
    required this.salesYesterday,
    required this.pending,
    required this.deliveredThisWeek,
    required this.deliveredLastWeek,
    required this.aiOrdersThisWeek,
    required this.weekSales,
    required this.topProducts,
  });

  /// Calcula las cifras con [orders] tomando [now] como el momento actual.
  factory DashboardStats.from(List<Order> orders, {DateTime? now}) {
    final today = _day(now ?? DateTime.now());
    // Se usa el constructor de DateTime (y no Duration) para que los cambios
    // de horario de verano no corran los días.
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final weekStart =
        DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final lastWeekStart =
        DateTime(weekStart.year, weekStart.month, weekStart.day - 7);

    var salesToday = 0, salesYesterday = 0, pending = 0;
    var deliveredThisWeek = 0, deliveredLastWeek = 0, aiOrders = 0;
    final weekSales = List<int>.filled(7, 0);
    final top = <String, TopProduct>{};

    for (final order in orders) {
      if (order.status == OrderStatus.pendiente) pending++;

      final delivered = order.history[OrderStatus.entregado];
      if (order.status == OrderStatus.entregado && delivered != null) {
        final day = _day(delivered);
        if (!day.isBefore(weekStart)) {
          deliveredThisWeek++;
        } else if (!day.isBefore(lastWeekStart)) {
          deliveredLastWeek++;
        }
      }

      final created = order.createdAt;
      if (created == null || order.status == OrderStatus.cancelado) continue;
      final day = _day(created);
      if (day == today) salesToday += order.total;
      if (day == yesterday) salesYesterday += order.total;
      if (day.isBefore(weekStart)) continue;

      // Desde aquí, solo pedidos de esta semana.
      weekSales[day.weekday - 1] += order.total;
      if (order.origin == OrderOrigin.ia) aiOrders++;
      for (final item in order.items) {
        final prev = top[item.productId];
        top[item.productId] = TopProduct(
          productId: item.productId,
          name: item.name,
          art: item.art,
          image: item.image,
          units: (prev?.units ?? 0) + item.quantity,
          revenue: (prev?.revenue ?? 0) + item.subtotal,
        );
      }
    }

    final ranked = top.values.toList()
      ..sort((a, b) => b.units != a.units
          ? b.units.compareTo(a.units)
          : b.revenue.compareTo(a.revenue));

    return DashboardStats._(
      salesToday: salesToday,
      salesYesterday: salesYesterday,
      pending: pending,
      deliveredThisWeek: deliveredThisWeek,
      deliveredLastWeek: deliveredLastWeek,
      aiOrdersThisWeek: aiOrders,
      weekSales: weekSales,
      topProducts: ranked.take(4).toList(),
    );
  }

  /// Ventas (COP) de hoy y de ayer, para la tendencia.
  final int salesToday;
  final int salesYesterday;

  /// Pedidos que esperan ser aceptados.
  final int pending;

  /// Pedidos entregados desde el lunes, y los de la semana anterior.
  final int deliveredThisWeek;
  final int deliveredLastWeek;

  /// Pedidos hechos desde el asistente esta semana.
  final int aiOrdersThisWeek;

  /// Ventas (COP) de lunes a domingo de la semana actual.
  final List<int> weekSales;

  /// Hasta cuatro productos con más unidades vendidas esta semana.
  final List<TopProduct> topProducts;

  /// Variación porcentual de las ventas frente a ayer, o `null` si ayer no
  /// hubo ventas (no se puede dividir entre cero).
  int? get salesTrend => percentChange(salesToday, salesYesterday);

  /// Variación porcentual de entregas frente a la semana anterior.
  int? get deliveredTrend =>
      percentChange(deliveredThisWeek, deliveredLastWeek);

  /// Total vendido en la semana.
  int get weekTotal => weekSales.fold(0, (sum, v) => sum + v);

  /// Cambio porcentual redondeado de [previous] a [current].
  static int? percentChange(int current, int previous) =>
      previous == 0 ? null : ((current - previous) * 100 / previous).round();

  /// Fecha sin la hora, para comparar días.
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
}
