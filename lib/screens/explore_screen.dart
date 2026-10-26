// Pantalla del catálogo con búsqueda, categorías, orden, favoritos y acceso
// rápido al carrito.

import 'package:flutter/material.dart';

import '../core/snack.dart';
import '../core/theme.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../state/catalog_controller.dart';
import '../widgets/keki_nav.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';

/// Módulo Explorar (mockup 02 — Catálogo): búsqueda, categorías, orden,
/// favoritos y acceso rápido al carrito. Los productos llegan de Firestore.
class ExploreScreen extends StatefulWidget {
  /// Crea la pantalla de catálogo.
  const ExploreScreen({super.key});

  /// Crea el estado que conserva el texto introducido en la búsqueda.
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _search = TextEditingController();

  /// Libera el controlador de búsqueda al cerrar la pantalla.
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Crea un borde redondeado para los estados normal y enfocado del buscador.
  OutlineInputBorder _border(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color),
      );

  /// Navega al detalle del producto seleccionado.
  void _openDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  /// Agrega el producto con sus opciones predeterminadas y muestra confirmación.
  void _quickAdd(Product product) {
    AppScope.of(context).cart.add(product, product.defaultSelection);
    showKekiSnack(context, '${product.name} agregado al carrito');
  }

  /// Muestra las opciones de ordenamiento y actualiza el catálogo al elegir una.
  Future<void> _openSort(CatalogController catalog) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 0, 22, 8),
              child: Text(
                'Ordenar por',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            for (final mode in SortMode.values)
              ListTile(
                title: Text(mode.label),
                trailing: catalog.sort == mode
                    ? const Icon(Icons.check_rounded,
                        color: KekiColors.blueDeep)
                    : null,
                onTap: () {
                  catalog.setSort(mode);
                  Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Construye el catálogo y escucha los cambios del controlador.
  @override
  Widget build(BuildContext context) {
    final catalog = AppScope.of(context).catalog;

    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: catalog,
        builder: (context, _) {
          final items = catalog.results;
          final count = items.length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Descubre nuestros productos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: KekiColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$count ${count == 1 ? 'creación disponible' : 'creaciones disponibles'}',
                      style: const TextStyle(
                          fontSize: 12, color: KekiColors.text2),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: catalog.setQuery,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'Buscar producto…',
                          hintStyle: const TextStyle(
                            fontSize: 13.5,
                            color: KekiColors.text2,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: KekiColors.text2,
                          ),
                          suffixIcon: catalog.query.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Limpiar búsqueda',
                                  icon:
                                      const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _search.clear();
                                    catalog.setQuery('');
                                  },
                                ),
                          filled: true,
                          fillColor: KekiColors.bg,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          border: _border(KekiColors.border),
                          enabledBorder: _border(KekiColors.border),
                          focusedBorder: _border(KekiColors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _FilterButton(
                      active: catalog.sort != SortMode.relevance,
                      onTap: () => _openSort(catalog),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    children: [
                      _CategoryChip(
                        label: 'Todo',
                        selected: catalog.category == null,
                        onTap: () => catalog.setCategory(null),
                      ),
                      for (final c in ProductCategory.values) ...[
                        const SizedBox(width: 9),
                        _CategoryChip(
                          label: c.label,
                          selected: catalog.category == c,
                          onTap: () => catalog.setCategory(c),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Expanded(
                child: catalog.loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: KekiColors.blueDeep),
                      )
                    : catalog.error != null
                        ? InfoPlaceholder(
                            icon: Icons.cloud_off_rounded,
                            title: 'No pudimos cargar el catálogo',
                            message: '${catalog.error}',
                          )
                        : catalog.totalCount == 0
                            ? const InfoPlaceholder(
                                icon: Icons.inventory_2_outlined,
                                title: 'Aún no hay productos',
                                message:
                                    'La pastelería está preparando su catálogo.',
                              )
                            : items.isEmpty
                                ? _EmptyState(
                                    onClear: () {
                                      _search.clear();
                                      catalog.clearFilters();
                                    },
                                  )
                                : GridView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        22, 2, 22, 20),
                                    gridDelegate:
                                        const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 200,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      mainAxisExtent: 252,
                                    ),
                                    itemCount: items.length,
                                    itemBuilder: (context, i) {
                                      final product = items[i];
                                      return ProductCard(
                                        product: product,
                                        isFavorite:
                                            catalog.isFavorite(product.id),
                                        onTap: () => _openDetail(product),
                                        onFavorite: () =>
                                            catalog.toggleFavorite(product.id),
                                        onAdd: () => _quickAdd(product),
                                      );
                                    },
                                  ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  /// Crea una etiqueta seleccionable para filtrar por categoría.
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Dibuja la etiqueta y cambia su apariencia según [selected].
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? KekiColors.blue : KekiColors.bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? KekiColors.blue : const Color(0xFFEEF1F4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Colors.white : KekiColors.text2,
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  /// Crea el botón que abre el menú de ordenamiento.
  const _FilterButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  /// Dibuja el icono de ajustes y señala si hay un orden no predeterminado.
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Ordenar',
      child: Material(
        color: KekiColors.blue,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.tune_rounded, size: 20, color: Colors.white),
                if (active)
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: KekiColors.pinkDeep,
                        shape: BoxShape.circle,
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

class _EmptyState extends StatelessWidget {
  /// Crea el mensaje de resultados vacíos y su acción para limpiar filtros.
  const _EmptyState({required this.onClear});

  final VoidCallback onClear;

  /// Muestra una explicación cuando ningún producto coincide con los filtros.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: KekiColors.blue),
            const SizedBox(height: 12),
            const Text(
              'No encontramos productos',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Prueba con otra búsqueda o categoría.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: KekiColors.text2),
            ),
            const SizedBox(height: 8),
            TextButton(
                onPressed: onClear, child: const Text('Limpiar filtros')),
          ],
        ),
      ),
    );
  }
}
