import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/services/usuario_services.dart';
import '../../data/model/usuario.dart';

/// Pantalla de detalle que muestra los datos y permite eliminar un usuario.
class EditarScreen extends StatefulWidget {
  /// Usuario cuyos datos se presentan en esta pantalla.
  final Usuario user;

  const EditarScreen({super.key, required this.user});

  @override
  State<EditarScreen> createState() => _EditarScreenState();
}

/// Mantiene los controladores y el estado de carga de la pantalla.
class _EditarScreenState extends State<EditarScreen> {
  // Controladores para mostrar los datos del usuario en los campos de texto.
  late TextEditingController cNombre;
  late TextEditingController cCorreo;

  // Evita repetir la solicitud mientras se elimina el usuario.
  bool loading = false;
  bool editando = false;

  /// Inicializa los campos con la información recibida del usuario.
  @override
  void initState() {
    super.initState();

    cNombre = TextEditingController(text: widget.user.nombre);
    cCorreo = TextEditingController(text: widget.user.correo);
  }

  /// Libera los controladores cuando la pantalla deja de existir.
  @override
  void dispose() {
    cNombre.dispose();
    cCorreo.dispose();
    super.dispose();
  }

  /// Guarda los campos editables del usuario.
  Future<void> guardar() async {
    if (cNombre.text.trim().isEmpty || cCorreo.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y correo son obligatorios.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final mensaje = await UsuarioService.editar({
        'nombre': cNombre.text.trim(),
        'correo': cCorreo.text.trim(),
      }, widget.user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Confirma y elimina el usuario seleccionado.
  Future<void> eliminar() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text('¿Deseas eliminar a ${widget.user.nombre}?'),
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
    if (confirmado != true || !mounted) return;

    setState(() => loading = true);
    try {
      await UsuarioService.eliminar(widget.user.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $error')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  /// Construye el detalle del usuario y la acción para eliminarlo.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Detalle de usuario"),
        actions: [
          if (!editando)
            IconButton(
              tooltip: 'Editar usuario',
              onPressed: loading ? null : () => setState(() => editando = true),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (editando)
            IconButton(
              tooltip: 'Guardar cambios',
              onPressed: loading ? null : guardar,
              icon: const Icon(Icons.save_outlined),
            ),
          // Mientras se elimina muestra progreso y deshabilita el botón.
          IconButton(
            icon: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete),
            onPressed: loading ? null : eliminar,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Los campos son de solo lectura: esta pantalla no edita datos.
            TextField(
              controller: cNombre,
              readOnly: !editando,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: cCorreo,
              readOnly: !editando,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Correo"),
            ),
            ListTile(title: const Text("Rol"), subtitle: Text(widget.user.rol)),
            ListTile(
              title: const Text("Estado"),
              subtitle: Text(widget.user.estado),
            ),
          ],
        ),
      ),
    );
  }
}
