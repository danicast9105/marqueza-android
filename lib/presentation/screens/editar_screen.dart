import 'package:flutter/material.dart';
import '../../core/services/usuario_services.dart';
import '../../data/model/usuario.dart';

class EditarScreen extends StatefulWidget {
  final Usuario user;

  const EditarScreen({super.key, required this.user});

  @override
  State<EditarScreen> createState() => _EditarScreenState();
}

class _EditarScreenState extends State<EditarScreen> {
  late TextEditingController cNombre;
  late TextEditingController cCorreo;

  bool loading = false;

  @override
  void initState() {
    super.initState();

    cNombre = TextEditingController(text: widget.user.nombre);
    cCorreo = TextEditingController(text: widget.user.correo);
  }

  @override
  void dispose() {
    cNombre.dispose();
    cCorreo.dispose();
    super.dispose();
  }

  void eliminar() async {
    setState(() => loading = true);

    await UsuarioService.eliminar(widget.user.id);

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle de usuario"),
        actions: [
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
            TextField(
              controller: cNombre,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: cCorreo,
              readOnly: true,
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
