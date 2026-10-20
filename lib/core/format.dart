/// Utilidades para presentar valores monetarios en la interfaz.
///
/// Formatea un valor en pesos colombianos como en los mockups: $65.000.
/// [value] es el valor entero en COP que se desea mostrar.
String cop(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${value < 0 ? '-' : ''}\$$buffer';
}
