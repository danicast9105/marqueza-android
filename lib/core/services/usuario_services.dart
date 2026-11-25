import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/ruta.dart';
import '../../core/services/api_service.dart';
import '../../data/model/usuario.dart';

/// Implementa las operaciones de usuarios disponibles en la API.
class UsuarioService {
  /// Obtiene la lista de usuarios y convierte cada elemento al modelo Usuario.
  static Future<List<Usuario>> getUsuarios() async {
    final r = await ApiService.get("${Ruta.baseUrl}usuarios");

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('Error al cargar usuarios (${r.statusCode}): ${r.body}');
    }

    final dynamic decoded = json.decode(r.body);
    final dynamic lista = decoded is List
        ? decoded
        : decoded is Map
        ? decoded['usuarios'] ??
              decoded['datos'] ??
              decoded['data'] ??
              decoded['value'] ??
              decoded['resultado']
        : null;
    if (lista is! List) {
      throw const FormatException(
        'La respuesta de usuarios no contiene una lista JSON válida',
      );
    }

    return lista.map((item) {
      if (item is! Map) {
        throw const FormatException(
          'La respuesta contiene un usuario con formato inválido',
        );
      }
      return Usuario.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  /// Registra un usuario y devuelve el mensaje enviado por la API.
  static Future<String> registrar(Map<String, dynamic> data) async {
    final r = await ApiService.post("${Ruta.baseUrl}usuarios/", data);
    dynamic res;
    // Convierte el cuerpo JSON y produce un error explícito si no es válido.
    try {
      res = json.decode(r.body);
    } on FormatException {
      throw Exception(
        'La API devolvió HTTP ${r.statusCode} con una respuesta no JSON: ${r.body}',
      );
    }

    // La API puede nombrar el mensaje de respuesta de distintas maneras.
    final mensaje = res is Map
        ? res['respuesta'] ?? res['mensaje'] ?? res['message'] ?? res['error']
        : null;

    // Convierte cualquier estado HTTP fuera del rango 2xx en un error.
    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception(
        mensaje?.toString() ?? 'Error HTTP ${r.statusCode}: ${r.body}',
      );
    }
    if (mensaje is String) return mensaje;

    // Un registro exitoso también debe incluir un mensaje en la respuesta.
    throw FormatException(
      'La respuesta de registro no contiene "respuesta": ${r.body}',
    );
  }

  /// Actualiza los campos de un usuario usando el método PUT documentado.
  static Future<String> editar(Map<String, dynamic> data, int id) async {
    final r = await ApiService.put("${Ruta.baseUrl}usuarios/$id", data);
    return _mensajeRespuesta(r);
  }

  /// Elimina el usuario indicado y devuelve el mensaje de la API.
  static Future<String> eliminar(int id) async {
    final r = await ApiService.delete("${Ruta.baseUrl}usuarios/$id");
    return _mensajeRespuesta(r);
  }

  static String _mensajeRespuesta(http.Response response) {
    dynamic res;
    try {
      res = json.decode(response.body);
    } on FormatException {
      res = null;
    }

    final mensaje = res is Map
        ? res['respuesta'] ?? res['mensaje'] ?? res['message'] ?? res['error']
        : null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        mensaje?.toString() ??
            'Error HTTP ${response.statusCode}: ${response.body}',
      );
    }
    return mensaje?.toString() ?? 'Operación completada correctamente.';
  }
}
