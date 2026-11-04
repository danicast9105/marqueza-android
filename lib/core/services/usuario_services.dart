import 'dart:convert';

import '../../core/config/ruta.dart';
import '../../core/services/api_service.dart';
import '../../data/model/usuario.dart';

class UsuarioService {
  static Future<List<Usuario>> getUsuarios() async {
    final r = await ApiService.get("${Ruta.baseUrl}usuarios");

    if (r.statusCode == 200) {
      final dynamic decoded = json.decode(r.body);
      if (decoded is! List) {
        throw const FormatException(
          'La respuesta de usuarios no es una lista JSON',
        );
      }
      return decoded.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException(
            'La respuesta contiene un usuario con formato inválido',
          );
        }
        return Usuario.fromJson(item);
      }).toList();
    }

    throw Exception('Error al cargar usuarios (${r.statusCode}): ${r.body}');
  }

  static Future<String> registrar(Map<String, dynamic> data) async {
    final r = await ApiService.post("${Ruta.baseUrl}usuarios/", data);
    dynamic res;
    try {
      res = json.decode(r.body);
    } on FormatException {
      throw Exception(
        'La API devolvió HTTP ${r.statusCode} con una respuesta no JSON: ${r.body}',
      );
    }

    final mensaje = res is Map
      ? res['respuesta'] ?? res['mensaje'] ?? res['message'] ?? res['error']
        : null;

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception(
        mensaje?.toString() ?? 'Error HTTP ${r.statusCode}: ${r.body}',
      );
    }
    if (mensaje is String) return mensaje;

    throw FormatException(
      'La respuesta de registro no contiene "respuesta": ${r.body}',
    );
  }

  static Future<String> editar(Map data, int id) async {
    final r = await ApiService.post("${Ruta.baseUrl}usuarios/$id", data);
    final res = json.decode(r.body);
    return res["respuesta"];
  }

  static Future<String> eliminar(int id) async {
    final r = await ApiService.delete("${Ruta.baseUrl}usuarios/$id");
    final res = json.decode(r.body);
    return res["respuesta"];
  }
}
