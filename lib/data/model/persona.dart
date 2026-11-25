/// Representa una persona registrada en la API.
class Persona {
  final int id;
  final String identificacion;
  final String nombre;
  final String? segundoNombre;
  final String? primerApellido;
  final String? segundoApellido;
  final String? telefono;
  final String? correo;
  final String? direccion;

  const Persona({
    required this.id,
    required this.identificacion,
    required this.nombre,
    this.segundoNombre,
    this.primerApellido,
    this.segundoApellido,
    this.telefono,
    this.correo,
    this.direccion,
  });

  /// Convierte una respuesta JSON de la API en una persona tipada.
  factory Persona.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw const FormatException('El id de la persona no es válido');
    }

    return Persona(
      id: id,
      identificacion: _requiredString(json, 'identificacion'),
      nombre: _requiredString(json, 'nombre'),
      segundoNombre: _optionalString(json, 'seg_nombre'),
      primerApellido: _optionalString(json, 'pri_apellido'),
      segundoApellido: _optionalString(json, 'seg_apellido'),
      telefono: _optionalString(json, 'telefono'),
      correo: _optionalString(json, 'correo'),
      direccion: _optionalString(json, 'direccion'),
    );
  }

  /// Une los nombres y apellidos disponibles para mostrar el nombre completo.
  String get nombreCompleto => [
    nombre,
    segundoNombre,
    primerApellido,
    segundoApellido,
  ].where((parte) => parte != null && parte.trim().isNotEmpty).join(' ');

  static String _requiredString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('El campo "$key" no es válido');
    }
    return value;
  }

  static String? _optionalString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException('El campo "$key" no es válido');
    }
    return value;
  }
}
