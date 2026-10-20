// Pantalla de detalle para revisar y personalizar un producto antes de
// agregarlo al carrito.

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/snack.dart';
import '../core/theme.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../widgets/product_art.dart';
import '../widgets/product_widgets.dart';

/// Módulo Producto (mockup 03 — Detalle / Personalización).
class ProductDetailScreen extends StatefulWidget {
  /// Crea el detalle para el [product] recibido desde el catálogo.
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  /// Crea el estado que guarda las opciones elegidas y la cantidad.
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

/// Mantiene la personalización y cantidad del producto durante la pantalla.
class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const int _maxQty = 20;

  late final Map<String, int> _selection =
      Map<String, int>.of(widget.product.defaultSelection);
  int _qty = 1;

  /// Agrega la configuración actual al carrito y confirma la acción.
  void _addToCart() {
    AppScope.of(context).cart.add(widget.product, _selection, quantity: _qty);
    showKekiSnack(context, '${widget.product.name} agregado al carrito');
  }

  /// Construye la ilustración, el detalle desplazable y la barra inferior fija.
  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final catalog = AppScope.of(context).catalog;
    final unitPrice = product.priceFor(_selection);

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _BottomBar(
        qty: _qty,
        onMinus: _qty > 1 ? () => setState(() => _qty--) : null,
        onPlus: _qty < _maxQty ? () => setState(() => _qty++) : null,
        label: 'Agregar al carrito · ${cop(unitPrice * _qty)}',
        onAdd: _addToCart,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final artHeight =
              (constraints.maxHeight * 0.36).clamp(200.0, 320.0).toDouble();

          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: artHeight,
                child: Hero(
                  tag: artHeroTag(product.id),
                  child: ProductArt(kind: product.art),
                ),
              ),
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: artHeight - 26),
                  child: _buildSheet(product, unitPrice),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Tooltip(
                          message: 'Volver',
                          child: Material(
                            color: const Color(0xD9FFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              child: const SizedBox(
                                width: 38,
                                height: 38,
                                child:
                                    Icon(Icons.chevron_left_rounded, size: 24),
                              ),
                            ),
                          ),
                        ),
                        ListenableBuilder(
                          listenable: catalog,
                          builder: (context, _) => FavButton(
                            size: 38,
                            active: catalog.isFavorite(product.id),
                            onTap: () => catalog.toggleFavorite(product.id),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Construye la ficha con precio, calificación, descripción y opciones.
  Widget _buildSheet(Product product, int unitPrice) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: Color(0x14252525), blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: KekiColors.text,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                cop(unitPrice),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: KekiColors.blueDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              RatingBadge(
                  rating: product.rating, reviewCount: product.reviewCount),
              if (product.noPreservatives) ...[
                const SizedBox(width: 12),
                Container(
                  width: 15,
                  height: 15,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: KekiColors.green, width: 1.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: KekiColors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Sin conservantes',
                  style: TextStyle(fontSize: 11.5, color: KekiColors.text2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              text: product.description,
              children: [
                if (product.highlight != null)
                  TextSpan(
                    text: ' ${product.highlight}',
                    style: const TextStyle(
                      color: KekiColors.blueDeep,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            style: const TextStyle(
                fontSize: 12, height: 1.6, color: KekiColors.text2),
          ),
          for (final group in product.options) ...[
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 9),
              child: Text(
                group.title,
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: [
                for (var i = 0; i < group.choices.length; i++)
                  _OptionChip(
                    label: group.choices[i].label,
                    selected: (_selection[group.id] ?? group.defaultIndex) == i,
                    onTap: () => setState(() => _selection[group.id] = i),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Material(
            color: KekiColors.pinkTint,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () =>
                  showKekiSnack(context, 'Personalizar con IA: próximamente'),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome,
                        size: 18, color: KekiColors.pinkDeep),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Personalizar con IA',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: KekiColors.text2),
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

class _OptionChip extends StatelessWidget {
  /// Crea una opción interactiva que puede estar seleccionada o no.
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Presenta la etiqueta y aplica el estilo correspondiente a su selección.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
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

class _BottomBar extends StatelessWidget {
  /// Crea la barra fija con el selector de cantidad y el botón de compra.
  const _BottomBar({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
    required this.label,
    required this.onAdd,
  });

  final int qty;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final String label;
  final VoidCallback onAdd;

  /// Dibuja controles de cantidad y botón con el precio total actualizado.
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F3F5))),
      ),
      child: SafeArea(
        top: false,
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
            child: SizedBox(
              height: 56,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: KekiColors.bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Menos',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.remove_rounded, size: 18),
                          onPressed: onMinus,
                        ),
                        SizedBox(
                          width: 22,
                          child: Text(
                            '$qty',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Más',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.add_rounded, size: 18),
                          onPressed: onPlus,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                      child: GradientButton(label: label, onPressed: onAdd)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
