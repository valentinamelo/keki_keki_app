// Componentes visuales reutilizables: calificación, favorito y botón principal.

import 'package:flutter/material.dart';

import '../core/theme.dart';

class RatingBadge extends StatelessWidget {
  /// Crea el indicador de calificación o la etiqueta «Nuevo».
  const RatingBadge({
    super.key,
    required this.rating,
    this.reviewCount,
    this.fontSize = 12,
  });

  final double? rating;
  final int? reviewCount;
  final double fontSize;

  /// Dibuja una estrella y el valor, o «Nuevo» si no hay calificación.
  @override
  Widget build(BuildContext context) {
    final r = rating;
    if (r == null) {
      return Text(
        'Nuevo',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: KekiColors.pinkDeep,
        ),
      );
    }
    final label = reviewCount == null
        ? r.toStringAsFixed(1)
        : '${r.toStringAsFixed(1)} ($reviewCount)';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: fontSize + 3, color: KekiColors.star),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: KekiColors.text,
          ),
        ),
      ],
    );
  }
}

class FavButton extends StatelessWidget {
  /// Crea un botón de favorito usando [active] para definir su apariencia.
  const FavButton({
    super.key,
    required this.active,
    required this.onTap,
    this.size = 28,
  });

  final bool active;
  final VoidCallback onTap;
  final double size;

  /// Dibuja el corazón y llama a [onTap] al presionarlo.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xE6FFFFFF),
      borderRadius: BorderRadius.circular(size * 0.35),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            active ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: size * 0.55,
            color: KekiColors.pinkDeep,
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  /// Crea un botón de acción con degradado, etiqueta y callback.
  const GradientButton(
      {super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  /// Presenta la etiqueta y ejecuta la acción al tocar el botón.
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [KekiColors.blue, KekiColors.blueDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        boxShadow: const [
          BoxShadow(
            color: Color(0xA66FAFCE),
            blurRadius: 24,
            spreadRadius: -12,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
