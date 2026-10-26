// Pantalla de acceso: inicio de sesión y registro de clientes.

import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/services.dart';
import '../widgets/product_widgets.dart';

/// Inicio de sesión y registro con correo y contraseña.
class LoginScreen extends StatefulWidget {
  /// Crea la pantalla usando [auth]. Con [showDemoAccounts] se listan las
  /// cuentas del modo demo.
  const LoginScreen({
    super.key,
    required this.auth,
    this.showDemoAccounts = false,
  });

  final AuthService auth;
  final bool showDemoAccounts;

  /// Crea el estado que conserva el modo (entrar/registrarse) y los campos.
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  /// Libera los controladores de texto.
  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Valida el formulario y llama al servicio de autenticación. Si todo sale
  /// bien no hace falta navegar: la puerta de acceso cambia de pantalla sola.
  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        await widget.auth.register(
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          password: _password.text,
        );
      } else {
        await widget.auth.signIn(
          email: _email.text,
          password: _password.text,
        );
      }
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Ocurrió un error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Decoración común de los campos con el estilo del buscador de Explorar.
  InputDecoration _decoration(String label, IconData icon) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color),
        );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: KekiColors.text2),
      prefixIcon: Icon(icon, size: 20, color: KekiColors.text2),
      filled: true,
      fillColor: KekiColors.bg,
      border: border(KekiColors.border),
      enabledBorder: border(KekiColors.border),
      focusedBorder: border(KekiColors.blue),
    );
  }

  /// Construye la marca, el selector de modo, los campos y el botón.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [KekiColors.blueTint, Colors.white, KekiColors.pinkTint],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _Brand(),
                      const SizedBox(height: 28),
                      _ModeSwitch(
                        register: _register,
                        onChanged: (v) => setState(() {
                          _register = v;
                          _error = null;
                        }),
                      ),
                      const SizedBox(height: 20),
                      if (_register) ...[
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: _decoration(
                              'Nombre completo', Icons.person_outline_rounded),
                          validator: (v) => (v ?? '').trim().length < 3
                              ? 'Escribe tu nombre'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration:
                              _decoration('Celular', Icons.phone_outlined),
                          validator: (v) => (v ?? '').trim().length < 7
                              ? 'Escribe un número de contacto'
                              : null,
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        decoration: _decoration(
                            'Correo electrónico', Icons.mail_outline_rounded),
                        validator: (v) {
                          final value = (v ?? '').trim();
                          return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(value)
                              ? null
                              : 'Escribe un correo válido';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: _decoration(
                                'Contraseña', Icons.lock_outline_rounded)
                            .copyWith(
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 20,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) =>
                            (v ?? '').length < 6 ? 'Mínimo 6 caracteres' : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBEDED),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                fontSize: 12.5, color: Color(0xFFC24E4E)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      GradientButton(
                        label: _busy
                            ? 'Un momento…'
                            : _register
                                ? 'Crear cuenta'
                                : 'Iniciar sesión',
                        onPressed: _submit,
                      ),
                      if (widget.showDemoAccounts) ...[
                        const SizedBox(height: 20),
                        const _DemoAccounts(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  /// Crea el logo y el nombre de la marca.
  const _Brand();

  /// Dibuja el icono con degradado, «Keki Keki» y el lema.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [KekiColors.blue, KekiColors.pink],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: KekiShadows.card,
          ),
          child: const Icon(Icons.cake_outlined, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 14),
        const Text.rich(
          TextSpan(
            text: 'Keki ',
            style: TextStyle(color: KekiColors.pinkDeep),
            children: [
              TextSpan(
                text: 'Keki',
                style: TextStyle(color: KekiColors.blueDeep),
              ),
            ],
          ),
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        const Text(
          'PASTELERÍA INTELIGENTE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2.4,
            fontWeight: FontWeight.w600,
            color: KekiColors.text2,
          ),
        ),
      ],
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  /// Crea el selector entre «Iniciar sesión» y «Crear cuenta».
  const _ModeSwitch({required this.register, required this.onChanged});

  final bool register;
  final ValueChanged<bool> onChanged;

  /// Construye una de las dos opciones del selector.
  Widget _option(String label, bool value) {
    final selected = register == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected ? KekiShadows.card : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? KekiColors.blueDeep : KekiColors.text2,
            ),
          ),
        ),
      ),
    );
  }

  /// Dibuja las dos opciones sobre un fondo suave.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: KekiColors.blueTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _option('Iniciar sesión', false),
          _option('Crear cuenta', true),
        ],
      ),
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  /// Crea el recuadro con las cuentas del modo demo.
  const _DemoAccounts();

  /// Lista las credenciales de cliente y administrador.
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: KekiColors.pinkTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Modo demo (sin Firebase)\n'
        'Cliente: cliente@keki.co · 123456\n'
        'Admin: admin@keki.co · 123456',
        style: TextStyle(fontSize: 12, height: 1.6),
      ),
    );
  }
}
