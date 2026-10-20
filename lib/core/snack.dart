// Funciones de apoyo para mostrar mensajes breves en la interfaz.

import 'package:flutter/material.dart';

/// Reemplaza cualquier aviso visible y presenta [message] durante dos segundos.
void showKekiSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
}
