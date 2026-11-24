// Cifras de la pestaña IA del administrador (mockup admin 04), calculadas
// con las conversaciones guardadas en `conversaciones`.

import '../models/assistant.dart';

/// Rendimiento del asistente.
class AssistantStats {
  const AssistantStats._({
    required this.today,
    required this.total,
    required this.purchased,
    required this.averageSeconds,
    required this.topProduct,
  });

  /// Calcula las cifras con [conversations] tomando [now] como el momento
  /// actual.
  factory AssistantStats.from(List<Conversation> conversations,
      {DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    var todayCount = 0, purchased = 0, seconds = 0;
    final byProduct = <String, int>{};
    for (final c in conversations) {
      final created = c.createdAt;
      if (created != null && !created.isBefore(today)) todayCount++;
      if (c.result == ConversationResult.compro) purchased++;
      seconds += c.seconds;
      if (c.productName.isNotEmpty) {
        byProduct[c.productName] = (byProduct[c.productName] ?? 0) + 1;
      }
    }
    String? top;
    var topCount = 0;
    byProduct.forEach((name, count) {
      if (count > topCount) {
        top = name;
        topCount = count;
      }
    });
    return AssistantStats._(
      today: todayCount,
      total: conversations.length,
      purchased: purchased,
      averageSeconds:
          conversations.isEmpty ? 0 : (seconds / conversations.length).round(),
      topProduct: top,
    );
  }

  /// Conversaciones que empezaron hoy.
  final int today;

  /// Conversaciones registradas (las últimas 200).
  final int total;

  /// Conversaciones que terminaron en un pedido.
  final int purchased;

  /// Segundos promedio desde el saludo hasta la recomendación.
  final int averageSeconds;

  /// Producto que más veces recomendó el asistente.
  final String? topProduct;

  /// Porcentaje de conversaciones que terminaron en pedido.
  int get conversionRate => total == 0 ? 0 : (purchased * 100 / total).round();

  /// Tiempo promedio en texto: «48 seg» o «2 min 5 seg».
  String get averageLabel {
    if (averageSeconds < 60) return '$averageSeconds seg';
    final m = averageSeconds ~/ 60, s = averageSeconds % 60;
    return s == 0 ? '$m min' : '$m min $s seg';
  }
}
