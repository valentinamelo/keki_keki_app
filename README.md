# Keki Keki — Pastelería Inteligente (Flutter + Firebase)

**Integrantes:** _Brayan Fuertes_ y _Valentina Melo_   **Repositorio:** _https://github.com/valentinamelo/keki_keki_app.git_

App Flutter basada en los mockups de Keki Keki. Hay dos interfaces en la misma app:
la **tienda del cliente** y el **panel del administrador**. Al iniciar sesión, la app
lee el rol del usuario en Firestore y lo envía a la interfaz que le corresponde.

| Entrega | Contenido | Estado |
|---|---|---|
| 1 | Catálogo del cliente: Explorar y Producto (mockups 02 y 03) | ✅ |
| 2 | Firebase, registro/inicio de sesión con roles, productos en Firestore, carrito y confirmación del pedido (mockup 05), gestión de pedidos del admin en tiempo real y reglas de seguridad | ✅ |
| 3 | Administración de productos (crear, editar, activar, stock bajo), panel general con cifras reales, pedido manual del admin, inicio del cliente y favoritos guardados en la cuenta | ✅ |
| 4 | Asistente IA, pulido y sustentación | Pendiente |

## Cómo ejecutarla

### Opción A — Modo demo (sin Firebase)

Sirve para probar la app sin conexión o antes de configurar Firebase. Los datos viven
en memoria y se pierden al cerrar la app.

```bash
flutter pub get
flutter run --dart-define=KEKI_DEMO=true
```

Cuentas de prueba (contraseña `123456`): `cliente@keki.co` y `admin@keki.co`.

### Opción B — Con Firebase (la versión real)

1. **Crear el proyecto.** En <https://console.firebase.google.com> crea un proyecto
   (por ejemplo `keki-keki`).
2. **Activar Authentication.** *Authentication › Comenzar › Correo electrónico/contraseña ›
   Habilitar.*
3. **Crear Firestore.** *Firestore Database › Crear base de datos* (modo producción,
   ubicación `southamerica-east1` o la más cercana).
4. **Publicar las reglas.** En *Firestore › Reglas*, pega el contenido de
   [`firestore.rules`](firestore.rules) y pulsa *Publicar*.
5. **Conectar la app** (una sola vez por equipo):
   ```bash
   npm install -g firebase-tools          # CLI de Firebase
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<id-del-proyecto>
   ```
   El último comando reemplaza `lib/firebase_options.dart` (hoy es un archivo
   provisional) con las claves del proyecto y registra las apps Android, iOS y web.
6. **Ejecutar:** `flutter pub get` y `flutter run`.
7. **Crear el administrador.** Regístrate desde la app con la cuenta que será admin.
   Luego, en la consola, abre *Firestore › usuarios › (tu uid)* y cambia el campo
   `rol` de `"cliente"` a `"admin"`. Cierra sesión y vuelve a entrar.
   (Por seguridad, la app nunca permite que alguien se asigne el rol admin.)
8. **Cargar el catálogo.** Como admin, ve a la pestaña **Productos** y pulsa
   **Cargar catálogo de ejemplo**: se suben los 7 productos a la colección `productos`.
   Desde ese momento los clientes los ven en Explorar.

> **Al pasar a la entrega 3:** vuelve a publicar [`firestore.rules`](firestore.rules)
> (cambiaron) y, como admin, usa **Productos › ⋮ › Restablecer catálogo de ejemplo**
> para que los productos cargados antes reciban sus valores de stock.

> Si iOS se queja de la versión mínima al compilar, abre `ios/Podfile` y deja
> `platform :ios, '15.0'`.

### Pruebas

```bash
flutter test
```

Las pruebas usan los servicios en memoria, así que no necesitan Firebase.

## Demostración sugerida (tiempo real)

**Pedidos en vivo (entrega 2)**

1. Abre la app en dos dispositivos o emuladores (o uno y la web): uno con una cuenta
   de cliente y otro con la cuenta admin en la pestaña **Pedidos**.
2. El cliente agrega productos, abre **Carrito**, elige entrega y pulsa **Confirmar pedido**.
3. En el admin, el pedido aparece al instante (sin recargar), con el aviso
   «Nuevo pedido de …» y el contador de pendientes en la barra inferior.
4. El admin abre el pedido y pulsa **Marcar como En preparación**, luego **Listo** y
   **Entregado**. En el celular del cliente (**Perfil › Mis pedidos**) el estado cambia
   solo, en el mismo momento.

**Catálogo y panel (entrega 3)**

5. El admin crea un producto en **Productos › Nuevo**: aparece al instante en Explorar
   del cliente. Si lo desactiva con el interruptor, desaparece del cliente.
6. Al marcar un pedido **En preparación**, el stock de sus productos baja; si un
   producto queda en 5 unidades o menos, sale el aviso de **Stock bajo**.
7. El **Panel general** (Inicio del admin) se actualiza solo con cada pedido:
   ventas de hoy, pendientes, entregados de la semana, gráfico y más vendidos.
8. El cliente marca favoritos, cierra sesión y vuelve a entrar: siguen ahí, y
   aparecen en **Inicio › Tus favoritos**.

## Qué incluye la entrega 3

**Inicio del cliente (mockup 01)** — `home_screen.dart`
- Saludo según la hora, buscador y categorías (llevan a Explorar ya filtrado),
  «Destacados de la semana» (los mejor calificados), «Tus favoritos» y la tarjeta
  del asistente (la IA llega en la entrega 4). La app del cliente abre aquí.

**Favoritos en la cuenta** — `catalog_controller.dart`, `auth_gate.dart`
- Se guardan en `usuarios/{uid}.favoritos` con `arrayUnion` / `arrayRemove`.
  El corazón cambia al instante y, si no se puede guardar, vuelve atrás.
  Si se marcan desde otro dispositivo, se sincronizan solos.

**Catálogo de productos del admin (mockup admin 03)** — `admin_products_screen.dart`, `product_form_screen.dart`
- Cuadrícula con todos los productos (también los ocultos), filtro por categoría,
  interruptor para activar/desactivar, precio, stock (verde, ámbar si es bajo, rojo
  si está agotado), editar y eliminar con confirmación.
- Aviso de **stock bajo** (5 unidades o menos) que permite filtrar esos productos.
- Formulario para crear/editar: ilustración, nombre, categoría, descripción, frase
  destacada, precio base, stock, visibilidad, sin conservantes y **grupos de opciones**
  (por ejemplo Tamaño o Sabor) con el recargo de cada alternativa y cuál viene elegida.
- El stock se descuenta cuando un pedido pasa a **En preparación** y se devuelve si
  ese pedido se cancela. Se hace en una **transacción** de Firestore junto con el
  cambio de estado: o se guardan los dos, o ninguno.

**Panel general (mockup admin 01)** — `admin_dashboard_screen.dart`, `dashboard_stats.dart`
- Ventas de hoy (con variación frente a ayer), pedidos pendientes (al tocarla abre
  Pedidos filtrado), entregados esta semana (frente a la semana pasada) y pedidos vía
  asistente (en cero hasta la entrega 4).
- Gráfico de ventas de lunes a domingo: el día con más ventas muestra su valor y al
  tocar cualquier barra se ve el suyo. Más vendidos de la semana con unidades y dinero.
- Todo se calcula con los pedidos reales que ya escucha la gestión de pedidos, así que
  se actualiza en vivo. Los pedidos cancelados no cuentan como ventas.

**Pedido manual del admin** — `new_order_screen.dart`
- El botón central de la barra del admin abre **Nuevo pedido**: nombre y celular del
  cliente, productos (con su personalización), entrega (puede ser el mismo día) y total.
  El pedido queda con origen «Pedido manual» y sigue el mismo flujo de estados.

## Qué incluye la entrega 2

**Autenticación y roles** — `login_screen.dart`, `auth_gate.dart`
- Registro (nombre, celular, correo, contraseña) e inicio de sesión con Firebase Authentication.
- Cada usuario tiene un documento en `usuarios/{uid}` con su `rol` (`cliente` o `admin`).
- `AuthGate` escucha la sesión y el perfil: sin sesión muestra el login; con rol admin,
  el panel; con rol cliente, la tienda. Errores de Firebase traducidos al español.

**Productos desde Firestore** — `firebase_services.dart`, `catalog_controller.dart`
- Explorar y Producto ya no usan la lista en memoria: escuchan la colección `productos`
  con `snapshots()`. Si el admin cambia un producto, el cliente lo ve sin recargar.
- Estados de carga, error y catálogo vacío.

**Carrito y confirmación del pedido (mockup 05)** — `cart_screen.dart`
- Cantidades con `+` / `−` (con `−` en 1 se quita la línea) y botón «Vaciar».
- Entrega: a domicilio ($6.000) o recoger en tienda (gratis), día (desde mañana,
  14 días), franja horaria, dirección e indicaciones.
- Resumen con subtotal, domicilio y total. «Confirmar pedido» valida los datos,
  crea el documento en `pedidos` y muestra la confirmación con el número del pedido.

**Mis pedidos (cliente)** — `profile_screen.dart`
- Datos de la cuenta, cierre de sesión y lista de pedidos en tiempo real con su estado.

**Gestión de pedidos (admin, mockup admin 02)** — `admin_orders_screen.dart`, `order_detail_screen.dart`
- Lista en vivo con indicador «En vivo», chips de filtro con contador por estado
  (Todos, Pendientes, En preparación, Listos, Entregados, Cancelados).
- Aviso cuando llega un pedido nuevo y contador de pendientes en la barra inferior.
- Detalle: progreso con la hora de cada estado, cliente, entrega, productos y totales.
- Cambio de estado: pendiente → en preparación → listo → entregado, y cancelación
  (solo antes de que esté listo, con confirmación).

**Reglas de seguridad** — `firestore.rules`
- `usuarios`: cada quien lee y edita su perfil; nadie puede cambiar su propio rol.
- `productos`: lectura para usuarios con sesión; escritura solo del admin.
- `pedidos`: el cliente solo crea pedidos a su nombre, en estado `pendiente`, y solo
  lee los suyos. Solo el admin cambia el estado (y únicamente `estado`, `actualizado`
  e `historial`). Nadie borra pedidos.

## Modelo de datos en Firestore

```
usuarios/{uid}
  nombre, email, telefono, rol ("cliente" | "admin"), favoritos: [idProducto], creado

productos/{id}            (id legible en los de ejemplo, automático en los nuevos)
  nombre, nombreDetalle, categoria, descripcion, destacado, precioBase,
  calificacion, resenas, sinConservantes, ilustracion, activo, stock, orden,
  opciones: [{ id, titulo, predeterminada, opciones: [{ nombre, extra }] }]

pedidos/{id}
  clienteId, clienteNombre, clienteTelefono,
  items: [{ productoId, nombre, ilustracion, opciones, precioUnitario, cantidad }],
  subtotal, domicilio, total,
  tipoEntrega ("domicilio" | "recoger"), entrega (fecha y hora), franja,
  direccion, notas, origen ("catalogo" | "ia" | "manual"),
  estado ("pendiente" | "en_preparacion" | "listo" | "entregado" | "cancelado"),
  historial: { <estado>: fecha }, creado, actualizado
```

Decisiones:
- Cada línea del pedido **copia** nombre y precio del producto. Así, si luego cambia
  el catálogo, los pedidos antiguos conservan lo que el cliente pagó.
- `creado`, `actualizado` e `historial` usan la hora del servidor (`serverTimestamp`),
  no la del celular.
- Las consultas no combinan filtros con orden (el orden se hace en el dispositivo),
  por eso **no hace falta crear índices compuestos**.
- `origen` ya existe para que la entrega 4 marque los pedidos hechos desde el asistente.
  Los pedidos manuales tienen `clienteId` del admin (lo exigen las reglas) y el nombre
  y teléfono del cliente real en `clienteNombre` y `clienteTelefono`.

## Estructura y explicación de los archivos

```
lib/
  main.dart
  firebase_options.dart          (lo genera flutterfire configure)
  core/
    format.dart
    snack.dart
    theme.dart
  models/
    app_user.dart
    order.dart
    product.dart
  data/
    services.dart
    firebase_services.dart
    memory_services.dart
    products_data.dart
  state/
    app_scope.dart
    catalog_controller.dart
    cart_controller.dart
    admin_orders_controller.dart
    dashboard_stats.dart         (nuevo, entrega 3)
  widgets/
    keki_nav.dart
    order_widgets.dart
    product_art.dart
    product_card.dart
    product_widgets.dart
  screens/
    auth_gate.dart
    login_screen.dart
    home_shell.dart
    home_screen.dart             (nuevo, entrega 3)
    explore_screen.dart
    product_detail_screen.dart
    cart_screen.dart
    profile_screen.dart
    order_detail_screen.dart
    admin/
      admin_shell.dart
      admin_orders_screen.dart
      admin_dashboard_screen.dart (nuevo, entrega 3)
      admin_products_screen.dart  (nuevo, entrega 3)
      product_form_screen.dart    (nuevo, entrega 3)
      new_order_screen.dart       (nuevo, entrega 3)
firestore.rules
test/
  widget_test.dart
```

### Inicio y configuración

- **`lib/main.dart`**: punto de entrada. `main()` inicializa Firebase con
  `DefaultFirebaseOptions.currentPlatform` y monta `KekiApp` con los servicios de
  Firebase. Con `--dart-define=KEKI_DEMO=true` usa los servicios en memoria.
  `KekiApp` recibe los servicios y delega en `AuthGate`.
- **`lib/firebase_options.dart`**: claves del proyecto `keki-keki` para Android e iOS.
  Para agregar otra plataforma (web, macOS) hay que volver a ejecutar `flutterfire configure`.
- **`firestore.rules`**: reglas de seguridad de Firestore (ver arriba).
- **`pubspec.yaml`**: dependencias. Además del SDK de Flutter usa `firebase_core`,
  `firebase_auth` y `cloud_firestore`.

### Datos y modelo

- **`lib/models/product.dart`**: categorías, ilustraciones, opciones y producto.
  `priceFor` y `summaryFor` calculan precio y resumen de la personalización.
  `toMap` / `fromMap` convierten cada clase al formato de Firestore. Tiene `active`,
  `stock`, `sortOrder` (campo `orden`) y `lowStock` (5 unidades o menos).
- **`lib/models/app_user.dart`**: `UserRole` (cliente/admin) y `AppUser`, el perfil
  guardado en `usuarios`. `isAdmin` decide la interfaz y `favorites` guarda los favoritos.
- **`lib/models/order.dart`**: `OrderStatus` (con `next` para el siguiente paso del
  flujo, `isOpen`, `canCancel` y `stockSignTo`, que dice si un cambio de estado descuenta
  o devuelve stock), `DeliveryMode`, `OrderOrigin` (catálogo, IA o manual), `OrderItem` y `Order`.
  `Order` calcula subtotal, total y un resumen de productos, y se convierte a/desde
  el documento de `pedidos`.
- **`lib/data/services.dart`**: contratos `AuthService`, `UserRepository` (favoritos),
  `ProductRepository` (leer, cargar, guardar, activar y borrar) y `OrderRepository`,
  y `AppServices`, que los agrupa. Las pantallas solo conocen estas
  interfaces, no Firebase: por eso se pueden probar sin conexión.
- **`lib/data/firebase_services.dart`**: implementaciones reales.
  `FirebaseAuthService` combina la sesión de Auth con el documento del usuario
  (al cambiar de sesión, deja de escuchar el perfil anterior); también traduce los
  errores. `FirestoreProductRepository` escucha `productos` y sube el catálogo inicial
  en un lote. `FirestoreOrderRepository` crea pedidos con hora del servidor, los
  escucha con `snapshots()` y cambia su estado en una transacción que también ajusta
  el stock. `FirestoreUserRepository` guarda los favoritos. `_plain` convierte los `Timestamp`
  en `DateTime` para que los modelos no dependan de Firebase.
- **`lib/data/memory_services.dart`**: las mismas operaciones en memoria, con las
  cuentas demo. Se usan en las pruebas y en el modo demo.
- **`lib/data/products_data.dart`**: los 7 productos de ejemplo. Ahora solo sirven
  para la carga inicial a Firestore (y para el modo demo).

### Estado de la aplicación

- **`lib/state/app_scope.dart`**: `AppScope` comparte con todas las pantallas el
  usuario de la sesión, los servicios y los controladores del catálogo y el carrito.
- **`lib/state/catalog_controller.dart`**: búsqueda, categoría, orden y favoritos
  sobre los productos que llegan del stream de Firestore. Expone `loading`, `error`,
  `totalCount`, `featured` (destacados) y `favoriteProducts`. `toggleFavorite` cambia
  el favorito al instante y lo guarda con `saveFavorite`; `syncFavorites` aplica los
  que llegan de la cuenta.
- **`lib/state/cart_controller.dart`**: líneas del carrito y datos de entrega.
  `setQuantity` cambia o quita una línea; `setDelivery` guarda forma, día, franja,
  dirección e indicaciones; `missingInfo` dice qué falta para confirmar;
  `buildOrder` arma el `Order` (con su `origin`) y `placeOrder` lo guarda y vacía el carrito.
  `kDeliveryFee` y `kDeliverySlots` definen el domicilio y las franjas.
- **`lib/state/admin_orders_controller.dart`**: escucha todos los pedidos, filtra por
  estado, cuenta pedidos por estado y llama a `onNewOrder` con cada pedido que llega
  después de la primera carga (el aviso en vivo). También alimenta el Panel general.
- **`lib/state/dashboard_stats.dart`**: `DashboardStats.from(pedidos)` calcula, sin
  tocar la interfaz, las ventas de hoy y ayer, pendientes, entregados de esta semana y
  la anterior, pedidos vía IA, ventas por día y los más vendidos (`TopProduct`).

### Pantallas

- **`lib/screens/auth_gate.dart`**: `AuthGate` escucha `userChanges` y elige entre
  carga, error, login, `HomeShell` (cliente) o `AdminShell` (admin). Cada sesión tiene
  su propio `MaterialApp`, envuelto en `SessionScope`, que crea el catálogo y el
  carrito de esa sesión y los destruye al cerrar sesión.
- **`lib/screens/login_screen.dart`**: selector «Iniciar sesión / Crear cuenta»,
  validación de campos, mensajes de error y, en modo demo, las cuentas de prueba.
- **`lib/screens/home_shell.dart`**: pestañas del cliente (Inicio, Explorar, Carrito,
  Perfil) con la barra inferior compartida. Abre en Inicio.
- **`lib/screens/home_screen.dart`**: Inicio del cliente (mockup 01).
- **`lib/screens/explore_screen.dart`** y **`product_detail_screen.dart`**: igual que
  en la entrega 1, ahora con datos de Firestore y estados de carga y error. El detalle
  acepta `onAdd` para que el pedido manual del admin reciba la selección.
- **`lib/screens/cart_screen.dart`**: carrito y confirmación (mockup 05).
  `showDeliverySheet` abre la hoja para elegir la entrega (si falta algo al confirmar
  se abre sola y explica qué falta). `CartItemTile`, `DeliveryCard` y `CartSummary`
  se reutilizan en el pedido manual del admin.
- **`lib/screens/profile_screen.dart`**: cuenta del cliente y «Mis pedidos» en vivo.
- **`lib/screens/order_detail_screen.dart`**: detalle de un pedido en vivo. Para el
  admin añade la barra con «Marcar como …» y «Cancelar».
- **`lib/screens/admin/admin_shell.dart`**: pestañas del admin (Inicio, Pedidos,
  Productos, IA), el botón central «Nuevo pedido» y `AdminTopBar` con el menú de la cuenta.
- **`lib/screens/admin/admin_orders_screen.dart`**: gestión de pedidos con filtros.
- **`lib/screens/admin/admin_dashboard_screen.dart`**: Panel general (mockup admin 01).
- **`lib/screens/admin/admin_products_screen.dart`**: catálogo del admin (mockup admin 03)
  y la opción «Restablecer catálogo de ejemplo».
- **`lib/screens/admin/product_form_screen.dart`**: crear o editar un producto y sus opciones.
- **`lib/screens/admin/new_order_screen.dart`**: pedido manual del admin.

### Componentes visuales y utilidades

- **`lib/widgets/keki_nav.dart`**: `KekiBottomNav` (barra inferior con botón central:
  IA en el cliente, «Nuevo pedido» en el admin) e `InfoPlaceholder` (mensajes de vacío o error).
- **`lib/widgets/order_widgets.dart`**: `StatusChip` con los colores de estado del
  mockup, `InitialAvatar`, `OrderCard` para las listas y `shortOrderId`.
- **`lib/widgets/product_art.dart`**, **`product_card.dart`**, **`product_widgets.dart`**:
  ilustraciones con `CustomPaint`, tarjeta de producto, calificación, favorito y botón
  con degradado (sin cambios).
- **`lib/core/format.dart`**: `cop` para pesos colombianos y, nuevo, `shortDate`,
  `relativeDay` («Hoy», «Mañana», «Ayer»), `clock` y `greeting` («Buenas tardes»).
- **`lib/core/snack.dart`** y **`lib/core/theme.dart`**: avisos breves y paleta del mockup.
- **`test/widget_test.dart`**: formato de precios y fechas, conversión de productos,
  validación del carrito, aviso de pedidos nuevos, cifras del panel, stock al preparar
  y cancelar, favoritos guardados en la cuenta, el recorrido de Inicio y Explorar, el
  login por rol, el recorrido cliente → admin, la creación y desactivación de un
  producto y el pedido manual del admin.

## Flujo de la aplicación

1. `main.dart` inicializa Firebase y monta `KekiApp` con los servicios.
2. `AuthGate` escucha la sesión: sin usuario muestra `LoginScreen`.
3. Al entrar, `FirebaseAuthService` lee `usuarios/{uid}`; según `rol` se abre la
   tienda o el panel, dentro de un `SessionScope` con sus controladores.
4. **Cliente:** Explorar lee `productos` → Producto → Carrito → entrega →
   «Confirmar pedido» crea un documento en `pedidos` → Perfil muestra su estado en vivo.
5. **Admin:** `AdminOrdersController` escucha `pedidos` con `snapshots()`; cada cambio
   en la base de datos actualiza la lista. En el detalle, «Marcar como …» actualiza
   `estado` y el cliente lo ve al instante.

**Gestión de estado:** igual que en la entrega 1, `ChangeNotifier` + `ListenableBuilder`
y `AppScope` (sin el paquete `provider`). Los datos remotos llegan como `Stream` y
los controladores los convierten en estado para la interfaz.

## Limitaciones conocidas

- El total del pedido se calcula en el celular. Las reglas validan dueño, estado y
  que haya productos, pero no pueden comparar precios con el catálogo; para eso haría
  falta una Cloud Function (fuera del alcance del curso).
- El stock se descuenta al preparar, no al pedir: el cliente puede pedir un producto
  agotado (las tortas se hacen por encargo) y el admin lo ve en el aviso de stock.
- Si al preparar no alcanza el stock, queda en 0; al cancelar se devuelven todas las
  unidades del pedido, así que en ese caso el stock puede quedar un poco por encima.
- El Panel general usa los últimos 200 pedidos (los mismos que muestra Pedidos).
- Las opciones «Clientes» y «Configuración» del menú del admin no tienen mockup y
  quedan como trabajo futuro.
- Las notificaciones de pedidos nuevos solo se ven con la app del admin abierta
  (no son notificaciones push).

## Datos de ejemplo

- Nombres, precios base y calificaciones de los 7 productos salen de los mockups.
- Los **recargos por opción** (p. ej. tamaño 20 pers. +$15.000), el domicilio de $6.000
  y las franjas horarias son valores de muestra: se editan en
  `lib/data/products_data.dart` y `lib/state/cart_controller.dart`.
- Los mockups usan la fuente Poppins; aquí se usa la fuente por defecto. Se puede añadir con `google_fonts`.
