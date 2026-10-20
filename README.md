# Keki Keki — Módulos Explorar y Producto (Flutter)

**Integrantes:** _Brayan Fuertes_ y _Valentuna Melo_   **Repositorio:** _https://github.com/valentinamelo/keki_keki_app.git_

App Flutter sencilla basada en los mockups **02 — Catálogo** y **03 — Detalle / Personalización**.
Solo usa el SDK de Flutter (sin paquetes externos, aún no se incluyen i imágenes: las tortas se dibujan con `CustomPaint`).

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

## Estructura y explicación de los archivos

Esta sección sirve como guía para entender y sustentar el proyecto. Los archivos
Dart también incluyen comentarios junto a sus clases y métodos principales.

```
lib/
  main.dart
  core/
    format.dart
    snack.dart
    theme.dart
  models/product.dart
  data/products_data.dart
  state/
    app_scope.dart
    catalog_controller.dart
    cart_controller.dart
  widgets/
    product_art.dart
    product_card.dart
    product_widgets.dart
  screens/
    explore_screen.dart
    product_detail_screen.dart
    home_shell.dart
test/
  widget_test.dart
```

### Inicio y configuración

- **`lib/main.dart`**: punto de entrada. `main()` arranca Flutter y muestra `KekiApp`.
  `KekiApp` crea los controladores del catálogo y el carrito, los comparte con la
  aplicación y define la pantalla inicial. Al desmontarse, libera los controladores.
- **`pubspec.yaml`**: nombre, versión, requisito de Dart y dependencias del proyecto.
  La app solo depende del SDK de Flutter y de sus herramientas de prueba y análisis.
- **`pubspec.lock`**: registra las versiones resueltas de las dependencias para que
  las instalaciones del proyecto sean reproducibles.
- **`analysis_options.yaml`**: configura las reglas del analizador Dart y excluye
  carpetas generadas o específicas de las plataformas.

### Datos y modelo

- **`lib/data/products_data.dart`**: define el catálogo en memoria de siete productos.
  Los métodos auxiliares `_tamanos`, `_sabores`, `_rellenos` y `_presentacion`
  construyen los grupos de opciones reutilizados por los productos. Aquí se editan
  los datos de ejemplo y los recargos.
- **`lib/models/product.dart`**: define las categorías (`ProductCategory`), los tipos
  de ilustración (`ArtKind`), las opciones (`OptionChoice` y `OptionGroup`) y el
  producto (`Product`). `defaultSelection` obtiene las opciones iniciales,
  `priceFor` calcula el precio con recargos y `summaryFor` genera un resumen de las
  opciones escogidas. Así, las reglas de precio viven en el modelo y no en la UI.

### Estado de la aplicación

- **`lib/state/app_scope.dart`**: `AppScope` es un `InheritedWidget` que permite a
  las pantallas descendientes acceder a los controladores sin pasar los objetos
  manualmente por cada constructor. `of(context)` los obtiene del árbol y
  `updateShouldNotify` detecta si se reemplazaron.
- **`lib/state/catalog_controller.dart`**: `CatalogController` conserva el texto
  de búsqueda, la categoría, el orden y los favoritos. `results` filtra y ordena
  el catálogo; `setQuery`, `setCategory` y `setSort` actualizan esos criterios;
  `clearFilters` restablece búsqueda y categoría; `toggleFavorite` cambia un
  favorito. `_normalize` permite buscar sin distinguir mayúsculas ni tildes.
  `SortMode` enumera los criterios de ordenamiento.
- **`lib/state/cart_controller.dart`**: `CartLine` representa un producto del
  carrito con sus opciones y cantidad; sus getters calculan precio unitario,
  subtotal y resumen. `CartController` administra las líneas en memoria:
  `add` añade una línea o acumula cantidad si producto y opciones coinciden,
  mientras `clear` vacía el carrito. `count` y `total` calculan las unidades y el
  valor total. No hay persistencia: los datos se pierden al cerrar la app.

### Pantallas

- **`lib/screens/home_shell.dart`**: `HomeShell` organiza las pestañas y la barra
  inferior. `_KekiBottomNav`, `_NavItem` y `_AiFab` construyen sus controles.
  `_Placeholder` representa secciones todavía no implementadas y `_CartTab`
  presenta el carrito provisional, sus líneas y el total.
- **`lib/screens/explore_screen.dart`**: `ExploreScreen` muestra búsqueda, categorías,
  ordenamiento y cuadrícula. `_openDetail` navega al detalle, `_quickAdd` añade
  usando opciones predeterminadas, `_openSort` presenta el selector de orden y
  `_border` configura el borde del buscador. `_CategoryChip`, `_FilterButton` y
  `_EmptyState` son componentes visuales locales para filtros y estado vacío.
- **`lib/screens/product_detail_screen.dart`**: `ProductDetailScreen` muestra la
  ilustración, información y opciones del producto. `_buildSheet` construye la
  ficha desplazable, `_OptionChip` representa cada opción y `_BottomBar` mantiene
  visibles el selector de cantidad y el botón para agregar. `_addToCart` envía al
  carrito la selección y cantidad actuales.

### Componentes visuales y utilidades

- **`lib/widgets/product_art.dart`**: `ProductArt` utiliza `CustomPaint` y
  `_ArtPainter` para dibujar tortas, cupcakes, brownies y galletas sin imágenes.
  Funciones como `_drawCake`, `_drawCupcake`, `_drawBrownie` y `_drawCookies`
  dibujan cada figura; `_paletteFor` elige sus colores y `artHeroTag` comparte la
  etiqueta de transición entre tarjeta y detalle.
- **`lib/widgets/product_card.dart`**: `ProductCard` presenta la ilustración,
  nombre, calificación, precio, favorito y acceso rápido al carrito. Recibe las
  acciones como callbacks para que la pantalla que la contiene decida qué hacer.
- **`lib/widgets/product_widgets.dart`**: componentes reutilizables:
  `RatingBadge` muestra una calificación o «Nuevo», `FavButton` representa el
  estado de favorito y `GradientButton` dibuja un botón de acción con degradado.
- **`lib/core/format.dart`**: `cop` formatea números como pesos colombianos, por
  ejemplo `65000` como `$65.000`.
- **`lib/core/snack.dart`**: `showKekiSnack` reemplaza el aviso actual y muestra
  una confirmación breve en pantalla.
- **`lib/core/theme.dart`**: `KekiColors` centraliza la paleta, `KekiShadows`
  define sombras reutilizables y `buildKekiTheme` crea el tema Material 3.
- **`test/widget_test.dart`**: comprueba el formato de precios y el flujo principal:
  filtrar por categoría, abrir un producto, ver sus opciones y agregarlo al carrito.

## Flujo de la aplicación

1. `main.dart` crea los controladores y los comparte mediante `AppScope`.
2. `HomeShell` abre en Explorar y mantiene disponible la pestaña del carrito.
3. `ExploreScreen` solicita al `CatalogController` los resultados filtrados y los
   muestra con `ProductCard`.
4. Al tocar una tarjeta, se abre `ProductDetailScreen`. El modelo `Product`
   calcula el precio de la personalización elegida.
5. Al agregar, `CartController` guarda el producto, sus opciones y la cantidad.
   `HomeShell` escucha ese controlador y actualiza el contador y el resumen.

**Gestión de estado:** `ChangeNotifier` avisa cuando cambian el catálogo o el
carrito; `ListenableBuilder` reconstruye las partes de la interfaz que los escuchan.
Los controladores se comparten con `AppScope`, sin usar el paquete `provider`.

## Datos de ejemplo

- Nombres, precios base y calificaciones de los 7 productos salen de los mockups.
- Los **recargos por opción** (p. ej. tamaño 20 pers. +$15.000) y las descripciones de los
  productos que no aparecen con texto en los mockups son valores de muestra: edítalos en
  `lib/data/products_data.dart`.
- Los mockups usan la fuente Poppins; aquí se usa la fuente por defecto. Se puede añadir con `google_fonts`.
