import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/ruta.dart';
import '../../data/model/persona.dart';
import 'api_service.dart';

/// Registro de cliente o proveedor asociado a una persona.
class PersonaVinculo {
  final int id;
  final String descripcion;

  const PersonaVinculo({required this.id, required this.descripcion});
}

/// Registros relacionados que deben eliminarse antes que la persona.
class PersonaVinculos {
  final List<PersonaVinculo> clientes;
  final List<PersonaVinculo> proveedores;

  const PersonaVinculos({required this.clientes, required this.proveedores});

  bool get estaVinculada => clientes.isNotEmpty || proveedores.isNotEmpty;
}

/// Realiza las operaciones de consulta y mantenimiento de personas.
class PersonaService {
  /// Obtiene todas las personas y valida el formato de la respuesta.
  static Future<List<Persona>> obtenerPersonas() async {
    final response = await ApiService.get('${Ruta.baseUrl}personas');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error al cargar personas (${response.statusCode}): ${response.body}',
      );
    }

    final dynamic decoded = json.decode(response.body);
    dynamic lista = decoded;
    if (decoded is Map) {
      lista =
          decoded['personas'] ??
          decoded['datos'] ??
          decoded['data'] ??
          decoded['resultado'] ??
          decoded['value'];
    }
    if (lista is! List) {
      throw const FormatException(
        'La respuesta de personas no contiene una lista válida',
      );
    }

    return lista
        .whereType<Map>()
        .map((item) => Persona.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  /// Crea una persona y devuelve el mensaje de confirmación de la API.
  static Future<String> crearPersona(Map<String, dynamic> datos) async {
    final response = await ApiService.post('${Ruta.baseUrl}personas', datos);
    return _mensajeRespuesta(response);
  }

  /// Actualiza los datos de la persona indicada.
  static Future<String> actualizarPersona(
    int id,
    Map<String, dynamic> datos,
  ) async {
    final response = await ApiService.put('${Ruta.baseUrl}personas/$id', datos);
    return _mensajeRespuesta(response);
  }

  /// Busca los clientes y proveedores vinculados usando los datos de persona.
  static Future<PersonaVinculos> obtenerVinculos(Persona persona) async {
    final clientes = await _obtenerLista('clientes');
    final proveedores = await _obtenerLista('proveedores');
    final nombre = _normalizar(persona.nombreCompleto);
    final correo = _normalizar(persona.correo);
    final telefono = _normalizar(persona.telefono);
    final identificacion = _normalizar(persona.identificacion);

    return PersonaVinculos(
      clientes: _buscarVinculos(
        clientes,
        coincide: (registro) =>
            _idCoincide(registro['persona_id'], persona.id) ||
            _normalizar(
                  _primerValor(registro, ['documento', 'identificacion']),
                ) ==
                identificacion,
        descripcion: (registro) =>
            _primerValor(registro, ['nombre', 'razon_social']) ?? 'Cliente',
      ),
      proveedores: _buscarVinculos(
        proveedores,
        coincide: (registro) =>
            _idCoincide(registro['persona_id'], persona.id) ||
            (nombre.isNotEmpty &&
                _normalizar(
                      _primerValor(registro, ['contacto', 'nombre_contacto']),
                    ) ==
                    nombre) ||
            (correo.isNotEmpty && _normalizar(registro['correo']) == correo) ||
            (telefono.isNotEmpty &&
                _normalizar(registro['telefono']) == telefono),
        descripcion: (registro) =>
            _primerValor(registro, ['empresa', 'nombre', 'contacto']) ??
            'Proveedor',
      ),
    );
  }

  /// Elimina primero los registros dependientes y al final la persona.
  static Future<String> eliminarPersona(
    Persona persona,
    PersonaVinculos vinculos,
  ) async {
    final eliminados = <String>[];
    try {
      for (final cliente in vinculos.clientes) {
        final response = await ApiService.delete(
          '${Ruta.baseUrl}clientes/${cliente.id}',
        );
        _mensajeRespuesta(response);
        eliminados.add('cliente "${cliente.descripcion}"');
      }

      for (final proveedor in vinculos.proveedores) {
        final response = await ApiService.delete(
          '${Ruta.baseUrl}proveedores/${proveedor.id}',
        );
        _mensajeRespuesta(response);
        eliminados.add('proveedor "${proveedor.descripcion}"');
      }

      final response = await ApiService.delete(
        '${Ruta.baseUrl}personas/${persona.id}',
      );
      final mensaje = _mensajeRespuesta(response);
      if (eliminados.isEmpty) return mensaje;
      return 'Persona y ${eliminados.join(', ')} eliminados. $mensaje';
    } catch (error) {
      if (eliminados.isEmpty) rethrow;
      throw Exception(
        'Se eliminaron ${eliminados.join(', ')}, pero no se pudo completar '
        'la eliminación de la persona: $error',
      );
    }
  }

  /// Descarga una colección y acepta listas directas o respuestas envueltas.
  static Future<List<Map<String, dynamic>>> _obtenerLista(
    String endpoint,
  ) async {
    final response = await ApiService.get('${Ruta.baseUrl}$endpoint');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudieron comprobar los vínculos de $endpoint '
        '(${response.statusCode}): ${response.body}',
      );
    }

    final dynamic decoded = json.decode(response.body);
    dynamic lista = decoded;
    if (decoded is Map) {
      lista =
          decoded[endpoint] ??
          decoded['datos'] ??
          decoded['data'] ??
          decoded['resultado'] ??
          decoded['value'];
    }
    if (lista is! List) {
      throw FormatException(
        'La respuesta de $endpoint no contiene una lista válida',
      );
    }

    return lista
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<PersonaVinculo> _buscarVinculos(
    List<Map<String, dynamic>> registros, {
    required bool Function(Map<String, dynamic>) coincide,
    required String? Function(Map<String, dynamic>) descripcion,
  }) {
    final vinculados = <PersonaVinculo>[];
    for (final registro in registros) {
      if (!coincide(registro)) continue;
      final id = _convertirId(registro['id']);
      if (id == null) {
        throw const FormatException(
          'Un registro vinculado no contiene un identificador válido',
        );
      }
      vinculados.add(
        PersonaVinculo(
          id: id,
          descripcion: descripcion(registro) ?? 'Registro vinculado',
        ),
      );
    }
    return vinculados;
  }

  static String? _primerValor(
    Map<String, dynamic> registro,
    List<String> claves,
  ) {
    for (final clave in claves) {
      final valor = registro[clave];
      if (valor is String && valor.trim().isNotEmpty) return valor;
    }
    return null;
  }

  static String _normalizar(String? valor) =>
      (valor ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static int? _convertirId(dynamic valor) {
    if (valor is int && valor > 0) return valor;
    if (valor is String) return int.tryParse(valor);
    return null;
  }

  static bool _idCoincide(dynamic valor, int id) => _convertirId(valor) == id;

  /// Extrae el mensaje de la API o informa claramente un error HTTP.
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
