// auth_service.dart
//
// Envuelve FirebaseAuth para exponer tres operaciones (registrarse, iniciar
// sesión, cerrar sesión) y traducir los códigos de FirebaseAuthException a
// mensajes legibles para el usuario — el mismo espíritu del manejo
// diferenciado de DioException que se construyó en la Clase 21, aplicado
// ahora a errores de autenticación.

import 'package:firebase_auth/firebase_auth.dart';

/// Excepción propia de la app: envuelve el código de Firebase con un
/// mensaje en español, para que la pantalla nunca tenga que interpretar
/// códigos de error de Firebase directamente.
class AuthFailure implements Exception {
  final String mensaje;
  AuthFailure(this.mensaje);

  @override
  String toString() => mensaje;
}

class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  /// Stream del usuario autenticado actual. Emite null cuando no hay
  /// sesión activa, y un User cuando sí la hay. AuthGate (ver main.dart)
  /// se suscribe a este stream con un StreamBuilder para decidir, en cada
  /// cambio, si mostrar LoginScreen o HomeScreen.
  Stream<User?> get cambiosDeUsuario => _auth.authStateChanges();

  User? get usuarioActual => _auth.currentUser;

  Future<void> registrarse({
    required String correo,
    required String contrasena,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mensajeParaCodigo(e.code));
    }
  }

  Future<void> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: correo.trim(),
        password: contrasena,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_mensajeParaCodigo(e.code));
    }
  }

  Future<void> cerrarSesion() => _auth.signOut();

  /// Traduce los códigos más comunes de FirebaseAuthException. La lista no
  /// es exhaustiva a propósito: es un ejemplo de manejo diferenciado de
  /// errores, no un mapeo completo de la documentación oficial.
  String _mensajeParaCodigo(String codigo) {
    switch (codigo) {
      case 'email-already-in-use':
        return 'Ya existe una cuenta registrada con ese correo.';
      case 'invalid-email':
        return 'El correo electrónico no tiene un formato válido.';
      case 'weak-password':
        return 'La contraseña es demasiado débil (mínimo 6 caracteres).';
      case 'user-not-found':
        return 'No existe ninguna cuenta registrada con ese correo.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'user-disabled':
        return 'Esta cuenta fue deshabilitada. Contacta al administrador.';
      case 'too-many-requests':
        return 'Demasiados intentos fallidos. Intenta de nuevo más tarde.';
      default:
        return 'No se pudo completar la operación (código: $codigo).';
    }
  }
}
