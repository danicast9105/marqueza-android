import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/ruta.dart';
import 'api_service.dart';

/// Mantiene la sesión de la aplicación y se comunica con la API de acceso.
class AuthService {
  static String? nombreUsuario;
  static bool sesionActiva = false;
  static String? tokenAcceso;

  static const _claveSesionActiva = 'auth.sesionActiva';
  static const _claveNombreUsuario = 'auth.nombreUsuario';
  static const _claveTokenAcceso = 'auth.tokenAcceso';

  /// Valida las credenciales usando el endpoint de autenticación.
  static Future<void> iniciarSesion(
    String usuario,
    String contrasena, {
    bool recordarSesion = false,
  }) async {
    final response = await ApiService.post('${Ruta.baseUrl}auth/login', {
      'usuario': usuario.trim(),
      'contrasena': contrasena,
    });

    dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final mensaje = decoded is Map
          ? decoded['respuesta'] ??
                decoded['mensaje'] ??
                decoded['message'] ??
                decoded['error']
          : null;
      throw Exception(
        mensaje?.toString() ??
            'No se pudo iniciar sesión (HTTP ${response.statusCode}).',
      );
    }

    if (decoded is! Map) {
      throw const FormatException(
        'La API devolvió una respuesta de inicio de sesión inválida.',
      );
    }

    final token = decoded['token'];
    if (token is! String || token.trim().isEmpty) {
      throw const FormatException(
        'La API no devolvió un token de acceso válido.',
      );
    }

    final usuarioRespuesta = decoded['usuario'] ?? decoded['user'] ?? decoded;
    String nombre;
    if (usuarioRespuesta is Map) {
      final nombreRespuesta =
          usuarioRespuesta['nombre'] ??
          usuarioRespuesta['usuario'] ??
          usuarioRespuesta['correo'] ??
          usuarioRespuesta['email'];
      nombre = nombreRespuesta is String && nombreRespuesta.trim().isNotEmpty
          ? nombreRespuesta.trim()
          : usuario.trim();
    } else {
      nombre = usuario.trim();
    }

    final preferencias = await SharedPreferences.getInstance();
    if (recordarSesion) {
      await preferencias.setString(_claveNombreUsuario, nombre);
      await preferencias.setBool(_claveSesionActiva, true);
      await preferencias.setString(_claveTokenAcceso, token);
    } else {
      await preferencias.remove(_claveNombreUsuario);
      await preferencias.remove(_claveSesionActiva);
      await preferencias.remove(_claveTokenAcceso);
    }

    nombreUsuario = nombre;
    tokenAcceso = token;
    ApiService.setBearerToken(token);
    sesionActiva = true;
  }

  /// Recupera la sesión guardada, si el usuario eligió recordarla.
  static Future<void> restaurarSesion() async {
    final preferencias = await SharedPreferences.getInstance();
    final tokenGuardado = preferencias.getString(_claveTokenAcceso);
    sesionActiva =
        (preferencias.getBool(_claveSesionActiva) ?? false) &&
        tokenGuardado != null &&
        tokenGuardado.trim().isNotEmpty;
    nombreUsuario = sesionActiva
        ? preferencias.getString(_claveNombreUsuario)
        : null;
    tokenAcceso = sesionActiva ? tokenGuardado : null;
    ApiService.setBearerToken(tokenAcceso);

    if (!sesionActiva) {
      await preferencias.remove(_claveSesionActiva);
      await preferencias.remove(_claveNombreUsuario);
      await preferencias.remove(_claveTokenAcceso);
    }
  }

  /// Solicita a la API enviar un enlace para restablecer la contraseña.
  static Future<String> solicitarRecuperacion(String correo) async {
    final response = await ApiService.post(
      '${Ruta.baseUrl}auth/forgot-password',
      {'correo': correo.trim()},
    );

    dynamic decoded;
    try {
      decoded = json.decode(response.body);
    } on FormatException {
      decoded = null;
    }

    final mensaje = decoded is Map
        ? decoded['respuesta'] ??
              decoded['mensaje'] ??
              decoded['message'] ??
              decoded['error']
        : null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        mensaje?.toString() ??
            'No se pudo solicitar la recuperación '
                '(HTTP ${response.statusCode}).',
      );
    }
    return mensaje?.toString() ??
        'Si el correo está registrado, recibirás instrucciones para recuperar el acceso.';
  }

  /// Descarta los datos locales de la sesión actual.
  static Future<void> cerrarSesion() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_claveSesionActiva);
    await preferencias.remove(_claveNombreUsuario);
    await preferencias.remove(_claveTokenAcceso);
    nombreUsuario = null;
    tokenAcceso = null;
    ApiService.setBearerToken(null);
    sesionActiva = false;
  }
}
