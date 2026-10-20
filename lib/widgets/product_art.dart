import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/product.dart';

String artHeroTag(String productId) => 'art-$productId';

/// Ilustración vectorial del producto, dibujada con CustomPainter a partir de
/// los SVG de los mockups (lienzo de referencia 170 x 118).
class ProductArt extends StatelessWidget {
  const ProductArt({super.key, required this.kind});

  final ArtKind kind;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ArtPainter(kind), size: Size.infinite);
  }
}

class _Palette {
  const _Palette(this.bg, this.shadow, this.stroke);
  final Color bg;
  final Color shadow;
  final Color stroke;
}

class _Dot {
  const _Dot(this.x, this.y, this.r, this.color);
  final double x;
  final double y;
  final double r;
  final Color color;
}

const _pink = _Palette(Color(0xFFFFF3F8), Color(0x40F7A9D2), Color(0xFFF3D3E6));
const _blue = _Palette(Color(0xFFEEF8FC), Color(0x4092C7E1), Color(0xFFD7EBF4));
const _brown =
    _Palette(Color(0xFFF5EDE6), Color(0x338B5E3C), Color(0xFFEADFD2));
const _cream =
    _Palette(Color(0xFFFBF6E9), Color(0x33B98A3E), Color(0xFFEADFC0));

_Palette _paletteFor(ArtKind kind) {
  switch (kind) {
    case ArtKind.roseCake:
    case ArtKind.strawberryCake:
      return _pink;
    case ArtKind.blueCake:
    case ArtKind.cupcakes:
      return _blue;
    case ArtKind.chocolateCake:
    case ArtKind.brownie:
      return _brown;
    case ArtKind.cookies:
      return _cream;
  }
}

Paint _fill(Color c) => Paint()..color = c;

Paint _line(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w;

/// Franja ondulada (glaseado) de [w] de ancho y [thick] de grosor.
Path _wave(double x, double y, double w,
    {int n = 3, double amp = 8, double thick = 5}) {
  final seg = w / n;
  final path = Path()..moveTo(x, y);
  for (var i = 0; i < n; i++) {
    final x0 = x + i * seg;
    final dir = i.isEven ? 1.0 : -1.0;
    path.quadraticBezierTo(x0 + seg / 2, y + amp * dir, x0 + seg, y);
  }
  path.lineTo(x + w, y + thick);
  for (var i = n - 1; i >= 0; i--) {
    final x0 = x + i * seg;
    final dir = i.isEven ? 1.0 : -1.0;
    path.quadraticBezierTo(x0 + seg / 2, y + thick + amp * dir, x0, y + thick);
  }
  path.close();
  return path;
}

void _drawCake(
  Canvas c, {
  required Color stroke,
  required Color frosting,
  required List<_Dot> toppings,
}) {
  final body = RRect.fromRectAndRadius(
    Rect.fromLTWH(44, 58, 82, 40),
    const Radius.circular(9),
  );
  c.drawRRect(body, _fill(Colors.white));
  c.drawRRect(body, _line(stroke, 1));
  c.drawPath(_wave(44, 62, 82), _fill(frosting));
  for (final d in toppings) {
    c.drawCircle(Offset(d.x, d.y), d.r, _fill(d.color));
  }
}

void _drawCupcake(Canvas c, double cx, Color frosting, Color cherry) {
  final liner = Path()
    ..moveTo(cx - 14, 66)
    ..lineTo(cx + 14, 66)
    ..lineTo(cx + 10, 92)
    ..lineTo(cx - 10, 92)
    ..close();
  c.drawPath(liner, _fill(Colors.white));
  c.drawPath(liner, _line(const Color(0xFFD7EBF4), 1));
  c.drawCircle(Offset(cx, 58), 14, _fill(frosting));
  c.drawCircle(Offset(cx, 45), 4, _fill(cherry));
}

void _drawBrownie(Canvas c) {
  final body = RRect.fromRectAndRadius(
    Rect.fromLTWH(46, 58, 78, 38),
    const Radius.circular(8),
  );
  c.drawRRect(body, _fill(const Color(0xFF8B5E3C)));
  c.save();
  c.clipRRect(body);
  c.drawRect(Rect.fromLTWH(46, 58, 78, 12), _fill(const Color(0xFF5C3B22)));
  c.restore();
  const nut = Color(0xFFD2A679);
  for (final p in const [Offset(62, 80), Offset(86, 84), Offset(108, 79)]) {
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: p, width: 9, height: 9),
        const Radius.circular(2.5),
      ),
      _fill(nut),
    );
  }
}

void _drawCookies(Canvas c) {
  const chip = Color(0xFFB98A3E);
  for (final cx in const [52.0, 85.0, 118.0]) {
    c.drawCircle(Offset(cx, 68), 15, _fill(const Color(0xFFF3D98B)));
    for (final d in const [
      Offset(-5, -5),
      Offset(5, -2),
      Offset(-2, 5),
      Offset(6, 6),
    ]) {
      c.drawCircle(Offset(cx + d.dx, 68 + d.dy), 2, _fill(chip));
    }
  }
}

class _ArtPainter extends CustomPainter {
  const _ArtPainter(this.kind);

  final ArtKind kind;

  static const double _w = 170;
  static const double _h = 118;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final palette = _paletteFor(kind);

    canvas.drawRect(Offset.zero & size, _fill(palette.bg));

    // Se escala de forma uniforme y se centra el lienzo de 170 x 118.
    final scale = math.min(size.width / _w, size.height / _h);
    canvas.save();
    canvas.translate(
      (size.width - _w * scale) / 2,
      (size.height - _h * scale) / 2,
    );
    canvas.scale(scale);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(85, 100), width: 100, height: 14),
      _fill(palette.shadow),
    );

    switch (kind) {
      case ArtKind.roseCake:
        _drawCake(canvas,
            stroke: palette.stroke,
            frosting: const Color(0xFFFFC8E6),
            toppings: const [
              _Dot(64, 53, 5.5, Color(0xFFF7A9D2)),
              _Dot(85, 47, 8, Color(0xFFFFDDEE)),
              _Dot(106, 53, 5.5, Color(0xFFF7A9D2)),
            ]);
        break;
      case ArtKind.strawberryCake:
        _drawCake(canvas,
            stroke: palette.stroke,
            frosting: const Color(0xFFFFC8E6),
            toppings: const [
              _Dot(66, 53, 5, Color(0xFFE8647C)),
              _Dot(85, 47, 7.5, Color(0xFFE8647C)),
              _Dot(104, 53, 5, Color(0xFFE8647C)),
            ]);
        break;
      case ArtKind.blueCake:
        _drawCake(canvas,
            stroke: palette.stroke,
            frosting: const Color(0xFF92C7E1),
            toppings: const [
              _Dot(66, 54, 4, Color(0xFFD9EEF7)),
              _Dot(85, 48, 6, Color(0xFF6FAFCE)),
              _Dot(104, 54, 4, Color(0xFFD9EEF7)),
            ]);
        break;
      case ArtKind.chocolateCake:
        _drawCake(canvas,
            stroke: palette.stroke,
            frosting: const Color(0xFF8B5E3C),
            toppings: const [
              _Dot(66, 53, 4.5, Color(0xFFF7A9D2)),
              _Dot(85, 48, 5, Color(0xFFF7A9D2)),
              _Dot(104, 53, 4.5, Color(0xFFF7A9D2)),
            ]);
        break;
      case ArtKind.brownie:
        _drawBrownie(canvas);
        break;
      case ArtKind.cupcakes:
        _drawCupcake(
            canvas, 62, const Color(0xFF92C7E1), const Color(0xFF6FAFCE));
        _drawCupcake(
            canvas, 108, const Color(0xFFFFC8E6), const Color(0xFFF7A9D2));
        break;
      case ArtKind.cookies:
        _drawCookies(canvas);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArtPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
