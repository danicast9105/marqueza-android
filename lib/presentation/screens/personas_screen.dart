import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/services/persona_service.dart';
import '../../data/model/persona.dart';

/// Pantalla para listar, crear, editar y eliminar personas.
class PersonasScreen extends StatefulWidget {
  const PersonasScreen({super.key});

  @override
  State<PersonasScreen> createState() => _PersonasScreenState();
}

class _PersonasScreenState extends State<PersonasScreen> {
  late Future<List<Persona>> personas;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    personas = PersonaService.obtenerPersonas();
  }

  /// Recarga la lista desde la API.
  void cargarPersonas() {
    setState(() {
      personas = PersonaService.obtenerPersonas();
    });
  }

  /// Muestra un aviso breve con el resultado de una operación.
  void mostrarMensaje(String mensaje, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        ),
      );
  }

  /// Abre un formulario compartido para crear o actualizar una persona.
  Future<bool> abrirFormulario({Persona? persona}) async {
    final controladores = <String, TextEditingController>{
      'identificacion': TextEditingController(
        text: persona?.identificacion ?? '',
      ),
      'nombre': TextEditingController(text: persona?.nombre ?? ''),
      'seg_nombre': TextEditingController(text: persona?.segundoNombre ?? ''),
      'pri_apellido': TextEditingController(
        text: persona?.primerApellido ?? '',
      ),
      'seg_apellido': TextEditingController(
        text: persona?.segundoApellido ?? '',
      ),
      'telefono': TextEditingController(text: persona?.telefono ?? ''),
      'correo': TextEditingController(text: persona?.correo ?? ''),
      'direccion': TextEditingController(text: persona?.direccion ?? ''),
    };
    final formKey = GlobalKey<FormState>();

    try {
      final guardar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(persona == null ? 'Nueva persona' : 'Editar persona'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _campo(
                      controladores['identificacion']!,
                      'Identificación',
                      requerido: true,
                    ),
                    _campo(
                      controladores['nombre']!,
                      'Nombres',
                      requerido: true,
                    ),
                    _campo(controladores['seg_nombre']!, 'Segundo nombre'),
                    _campo(controladores['pri_apellido']!, 'Primer apellido'),
                    _campo(controladores['seg_apellido']!, 'Segundo apellido'),
                    _campo(
                      controladores['telefono']!,
                      'Teléfono',
                      tipo: TextInputType.phone,
                    ),
                    _campo(
                      controladores['correo']!,
                      'Correo electrónico',
                      tipo: TextInputType.emailAddress,
                    ),
                    _campo(
                      controladores['direccion']!,
                      'Dirección',
                      maxLineas: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      );

      if (guardar != true || !mounted) return false;

      setState(() => guardando = true);
      final datos = {
        for (final entrada in controladores.entries)
          entrada.key: entrada.value.text.trim().isEmpty
              ? null
              : entrada.value.text.trim(),
      };

      try {
        final mensaje = persona == null
            ? await PersonaService.crearPersona(datos)
            : await PersonaService.actualizarPersona(persona.id, datos);
        if (!mounted) return false;
        cargarPersonas();
        mostrarMensaje(mensaje);
        return true;
      } catch (error) {
        if (mounted) mostrarMensaje('No se pudo guardar: $error', error: true);
        return false;
      } finally {
        if (mounted) setState(() => guardando = false);
      }
    } finally {
      for (final controlador in controladores.values) {
        controlador.dispose();
      }
    }
  }

  /// Construye un campo de formulario con validación opcional.
  Widget _campo(
    TextEditingController controlador,
    String etiqueta, {
    bool requerido = false,
    TextInputType? tipo,
    int maxLineas = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controlador,
        keyboardType: tipo,
        maxLines: maxLineas,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(),
        ),
        validator: requerido
            ? (valor) => valor == null || valor.trim().isEmpty
                  ? 'Ingresa $etiqueta'
                  : null
            : null,
      ),
    );
  }

  /// Solicita confirmación antes de eliminar una persona.
  Future<bool> confirmarEliminacion(Persona persona) async {
    if (guardando) return false;
    setState(() => guardando = true);
    try {
      // Revisa primero dependencias para advertir exactamente qué se borrará.
      final vinculos = await PersonaService.obtenerVinculos(persona);
      if (!mounted) return false;

      final elementosVinculados = [
        ...vinculos.clientes.map(
          (cliente) => 'Cliente: ${cliente.descripcion} (ID ${cliente.id})',
        ),
        ...vinculos.proveedores.map(
          (proveedor) =>
              'Proveedor: ${proveedor.descripcion} (ID ${proveedor.id})',
        ),
      ];
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Eliminar persona'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('¿Deseas eliminar a ${persona.nombreCompleto}?'),
                if (elementosVinculados.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'También se eliminarán estos registros vinculados:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...elementosVinculados.map(
                    (elemento) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $elemento'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (confirmado != true || !mounted) return false;

      final mensaje = await PersonaService.eliminarPersona(persona, vinculos);
      if (!mounted) return false;
      cargarPersonas();
      mostrarMensaje(mensaje);
      return true;
    } catch (error) {
      if (mounted) {
        cargarPersonas();
        mostrarMensaje(
          'No se pudo completar la eliminación: $error',
          error: true,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  /// Presenta solo el nombre y abre la pantalla con el detalle completo.
  Widget _tarjetaPersona(Persona persona) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.paleCyan,
          foregroundColor: AppColors.petrol,
          child: Icon(Icons.person),
        ),
        title: Text(
          persona.nombreCompleto,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.cyan,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => PersonaDetalleScreen(
                persona: persona,
                onEditar: () => abrirFormulario(persona: persona),
                onEliminar: () => confirmarEliminacion(persona),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Personas'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: cargarPersonas,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: guardando ? null : () => abrirFormulario(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nueva persona'),
      ),
      body: FutureBuilder<List<Persona>>(
        future: personas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No se pudieron cargar las personas.'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: cargarPersonas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final lista = snapshot.data ?? [];
          if (lista.isEmpty) {
            return const Center(child: Text('No hay personas registradas.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              cargarPersonas();
              await personas;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                Text(
                  'Personas registradas (${lista.length})',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                ...lista.map(_tarjetaPersona),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Muestra los datos completos y las acciones para una persona seleccionada.
class PersonaDetalleScreen extends StatelessWidget {
  final Persona persona;
  final Future<bool> Function() onEditar;
  final Future<bool> Function() onEliminar;

  const PersonaDetalleScreen({
    super.key,
    required this.persona,
    required this.onEditar,
    required this.onEliminar,
  });

  /// Cierra la pantalla de detalle después de completar una acción.
  Future<void> _ejecutarAccion(
    BuildContext context,
    Future<bool> Function() accion,
  ) async {
    final completada = await accion();
    if (completada && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Presenta un dato con su etiqueta y un valor alternativo si está vacío.
  Widget _dato(String etiqueta, String? valor) {
    final texto = valor == null || valor.trim().isEmpty
        ? 'No registrado'
        : valor;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        etiqueta.toUpperCase(),
        style: const TextStyle(
          color: AppColors.teal,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
      subtitle: Text(
        texto,
        style: const TextStyle(fontSize: 16, color: AppColors.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalle de persona'),
        leading: IconButton(
          tooltip: 'Regresar',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 34,
                    backgroundColor: AppColors.paleCyan,
                    foregroundColor: AppColors.petrol,
                    child: Icon(Icons.person, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    persona.nombreCompleto,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  const Divider(height: 28),
                  _dato('Identificación', persona.identificacion),
                  _dato('Nombre', persona.nombre),
                  _dato('Segundo nombre', persona.segundoNombre),
                  _dato('Primer apellido', persona.primerApellido),
                  _dato('Segundo apellido', persona.segundoApellido),
                  _dato('Teléfono', persona.telefono),
                  _dato('Correo electrónico', persona.correo),
                  _dato('Dirección', persona.direccion),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _ejecutarAccion(context, onEditar),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar persona'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _ejecutarAccion(context, onEliminar),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar persona'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Regresar a personas'),
          ),
        ],
      ),
    );
  }
}
