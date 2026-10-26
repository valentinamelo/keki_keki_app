// Opciones de Firebase del proyecto keki-keki, con el mismo formato que
// genera `flutterfire configure`. Los valores salen de
// android/app/google-services.json e ios/Runner/GoogleService-Info.plist.
// Para agregar web u otra plataforma, vuelve a ejecutar `flutterfire configure`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones de Firebase por plataforma.
class DefaultFirebaseOptions {
  /// Devuelve las opciones de la plataforma en la que corre la app.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'La app web no está registrada en Firebase. Ejecuta '
        '`flutterfire configure` y marca la plataforma web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase solo está configurado para Android e iOS.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnWnC8aop1X8zAHA7S9YfNwTMuZ_wCZjo',
    appId: '1:537609770699:android:a4dd5ebd2a49e7f2862d4e',
    messagingSenderId: '537609770699',
    projectId: 'keki-keki',
    storageBucket: 'keki-keki.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAui-EthcoorFe5vBQED3ttlIo5ygPzbGA',
    appId: '1:537609770699:ios:3ff963851579e47c862d4e',
    messagingSenderId: '537609770699',
    projectId: 'keki-keki',
    storageBucket: 'keki-keki.firebasestorage.app',
    iosClientId:
        '537609770699-3ms7q2ot3oml0ep13ubcbetmjj81ih63.apps.googleusercontent.com',
    iosBundleId: 'com.example.kekiKeki',
  );
}
