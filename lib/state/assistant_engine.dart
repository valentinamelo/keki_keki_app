// Motor del Asistente Keki IA: entiende lo que escribe el cliente (ocasión,
// personas, presupuesto y sabores) y elige del catálogo real el producto y la
// personalización que mejor encajan. No usa la interfaz ni Firebase, así que
// se prueba con funciones puras.

import '../core/format.dart';
import '../models/assistant.dart';
import '../models/product.dart';

/// Lo que el cliente ha contado hasta ahora. Cada dato es `null` mientras no
/// se haya respondido; [flavorsAnswered] distingue «aún no responde» de «me
/// da igual el sabor».
class AssistantBrief {
  /// Crea un resumen con los datos ya conocidos.
  const AssistantBrief({
    this.occasion,
    this.occasionLabel,
    this.people,
    this.budgetAnswered = false,
    this.budgetMin,
    this.budgetMax,
    this.flavorsAnswered = false,
    this.flavors = const [],
  });

  final Occasion? occasion;
  final String? occasionLabel;
  final int? people;
  final bool budgetAnswered;
  final int? budgetMin;
  final int? budgetMax;
  final bool flavorsAnswered;

  /// Sabores pedidos, con su nombre para mostrar (p. ej. «Frutos rojos»).
  final List<String> flavors;

  /// `true` cuando ya se respondieron las cuatro preguntas.
  bool get complete =>
      occasion != null && people != null && budgetAnswered && flavorsAnswered;

  /// Texto del presupuesto, por ejemplo «$70.000–$90.000».
  String get budgetLabel => budgetText(budgetMin, budgetMax);

  /// Combina este resumen con [other]: los datos de [other] ganan.
  AssistantBrief merge(AssistantBrief other) => AssistantBrief(
        occasion: other.occasion ?? occasion,
        occasionLabel:
            other.occasion != null ? other.occasionLabel : occasionLabel,
        people: other.people ?? people,
        budgetAnswered: budgetAnswered || other.budgetAnswered,
        budgetMin: other.budgetAnswered ? other.budgetMin : budgetMin,
        budgetMax: other.budgetAnswered ? other.budgetMax : budgetMax,
        flavorsAnswered: flavorsAnswered || other.flavorsAnswered,
        flavors: other.flavorsAnswered ? other.flavors : flavors,
      );
}

/// Texto legible de un rango de presupuesto.
String budgetText(int? min, int? max) {
  if (min == null && max == null) return 'Sin definir';
  if (min == null || min == 0) return 'Hasta ${cop(max!)}';
  if (max == null) return 'Desde ${cop(min)}';
  return '${cop(min)}–${cop(max)}';
}

/// Pregunta del flujo del mockup 04, en orden.
enum AssistantStep { occasion, people, budget, flavors }

/// Sabores que reconoce el asistente: nombre para mostrar y palabras clave.
const Map<String, List<String>> kFlavorKeywords = {
  'Chocolate': ['chocolate', 'cacao', 'choco'],
  'Vainilla': ['vainilla'],
  'Red velvet': ['red velvet', 'terciopelo'],
  'Frutos rojos': ['frutos rojos', 'frutos', 'mora', 'frambuesa', 'arandano'],
  'Fresa': ['fresa'],
  'Arequipe': ['arequipe', 'dulce de leche', 'manjar'],
  'Tres leches': ['tres leches', '3 leches'],
  'Naranja': ['naranja'],
  'Frutas': ['frutas', 'fruta', 'frutal'],
  'Canela': ['canela'],
  'Zanahoria': ['zanahoria'],
  'Mantequilla': ['mantequilla'],
  'Maracuyá': ['maracuya'],
  'Limón': ['limon'],
  'Café': ['cafe', 'moka'],
  'Coco': ['coco'],
};

/// Pasa el texto a minúsculas y quita tildes para comparar palabras.
String normalize(String s) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñ';
  const to = 'aaaaeeeeiiiioooouuuun';
  final buffer = StringBuffer();
  for (final ch in s.toLowerCase().split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString();
}

/// `true` si [text] contiene [word] como palabra (o frase) completa.
bool _hasWord(String text, String word) =>
    RegExp('(^|[^a-z])${RegExp.escape(word)}s?(\$|[^a-z])').hasMatch(text);

const Map<String, int> _numberWords = {
  'una': 1,
  'uno': 1,
  'dos': 2,
  'tres': 3,
  'cuatro': 4,
  'cinco': 5,
  'seis': 6,
  'siete': 7,
  'ocho': 8,
  'nueve': 9,
  'diez': 10,
  'once': 11,
  'doce': 12,
  'docena': 12,
  'quince': 15,
  'veinte': 20,
  'veinticinco': 25,
  'treinta': 30,
  'cuarenta': 40,
  'cincuenta': 50,
  'cien': 100,
};

/// Números escritos en [text], con dígitos («20», «$70.000») o en palabras
/// («veinte»). Los puntos y comas de miles se ignoran.
List<int> _numbers(String text) {
  final found = <(int, int)>[]; // (posición, valor)
  for (final m in RegExp(r'\d[\d.,]*').allMatches(text)) {
    final digits = m.group(0)!.replaceAll(RegExp(r'[.,]'), '');
    final value = int.tryParse(digits);
    if (value != null) found.add((m.start, value));
  }
  for (final entry in _numberWords.entries) {
    for (final m
        in RegExp('(^|[^a-z])${entry.key}(\$|[^a-z])').allMatches(text)) {
      found.add((m.start, entry.value));
    }
  }
  found.sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final f in found) f.$2];
}

/// Detecta la ocasión en [text], o `null` si no menciona ninguna conocida.
Occasion? parseOccasion(String text) {
  final t = normalize(text);
  for (final o in Occasion.values) {
    for (final k in o.keywords) {
      if (t.contains(k)) return o;
    }
  }
  return null;
}

/// Detecta para cuántas personas es. Si [expected] es `true` (se acaba de
/// preguntar) basta un número; si no, el número debe ir con «personas».
int? parsePeople(String text, {bool expected = false}) {
  final t = normalize(text);
  final m = RegExp(
          r'(\d+)\s*(personas|persona|pers|invitados|invitadas|comensales|porciones|gente)')
      .firstMatch(t);
  if (m != null) return int.parse(m.group(1)!);
  for (final entry in _numberWords.entries) {
    if (RegExp('(^|[^a-z])${entry.key}\\s*(personas|invitados|porciones)')
        .hasMatch(t)) {
      return entry.value;
    }
  }
  if (!expected) return null;
  final nums = _numbers(t).where((n) => n > 0 && n <= 300);
  return nums.isEmpty ? null : nums.first;
}

/// Detecta el presupuesto como rango (mínimo, máximo); cualquiera de los dos
/// puede ser `null`. Devuelve `null` si el texto no habla de presupuesto.
/// Con [expected] (se acaba de preguntar) los números pequeños se toman como
/// miles («entre 70 y 90») y se acepta «no sé» como «sin presupuesto».
(int?, int?)? parseBudget(String text, {bool expected = false}) {
  final t = normalize(text);
  final hasDigits = RegExp(r'\d').hasMatch(t);
  if (expected &&
      !hasDigits &&
      RegExp(r'no se|no tengo|sin limite|cualquier|lo que sea|da igual|no importa|ninguno')
          .hasMatch(t)) {
    return (null, null);
  }
  // Fuera de la pregunta solo vale si lo dice claramente.
  if (RegExp(r'sin limite de presupuesto|sin presupuesto|no tengo presupuesto|'
          r'presupuesto (abierto|libre)|cualquier precio|el precio no importa')
      .hasMatch(t)) {
    return (null, null);
  }
  final values = <int>[];
  // «Entre 70 y 90 mil»: el «mil» del final vale para las dos cifras.
  final range =
      RegExp(r'(\d+)\s*(?:y|a|-|–|hasta)\s*\$?\s*(\d+)\s*(?:mil\b|k\b)')
          .firstMatch(t);
  if (range != null) {
    values
      ..add(int.parse(range.group(1)!) * 1000)
      ..add(int.parse(range.group(2)!) * 1000);
  } else {
    for (final m
        in RegExp(r'(\$)?\s*(\d[\d.,]*)\s*(mil\b|k\b)?').allMatches(t)) {
      final raw = int.tryParse(m.group(2)!.replaceAll(RegExp(r'[.,]'), ''));
      if (raw == null || raw == 0) continue;
      final suffix = m.group(3) != null;
      // Fuera de la pregunta solo cuentan cifras que parecen dinero; las
      // pequeñas sin «$» ni «mil» suelen ser personas.
      final looksLikeMoney = m.group(1) != null || suffix || raw >= 1000;
      if (!expected && !looksLikeMoney) continue;
      final value = raw < 1000 && (suffix || expected || m.group(1) != null)
          ? raw * 1000
          : raw;
      if (value >= 1000) values.add(value);
    }
  }
  if (values.isEmpty) return null;

  if (values.length >= 2) {
    final a = values[0], b = values[1];
    return a <= b ? (a, b) : (b, a);
  }
  final n = values.first;
  if (RegExp(r'hasta|maximo|menos de|no mas de|tope').hasMatch(t)) {
    return (null, n);
  }
  if (RegExp(r'mas de|desde|minimo|por encima|arriba de').hasMatch(t)) {
    return (n, null);
  }
  // «Unos 80 mil»: un margen de 15 % hacia cada lado, en miles redondos.
  return ((n * 0.85) ~/ 1000 * 1000, (n * 1.15) ~/ 1000 * 1000);
}

/// Detecta los sabores de [text]. Con [expected] reconoce «me da igual»
/// (lista vacía); devuelve `null` si no se entendió nada.
List<String>? parseFlavors(String text, {bool expected = false}) {
  final t = normalize(text);
  final found = <String>[];
  for (final entry in kFlavorKeywords.entries) {
    if (entry.value.any((k) => _hasWord(t, k))) found.add(entry.key);
  }
  // «Frutos rojos» no debe contar también como «fresa» si no se dijo.
  if (found.isNotEmpty) return found;
  if (expected &&
      RegExp(r'cualquier|da igual|no importa|sorprend|todos|todas|ninguno|no se|tu eliges|lo que')
          .hasMatch(t)) {
    return const [];
  }
  return null;
}

/// Extrae todo lo que se pueda de [text]. [step] es la pregunta que se acaba
/// de hacer: para esa pregunta se aceptan respuestas más cortas.
AssistantBrief parseMessage(String text, {AssistantStep? step}) {
  var occasion = parseOccasion(text);
  String? occasionLabel = occasion?.label;
  if (occasion == null &&
      step == AssistantStep.occasion &&
      RegExp('[a-zA-ZáéíóúñÁÉÍÓÚÑ]{3,}').hasMatch(text)) {
    // Respuesta libre («Despedida de Ana»): se guarda tal como la escribió.
    final clean = text.trim();
    if (clean.isNotEmpty) {
      occasion = Occasion.otra;
      occasionLabel = clean.length > 32 ? '${clean.substring(0, 32)}…' : clean;
      occasionLabel =
          occasionLabel[0].toUpperCase() + occasionLabel.substring(1);
    }
  }
  final budget = parseBudget(text, expected: step == AssistantStep.budget);
  // Si el mensaje habla de dinero, sus cifras no son personas.
  final people = (budget != null && step != AssistantStep.people)
      ? parsePeople(text)
      : parsePeople(text, expected: step == AssistantStep.people);
  final flavors = parseFlavors(text, expected: step == AssistantStep.flavors);
  return AssistantBrief(
    occasion: occasion,
    occasionLabel: occasionLabel,
    people: people,
    budgetAnswered: budget != null,
    budgetMin: budget?.$1,
    budgetMax: budget?.$2,
    flavorsAnswered: flavors != null,
    flavors: flavors ?? const [],
  );
}

/// Producto recomendado con su personalización, cantidad y motivos.
class Recommendation {
  /// Crea la recomendación de [product] con la [selection] elegida.
  const Recommendation({
    required this.product,
    required this.selection,
    required this.quantity,
    required this.score,
    required this.reasons,
    this.overBudget = false,
  });

  final Product product;
  final Map<String, int> selection;

  /// Unidades (cajas o tortas) para alcanzar las personas pedidas.
  final int quantity;
  final double score;

  /// Frases cortas de por qué encaja («Dentro de tu presupuesto», …).
  final List<String> reasons;

  /// `true` si ninguna opción cabía y esta supera el presupuesto.
  final bool overBudget;

  /// Precio de una unidad con la personalización.
  int get unitPrice => product.priceFor(selection);

  /// Precio total de la recomendación.
  int get total => unitPrice * quantity;

  /// Resumen de la personalización, p. ej. «20 pers. · Chocolate · Frutos rojos».
  String get summary => product.summaryFor(selection);
}

/// Personas que alcanza una alternativa como «20 pers.» o «Caja x12».
int? _capacityOf(OptionChoice choice) {
  final t = normalize(choice.label);
  // El Minicake es una torta individual o para compartir entre pocos.
  if (t.contains('mini')) return 4;
  final m = RegExp(r'(\d+)\s*pers').firstMatch(t) ??
      RegExp(r'x\s*(\d+)').firstMatch(t) ??
      RegExp(r'(\d+)\s*(unidades|und|porciones)').firstMatch(t);
  return m == null ? null : int.parse(m.group(1)!);
}

/// Cuánto le gusta a cada ocasión cada categoría (0 a 20).
const Map<Occasion, Map<ProductCategory, int>> _affinity = {
  Occasion.cumpleanos: {
    ProductCategory.tortas: 20,
    ProductCategory.cupcakes: 9,
    ProductCategory.rollos: 4,
    ProductCategory.galletas: 3,
  },
  Occasion.aniversario: {
    ProductCategory.tortas: 20,
    ProductCategory.cupcakes: 8,
    ProductCategory.rollos: 6,
    ProductCategory.galletas: 3,
  },
  Occasion.babyShower: {
    ProductCategory.cupcakes: 20,
    ProductCategory.tortas: 14,
    ProductCategory.galletas: 9,
    ProductCategory.rollos: 5,
  },
  Occasion.reunion: {
    ProductCategory.rollos: 16,
    ProductCategory.galletas: 16,
    ProductCategory.cupcakes: 13,
    ProductCategory.tortas: 8,
  },
  Occasion.grado: {
    ProductCategory.tortas: 18,
    ProductCategory.cupcakes: 12,
    ProductCategory.rollos: 6,
    ProductCategory.galletas: 5,
  },
  Occasion.otra: {
    ProductCategory.tortas: 10,
    ProductCategory.cupcakes: 8,
    ProductCategory.rollos: 7,
    ProductCategory.galletas: 6,
  },
};

/// `true` si la alternativa [choice] corresponde al sabor [flavor].
bool _choiceMatches(OptionChoice choice, String flavor) {
  final t = normalize(choice.label);
  return kFlavorKeywords[flavor]!.any((k) => _hasWord(t, k));
}

/// `true` si el nombre o la descripción del producto mencionan [flavor].
bool _productMentions(Product p, String flavor) {
  final t = normalize('${p.name} ${p.description}');
  return kFlavorKeywords[flavor]!.any((k) => _hasWord(t, k));
}

/// Arma la mejor versión de [product] para [brief] y le da un puntaje.
Recommendation _evaluate(
  Product product,
  AssistantBrief brief,
  AssistantSettings settings,
) {
  final selection = Map<String, int>.of(product.defaultSelection);
  final reasons = <String>[];
  final people = brief.people ?? 0;
  var quantity = 1;
  var score = (product.rating ?? 4.2) * 4;

  // 1. Tamaño: la alternativa más pequeña que alcance para todos.
  for (final g in product.options) {
    final caps = [for (final c in g.choices) _capacityOf(c)];
    if (caps.every((c) => c == null) || people == 0) continue;
    var best = -1;
    for (var i = 0; i < caps.length; i++) {
      final c = caps[i];
      if (c != null && c >= people && (best < 0 || c < caps[best]!)) best = i;
    }
    if (best < 0) {
      // Ninguna alcanza: la más grande, varias veces.
      for (var i = 0; i < caps.length; i++) {
        if (caps[i] != null && (best < 0 || caps[i]! > caps[best]!)) best = i;
      }
      quantity = (people / caps[best]!).ceil().clamp(1, 6);
    }
    selection[g.id] = best;
  }

  // 2. Sabores: cada grupo de opciones toma el primer sabor pedido que tenga
  //    (p. ej. Sabor → Chocolate y Relleno → Frutos rojos).
  final matched = <String>{};
  for (final g in product.options) {
    for (final flavor in brief.flavors) {
      if (matched.contains(flavor)) continue;
      final i = g.choices.indexWhere((c) => _choiceMatches(c, flavor));
      if (i >= 0) {
        selection[g.id] = i;
        matched.add(flavor);
        break;
      }
    }
  }
  // Un sabor que es propio del producto (está en su nombre o descripción)
  // pesa más que uno que solo se puede elegir como opción.
  for (final flavor in brief.flavors) {
    if (_productMentions(product, flavor)) {
      matched.add(flavor);
      score += 10;
    }
  }
  if (brief.flavors.isNotEmpty) {
    score += matched.length * 13;
    if (matched.isEmpty) score -= 10;
    if (matched.isNotEmpty) {
      final names = [
        for (final f in brief.flavors)
          if (matched.contains(f)) f.toLowerCase(),
      ];
      reasons.add('Con ${_joinEs(names)}');
    }
  }

  // 3. Decoración según la ocasión, si el admin lo permite y cabe en el
  //    presupuesto.
  if (settings.suggestCustomization &&
      {
        Occasion.cumpleanos,
        Occasion.aniversario,
        Occasion.babyShower,
        Occasion.grado
      }.contains(brief.occasion)) {
    for (final g in product.options) {
      final i =
          g.choices.indexWhere((c) => normalize(c.label).contains('flores'));
      if (i < 0) continue;
      final current = g.choices[selection[g.id]!];
      final takenByFlavor =
          brief.flavors.any((f) => _choiceMatches(current, f));
      if (takenByFlavor) continue;
      final trial = {...selection, g.id: i};
      final max = brief.budgetMax;
      if (max == null || product.priceFor(trial) * quantity <= max) {
        selection[g.id] = i;
        reasons.add('Decoración floral para la ocasión');
      }
    }
  }

  // 3b. Pedido mínimo del administrador: si la opción queda por debajo, se
  //     sube el tamaño y, si ya es el más grande, la cantidad.
  if (product.priceFor(selection) * quantity < settings.minBudget) {
    OptionGroup? sizes;
    for (final g in product.options) {
      if (g.choices.any((c) => _capacityOf(c) != null)) {
        sizes = g;
        break;
      }
    }
    for (var guard = 0;
        guard < 12 &&
            product.priceFor(selection) * quantity < settings.minBudget;
        guard++) {
      final g = sizes;
      if (g != null) {
        final current = _capacityOf(g.choices[selection[g.id]!]) ?? 0;
        var next = -1;
        for (var i = 0; i < g.choices.length; i++) {
          final c = _capacityOf(g.choices[i]);
          if (c != null &&
              c > current &&
              (next < 0 || c < _capacityOf(g.choices[next])!)) {
            next = i;
          }
        }
        if (next >= 0) {
          selection[g.id] = next;
          continue;
        }
      }
      if (quantity >= 6) break;
      quantity++;
    }
    reasons.add('Pedido mínimo de ${cop(settings.minBudget)}');
  }

  // 4. Ocasión y presupuesto.
  final occasion = brief.occasion ?? Occasion.otra;
  score += _affinity[occasion]![product.category] ?? 5;
  if (quantity > 1 && product.category == ProductCategory.tortas) score -= 12;

  final total = product.priceFor(selection) * quantity;
  final min = brief.budgetMin ?? 0;
  final max = brief.budgetMax;
  var over = false;
  if (max != null && total > max) {
    over = true;
    score -= 15 + (total - max) / max * 100;
  } else if (total < min) {
    score += 22 - (min - total) / (min == 0 ? 1 : min) * 30;
  } else if (brief.budgetMin != null || max != null) {
    score += 40;
    reasons.insert(0, 'Dentro de tu presupuesto');
  }
  if (people > 0) {
    reasons.add(quantity > 1
        ? '$quantity unidades alcanzan para $people personas'
        : 'Alcanza para $people personas');
  }
  if (product.stock <= 0) score -= 6;

  return Recommendation(
    product: product,
    selection: selection,
    quantity: quantity,
    score: score,
    reasons: reasons,
    overBudget: over,
  );
}

/// Une palabras en español: «a, b y c».
String _joinEs(List<String> items) {
  if (items.length <= 1) return items.join();
  return '${items.sublist(0, items.length - 1).join(', ')} y ${items.last}';
}

/// Ordena los productos de [catalog] del que mejor encaja con [brief] al que
/// menos. Con [onlyProduct] solo se personaliza ese producto («Personalizar
/// con IA» desde el detalle). Se omiten los productos inactivos y los que
/// cuestan menos que el mínimo que fijó el administrador.
List<Recommendation> recommend(
  List<Product> catalog,
  AssistantBrief brief, {
  AssistantSettings settings = const AssistantSettings(),
  String? onlyProduct,
}) {
  final candidates = [
    for (final p in catalog)
      if (p.active && (onlyProduct == null || p.id == onlyProduct)) p,
  ];
  final all = [for (final p in candidates) _evaluate(p, brief, settings)];
  final allowed = onlyProduct != null
      ? all
      : all.where((r) => r.total >= settings.minBudget).toList();
  final list = allowed.isEmpty ? all : allowed;
  list.sort((a, b) => b.score.compareTo(a.score));
  return list;
}

/// Cómo se nombra cada ocasión dentro de una frase.
const Map<Occasion, String> _occasionPhrase = {
  Occasion.cumpleanos: 'un cumpleaños',
  Occasion.aniversario: 'un aniversario',
  Occasion.babyShower: 'un baby shower',
  Occasion.reunion: 'una reunión',
  Occasion.grado: 'un grado',
};

/// Mensaje del asistente que presenta [rec] para [brief].
String recommendationIntro(Recommendation rec, AssistantBrief brief) {
  final who = brief.people != null ? ' de ${brief.people} personas' : '';
  final occasion = _occasionPhrase[brief.occasion] ?? 'tu celebración';
  if (rec.overBudget) {
    return 'No encontré nada dentro de ${brief.budgetLabel}, pero esta es la '
        'opción más cercana para $occasion$who:';
  }
  return '¡Listo! Para $occasion$who esta es mi recomendación:';
}
