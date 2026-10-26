// Barra de navegación inferior de los mockups y pantalla de marcador de
// posición, compartidas por la app del cliente y la del administrador.

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Datos de una pestaña: icono, etiqueta y contador opcional.
class NavEntry {
  /// Crea una pestaña con [icon], [label] y un [badge] (0 lo oculta).
  const NavEntry(this.icon, this.label, {this.badge = 0});

  final IconData icon;
  final String label;
  final int badge;
}

/// Barra inferior con cuatro pestañas y el botón central del asistente.
class KekiBottomNav extends StatelessWidget {
  /// Crea la barra; [items] debe tener cuatro pestañas (dos a cada lado).
  const KekiBottomNav({
    super.key,
    required this.items,
    required this.current,
    required this.onSelect,
    required this.onFab,
  }) : assert(items.length == 4);

  final List<NavEntry> items;
  final int current;
  final ValueChanged<int> onSelect;
  final VoidCallback onFab;

  /// Construye la pestaña [i] de [items].
  Widget _item(int i) => _NavItem(
        entry: items[i],
        selected: current == i,
        onTap: () => onSelect(i),
      );

  /// Dibuja las pestañas y el acceso central al asistente de IA.
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F3F5))),
      ),
      child: SafeArea(
        top: false,
        child: Material(
          type: MaterialType.transparency,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                _item(0),
                _item(1),
                Expanded(
                  child: Center(
                    child: Transform.translate(
                      offset: const Offset(0, -10),
                      child: _AiFab(onTap: onFab),
                    ),
                  ),
                ),
                _item(2),
                _item(3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  /// Crea una pestaña de navegación con icono, etiqueta y contador opcional.
  const _NavItem({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final NavEntry entry;
  final bool selected;
  final VoidCallback onTap;

  /// Dibuja el elemento y ejecuta [onTap] al seleccionarlo.
  @override
  Widget build(BuildContext context) {
    final color = selected ? KekiColors.blueDeep : const Color(0xFFB9C0C6);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(entry.icon, size: 22, color: color),
                if (entry.badge > 0)
                  Positioned(
                    right: -9,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: KekiColors.pinkDeep,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${entry.badge}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiFab extends StatelessWidget {
  /// Crea el botón decorativo que representa el asistente de IA.
  const _AiFab({required this.onTap});

  final VoidCallback onTap;

  /// Dibuja el botón y ejecuta la acción asociada cuando se toca.
  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(15);
    return Tooltip(
      message: 'Asistente Keki IA',
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [KekiColors.blue, KekiColors.pink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0xB392C7E1),
              blurRadius: 20,
              spreadRadius: -8,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child:
                const Icon(Icons.auto_awesome, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Pantalla informativa para secciones vacías o aún no implementadas.
class InfoPlaceholder extends StatelessWidget {
  /// Crea el mensaje con [icon], [title], [message] y una acción opcional.
  const InfoPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Botón opcional bajo el mensaje (por ejemplo, «Reintentar»).
  final Widget? action;

  /// Centra el icono, título y explicación del marcador de posición.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: KekiColors.blue),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: KekiColors.text2),
              ),
              if (action != null) ...[
                const SizedBox(height: 12),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
