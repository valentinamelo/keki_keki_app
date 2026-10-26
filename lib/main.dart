// Punto de entrada y composición raíz de la aplicación Keki Keki.

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/firebase_services.dart';
import 'data/memory_services.dart';
import 'data/services.dart';
import 'firebase_options.dart';
import 'screens/auth_gate.dart';

/// Con `flutter run --dart-define=KEKI_DEMO=true` la app usa datos en memoria
/// y no necesita Firebase (útil para probar sin conexión).
const bool kDemoMode = bool.fromEnvironment('KEKI_DEMO');

/// Inicializa Firebase (salvo en modo demo) y monta la aplicación.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDemoMode) {
    runApp(KekiApp(services: memoryServices(), demo: true));
    return;
  }
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Sin esto, un error aquí deja la app en el splash sin explicación.
    runApp(SetupErrorApp(error: e));
    return;
  }
  runApp(KekiApp(services: firebaseServices()));
}

/// Pantalla que se muestra si Firebase no se pudo inicializar.
class SetupErrorApp extends StatelessWidget {
  /// Crea la pantalla con el [error] recibido al inicializar Firebase.
  const SetupErrorApp({super.key, required this.error});

  final Object error;

  /// Explica el error y cómo configurar Firebase o usar el modo demo.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'No se pudo iniciar Firebase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text('$error'),
                const SizedBox(height: 16),
                const Text(
                  '1. Ejecuta `flutterfire configure` en la carpeta del '
                  'proyecto y vuelve a correr la app.\n'
                  '2. O pruébala sin Firebase con:\n'
                  '   flutter run --dart-define=KEKI_DEMO=true',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Raíz de la aplicación: recibe los servicios y delega en [AuthGate] la
/// elección entre el login, la tienda del cliente y el panel del admin.
class KekiApp extends StatelessWidget {
  /// Crea la raíz con los [services] de datos que usará toda la app.
  const KekiApp({super.key, required this.services, this.demo = false});

  final AppServices services;

  /// `true` cuando los servicios son en memoria.
  final bool demo;

  /// Construye la puerta de acceso.
  @override
  Widget build(BuildContext context) =>
      AuthGate(services: services, demo: demo);
}
