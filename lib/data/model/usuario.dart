class Usuario {
  final int id;
  final String nombre;
  final String correo;
  final String estado;
  final String rol;
  final int rolId;
  final String? ultimoAcceso;
  final String uuid;

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

  factory Usuario.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final rolId = json['rol_id'];
    final ultimoAcceso = json['ultimo_acceso'];

    if (id is! int || rolId is! int) {
      throw const FormatException('El id del usuario o del rol no es válido');
    }
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

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('El campo "$key" no es válido');
    }
    return value;
  }
}
