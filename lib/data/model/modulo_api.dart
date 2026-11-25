/// Describe un recurso de la API que se puede administrar desde la app.
class ModuloApi {
  final String endpoint;
  final String titulo;
  final String categoria;
  final String descripcion;
  final List<String> camposResumen;
  final bool soloLectura;

  const ModuloApi({
    required this.endpoint,
    required this.titulo,
    required this.categoria,
    required this.descripcion,
    required this.camposResumen,
    this.soloLectura = false,
  });

  static const List<ModuloApi> disponibles = [
    ModuloApi(
      endpoint: 'insumos',
      titulo: 'Insumos',
      categoria: 'Inventario',
      descripcion: 'Materias primas, cantidades y costos.',
      camposResumen: ['nombre', 'codigo', 'cantidad'],
    ),
    ModuloApi(
      endpoint: 'productos',
      titulo: 'Productos',
      categoria: 'Inventario',
      descripcion: 'Productos, existencias y precios.',
      camposResumen: ['nombre', 'codigo', 'cantidad'],
    ),
    ModuloApi(
      endpoint: 'ventas',
      titulo: 'Ventas',
      categoria: 'Gestión comercial',
      descripcion: 'Operaciones y valores de venta.',
      camposResumen: ['factura', 'cliente', 'total'],
    ),
    ModuloApi(
      endpoint: 'cotizaciones',
      titulo: 'Cotizaciones',
      categoria: 'Gestión comercial',
      descripcion: 'Propuestas comerciales y su estado.',
      camposResumen: ['numero', 'cliente', 'estado'],
    ),
    ModuloApi(
      endpoint: 'clientes',
      titulo: 'Clientes',
      categoria: 'Contactos',
      descripcion: 'Directorio de clientes.',
      camposResumen: ['nombre', 'documento', 'correo'],
    ),
    ModuloApi(
      endpoint: 'proveedores',
      titulo: 'Proveedores',
      categoria: 'Contactos',
      descripcion: 'Empresas y contactos proveedores.',
      camposResumen: ['empresa', 'contacto', 'correo'],
    ),
    ModuloApi(
      endpoint: 'usuarios',
      titulo: 'Usuarios',
      categoria: 'Administración',
      descripcion: 'Cuentas, roles y estado de acceso.',
      camposResumen: ['nombre', 'correo', 'rol'],
    ),
    ModuloApi(
      endpoint: 'bitacora-auditoria',
      titulo: 'Registro de actividad',
      categoria: 'Administración',
      descripcion: 'Eventos registrados para seguimiento.',
      camposResumen: ['fecha_hora', 'actor', 'action'],
      soloLectura: true,
    ),
  ];
}
