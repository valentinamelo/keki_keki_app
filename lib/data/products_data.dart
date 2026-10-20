import '../models/product.dart';

// ---------------------------------------------------------------------------
// Datos de ejemplo (en memoria). Nombres, precios base y calificaciones salen
// de los mockups; los recargos de cada opción son valores de muestra y se
// pueden editar aquí sin tocar la interfaz.
// ---------------------------------------------------------------------------

/// Tamaños de torta. [basePersons] es el tamaño al que corresponde el precio
/// base; los demás se ajustan con una tabla de recargos de ejemplo.
OptionGroup _tamanos(int basePersons) {
  const persons = [10, 15, 20, 30];
  const table = {10: 0, 15: 10000, 20: 25000, 30: 45000};
  return OptionGroup(
    id: 'tamano',
    title: 'Tamaño',
    defaultIndex: persons.indexOf(basePersons),
    choices: [
      for (final p in persons)
        OptionChoice('$p pers.', extra: table[p]! - table[basePersons]!),
    ],
  );
}

OptionGroup _sabores({int defaultIndex = 0}) => OptionGroup(
      id: 'sabor',
      title: 'Sabor',
      defaultIndex: defaultIndex,
      choices: const [
        OptionChoice('Vainilla'),
        OptionChoice('Chocolate'),
        OptionChoice('Red velvet'),
      ],
    );

OptionGroup _rellenos() => const OptionGroup(
      id: 'relleno',
      title: 'Relleno & decoración',
      choices: [
        OptionChoice('Frutos rojos'),
        OptionChoice('Arequipe', extra: 3000),
        OptionChoice('Flores naturales', extra: 4000),
      ],
    );

OptionGroup _presentacion(List<OptionChoice> choices) => OptionGroup(
      id: 'presentacion',
      title: 'Presentación',
      choices: choices,
    );

final List<Product> kProducts = [
  Product(
    id: 'torta-fresa-silvestre',
    name: 'Torta fresa silvestre',
    category: ProductCategory.tortas,
    description:
        'Bizcocho esponjoso con fresas silvestres y crema chantillí, decorado a mano.',
    basePrice: 72000,
    rating: 4.9,
    art: ArtKind.strawberryCake,
    options: [_tamanos(15), _sabores(), _rellenos()],
  ),
  Product(
    id: 'brownie-doble-cacao',
    name: 'Brownie doble cacao',
    category: ProductCategory.brownies,
    description:
        'Brownies húmedos de doble chocolate, con centro suave y borde crocante.',
    basePrice: 18000,
    rating: 4.7,
    art: ArtKind.brownie,
    options: [
      _presentacion(const [
        OptionChoice('Caja x4'),
        OptionChoice('Caja x8', extra: 16000),
      ]),
    ],
  ),
  Product(
    id: 'cupcakes-duo-pastel',
    name: 'Cupcakes duo pastel',
    category: ProductCategory.cupcakes,
    description:
        'Cupcakes de vainilla con crema en tonos azul y rosa pastel.',
    basePrice: 22000,
    rating: 4.5,
    art: ArtKind.cupcakes,
    options: [
      _presentacion(const [
        OptionChoice('Caja x6'),
        OptionChoice('Caja x12', extra: 20000),
      ]),
    ],
  ),
  Product(
    id: 'galletas-mantequilla',
    name: 'Galletas de mantequilla',
    category: ProductCategory.galletas,
    description:
        'Galletas artesanales de mantequilla, crocantes por fuera y suaves por dentro.',
    basePrice: 15000,
    rating: 4.6,
    art: ArtKind.cookies,
    options: [
      _presentacion(const [
        OptionChoice('Caja x6'),
        OptionChoice('Caja x12', extra: 13000),
      ]),
    ],
  ),
  Product(
    id: 'torta-rosa-frutos',
    name: 'Torta rosa de frutos',
    detailName: 'Torta Rosa de Frutos Silvestres',
    category: ProductCategory.tortas,
    description:
        'Bizcocho de vainilla húmedo relleno de frutos rojos frescos y crema chantillí. '
        'Decoración artesanal con flores comestibles.',
    highlight: 'Elaborada el mismo día de tu pedido.',
    basePrice: 65000,
    rating: 4.8,
    reviewCount: 212,
    noPreservatives: true,
    art: ArtKind.roseCake,
    options: [_tamanos(15), _sabores(), _rellenos()],
  ),
  Product(
    id: 'torta-azul-vainilla',
    name: 'Torta azul vainilla',
    category: ProductCategory.tortas,
    description:
        'Bizcocho de vainilla suave con cobertura de crema azul pastel.',
    basePrice: 58000,
    rating: 4.6,
    art: ArtKind.blueCake,
    options: [_tamanos(15), _sabores(), _rellenos()],
  ),
  Product(
    id: 'torta-chocolate',
    name: 'Torta de chocolate',
    category: ProductCategory.tortas,
    description:
        'Bizcocho de chocolate relleno de frutos rojos, con decoración floral.',
    basePrice: 78000,
    art: ArtKind.chocolateCake,
    options: [_tamanos(20), _sabores(defaultIndex: 1), _rellenos()],
  ),
];
