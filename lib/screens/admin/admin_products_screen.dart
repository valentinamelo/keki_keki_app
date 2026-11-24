// Catálogo de productos del administrador (mockup admin 03 — Catálogo).

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/snack.dart';
import '../../core/theme.dart';
import '../../data/products_data.dart';
import '../../models/product.dart';
import '../../state/app_scope.dart';
import '../../widgets/keki_nav.dart';
import '../../widgets/product_art.dart';
import 'admin_shell.dart';
import 'product_form_screen.dart';

/// Lista todos los productos (también los inactivos) en tiempo real. Desde
/// aquí se crean, editan, activan, desactivan y eliminan; el cliente ve cada
/// cambio en su app de inmediato porque también escucha `productos`.
class AdminProductsScreen extends StatefulWidget {
  /// Crea la pantalla de productos del administrador.
  const AdminProductsScreen({super.key});

  /// Crea el estado con la suscripción y el filtro de categoría.
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  Stream<List<Product>>? _products;
  ProductCategory? _category;
  bool _onlyLowStock = false;
  bool _seeding = false;

  /// Escucha la colección completa (activos e inactivos) una sola vez.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _products ??=
        AppScope.of(context).services.products.watchProducts(onlyActive: false);
  }

  /// Abre el formulario para crear ([product] nulo) o editar.
  void _openForm([Product? product]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductFormScreen(product: product),
      ),
    );
  }

  /// Activa o desactiva el producto; los clientes dejan de verlo al instante.
  Future<void> _toggleActive(Product product, bool active) async {
    try {
      await AppScope.of(context)
          .services
          .products
          .setActive(product.id, active);
      if (mounted) {
        showKekiSnack(
          context,
          active
              ? '${product.name} visible para los clientes'
              : '${product.name} oculto para los clientes',
        );
      }
    } catch (e) {
      if (mounted) showKekiSnack(context, 'No se pudo actualizar: $e');
    }
  }

  /// Pide confirmación y elimina el producto.
  Future<void> _delete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿Eliminar «${product.name}»?'),
        content: const Text(
          'Desaparecerá del catálogo. Los pedidos que ya lo incluyen no '
          'cambian. Si solo quieres ocultarlo, desactívalo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFFC24E4E)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await AppScope.of(context).services.products.delete(product.id);
      if (mounted) showKekiSnack(context, '${product.name} eliminado');
    } catch (e) {
      if (mounted) showKekiSnack(context, 'No se pudo eliminar: $e');
    }
  }

  /// Escribe los productos de ejemplo en la colección `productos`.
  Future<void> _seed({required bool replace}) async {
    if (replace) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Restablecer el catálogo de ejemplo?'),
          content: Text(
            'Se volverán a escribir los ${kProducts.length} productos del '
            'catálogo con sus precios, opciones y stock originales, y se '
            'borran los productos de ejemplo de entregas anteriores. Los '
            'productos que hayas creado se conservan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Volver'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Restablecer'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _seeding = true);
    try {
      // También quita los productos de ejemplo de las entregas anteriores.
      await AppScope.of(context)
          .services
          .products
          .seed(kProducts, remove: kLegacySampleIds);
      if (mounted) showKekiSnack(context, 'Catálogo de ejemplo cargado');
    } catch (e) {
      if (mounted) showKekiSnack(context, 'No se pudo cargar: $e');
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  /// Construye la barra, los filtros, el aviso de stock y la cuadrícula.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _products,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <Product>[];
        final active = all.where((p) => p.active).length;
        final low = all.where((p) => p.active && p.lowStock).toList();
        final visible = all
            .where((p) => _category == null || p.category == _category)
            .where((p) => !_onlyLowStock || (p.active && p.lowStock))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminTopBar(
              title: 'Productos',
              subtitle: !snapshot.hasData
                  ? 'Cargando…'
                  : '$active ${active == 1 ? 'activo' : 'activos'} · '
                      '${low.length} con stock bajo',
              extra: PopupMenuButton<void>(
                tooltip: 'Más opciones',
                icon: const Icon(Icons.more_vert_rounded),
                itemBuilder: (_) => [
                  PopupMenuItem<void>(
                    enabled: !_seeding,
                    onTap: () => _seed(replace: true),
                    child: const Text('Restablecer catálogo de ejemplo'),
                  ),
                ],
              ),
            ),
            if (snapshot.hasError)
              Expanded(
                child: InfoPlaceholder(
                  icon: Icons.cloud_off_rounded,
                  title: 'No pudimos cargar los productos',
                  message: '${snapshot.error}',
                ),
              )
            else if (!snapshot.hasData)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: KekiColors.blueDeep),
                ),
              )
            else if (all.isEmpty)
              Expanded(
                child: InfoPlaceholder(
                  icon: Icons.inventory_2_outlined,
                  title: 'El catálogo está vacío',
                  message: 'Crea tu primer producto o carga los de ejemplo.',
                  action: Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed:
                            _seeding ? null : () => _seed(replace: false),
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(_seeding
                            ? 'Cargando…'
                            : 'Cargar catálogo de ejemplo'),
                      ),
                      TextButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Nuevo producto'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              _Toolbar(
                category: _category,
                onCategory: (c) => setState(() => _category = c),
                onNew: () => _openForm(),
              ),
              if (low.isNotEmpty)
                _LowStockBanner(
                  products: low,
                  selected: _onlyLowStock,
                  onTap: () => setState(() => _onlyLowStock = !_onlyLowStock),
                ),
              Expanded(
                child: visible.isEmpty
                    ? const InfoPlaceholder(
                        icon: Icons.search_off_rounded,
                        title: 'Sin productos en este filtro',
                        message: 'Prueba con otra categoría.',
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 262,
                        ),
                        itemCount: visible.length,
                        itemBuilder: (context, i) {
                          final p = visible[i];
                          return _AdminProductCard(
                            key: ValueKey(p.id),
                            product: p,
                            onToggle: (v) => _toggleActive(p, v),
                            onEdit: () => _openForm(p),
                            onDelete: () => _delete(p),
                          );
                        },
                      ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Toolbar extends StatelessWidget {
  /// Crea la fila de chips de categoría y el botón «Nuevo producto».
  const _Toolbar({
    required this.category,
    required this.onCategory,
    required this.onNew,
  });

  final ProductCategory? category;
  final ValueChanged<ProductCategory?> onCategory;
  final VoidCallback onNew;

  /// Construye un chip de filtro.
  Widget _chip(String label, ProductCategory? value) {
    final selected = category == value;
    return GestureDetector(
      onTap: () => onCategory(value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected ? KekiColors.blue : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? KekiColors.blue : const Color(0xFFEEF1F4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : KekiColors.text2,
          ),
        ),
      ),
    );
  }

  /// Dibuja los chips desplazables y el botón a la derecha.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _chip('Todos', null),
                  for (final c in ProductCategory.values) ...[
                    const SizedBox(width: 8),
                    _chip(c.label, c),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: onNew,
            style: FilledButton.styleFrom(
              backgroundColor: KekiColors.blueDeep,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.add_rounded, size: 17),
            label: const Text('Nuevo'),
          ),
        ],
      ),
    );
  }
}

class _LowStockBanner extends StatelessWidget {
  /// Crea el aviso con los productos activos que tienen poco stock.
  const _LowStockBanner({
    required this.products,
    required this.selected,
    required this.onTap,
  });

  final List<Product> products;
  final bool selected;
  final VoidCallback onTap;

  /// Lista los productos y permite filtrar solo esos al tocarlo.
  @override
  Widget build(BuildContext context) {
    final names = products.map((p) => '${p.name} (${p.stock})').join(', ');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 20, color: Color(0xFFB8801F)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Stock bajo: ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                      children: [
                        TextSpan(
                          text: names,
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF8A5F14)),
                  ),
                ),
                Text(
                  selected ? 'Ver todos' : 'Filtrar',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB8801F),
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

class _AdminProductCard extends StatelessWidget {
  /// Crea la tarjeta de un producto con sus acciones (.prod-admin-card).
  const _AdminProductCard({
    super.key,
    required this.product,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Dibuja ilustración, nombre, interruptor, precio, stock y acciones.
  @override
  Widget build(BuildContext context) {
    final p = product;
    final (stockBg, stockFg, stockText) = p.stock == 0
        ? (const Color(0xFFFBEDED), const Color(0xFFC24E4E), 'Agotado')
        : p.lowStock
            ? (
                const Color(0xFFFFF6E8),
                const Color(0xFFB8801F),
                'Stock: ${p.stock}'
              )
            : (
                const Color(0xFFEAF7EF),
                const Color(0xFF3D8F63),
                'Stock: ${p.stock}'
              );

    return Opacity(
      opacity: p.active ? 1 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF2F4F6)),
          boxShadow: KekiShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 82,
              width: double.infinity,
              child: ProductArt(kind: p.art, image: p.image),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                p.active
                                    ? p.category.label
                                    : '${p.category.label} · Oculto',
                                style: const TextStyle(
                                    fontSize: 10, color: KekiColors.text2),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 24,
                          child: FittedBox(
                            child: Switch(
                              value: p.active,
                              onChanged: onToggle,
                              activeTrackColor: KekiColors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cop(p.basePrice),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: KekiColors.blueDeep,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: stockBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            stockText,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: stockFg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onEdit,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: KekiColors.text,
                              side: const BorderSide(color: Color(0xFFE7ECEF)),
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(
                                  fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: const Text('Editar'),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Material(
                          color: const Color(0xFFFBEDED),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: onDelete,
                            child: const Tooltip(
                              message: 'Eliminar',
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: Icon(Icons.delete_outline_rounded,
                                    size: 16, color: Color(0xFFC24E4E)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
