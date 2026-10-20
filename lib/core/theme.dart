import 'package:flutter/material.dart';

/// Paleta tomada de los mockups (variables CSS :root).
class KekiColors {
  static const blue = Color(0xFF92C7E1);
  static const blueDeep = Color(0xFF6FAFCE);
  static const pink = Color(0xFFFFC8E6);
  static const pinkDeep = Color(0xFFF7A9D2);
  static const bg = Color(0xFFF9FBFD);
  static const blueTint = Color(0xFFEEF8FC);
  static const pinkTint = Color(0xFFFFF3F8);
  static const text = Color(0xFF252525);
  static const text2 = Color(0xFF777777);
  static const border = Color(0xFFEDF1F4);
  static const star = Color(0xFFF5B94C);
  static const green = Color(0xFF4CAF7D);
}

class KekiShadows {
  /// Equivale a --shadow-card: 0 10px 24px -12px rgba(37,37,37,.14)
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x24252525),
      blurRadius: 24,
      spreadRadius: -12,
      offset: Offset(0, 10),
    ),
  ];
}

ThemeData buildKekiTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: KekiColors.blue).copyWith(
    primary: KekiColors.blueDeep,
    secondary: KekiColors.pinkDeep,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.white,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: KekiColors.text,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
