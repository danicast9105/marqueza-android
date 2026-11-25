import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/ruta.dart';
import '../../data/model/modulo_api.dart';
import 'api_service.dart';

/// Lee y modifica los recursos configurados en la documentación de la API.
class RecursoApiService {
  /// Descarga una colección, admitiendo listas directas o envolturas JSON.
  static Future<List<Map<String, dynamic>>> listar(ModuloApi modulo) async {
    final response = await ApiService.get(
      '${Ruta.baseUrl}${modulo.endpoint}/',
    );
    _validarRespuesta(response);
    if (response.body.trim().isEmpty) return [];

    final dynamic decoded = json.decode(response.body);
    if (decoded == null) return [];
    dynamic lista = decoded;
    if (decoded is Map) {
      lista =
          decoded[modulo.endpoint] ??
          decoded['datos'] ??
          decoded['data'] ??
          decoded['resultado'] ??
          decoded['value'];
      if (lista == null) {
        for (final valor in decoded.values) {
          if (valor is List) {
            lista = valor;
            break;
          }
        }
      }
    }

    if (lista is! List) {
      throw FormatException(
        'La API no devolvió una lista válida para ${modulo.titulo}.',
      );
    }

    return lista
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// Crea un registro con el objeto JSON recibido del formulario.
  static Future<String> crear(
    ModuloApi modulo,
    Map<String, dynamic> datos,
  ) async {
    final response = await ApiService.post(
      '${Ruta.baseUrl}${modulo.endpoint}/',
      datos,
    );
    return _mensajeRespuesta(response);
  }

  /// Actualiza un registro mediante el identificador de ruta documentado.
  static Future<String> actualizar(
    ModuloApi modulo,
    int id,
    Map<String, dynamic> datos,
  ) async {
    final response = await ApiService.put(
      '${Ruta.baseUrl}${modulo.endpoint}/$id',
      datos,
    );
    return _mensajeRespuesta(response);
  }

  /// Elimina un registro mediante el identificador de ruta documentado.
  static Future<String> eliminar(ModuloApi modulo, int id) async {
    final response = await ApiService.delete(
      '${Ruta.baseUrl}${modulo.endpoint}/$id',
    );
    return _mensajeRespuesta(response);
  }

  static void _validarRespuesta(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
    }
  }

  static String _mensajeRespuesta(http.Response response) {
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
            'Error HTTP ${response.statusCode}: ${response.body}',
      );
    }
    return mensaje?.toString() ?? 'Operación completada correctamente.';
  }
}
