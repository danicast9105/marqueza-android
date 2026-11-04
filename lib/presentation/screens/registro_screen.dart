import 'package:flutter/material.dart';

import '../../core/services/usuario_services.dart';
import '../../routes/app_routes.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final cNombre = TextEditingController();
  final cApellido = TextEditingController();
  final cCorreo = TextEditingController();
  final cPassword = TextEditingController();

  String genero = "Masculino";
  String rol = "Empleado";

  bool loading = false;

  Future<void> registrar() async {
    setState(() => loading = true);

    var exitoso = false;
    late String mensaje;
    try {
      mensaje = await UsuarioService.registrar({
        'nombre': cNombre.text.trim(),
        'apellido': cApellido.text.trim(),
        'correo': cCorreo.text.trim(),
        'rol': rol,
        'genero': genero,
        'contrasena': cPassword.text,
      });
      exitoso = true;
    } catch (e) {
      mensaje = 'No se pudo registrar el usuario: $e';
    }

    if (!mounted) return;
    setState(() => loading = false);

    mostrarMensaje(mensaje, exitoso: exitoso);
  }

  void mostrarMensaje(String msg, {required bool exitoso}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Mensaje"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (exitoso && mounted) {
                Navigator.of(context).pushReplacementNamed(AppRoutes.home);
              }
            },
            child: Text(exitoso ? "Ver usuarios" : "OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cNombre.dispose();
    cApellido.dispose();
    cCorreo.dispose();
    cPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registrar Usuario")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: cNombre,
              decoration: const InputDecoration(labelText: "Nombres"),
            ),
            TextField(
              controller: cApellido,
              decoration: const InputDecoration(labelText: "Apellidos"),
            ),
            TextField(
              controller: cCorreo,
              decoration: const InputDecoration(labelText: "Correo"),
            ),
            TextField(
              controller: cPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 15),

            DropdownButton<String>(
              value: genero,
              isExpanded: true,
              items: [
                "Masculino",
                "Femenino",
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => genero = v!),
            ),

            DropdownButton<String>(
              value: rol,
              isExpanded: true,
              items: [
                "Administrador",
                "Empleado",
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => rol = v!),
            ),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: registrar,
                    child: const Text("Registrar"),
                  ),
          ],
        ),
      ),
    );
  }
}
