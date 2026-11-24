// Chat del Asistente Keki IA (mockup 04 — Asistente Keki IA).

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/snack.dart';
import '../core/theme.dart';
import '../models/assistant.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../state/assistant_controller.dart';
import '../state/assistant_engine.dart';
import '../state/cart_controller.dart';
import '../widgets/keki_nav.dart';
import '../widgets/product_art.dart';
import 'product_detail_screen.dart';

/// Abre el asistente. Con [focus] solo ayuda a personalizar ese producto.
Future<void> openAssistant(BuildContext context, {Product? focus}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AssistantScreen(focus: focus)),
  );
}

/// Conversación guiada: ocasión, personas, presupuesto y sabores; luego
/// recomienda productos reales del catálogo con su personalización.
class AssistantScreen extends StatefulWidget {
  /// Crea el chat; [focus] limita la recomendación a un producto.
  const AssistantScreen({super.key, this.focus});

  final Product? focus;

  /// Crea el estado que conserva la conversación.
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  AssistantController? _chat;
  CartController? _cart;
  Stream<AssistantSettings>? _settingsStream;
  AssistantSettings _settings = const AssistantSettings();
  int _lastCount = 0;

  /// Crea la conversación la primera vez que hay acceso al scope.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_chat != null) return;
    final scope = AppScope.of(context);
    _cart = scope.cart;
    _settingsStream = scope.services.assistant.watchSettings();
    _chat = AssistantController(
      user: scope.user,
      repository: scope.services.assistant,
      catalog: () => scope.catalog.all,
      settings: () => _settings,
      focus: widget.focus,
    )..addListener(_onChat);
  }

  /// Baja al último mensaje cuando llega uno nuevo.
  void _onChat() {
    final count = _chat!.messages.length + (_chat!.typing ? 1 : 0);
    if (count == _lastCount) return;
    _lastCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  /// Envía [text] (o lo escrito en el campo).
  void _send([String? text]) {
    final value = text ?? _input.text;
    if (value.trim().isEmpty) return;
    _chat!.send(value);
    if (text == null) _input.clear();
  }

  /// Agrega la recomendación al carrito, marcada como venta del asistente.
  void _addToCart(Recommendation rec) {
    final cart = AppScope.of(context).cart;
    cart.add(
      rec.product,
      rec.selection,
      quantity: rec.quantity,
      conversationId: _chat!.conversationId,
    );
    _chat!.markAddedToCart();
    showKekiSnack(context, '${rec.product.name} agregado al carrito');
  }

  /// Abre el detalle con la personalización recomendada ya elegida.
  void _customize(Recommendation rec) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          product: rec.product,
          initialSelection: rec.selection,
          initialQuantity: rec.quantity,
          conversationId: _chat!.conversationId,
        ),
      ),
    );
  }

  /// Cierra la conversación: si la recomendación quedó en el carrito
  /// (directo o desde «Personalizar») no cuenta como «Sin compra».
  @override
  void dispose() {
    final chat = _chat!;
    final cartConversation = _cart!.assistantConversationId;
    if (cartConversation != null && cartConversation == chat.conversationId) {
      chat.markAddedToCart();
    }
    chat
      ..removeListener(_onChat)
      ..dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Construye el encabezado, el chat, las respuestas rápidas y la entrada.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AssistantSettings>(
      stream: _settingsStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) _settings = snapshot.data!;
        final available = _settings.active;
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              _Header(onBack: () => Navigator.of(context).pop()),
              Expanded(
                child: !available
                    ? const InfoPlaceholder(
                        icon: Icons.nights_stay_outlined,
                        title: 'El asistente está descansando',
                        message: 'Por ahora no está disponible. Mientras '
                            'tanto, puedes ver todo el catálogo en Explorar.',
                      )
                    : ListenableBuilder(
                        listenable: _chat!,
                        builder: (context, _) => _ChatList(
                          chat: _chat!,
                          controller: _scroll,
                          onAdd: _addToCart,
                          onCustomize: _customize,
                        ),
                      ),
              ),
              if (available)
                ListenableBuilder(
                  listenable: _chat!,
                  builder: (context, _) => _QuickReplies(
                    replies: _chat!.quickReplies,
                    onTap: _send,
                  ),
                ),
              if (available) _InputRow(controller: _input, onSend: _send),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  /// Crea el encabezado del mockup (.ai-screen-header).
  const _Header({required this.onBack});

  final VoidCallback onBack;

  /// Dibuja volver, el avatar con degradado, el nombre y el estado.
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [KekiColors.blueTint, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 22, 14),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Volver',
                onPressed: onBack,
                icon: const Icon(Icons.chevron_left_rounded, size: 26),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [KekiColors.blue, KekiColors.pink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.auto_awesome,
                    size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Asistente Keki',
                      style: TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: KekiColors.green,
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(width: 6, height: 6),
                        ),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Diseñando tu torta ideal',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: KekiColors.text2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatList extends StatelessWidget {
  /// Crea la lista de mensajes de [chat].
  const _ChatList({
    required this.chat,
    required this.controller,
    required this.onAdd,
    required this.onCustomize,
  });

  final AssistantController chat;
  final ScrollController controller;
  final ValueChanged<Recommendation> onAdd;
  final ValueChanged<Recommendation> onCustomize;

  /// Dibuja burbujas, tarjetas y el indicador «escribiendo».
  @override
  Widget build(BuildContext context) {
    final messages = chat.messages;
    final current = chat.current;
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      itemCount: messages.length + (chat.typing ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == messages.length) return const _TypingBubble();
        final m = messages[i];
        final rec = m.recommendation;
        if (rec != null) {
          return _ResultCard(
            rec: rec,
            highlighted: identical(rec, current),
            onAdd: () => onAdd(rec),
            onCustomize: () => onCustomize(rec),
          );
        }
        return _Bubble(text: m.text, fromUser: m.fromUser);
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  /// Crea una burbuja del cliente o del asistente.
  const _Bubble({required this.text, required this.fromUser});

  final String text;
  final bool fromUser;

  /// Dibuja la burbuja con las esquinas del mockup (.bubble).
  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(18);
    const tail = Radius.circular(6);
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: fromUser ? KekiColors.blue : KekiColors.blueTint,
            borderRadius: BorderRadius.only(
              topLeft: r,
              topRight: r,
              bottomLeft: fromUser ? r : tail,
              bottomRight: fromUser ? tail : r,
            ),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              fontWeight: fromUser ? FontWeight.w500 : FontWeight.w400,
              color: fromUser ? Colors.white : KekiColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  /// Crea la burbuja con tres puntos que indica «escribiendo…».
  const _TypingBubble();

  /// Crea el estado con la animación de los puntos.
  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  /// Detiene la animación.
  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Dibuja los tres puntos que suben y bajan en orden.
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        label: 'El asistente está escribiendo',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            color: KekiColors.blueTint,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(6),
            ),
          ),
          child: AnimatedBuilder(
            animation: _anim,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Opacity(
                      opacity: 0.35 +
                          0.65 *
                              (1 -
                                  ((_anim.value * 3 - i).abs() % 3)
                                      .clamp(0, 1)),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: KekiColors.blueDeep,
                          shape: BoxShape.circle,
                        ),
                      ),
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

class _ResultCard extends StatelessWidget {
  /// Crea la tarjeta «Encontré una opción para ti» (.ai-result-card).
  const _ResultCard({
    required this.rec,
    required this.highlighted,
    required this.onAdd,
    required this.onCustomize,
  });

  final Recommendation rec;

  /// La última recomendación lleva el borde rosado del mockup.
  final bool highlighted;
  final VoidCallback onAdd;
  final VoidCallback onCustomize;

  /// Dibuja ilustración, nombre, personalización, motivos, precio y botones.
  @override
  Widget build(BuildContext context) {
    final product = rec.product;
    final meta = [
      if (rec.summary.isNotEmpty) rec.summary,
      ...rec.reasons,
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? KekiColors.pink : KekiColors.border,
          width: 1.4,
        ),
        boxShadow: KekiShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: KekiColors.pinkTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome,
                    size: 11, color: Color(0xFFD9799F)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    rec.overBudget
                        ? 'La opción más cercana'
                        : 'Encontré una opción para ti',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD9799F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 74,
                  height: 74,
                  child: ProductArt(kind: product.art, image: product.image),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meta.join('\n'),
                      style: const TextStyle(
                          fontSize: 11, height: 1.55, color: KekiColors.text2),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rec.quantity > 1
                          ? '${cop(rec.total)} · ${rec.quantity} × ${cop(rec.unitPrice)}'
                          : cop(rec.total),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: KekiColors.blueDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCustomize,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: KekiColors.text,
                    side: const BorderSide(color: KekiColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Personalizar'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: FilledButton(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: KekiColors.blueDeep,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Agregar al carrito'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickReplies extends StatelessWidget {
  /// Crea la fila de respuestas rápidas.
  const _QuickReplies({required this.replies, required this.onTap});

  final List<String> replies;
  final ValueChanged<String> onTap;

  /// Dibuja los chips; la fila desaparece mientras el asistente escribe.
  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox(height: 4);
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 6),
        itemCount: replies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ActionChip(
          label: Text(replies[i]),
          onPressed: () => onTap(replies[i]),
          backgroundColor: KekiColors.pinkTint,
          side: const BorderSide(color: Color(0xFFFBE0EE)),
          shape: const StadiumBorder(),
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: KekiColors.text,
          ),
        ),
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  /// Crea el campo «Escribe tu mensaje…» con el botón de enviar.
  const _InputRow({required this.controller, required this.onSend});

  final TextEditingController controller;
  final void Function([String? text]) onSend;

  /// Dibuja la entrada del mockup (.chat-input-row).
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F3F5))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => onSend(),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu mensaje…',
                    hintStyle:
                        const TextStyle(fontSize: 13, color: KekiColors.text2),
                    filled: true,
                    fillColor: KekiColors.bg,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 13),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: KekiColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: KekiColors.blue),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Tooltip(
                message: 'Enviar',
                child: Material(
                  color: KekiColors.blue,
                  borderRadius: BorderRadius.circular(13),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () => onSend(),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.send_rounded,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
