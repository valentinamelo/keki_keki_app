// Pestaña IA del administrador (mockup admin 04 — Asistente IA ·
// configuración): rendimiento del asistente, conversaciones recientes y
// ajustes de su comportamiento.

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/snack.dart';
import '../../core/theme.dart';
import '../../models/assistant.dart';
import '../../state/app_scope.dart';
import '../../state/assistant_engine.dart';
import '../../state/assistant_stats.dart';
import '../../widgets/keki_nav.dart';
import '../../widgets/order_widgets.dart';
import 'admin_dashboard_screen.dart';
import 'admin_shell.dart';

/// Escucha en vivo las conversaciones y los ajustes del asistente.
class AdminAssistantScreen extends StatefulWidget {
  /// Crea la pestaña IA.
  const AdminAssistantScreen({super.key});

  /// Crea el estado que conserva las suscripciones.
  @override
  State<AdminAssistantScreen> createState() => _AdminAssistantScreenState();
}

class _AdminAssistantScreenState extends State<AdminAssistantScreen> {
  Stream<List<Conversation>>? _conversations;
  Stream<AssistantSettings>? _settings;
  bool _showAll = false;

  /// Se suscribe una sola vez a la base de datos.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final assistant = AppScope.of(context).services.assistant;
    _conversations ??= assistant.watchConversations();
    _settings ??= assistant.watchSettings();
  }

  /// Construye la barra superior, las cifras y los dos paneles.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminTopBar(
          title: 'Asistente Keki IA',
          subtitle: 'Rendimiento y configuración del asistente de pedidos',
        ),
        Expanded(
          child: StreamBuilder<List<Conversation>>(
            stream: _conversations,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return InfoPlaceholder(
                  icon: Icons.cloud_off_rounded,
                  title: 'No pudimos cargar las conversaciones',
                  message: '${snapshot.error}\n\nSi dice «permission-denied», '
                      'publica firestore.rules (entrega 4) en Firebase.',
                );
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: KekiColors.blueDeep),
                );
              }
              final conversations = snapshot.data!;
              final stats = AssistantStats.from(conversations);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  _AssistantStatGrid(stats: stats),
                  const SizedBox(height: 12),
                  _ConversationsPanel(
                    conversations: conversations,
                    showAll: _showAll,
                    onToggle: () => setState(() => _showAll = !_showAll),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<AssistantSettings>(
                    stream: _settings,
                    builder: (context, s) => s.hasError
                        ? DashboardPanel(
                            title: 'Comportamiento del asistente',
                            subtitle: 'No se pudieron cargar los ajustes',
                            child: Text(
                              '${s.error}\n¿Ya publicaste firestore.rules?',
                              style: const TextStyle(
                                  fontSize: 12, color: KekiColors.text2),
                            ),
                          )
                        : s.hasData
                            ? _SettingsPanel(settings: s.data!)
                            : const SizedBox(
                                height: 80,
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: KekiColors.blueDeep),
                                ),
                              ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AssistantStatGrid extends StatelessWidget {
  /// Crea las cuatro cifras del mockup.
  const _AssistantStatGrid({required this.stats});

  final AssistantStats stats;

  /// Dibuja la cuadrícula de 2 x 2.
  @override
  Widget build(BuildContext context) {
    final cards = [
      StatCard(
        icon: Icons.chat_bubble_outline_rounded,
        tint: KekiColors.pinkTint,
        iconColor: KekiColors.pinkDeep,
        value: '${stats.today}',
        label: 'Conversaciones hoy',
      ),
      StatCard(
        icon: Icons.shopping_bag_outlined,
        tint: const Color(0xFFEAF7EF),
        iconColor: KekiColors.green,
        value: '${stats.conversionRate}%',
        label: 'Tasa de conversión a pedido',
        footnote: '${stats.purchased} de ${stats.total} conversaciones',
      ),
      StatCard(
        icon: Icons.timer_outlined,
        tint: KekiColors.blueTint,
        iconColor: KekiColors.blueDeep,
        value: stats.averageLabel,
        label: 'Tiempo medio hasta la recomendación',
      ),
      StatCard(
        icon: Icons.cake_outlined,
        tint: const Color(0xFFFFF6E8),
        iconColor: const Color(0xFFB8801F),
        value: stats.topProduct ?? '—',
        label: 'Producto más recomendado',
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

/// Colores del chip de resultado (como los .status-chip del mockup).
(Color, Color) _resultColors(ConversationResult r) {
  switch (r) {
    case ConversationResult.compro:
      return (const Color(0xFFEAF7EF), const Color(0xFF3D8F63));
    case ConversationResult.enChat:
      return (const Color(0xFFFFF6E8), const Color(0xFFB8801F));
    case ConversationResult.sinCompra:
      return (const Color(0xFFF1F3F5), KekiColors.text2);
  }
}

class _ConversationsPanel extends StatelessWidget {
  /// Crea el panel «Conversaciones recientes».
  const _ConversationsPanel({
    required this.conversations,
    required this.showAll,
    required this.onToggle,
  });

  final List<Conversation> conversations;
  final bool showAll;
  final VoidCallback onToggle;

  /// Lista cliente, ocasión, presupuesto, recomendación y resultado.
  @override
  Widget build(BuildContext context) {
    final visible = showAll ? conversations : conversations.take(5).toList();
    return DashboardPanel(
      title: 'Conversaciones recientes',
      subtitle: 'Últimas interacciones con clientes',
      trailing: conversations.length > 5
          ? TextButton(
              onPressed: onToggle,
              child: Text(showAll ? 'Ver menos' : 'Ver todas'),
            )
          : null,
      child: conversations.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Cuando un cliente use el asistente, su conversación aparecerá '
                'aquí al instante.',
                style: TextStyle(fontSize: 12, color: KekiColors.text2),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Color(0xFFF4F6F8)),
                  _ConversationRow(conversation: visible[i]),
                ],
              ],
            ),
    );
  }
}

class _ConversationRow extends StatelessWidget {
  /// Crea la fila de una conversación.
  const _ConversationRow({required this.conversation});

  final Conversation conversation;

  /// Dibuja avatar, datos y el chip del resultado.
  @override
  Widget build(BuildContext context) {
    final c = conversation;
    final (bg, fg) = _resultColors(c.result);
    final when = c.createdAt;
    final details = [
      c.occasionLabel,
      if (c.people != null) '${c.people} pers.',
      budgetText(c.budgetMin, c.budgetMax),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialAvatar(
            initial: c.clientName.trim().isEmpty
                ? '?'
                : c.clientName.trim()[0].toUpperCase(),
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (when != null)
                      Text(
                        '${relativeDay(when)} ${clock(when)}',
                        style: const TextStyle(
                            fontSize: 10, color: KekiColors.text2),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  details,
                  style: const TextStyle(fontSize: 11, color: KekiColors.text2),
                ),
                const SizedBox(height: 2),
                Text.rich(
                  TextSpan(
                    text: 'Recomendación: ',
                    children: [
                      TextSpan(
                        text: '${c.productName} · ${cop(c.price)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: KekiColors.text),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 11, color: KekiColors.text2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                const SizedBox(width: 5),
                Text(
                  c.result.label,
                  style: TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w600, color: fg),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsPanel extends StatefulWidget {
  /// Crea el panel «Comportamiento del asistente» con los [settings]
  /// guardados.
  const _SettingsPanel({required this.settings});

  final AssistantSettings settings;

  /// Crea el estado que guarda el texto del presupuesto mínimo.
  @override
  State<_SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<_SettingsPanel> {
  late final TextEditingController _minBudget =
      TextEditingController(text: '${widget.settings.minBudget}');

  /// Si el valor cambia desde otro dispositivo, se actualiza el campo.
  @override
  void didUpdateWidget(_SettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings.minBudget != widget.settings.minBudget) {
      _minBudget.text = '${widget.settings.minBudget}';
    }
  }

  /// Libera el campo de texto.
  @override
  void dispose() {
    _minBudget.dispose();
    super.dispose();
  }

  /// Guarda [settings] y avisa si falló.
  Future<void> _save(AssistantSettings settings, {String? message}) async {
    try {
      await AppScope.of(context).services.assistant.saveSettings(settings);
      if (mounted && message != null) showKekiSnack(context, message);
    } catch (e) {
      if (mounted) showKekiSnack(context, 'No se pudo guardar: $e');
    }
  }

  /// Valida y guarda el presupuesto mínimo.
  void _saveMinBudget() {
    final value =
        int.tryParse(_minBudget.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (value == null || value < 0 || value > 1000000) {
      showKekiSnack(context, 'Escribe un monto entre \$0 y \$1.000.000');
      return;
    }
    FocusScope.of(context).unfocus();
    _save(widget.settings.copyWith(minBudget: value),
        message: 'Presupuesto mínimo: ${cop(value)}');
  }

  /// Dibuja los interruptores y el campo del mockup.
  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    return DashboardPanel(
      title: 'Comportamiento del asistente',
      subtitle: 'Ajustes generales · se aplican al instante',
      child: Column(
        children: [
          _ToggleRow(
            label: 'Asistente activo',
            sub: 'Disponible para atender clientes en la app',
            value: s.active,
            onChanged: (v) => _save(s.copyWith(active: v)),
          ),
          _ToggleRow(
            label: 'Sugerir personalización',
            sub: 'Ofrecer sabores y decoración según la ocasión',
            value: s.suggestCustomization,
            onChanged: (v) => _save(s.copyWith(suggestCustomization: v)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                const Expanded(
                  child: _SettingText(
                    label: 'Presupuesto mínimo',
                    sub: 'Monto mínimo a recomendar por pedido',
                  ),
                ),
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _minBudget,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    onSubmitted: (_) => _saveMinBudget(),
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      isDense: true,
                      filled: true,
                      fillColor: KekiColors.bg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: KekiColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: KekiColors.border),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Guardar presupuesto mínimo',
                  onPressed: _saveMinBudget,
                  icon: const Icon(Icons.check_rounded,
                      color: KekiColors.blueDeep),
                ),
              ],
            ),
          ),
          _ToggleRow(
            label: 'Notificar pedidos vía IA',
            sub: 'Avisar al equipo cuando se confirme un pedido',
            value: s.notifyOrders,
            onChanged: (v) => _save(s.copyWith(notifyOrders: v)),
          ),
        ],
      ),
    );
  }
}

class _SettingText extends StatelessWidget {
  /// Crea el título y la explicación de un ajuste.
  const _SettingText({required this.label, required this.sub});

  final String label;
  final String sub;

  /// Dibuja los dos textos (.settings-label y .settings-sub).
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
        Text(sub,
            style: const TextStyle(fontSize: 10.5, color: KekiColors.text2)),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  /// Crea un ajuste con interruptor.
  const _ToggleRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  /// Dibuja el texto y el interruptor.
  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: _SettingText(label: label, sub: sub)),
            Switch(
              value: value,
              activeTrackColor: KekiColors.blueDeep,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
