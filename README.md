# Keki Keki — Módulos Explorar y Producto (Flutter)

App Flutter sencilla basada en los mockups **02 — Catálogo** y **03 — Detalle / Personalización**.
Solo usa el SDK de Flutter (sin paquetes externos ni imágenes: las tortas se dibujan con `CustomPaint`).

## Cómo ejecutarla

1. Abre una terminal dentro de esta carpeta (`keki_keki/`).
2. Genera las carpetas de plataforma (android, ios, web…), que no vienen en el zip:
   `flutter create .`
   (no sobrescribe `lib/`, `pubspec.yaml` ni `test/`).
3. Descarga dependencias: `flutter pub get`
4. Ejecuta en tu emulador, dispositivo o navegador: `flutter run`
5. (Opcional) Pruebas: `flutter test`

Requiere Flutter 3.10 o superior (Dart >= 3.0).

## Qué incluye

**Módulo Explorar** — `lib/screens/explore_screen.dart`
1. Título con contador según el filtro actual.
2. Búsqueda en vivo (ignora tildes y mayúsculas) con botón para limpiar.
3. Chips de categoría: Todo, Tortas, Cupcakes, Galletas, Brownies.
4. Botón de filtro (icono de ajustes) para ordenar: relevancia, precio, mejor calificados.
5. Grilla adaptable, favoritos (corazón) y botón "+" para agregar rápido con las opciones por defecto.
6. Estado vacío con "Limpiar filtros".

**Módulo Producto** — `lib/screens/product_detail_screen.dart`
1. Ilustración con transición (Hero) desde la tarjeta, precio, calificación y descripción.
2. Opciones por producto (tamaño, sabor, relleno o presentación); el **precio se recalcula** al elegir.
3. Selector de cantidad y botón "Agregar al carrito" con el total.
4. Favoritos sincronizados con Explorar.

**Barra inferior y carrito provisional** — `lib/screens/home_shell.dart`
- Solo Explorar está activo al abrir. Inicio, Perfil y el botón de IA son marcadores de posición.
- La pestaña Carrito es una vista de solo lectura (con contador en la barra) para comprobar que "Agregar" funciona.

## Estructura y arquitectura (para sustentación)

```
lib/
  main.dart                       punto de entrada, crea los controladores
  core/                           tema (paleta de los mockups), formato COP, snackbar
  models/product.dart             Product, OptionGroup, OptionChoice, cálculo de precio
  data/products_data.dart         catálogo en memoria (7 productos)
  state/
    app_scope.dart                InheritedWidget que expone los controladores
    catalog_controller.dart       búsqueda, categoría, orden, favoritos (ChangeNotifier)
    cart_controller.dart          carrito mínimo (ChangeNotifier)
  widgets/                        ilustraciones CustomPaint, tarjeta, botones
  screens/                        explore, detalle, shell con barra inferior
test/widget_test.dart             formato COP + flujo explorar → detalle → agregar
```

- **Estado**: `ChangeNotifier` + `ListenableBuilder`; los controladores viven en `AppScope`
  (sin `provider`), por lo que la UI solo se reconstruye donde cambia el dato.
- **Separación**: el modelo calcula precios (`Product.priceFor`); la UI solo muestra.

## Datos de ejemplo

- Nombres, precios base y calificaciones de los 7 productos salen de los mockups.
- Los **recargos por opción** (p. ej. tamaño 20 pers. +$15.000) y las descripciones de los
  productos que no aparecen con texto en los mockups son valores de muestra: edítalos en
  `lib/data/products_data.dart`.
- Los mockups usan la fuente Poppins; aquí se usa la fuente por defecto. Se puede añadir con `google_fonts`.
