# Keki Keki — Pastelería Inteligente (Flutter + Firebase)

**Integrantes:** _Brayan Fuertes_ y _Valentina Melo_   **Repositorio:** _https://github.com/valentinamelo/keki_keki_app.git_

App Flutter basada en los mockups de Keki Keki. Hay dos interfaces en la misma app:
la **tienda del cliente** y el **panel del administrador**. Al iniciar sesión, la app
lee el rol del usuario en Firestore y lo envía a la interfaz que le corresponde.

| Entrega | Contenido | Estado |
|---|---|---|
| 1 | Catálogo del cliente: Explorar y Producto (mockups 02 y 03) | ✅ |
| 2 | Firebase, registro/inicio de sesión con roles, productos en Firestore, carrito y confirmación del pedido (mockup 05), gestión de pedidos del admin en tiempo real y reglas de seguridad | ✅ |
| 3 | Administración de productos, panel general e inicio del cliente | Pendiente |
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

> Si iOS se queja de la versión mínima al compilar, abre `ios/Podfile` y deja
> `platform :ios, '15.0'`.

### Pruebas

```bash
flutter test
```

Las pruebas usan los servicios en memoria, así que no necesitan Firebase.

## Demostración sugerida (tiempo real)

1. Abre la app en dos dispositivos o emuladores (o uno y la web): uno con una cuenta
   de cliente y otro con la cuenta admin en la pestaña **Pedidos**.
2. El cliente agrega productos, abre **Carrito**, elige entrega y pulsa **Confirmar pedido**.
3. En el admin, el pedido aparece al instante (sin recargar), con el aviso
   «Nuevo pedido de …» y el contador de pendientes en la barra inferior.
4. El admin abre el pedido y pulsa **Marcar como En preparación**, luego **Listo** y
   **Entregado**. En el celular del cliente (**Perfil › Mis pedidos**) el estado cambia
   solo, en el mismo momento.

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
  nombre, email, telefono, rol ("cliente" | "admin"), creado

productos/{id}            (id legible, p. ej. "torta-chocolate")
  nombre, nombreDetalle, categoria, descripcion, destacado, precioBase,
  calificacion, resenas, sinConservantes, ilustracion, activo, stock, orden,
  opciones: [{ id, titulo, predeterminada, opciones: [{ nombre, extra }] }]

pedidos/{id}
  clienteId, clienteNombre, clienteTelefono,
  items: [{ productoId, nombre, ilustracion, opciones, precioUnitario, cantidad }],
  subtotal, domicilio, total,
  tipoEntrega ("domicilio" | "recoger"), entrega (fecha y hora), franja,
  direccion, notas, origen ("catalogo" | "ia"),
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
    app_user.dart                (nuevo)
    order.dart                   (nuevo)
    product.dart
  data/
    services.dart                (nuevo)
    firebase_services.dart       (nuevo)
    memory_services.dart         (nuevo)
    products_data.dart
  state/
    app_scope.dart
    catalog_controller.dart
    cart_controller.dart
    admin_orders_controller.dart (nuevo)
  widgets/
    keki_nav.dart                (nuevo)
    order_widgets.dart           (nuevo)
    product_art.dart
    product_card.dart
    product_widgets.dart
  screens/
    auth_gate.dart               (nuevo)
    login_screen.dart            (nuevo)
    home_shell.dart
    explore_screen.dart
    product_detail_screen.dart
    cart_screen.dart             (nuevo)
    profile_screen.dart          (nuevo)
    order_detail_screen.dart     (nuevo)
    admin/
      admin_shell.dart           (nuevo)
      admin_orders_screen.dart   (nuevo)
firestore.rules                  (nuevo)
test/
  widget_test.dart
```

### Inicio y configuración

- **`lib/main.dart`**: punto de entrada. `main()` inicializa Firebase con
  `DefaultFirebaseOptions.currentPlatform` y monta `KekiApp` con los servicios de
  Firebase. Con `--dart-define=KEKI_DEMO=true` usa los servicios en memoria.
  `KekiApp` recibe los servicios y delega en `AuthGate`.
- **`lib/firebase_options.dart`**: claves del proyecto de Firebase por plataforma.
  El archivo del repositorio es provisional y `flutterfire configure` lo reemplaza.
- **`firestore.rules`**: reglas de seguridad de Firestore (ver arriba).
- **`pubspec.yaml`**: dependencias. Además del SDK de Flutter usa `firebase_core`,
  `firebase_auth` y `cloud_firestore`.

### Datos y modelo

- **`lib/models/product.dart`**: categorías, ilustraciones, opciones y producto.
  `priceFor` y `summaryFor` calculan precio y resumen de la personalización.
  Nuevo: `toMap` / `fromMap` convierten cada clase al formato de Firestore, y los
  campos `active` y `stock`.
- **`lib/models/app_user.dart`**: `UserRole` (cliente/admin) y `AppUser`, el perfil
  guardado en `usuarios`. `isAdmin` decide la interfaz.
- **`lib/models/order.dart`**: `OrderStatus` (con `next` para el siguiente paso del
  flujo, `isOpen` y `canCancel`), `DeliveryMode`, `OrderOrigin`, `OrderItem` y `Order`.
  `Order` calcula subtotal, total y un resumen de productos, y se convierte a/desde
  el documento de `pedidos`.
- **`lib/data/services.dart`**: contratos `AuthService`, `ProductRepository` y
  `OrderRepository`, y `AppServices`, que los agrupa. Las pantallas solo conocen estas
  interfaces, no Firebase: por eso se pueden probar sin conexión.
- **`lib/data/firebase_services.dart`**: implementaciones reales.
  `FirebaseAuthService` combina la sesión de Auth con el documento del usuario
  (al cambiar de sesión, deja de escuchar el perfil anterior); también traduce los
  errores. `FirestoreProductRepository` escucha `productos` y sube el catálogo inicial
  en un lote. `FirestoreOrderRepository` crea pedidos con hora del servidor, los
  escucha con `snapshots()` y cambia su estado. `_plain` convierte los `Timestamp`
  en `DateTime` para que los modelos no dependan de Firebase.
- **`lib/data/memory_services.dart`**: las mismas operaciones en memoria, con las
  cuentas demo. Se usan en las pruebas y en el modo demo.
- **`lib/data/products_data.dart`**: los 7 productos de ejemplo. Ahora solo sirven
  para la carga inicial a Firestore (y para el modo demo).

### Estado de la aplicación

- **`lib/state/app_scope.dart`**: `AppScope` comparte con todas las pantallas el
  usuario de la sesión, los servicios y los controladores del catálogo y el carrito.
- **`lib/state/catalog_controller.dart`**: búsqueda, categoría, orden y favoritos
  sobre los productos que llegan del stream de Firestore. Expone `loading`, `error`
  y `totalCount`, y cancela la suscripción en `dispose`.
- **`lib/state/cart_controller.dart`**: líneas del carrito y datos de entrega.
  `setQuantity` cambia o quita una línea; `setDelivery` guarda forma, día, franja,
  dirección e indicaciones; `missingInfo` dice qué falta para confirmar;
  `buildOrder` arma el `Order` y `placeOrder` lo guarda y vacía el carrito.
  `kDeliveryFee` y `kDeliverySlots` definen el domicilio y las franjas.
- **`lib/state/admin_orders_controller.dart`**: escucha todos los pedidos, filtra por
  estado, cuenta pedidos por estado y llama a `onNewOrder` con cada pedido que llega
  después de la primera carga (el aviso en vivo).

### Pantallas

- **`lib/screens/auth_gate.dart`**: `AuthGate` escucha `userChanges` y elige entre
  carga, error, login, `HomeShell` (cliente) o `AdminShell` (admin). Cada sesión tiene
  su propio `MaterialApp`, envuelto en `SessionScope`, que crea el catálogo y el
  carrito de esa sesión y los destruye al cerrar sesión.
- **`lib/screens/login_screen.dart`**: selector «Iniciar sesión / Crear cuenta»,
  validación de campos, mensajes de error y, en modo demo, las cuentas de prueba.
- **`lib/screens/home_shell.dart`**: pestañas del cliente (Inicio, Explorar, Carrito,
  Perfil) con la barra inferior compartida.
- **`lib/screens/explore_screen.dart`** y **`product_detail_screen.dart`**: igual que
  en la entrega 1, ahora con datos de Firestore y estados de carga y error.
- **`lib/screens/cart_screen.dart`**: carrito y confirmación (mockup 05).
  `_DeliverySheet` es la hoja para elegir la entrega; si falta algo al confirmar se
  abre sola y explica qué falta.
- **`lib/screens/profile_screen.dart`**: cuenta del cliente y «Mis pedidos» en vivo.
- **`lib/screens/order_detail_screen.dart`**: detalle de un pedido en vivo. Para el
  admin añade la barra con «Marcar como …» y «Cancelar».
- **`lib/screens/admin/admin_shell.dart`**: pestañas del admin (Inicio, Pedidos,
  Productos, IA), `AdminTopBar` con el menú de la cuenta y la pestaña provisional de
  Productos con la carga del catálogo de ejemplo.
- **`lib/screens/admin/admin_orders_screen.dart`**: gestión de pedidos con filtros.

### Componentes visuales y utilidades

- **`lib/widgets/keki_nav.dart`**: `KekiBottomNav` (barra inferior con botón central
  de IA, usada por cliente y admin) e `InfoPlaceholder` (mensajes de vacío o error).
- **`lib/widgets/order_widgets.dart`**: `StatusChip` con los colores de estado del
  mockup, `InitialAvatar`, `OrderCard` para las listas y `shortOrderId`.
- **`lib/widgets/product_art.dart`**, **`product_card.dart`**, **`product_widgets.dart`**:
  ilustraciones con `CustomPaint`, tarjeta de producto, calificación, favorito y botón
  con degradado (sin cambios).
- **`lib/core/format.dart`**: `cop` para pesos colombianos y, nuevo, `shortDate`,
  `relativeDay` («Hoy», «Mañana», «Ayer») y `clock` para fechas y horas en español.
- **`lib/core/snack.dart`** y **`lib/core/theme.dart`**: avisos breves y paleta del mockup.
- **`test/widget_test.dart`**: formato de precios y fechas, conversión de productos,
  validación del carrito, aviso de pedidos nuevos, el recorrido de Explorar, el login
  por rol y el recorrido completo cliente → admin (confirmar pedido y cambiar estado).

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
- El stock aún no se descuenta al pedir (la gestión de stock llega en la entrega 3).
- Los favoritos siguen en memoria; en la entrega 3 se guardarán en la cuenta.
- Las notificaciones de pedidos nuevos solo se ven con la app del admin abierta
  (no son notificaciones push).

## Datos de ejemplo

- Nombres, precios base y calificaciones de los 7 productos salen de los mockups.
- Los **recargos por opción** (p. ej. tamaño 20 pers. +$15.000), el domicilio de $6.000
  y las franjas horarias son valores de muestra: se editan en
  `lib/data/products_data.dart` y `lib/state/cart_controller.dart`.
- Los mockups usan la fuente Poppins; aquí se usa la fuente por defecto. Se puede añadir con `google_fonts`.
