/// Utilidades para presentar precios y fechas en la interfaz.
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

const _weekdays = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sept',
  'oct',
  'nov',
  'dic',
];

/// Fecha corta en español, por ejemplo «jue 25 sept.».
String shortDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}.';

/// «Hoy», «Mañana» o «Ayer» si aplica; si no, la fecha corta.
/// [now] permite fijar la fecha de referencia en las pruebas.
String relativeDay(DateTime d, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final a = DateTime(today.year, today.month, today.day);
  final b = DateTime(d.year, d.month, d.day);
  switch (b.difference(a).inDays) {
    case 0:
      return 'Hoy';
    case 1:
      return 'Mañana';
    case -1:
      return 'Ayer';
    default:
      return shortDate(d);
  }
}

/// Hora en formato de 12 horas, por ejemplo «3:05 PM».
String clock(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
}
