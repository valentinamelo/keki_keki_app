// Modelos de dominio para productos, categorías, ilustraciones y opciones.

/// Categorías que se pueden seleccionar en el catálogo.
enum ProductCategory {
  tortas('Tortas'),
  cupcakes('Cupcakes'),
  galletas('Galletas'),
  brownies('Brownies');

  /// Asocia cada categoría con el nombre que se presenta en la interfaz.
  const ProductCategory(this.label);
  final String label;
}

/// Tipos de ilustración vectorial disponibles para los productos.
enum ArtKind {
  roseCake,
  blueCake,
  strawberryCake,
  chocolateCake,
  brownie,
  cupcakes,
  cookies,
}

/// Una alternativa dentro de una opción, con el recargo que puede tener.
class OptionChoice {
  /// Crea una alternativa llamada [label] con un recargo opcional en COP.
  const OptionChoice(this.label, {this.extra = 0});

  final String label;

  /// Diferencia de precio (COP) respecto al precio base del producto.
  final int extra;
}

/// Agrupa alternativas relacionadas, como tamaños o sabores.
class OptionGroup {
  /// Crea un grupo identificado por [id] y con [choices] seleccionables.
  const OptionGroup({
    required this.id,
    required this.title,
    required this.choices,
    this.defaultIndex = 0,
  });

  final String id;
  final String title;
  final List<OptionChoice> choices;
  final int defaultIndex;
}

/// Información de un producto y operaciones para sus opciones y precios.
class Product {
  /// Crea un producto con sus datos, ilustración y personalizaciones.
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.basePrice,
    required this.art,
    this.detailName,
    this.highlight,
    this.rating,
    this.reviewCount,
    this.noPreservatives = false,
    this.options = const [],
  });

  final String id;
  final String name;

  /// Nombre largo para la pantalla de detalle (si difiere del de la tarjeta).
  final String? detailName;
  final ProductCategory category;
  final String description;

  /// Frase final resaltada en azul dentro de la descripción.
  final String? highlight;
  final int basePrice;
  final double? rating;
  final int? reviewCount;
  final bool noPreservatives;
  final ArtKind art;
  final List<OptionGroup> options;

  /// Nombre que se muestra en el detalle, o [name] si no hay otro definido.
  String get title => detailName ?? name;

  /// Índice predeterminado de cada grupo de opciones del producto.
  Map<String, int> get defaultSelection => {
        for (final g in options) g.id: g.defaultIndex,
      };

  /// Precio del producto usando la selección predeterminada.
  int get defaultPrice => priceFor(defaultSelection);

  /// Suma al precio base los recargos de las opciones indicadas en [selection].
  int priceFor(Map<String, int> selection) {
    var total = basePrice;
    for (final g in options) {
      final i = selection[g.id] ?? g.defaultIndex;
      total += g.choices[i].extra;
    }
    return total;
  }

  /// Crea una descripción legible de las opciones seleccionadas.
  String summaryFor(Map<String, int> selection) {
    return options
        .map((g) => g.choices[selection[g.id] ?? g.defaultIndex].label)
        .join(' · ');
  }
}
