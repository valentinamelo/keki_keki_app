// Pruebas del formato COP y del recorrido principal de compra en la interfaz.

import 'package:flutter_test/flutter_test.dart';
import 'package:keki_keki/core/format.dart';
import 'package:keki_keki/main.dart';
import 'package:keki_keki/widgets/product_widgets.dart';

void main() {
  // Verifica que los importes se presenten con separadores colombianos.
  test('cop formatea pesos colombianos', () {
    expect(cop(65000), '\$65.000');
    expect(cop(1284000), '\$1.284.000');
    expect(cop(900), '\$900');
  });

  // Comprueba filtros, apertura del detalle y agregado de un producto.
  testWidgets(
      'Explorar filtra por categoría, abre el detalle y agrega al carrito',
      (tester) async {
    await tester.pumpWidget(const KekiApp());

    expect(find.text('Descubre nuestros productos'), findsOneWidget);
    expect(find.text('Torta fresa silvestre'), findsOneWidget);

    await tester.tap(find.text('Cupcakes'));
    await tester.pumpAndSettle();
    expect(find.text('Cupcakes duo pastel'), findsOneWidget);
    expect(find.text('Torta fresa silvestre'), findsNothing);

    await tester.tap(find.text('Cupcakes duo pastel'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Agregar al carrito'), findsOneWidget);
    expect(find.text('Presentación'), findsOneWidget);
    expect(find.text('Caja x6'), findsOneWidget);
    expect(tester.getSize(find.byType(GradientButton)).height, lessThan(100));
    expect(
        tester.getTopLeft(find.text('Cupcakes duo pastel')).dy, lessThan(280));

    await tester.tap(find.textContaining('Agregar al carrito'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('agregado al carrito'), findsOneWidget);
  });
}
