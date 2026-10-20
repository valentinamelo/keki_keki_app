// Tarjeta reutilizable de producto usada en la cuadrícula del catálogo.

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/product.dart';
import 'product_art.dart';
import 'product_widgets.dart';

/// Tarjeta del grid de Explorar (mockup 02 — Catálogo).
class ProductCard extends StatelessWidget {
  /// Crea una tarjeta con producto, estado de favorito y acciones de usuario.
  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    required this.onAdd,
  });

  final Product product;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAdd;

  /// Presenta la ilustración y los datos principales del producto.
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2F4F6)),
        boxShadow: KekiShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 118,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: artHeroTag(product.id),
                        child: ProductArt(kind: product.art),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: FavButton(active: isFavorite, onTap: onFavorite),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                            color: KekiColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        RatingBadge(rating: product.rating),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                cop(product.defaultPrice),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: KekiColors.blueDeep,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Agregar al carrito',
                              child: Material(
                                color: KekiColors.blue,
                                borderRadius: BorderRadius.circular(10),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: onAdd,
                                  child: const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
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
        ),
      ),
    );
  }
}
