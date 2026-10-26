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

  /// Busca la categoría guardada en Firestore por su nombre (`tortas`, …).
  static ProductCategory fromName(Object? name) => ProductCategory.values
      .firstWhere((c) => c.name == name, orElse: () => ProductCategory.tortas);
}

/// Tipos de ilustración vectorial disponibles para los productos.
enum ArtKind {
  roseCake,
  blueCake,
  strawberryCake,
  chocolateCake,
  brownie,
  cupcakes,
  cookies;

  /// Busca la ilustración guardada en Firestore por su nombre.
  static ArtKind fromName(Object? name) => ArtKind.values
      .firstWhere((a) => a.name == name, orElse: () => ArtKind.roseCake);
}

/// Una alternativa dentro de una opción, con el recargo que puede tener.
class OptionChoice {
  /// Crea una alternativa llamada [label] con un recargo opcional en COP.
  const OptionChoice(this.label, {this.extra = 0});

  final String label;

  /// Diferencia de precio (COP) respecto al precio base del producto.
  final int extra;

  /// Convierte la alternativa al mapa que se guarda en Firestore.
  Map<String, dynamic> toMap() => {'nombre': label, 'extra': extra};

  /// Reconstruye la alternativa a partir de un mapa de Firestore.
  factory OptionChoice.fromMap(Map<String, dynamic> map) => OptionChoice(
        map['nombre'] as String? ?? '',
        extra: (map['extra'] as num?)?.toInt() ?? 0,
      );
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

  /// Convierte el grupo y sus alternativas al formato de Firestore.
  Map<String, dynamic> toMap() => {
        'id': id,
        'titulo': title,
        'predeterminada': defaultIndex,
        'opciones': [for (final c in choices) c.toMap()],
      };

  /// Reconstruye el grupo a partir de un mapa de Firestore.
  factory OptionGroup.fromMap(Map<String, dynamic> map) {
    final choices = [
      for (final c in (map['opciones'] as List? ?? const []))
        OptionChoice.fromMap(Map<String, dynamic>.from(c as Map)),
    ];
    final index = (map['predeterminada'] as num?)?.toInt() ?? 0;
    return OptionGroup(
      id: map['id'] as String? ?? '',
      title: map['titulo'] as String? ?? '',
      choices: choices,
      defaultIndex: index.clamp(0, choices.isEmpty ? 0 : choices.length - 1),
    );
  }
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
    this.active = true,
    this.stock = 0,
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

  /// Si es `false`, el producto no se muestra a los clientes.
  final bool active;

  /// Unidades disponibles (la gestión de stock llega en la entrega 3).
  final int stock;

  /// Convierte el producto al documento de la colección `productos`.
  /// [order] conserva la posición del catálogo para el orden por relevancia.
  Map<String, dynamic> toMap({int order = 0}) => {
        'nombre': name,
        'nombreDetalle': detailName,
        'categoria': category.name,
        'descripcion': description,
        'destacado': highlight,
        'precioBase': basePrice,
        'calificacion': rating,
        'resenas': reviewCount,
        'sinConservantes': noPreservatives,
        'ilustracion': art.name,
        'opciones': [for (final g in options) g.toMap()],
        'activo': active,
        'stock': stock,
        'orden': order,
      };

  /// Reconstruye un producto a partir del documento [id] de Firestore.
  factory Product.fromMap(String id, Map<String, dynamic> map) => Product(
        id: id,
        name: map['nombre'] as String? ?? 'Producto',
        detailName: map['nombreDetalle'] as String?,
        category: ProductCategory.fromName(map['categoria']),
        description: map['descripcion'] as String? ?? '',
        highlight: map['destacado'] as String?,
        basePrice: (map['precioBase'] as num?)?.toInt() ?? 0,
        rating: (map['calificacion'] as num?)?.toDouble(),
        reviewCount: (map['resenas'] as num?)?.toInt(),
        noPreservatives: map['sinConservantes'] as bool? ?? false,
        art: ArtKind.fromName(map['ilustracion']),
        options: [
          for (final g in (map['opciones'] as List? ?? const []))
            OptionGroup.fromMap(Map<String, dynamic>.from(g as Map)),
        ],
        active: map['activo'] as bool? ?? true,
        stock: (map['stock'] as num?)?.toInt() ?? 0,
      );

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
