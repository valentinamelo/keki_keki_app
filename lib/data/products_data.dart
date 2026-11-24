// Catálogo real de Keki Keki para la carga inicial de Firestore (y para el
// modo demo y las pruebas).

import '../models/product.dart';

// ---------------------------------------------------------------------------
// Precios tomados de la lista «Precios · Sabores clásicos» de la pastelería.
// Las cajas grandes de galletas, cupcakes y rollos cuestan lo mismo por unidad
// que la caja pequeña. El stock inicial es un valor de ejemplo: el admin lo
// ajusta desde Productos.
// ---------------------------------------------------------------------------

/// Tamaños de torta con los precios de la lista: [prices] son los valores de
/// Minicake, 10-12, 18-20 y 28-30 personas. El precio base es el del Minicake
/// y la torta viene elegida en 10-12 personas.
OptionGroup _tamanos(List<int> prices) {
  const labels = ['Minicake', '10-12 pers.', '18-20 pers.', '28-30 pers.'];
  return OptionGroup(
    id: 'tamano',
    title: 'Tamaño',
    defaultIndex: 1,
    choices: [
      for (var i = 0; i < labels.length; i++)
        OptionChoice(labels[i], extra: prices[i] - prices[0]),
    ],
  );
}

/// Precios de los sabores clásicos: vainilla, naranja y red velvet.
const _clasicos = [15000, 35000, 55000, 75000];

/// Precios de chocolate, frutas, tres leches y zanahoria.
const _especiales = [17000, 37000, 58000, 79000];

/// Cajas de [unit] unidades y sus múltiplos ([sizes]), al mismo precio por
/// unidad que la caja más pequeña ([unitPrice] es el valor de esa caja).
OptionGroup _cajas(int unit, int unitPrice, List<int> sizes) => OptionGroup(
      id: 'presentacion',
      title: 'Presentación',
      choices: [
        for (final n in sizes)
          OptionChoice('Caja x$n', extra: unitPrice * (n ~/ unit) - unitPrice),
      ],
    );

/// Ruta de la foto de un producto dentro de `assets/productos/`.
String _foto(String name) => 'assets/productos/$name.jpg';

/// Fotos incluidas en la app; el admin las elige al crear o editar productos.
final List<String> kProductImages = [
  for (final n in const [
    'torta-chocolate',
    'torta-vainilla',
    'torta-tres-leches',
    'torta-frutas',
    'torta-naranja',
    'torta-red-velvet',
    'torta-zanahoria',
    'galletas-chips-chocolate',
    'cupcakes',
    'rollos-canela',
  ])
    _foto(n),
];

/// Productos que la app sube a la colección `productos` («Cargar catálogo de
/// ejemplo» en la pestaña Productos del admin).
final List<Product> kProducts = [
  Product(
    id: 'torta-chocolate',
    image: _foto('torta-chocolate'),
    name: 'Torta de chocolate',
    category: ProductCategory.tortas,
    description:
        'Bizcocho húmedo de chocolate con cobertura de chocolate. Hecha por encargo.',
    basePrice: _especiales[0],
    art: ArtKind.chocolateCake,
    options: [_tamanos(_especiales)],
    stock: 10,
  ),
  Product(
    id: 'torta-vainilla',
    image: _foto('torta-vainilla'),
    name: 'Torta de vainilla',
    category: ProductCategory.tortas,
    description:
        'Bizcocho suave de vainilla, el sabor clásico. Hecha por encargo.',
    basePrice: _clasicos[0],
    art: ArtKind.blueCake,
    options: [_tamanos(_clasicos)],
    stock: 10,
  ),
  Product(
    id: 'torta-tres-leches',
    image: _foto('torta-tres-leches'),
    name: 'Torta tres leches',
    category: ProductCategory.tortas,
    description:
        'Bizcocho bañado en tres leches, cremoso y fresco. Hecha por encargo.',
    basePrice: _especiales[0],
    art: ArtKind.creamCake,
    options: [_tamanos(_especiales)],
    stock: 10,
  ),
  Product(
    id: 'torta-frutas',
    image: _foto('torta-frutas'),
    name: 'Torta con frutas',
    category: ProductCategory.tortas,
    description: 'Bizcocho con frutas frescas y crema. Hecha por encargo.',
    basePrice: _especiales[0],
    art: ArtKind.strawberryCake,
    options: [_tamanos(_especiales)],
    stock: 10,
  ),
  Product(
    id: 'torta-naranja',
    image: _foto('torta-naranja'),
    name: 'Torta de naranja',
    category: ProductCategory.tortas,
    description:
        'Bizcocho de naranja con un toque cítrico y aromático. Hecha por encargo.',
    basePrice: _clasicos[0],
    art: ArtKind.orangeCake,
    options: [_tamanos(_clasicos)],
    stock: 10,
  ),
  Product(
    id: 'torta-red-velvet',
    image: _foto('torta-red-velvet'),
    name: 'Torta red velvet',
    category: ProductCategory.tortas,
    description:
        'Bizcocho red velvet de color intenso con crema. Hecha por encargo.',
    basePrice: _clasicos[0],
    art: ArtKind.roseCake,
    options: [_tamanos(_clasicos)],
    stock: 10,
  ),
  Product(
    id: 'torta-zanahoria',
    image: _foto('torta-zanahoria'),
    name: 'Torta de zanahoria',
    category: ProductCategory.tortas,
    description: 'Bizcocho de zanahoria especiado y húmedo. Hecha por encargo.',
    basePrice: _especiales[0],
    art: ArtKind.orangeCake,
    options: [_tamanos(_especiales)],
    stock: 10,
  ),
  Product(
    id: 'galletas-chips-chocolate',
    image: _foto('galletas-chips-chocolate'),
    name: 'Galletas con chips de chocolate',
    category: ProductCategory.galletas,
    description:
        'Galletas con chips de chocolate, crocantes por fuera y suaves por dentro.',
    basePrice: 10000,
    art: ArtKind.cookies,
    options: [
      _cajas(6, 10000, const [6, 12, 24])
    ],
    stock: 30,
  ),
  Product(
    id: 'cupcakes',
    image: _foto('cupcakes'),
    name: 'Cupcakes',
    category: ProductCategory.cupcakes,
    description: 'Cupcakes esponjosos decorados con crema.',
    basePrice: 21000,
    art: ArtKind.cupcakes,
    options: [
      _cajas(6, 21000, const [6, 12])
    ],
    stock: 20,
  ),
  Product(
    id: 'rollos-canela',
    image: _foto('rollos-canela'),
    name: 'Rollos de canela',
    category: ProductCategory.rollos,
    description: 'Rollos de canela suaves y aromáticos, con glaseado.',
    basePrice: 12000,
    art: ArtKind.cinnamonRoll,
    options: [
      _cajas(4, 12000, const [4, 8])
    ],
    stock: 20,
  ),
];

/// Ids del catálogo de ejemplo anterior (entregas 1 a 4). «Restablecer
/// catálogo» los borra para que no queden mezclados con los productos reales.
const List<String> kLegacySampleIds = [
  'torta-fresa-silvestre',
  'brownie-doble-cacao',
  'cupcakes-duo-pastel',
  'galletas-mantequilla',
  'torta-rosa-frutos',
  'torta-azul-vainilla',
];
