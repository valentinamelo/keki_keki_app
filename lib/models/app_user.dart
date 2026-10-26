// Modelo del usuario autenticado y de su rol dentro de la aplicación.

/// Rol guardado en la colección `usuarios`; decide qué interfaz se muestra.
enum UserRole {
  cliente,
  admin;

  /// Interpreta el campo `rol` de Firestore; cualquier otro valor es cliente.
  static UserRole fromName(Object? name) =>
      name == 'admin' ? UserRole.admin : UserRole.cliente;
}

/// Perfil del usuario: datos de la cuenta más los guardados en `usuarios/{uid}`.
class AppUser {
  /// Crea un perfil con su identificador, datos de contacto y rol.
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.phone = '',
    this.role = UserRole.cliente,
  });

  final String uid;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  /// Indica si el usuario debe ver la interfaz de administración.
  bool get isAdmin => role == UserRole.admin;

  /// Primera letra del nombre, usada en los avatares.
  String get initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  /// Primer nombre, para saludos como «Hola, Valentina».
  String get firstName => name.trim().split(' ').first;

  /// Convierte el perfil al documento de la colección `usuarios`.
  Map<String, dynamic> toMap() => {
        'nombre': name,
        'email': email,
        'telefono': phone,
        'rol': role.name,
      };

  /// Reconstruye el perfil a partir del documento `usuarios/[uid]`.
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        name: map['nombre'] as String? ?? '',
        email: map['email'] as String? ?? '',
        phone: map['telefono'] as String? ?? '',
        role: UserRole.fromName(map['rol']),
      );
}
