// Pantalla de Inicio del cliente (mockup 01 — Inicio).

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/snack.dart';
import '../core/theme.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../widgets/keki_nav.dart';
import '../widgets/order_widgets.dart';
import '../widgets/product_card.dart';
import 'assistant_screen.dart';
import 'product_detail_screen.dart';

/// Inicio: saludo, buscador, categorías, destacados, favoritos y la tarjeta
/// del asistente. Todo se calcula con el catálogo que llega de Firestore.
class HomeScreen extends StatelessWidget {
  /// Crea el Inicio. [onOpenExplore] cambia a la pestaña Explorar y
  /// [onOpenProfile] a la pestaña Perfil.
  const HomeScreen({
    super.key,
    required this.onOpenExplore,
    required this.onOpenProfile,
  });

  final VoidCallback onOpenExplore;
  final VoidCallback onOpenProfile;

  /// Abre el detalle del [product].
  void _openDetail(BuildContext context, Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  /// Construye las secciones y escucha el catálogo.
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final catalog = scope.catalog;
    final user = scope.user;

    return SafeArea(
      bottom: false,
      child: ListenableBuilder(
        listenable: catalog,
        builder: (context, _) {
          final featured = catalog.featured;
          final favorites = catalog.favoriteProducts;

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${greeting()} 👋',
                            style: const TextStyle(
                                fontSize: 12.5, color: KekiColors.text2),
                          ),
                          Text(
                            'Hola, ${user.firstName}',
                            style: const TextStyle(
                                fontSize: 19, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: 'Perfil',
                      child: GestureDetector(
                        onTap: onOpenProfile,
                        child: InitialAvatar(initial: user.initial, size: 42),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Material(
                  color: KekiColors.bg,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      catalog.setCategory(null);
                      onOpenExplore();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KekiColors.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search_rounded,
                              size: 20, color: KekiColors.text2),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Busca tu torta favorita…',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13.5, color: KekiColors.text2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 62,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 8),
                  itemCount: ProductCategory.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 9),
                  itemBuilder: (context, i) {
                    final c = ProductCategory.values[i];
                    return _CategoryPill(
                      label: c.label,
                      onTap: () {
                        catalog.setCategory(c);
                        onOpenExplore();
                      },
                    );
                  },
                ),
              ),
              if (catalog.loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: KekiColors.blueDeep),
                  ),
                )
              else if (catalog.totalCount == 0)
                const InfoPlaceholder(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aún no hay productos',
                  message: 'La pastelería está preparando su catálogo.',
                )
              else ...[
                _SectionHeader(
                  title: 'Destacados de la semana',
                  onSeeAll: () {
                    catalog.setCategory(null);
                    onOpenExplore();
                  },
                ),
                _ProductRow(
                  products: featured,
                  onOpen: (p) => _openDetail(context, p),
                ),
                if (favorites.isNotEmpty) ...[
                  const _SectionHeader(title: 'Tus favoritos'),
                  _ProductRow(
                    products: favorites,
                    onOpen: (p) => _openDetail(context, p),
                  ),
                ],
              ],
              const _AiCard(),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  /// Crea el acceso directo a una categoría.
  const _CategoryPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  /// Dibuja la píldora con el estilo de los chips de Explorar.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: KekiColors.bg,
      shape: const StadiumBorder(side: BorderSide(color: Color(0xFFEEF1F4))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: KekiColors.text2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  /// Crea el título de una sección con un enlace opcional «Ver todo».
  const _SectionHeader({required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  /// Dibuja el título a la izquierda y el enlace a la derecha.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style:
                  const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
            ),
          ),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('Ver todo')),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  /// Crea una fila horizontal de tarjetas de producto.
  const _ProductRow({required this.products, required this.onOpen});

  final List<Product> products;
  final ValueChanged<Product> onOpen;

  /// Dibuja las tarjetas con la misma tarjeta de Explorar.
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final catalog = scope.catalog;
    // Sin animación Hero: el mismo producto puede estar en Explorar y en
    // varias filas del Inicio, y Flutter no admite etiquetas Hero repetidas.
    return HeroMode(
      enabled: false,
      child: SizedBox(
        height: 262,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 6),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(width: 14),
          itemBuilder: (context, i) {
            final p = products[i];
            return SizedBox(
              width: 162,
              child: ProductCard(
                product: p,
                isFavorite: catalog.isFavorite(p.id),
                onTap: () => onOpen(p),
                onFavorite: () => catalog.toggleFavorite(p.id),
                onAdd: () {
                  scope.cart.add(p, p.defaultSelection);
                  showKekiSnack(context, '${p.name} agregado al carrito');
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AiCard extends StatelessWidget {
  /// Crea la tarjeta «¿No sabes qué elegir?» del asistente.
  const _AiCard();

  /// Dibuja la tarjeta con degradado que abre el asistente.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 18, 22, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [KekiColors.blue, KekiColors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 12, color: Color(0xFF3E3E3E)),
                SizedBox(width: 6),
                Text(
                  'Asistente Keki',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3E3E3E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '¿No sabes qué elegir?',
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Deja que nuestra IA encuentre la torta perfecta para ti.',
            style:
                TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF3E3E3E)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => openAssistant(context),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: KekiColors.text,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13)),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.auto_awesome, size: 15),
            label: const Text('Recomiéndame una torta'),
          ),
        ],
      ),
    );
  }
}
