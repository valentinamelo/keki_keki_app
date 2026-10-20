enum ProductCategory {
  tortas('Tortas'),
  cupcakes('Cupcakes'),
  galletas('Galletas'),
  brownies('Brownies');

  const ProductCategory(this.label);
  final String label;
}

/// Ilustración que se dibuja para cada producto (ver widgets/product_art.dart).
enum ArtKind {
  roseCake,
  blueCake,
  strawberryCake,
  chocolateCake,
  brownie,
  cupcakes,
  cookies,
}

class OptionChoice {
  const OptionChoice(this.label, {this.extra = 0});

  final String label;

  /// Diferencia de precio (COP) respecto al precio base del producto.
  final int extra;
}

class OptionGroup {
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

class Product {
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

  String get title => detailName ?? name;

  Map<String, int> get defaultSelection => {
        for (final g in options) g.id: g.defaultIndex,
      };

  int get defaultPrice => priceFor(defaultSelection);

  int priceFor(Map<String, int> selection) {
    var total = basePrice;
    for (final g in options) {
      final i = selection[g.id] ?? g.defaultIndex;
      total += g.choices[i].extra;
    }
    return total;
  }

  String summaryFor(Map<String, int> selection) {
    return options
        .map((g) => g.choices[selection[g.id] ?? g.defaultIndex].label)
        .join(' · ');
  }
}
