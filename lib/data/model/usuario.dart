/// Representa un usuario recibido desde la API.
class Usuario {
  /// Identificador numérico usado por las operaciones del servidor.
  final int id;

  /// Nombre visible del usuario.
  final String nombre;

  /// Correo electrónico asociado a la cuenta.
  final String correo;

  /// Estado actual de la cuenta.
  final String estado;

  /// Nombre del rol asignado.
  final String rol;

  /// Identificador numérico del rol.
  final int rolId;

  /// Fecha del último acceso, si la API la proporciona.
  final String? ultimoAcceso;

  /// Identificador único en formato UUID.
  final String uuid;

  /// Crea un usuario con todos sus campos ya validados.
  Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.estado,
    required this.rol,
    required this.rolId,
    required this.ultimoAcceso,
    required this.uuid,
  });

  /// Construye un [Usuario] desde el objeto JSON de la API.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final rolId = json['rol_id'];
    final ultimoAcceso = json['ultimo_acceso'];

    // Comprueba los campos numéricos antes de crear el modelo.
    if (id is! int || rolId is! int) {
      throw const FormatException('El id del usuario o del rol no es válido');
    }
    // El último acceso puede faltar, pero si existe debe ser texto.
    if (ultimoAcceso != null && ultimoAcceso is! String) {
      throw const FormatException(
        'El último acceso no tiene un formato válido',
      );
    }

    return Usuario(
      id: id,
      nombre: _requiredString(json, 'nombre'),
      correo: _requiredString(json, 'correo'),
      estado: _requiredString(json, 'estado'),
      rol: _requiredString(json, 'rol'),
      rolId: rolId,
      ultimoAcceso: ultimoAcceso as String?,
      uuid: _requiredString(json, 'uuid'),
    );
  }

  /// Lee un campo obligatorio y verifica que su valor sea una cadena.
  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('El campo "$key" no es válido');
    }
    return value;
  }
}
