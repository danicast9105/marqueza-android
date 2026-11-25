import 'dart:convert';

import 'package:http/http.dart' as http;

/// Agrupa las solicitudes HTTP utilizadas para comunicarse con la API.
class ApiService {
  static String? _bearerToken;

  /// Define el token de acceso que se envía en las solicitudes autenticadas.
  static void setBearerToken(String? token) {
    _bearerToken = token;
  }

  static Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (_bearerToken != null && _bearerToken!.isNotEmpty)
      'Authorization': 'Bearer $_bearerToken',
  };

  /// Realiza una solicitud GET a la URL recibida.
  static Future<http.Response> get(String url) {
    return http.get(Uri.parse(url), headers: _headers);
  }

  /// Envía un objeto como JSON mediante una solicitud POST.
  static Future<http.Response> post(String url, Map body) {
    return http.post(
      Uri.parse(url),
      // Indica que el cuerpo y la respuesta usan el formato JSON.
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }

  /// Realiza una solicitud DELETE a la URL recibida.
  static Future<http.Response> delete(String url) {
    return http.delete(Uri.parse(url), headers: _headers);
  }

  /// Envía un objeto como JSON mediante una solicitud PUT.
  static Future<http.Response> put(String url, Map body) {
    return http.put(
      Uri.parse(url),
      // Indica que el cuerpo y la respuesta usan el formato JSON.
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }
}
