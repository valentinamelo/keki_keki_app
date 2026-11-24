// Formulario del administrador para crear o editar un producto.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/snack.dart';
import '../../core/theme.dart';
import '../../models/product.dart';
import '../../state/app_scope.dart';
import '../../data/products_data.dart';
import '../../widgets/product_art.dart';
import '../../widgets/product_widgets.dart';

/// Crea un producto (si [product] es `null`) o edita uno existente,
/// incluidos sus grupos de opciones con los recargos de cada alternativa.
class ProductFormScreen extends StatefulWidget {
  /// Crea el formulario; con [product] se precargan sus datos.
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  /// Crea el estado con los campos editables.
  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

/// Alternativa editable dentro de un grupo de opciones.
class _ChoiceDraft {
  _ChoiceDraft([String label = '', int extra = 0])
      : label = TextEditingController(text: label),
        extra = TextEditingController(text: extra == 0 ? '' : '$extra');

  final TextEditingController label;
  final TextEditingController extra;

  void dispose() {
    label.dispose();
    extra.dispose();
  }
}

/// Grupo de opciones editable (por ejemplo «Tamaño»).
class _GroupDraft {
  _GroupDraft(
      {this.id = '',
      String title = '',
      List<_ChoiceDraft>? choices,
      this.defaultIndex = 0})
      : title = TextEditingController(text: title),
        choices = choices ?? [_ChoiceDraft()];

  /// Crea el borrador a partir de un grupo guardado.
  factory _GroupDraft.from(OptionGroup g) => _GroupDraft(
        id: g.id,
        title: g.title,
        defaultIndex: g.defaultIndex,
        choices: [for (final c in g.choices) _ChoiceDraft(c.label, c.extra)],
      );

  String id;
  final TextEditingController title;
  final List<_ChoiceDraft> choices;
  int defaultIndex;

  void dispose() {
    title.dispose();
    for (final c in choices) {
      c.dispose();
    }
  }
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Product? _original = widget.product;
  late final _name = TextEditingController(text: _original?.name);
  late final _detailName = TextEditingController(text: _original?.detailName);
  late final _description = TextEditingController(text: _original?.description);
  late final _highlight = TextEditingController(text: _original?.highlight);
  late final _price = TextEditingController(
      text: _original == null ? '' : '${_original?.basePrice}');
  late final _stock = TextEditingController(text: '${_original?.stock ?? 10}');
  late ProductCategory _category =
      _original?.category ?? ProductCategory.tortas;
  late ArtKind _art = _original?.art ?? ArtKind.roseCake;
  late String? _image = _original?.image;
  late bool _noPreservatives = _original?.noPreservatives ?? false;
  late bool _active = _original?.active ?? true;
  late final List<_GroupDraft> _groups = [
    for (final g in _original?.options ?? const <OptionGroup>[])
      _GroupDraft.from(g),
  ];
  bool _saving = false;

  /// Libera todos los controladores de texto.
  @override
  void dispose() {
    for (final c in [
      _name,
      _detailName,
      _description,
      _highlight,
      _price,
      _stock,
    ]) {
      c.dispose();
    }
    for (final g in _groups) {
      g.dispose();
    }
    super.dispose();
  }

  /// Convierte un título en un id simple: «Relleno & decoración» → «relleno-decoracion».
  static String _slug(String text) {
    const from = 'áàäâéèëêíìïîóòöôúùüûñ';
    const to = 'aaaaeeeeiiiioooouuuun';
    final buffer = StringBuffer();
    for (final ch in text.toLowerCase().split('')) {
      final i = from.indexOf(ch);
      buffer.write(i >= 0 ? to[i] : ch);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  /// Arma el [Product] con los valores del formulario.
  Product _buildProduct() {
    final usedIds = <String>{};
    final options = <OptionGroup>[];
    for (final g in _groups) {
      var id = g.id.isNotEmpty ? g.id : _slug(g.title.text);
      if (id.isEmpty) id = 'opcion';
      // Dos grupos no pueden compartir id: se le agrega un número.
      var unique = id;
      for (var n = 2; usedIds.contains(unique); n++) {
        unique = '$id-$n';
      }
      usedIds.add(unique);
      options.add(OptionGroup(
        id: unique,
        title: g.title.text.trim(),
        defaultIndex: g.defaultIndex.clamp(0, g.choices.length - 1),
        choices: [
          for (final c in g.choices)
            OptionChoice(
              c.label.text.trim(),
              extra: int.tryParse(c.extra.text) ?? 0,
            ),
        ],
      ));
    }
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();

    return Product(
      id: _original?.id ?? '',
      name: _name.text.trim(),
      detailName: optional(_detailName),
      category: _category,
      description: _description.text.trim(),
      highlight: optional(_highlight),
      basePrice: int.parse(_price.text),
      rating: _original?.rating,
      reviewCount: _original?.reviewCount,
      noPreservatives: _noPreservatives,
      art: _art,
      image: _image,
      options: options,
      active: _active,
      stock: int.parse(_stock.text),
      sortOrder: _original?.sortOrder ?? 0,
    );
  }

  /// Valida y guarda; al terminar vuelve a la lista.
  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      showKekiSnack(context, 'Revisa los campos marcados');
      return;
    }
    setState(() => _saving = true);
    try {
      final product = _buildProduct();
      await AppScope.of(context).services.products.save(product);
      if (!mounted) return;
      showKekiSnack(
        context,
        _original == null
            ? '${product.name} creado'
            : 'Cambios guardados en ${product.name}',
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showKekiSnack(context, 'No se pudo guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Decoración común de los campos.
  InputDecoration _decoration(String label, {String? hint, String? prefix}) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      isDense: true,
      filled: true,
      fillColor: KekiColors.bg,
      labelStyle: const TextStyle(fontSize: 13, color: KekiColors.text2),
      border: border(KekiColors.border),
      enabledBorder: border(KekiColors.border),
      focusedBorder: border(KekiColors.blue),
    );
  }

  /// Título de cada sección del formulario.
  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      );

  /// Valida un número entero mayor o igual que [min].
  String? Function(String?) _intValidator(String label, {int min = 0}) => (v) {
        final n = int.tryParse(v ?? '');
        if (n == null) return 'Escribe $label';
        if (n < min) return 'Debe ser al menos $min';
        return null;
      };

  /// Construye todas las secciones y la barra para guardar.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          _original == null ? 'Nuevo producto' : 'Editar producto',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFF1F3F5))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            // Altura fija: sin ella el botón ocuparía toda la pantalla.
            child: SizedBox(
              height: 56,
              child: GradientButton(
                label: _saving
                    ? 'Guardando…'
                    : _original == null
                        ? 'Crear producto'
                        : 'Guardar cambios',
                onPressed: _save,
              ),
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            _section('Foto'),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: kProductImages.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final path = i == 0 ? null : kProductImages[i - 1];
                  final selected = path == _image;
                  return Semantics(
                    button: true,
                    selected: selected,
                    label: path == null ? 'Sin foto' : 'Foto $i',
                    child: GestureDetector(
                      onTap: () => setState(() => _image = path),
                      child: Container(
                        width: 64,
                        decoration: BoxDecoration(
                          color: KekiColors.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? KekiColors.blueDeep
                                : const Color(0xFFEEF1F4),
                            width: selected ? 2.5 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: path == null
                            ? const Center(
                                child: Text(
                                  'Sin foto',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 10.5, color: KekiColors.text2),
                                ),
                              )
                            : ProductArt(kind: _art, image: path),
                      ),
                    ),
                  );
                },
              ),
            ),
            _section('Ilustración (si no tiene foto)'),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ArtKind.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final kind = ArtKind.values[i];
                  final selected = kind == _art;
                  return GestureDetector(
                    onTap: () => setState(() => _art = kind),
                    child: Container(
                      width: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? KekiColors.blueDeep
                              : const Color(0xFFEEF1F4),
                          width: selected ? 2.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ProductArt(kind: kind),
                    ),
                  );
                },
              ),
            ),
            _section('Datos del producto'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Nombre', hint: 'Torta de chocolate'),
              validator: (v) =>
                  (v ?? '').trim().length < 3 ? 'Escribe el nombre' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _detailName,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Nombre largo en el detalle (opcional)'),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in ProductCategory.values)
                  ChoiceChip(
                    label: Text(c.label),
                    selected: c == _category,
                    onSelected: (_) => setState(() => _category = c),
                    selectedColor: KekiColors.blueTint,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _description,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Descripción'),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Escribe una descripción' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _highlight,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration('Frase destacada (opcional)',
                  hint: 'Elaborada el mismo día de tu pedido.'),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration('Precio base', prefix: '\$ '),
                    validator: _intValidator('el precio', min: 1000),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _stock,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _decoration('Stock'),
                    validator: _intValidator('el stock'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _active,
              onChanged: (v) => setState(() => _active = v),
              activeTrackColor: KekiColors.blue,
              title: const Text('Visible para los clientes',
                  style: TextStyle(fontSize: 13.5)),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _noPreservatives,
              onChanged: (v) => setState(() => _noPreservatives = v),
              activeTrackColor: KekiColors.blue,
              title: const Text('Sin conservantes',
                  style: TextStyle(fontSize: 13.5)),
            ),
            _section('Opciones de personalización'),
            const Text(
              'Cada grupo aparece en el detalle (por ejemplo Tamaño o Sabor). '
              'El recargo se suma al precio base; marca con el círculo la '
              'opción que viene elegida.',
              style: TextStyle(fontSize: 11.5, color: KekiColors.text2),
            ),
            const SizedBox(height: 10),
            for (var g = 0; g < _groups.length; g++)
              _GroupEditor(
                key: ObjectKey(_groups[g]),
                group: _groups[g],
                decoration: _decoration,
                onChanged: () => setState(() {}),
                onRemove: () => setState(() {
                  _groups.removeAt(g).dispose();
                }),
              ),
            OutlinedButton.icon(
              onPressed: () => setState(() => _groups.add(_GroupDraft())),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar grupo de opciones'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupEditor extends StatelessWidget {
  /// Crea el editor de un grupo con sus alternativas.
  const _GroupEditor({
    super.key,
    required this.group,
    required this.decoration,
    required this.onChanged,
    required this.onRemove,
  });

  final _GroupDraft group;
  final InputDecoration Function(String label, {String? hint, String? prefix})
      decoration;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  /// Dibuja el título, cada alternativa con su recargo y los botones.
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF1F4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: group.title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: decoration('Nombre del grupo', hint: 'Tamaño'),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Escribe el nombre' : null,
                ),
              ),
              IconButton(
                tooltip: 'Quitar grupo',
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFC24E4E)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // El círculo marca la opción que viene elegida por defecto.
          RadioGroup<int>(
            groupValue: group.defaultIndex,
            onChanged: (v) {
              group.defaultIndex = v ?? 0;
              onChanged();
            },
            child: Column(
              children: [
                for (var i = 0; i < group.choices.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Radio<int>(value: i),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: group.choices[i].label,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: decoration('Opción', hint: '15 pers.'),
                            validator: (v) =>
                                (v ?? '').trim().isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: group.choices[i].extra,
                            keyboardType: const TextInputType.numberWithOptions(
                                signed: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^-?\d*')),
                            ],
                            decoration: decoration('Recargo', prefix: '\$ '),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Quitar opción',
                          onPressed: group.choices.length == 1
                              ? null
                              : () {
                                  group.choices.removeAt(i).dispose();
                                  if (group.defaultIndex >=
                                      group.choices.length) {
                                    group.defaultIndex = 0;
                                  }
                                  onChanged();
                                },
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                group.choices.add(_ChoiceDraft());
                onChanged();
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Agregar opción'),
            ),
          ),
        ],
      ),
    );
  }
}
