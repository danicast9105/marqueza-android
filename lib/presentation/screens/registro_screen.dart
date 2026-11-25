import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/services/usuario_services.dart';
import '../../routes/app_routes.dart';

/// Formulario para crear una cuenta de usuario en la API.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

/// Mantiene los valores del formulario y el estado de envío.
class _RegistroScreenState extends State<RegistroScreen> {
  // Controladores que permiten leer el texto ingresado en cada campo.
  final cNombre = TextEditingController();
  final cApellido = TextEditingController();
  final cCorreo = TextEditingController();
  final cPassword = TextEditingController();

  // Valores iniciales de las listas desplegables.
  String genero = "Masculino";
  String rol = "Empleado";

  // Indica si el registro está en curso.
  bool loading = false;

  /// Valida indirectamente y envía los campos del formulario al servicio.
  Future<void> registrar() async {
    setState(() => loading = true);

    var exitoso = false;
    late String mensaje;
    try {
      // Elimina espacios sobrantes en los campos de texto antes de enviarlos.
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
      // Conserva el motivo recibido para informar al usuario del fallo.
      mensaje = 'No se pudo registrar el usuario: $e';
    }

    // No actualiza la interfaz si la pantalla ya fue cerrada.
    if (!mounted) return;
    setState(() => loading = false);

    mostrarMensaje(mensaje, exitoso: exitoso);
  }

  /// Muestra el resultado y vuelve al inicio luego de un registro exitoso.
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
                // Sustituye el formulario por el menú principal.
                Navigator.of(context).pushReplacementNamed(AppRoutes.home);
              }
            },
            child: Text(exitoso ? "Ir al inicio" : "OK"),
          ),
        ],
      ),
    );
  }

  /// Libera los controladores al cerrar la pantalla.
  @override
  void dispose() {
    cNombre.dispose();
    cApellido.dispose();
    cCorreo.dispose();
    cPassword.dispose();
    super.dispose();
  }

  /// Construye los campos y las opciones del formulario.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("Registrar Usuario")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Campos de texto que recogen la información personal y de acceso.
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
              // Cambia el género seleccionado cuando el usuario elige una opción.
              value: genero,
              isExpanded: true,
              items: [
                "Masculino",
                "Femenino",
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => genero = v!),
            ),

            DropdownButton<String>(
              // Cambia el rol que se enviará a la API.
              value: rol,
              isExpanded: true,
              items: [
                "Administrador",
                "Empleado",
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => rol = v!),
            ),

            const SizedBox(height: 20),

            // Durante el envío reemplaza el botón por un indicador de progreso.
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
