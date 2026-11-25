import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/services/usuario_services.dart';
import '../../data/model/usuario.dart';
import 'editar_screen.dart';

/// Lista los usuarios registrados y permite abrir su ficha.
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  late Future<List<Usuario>> _usuarios;

  @override
  void initState() {
    super.initState();
    _usuarios = UsuarioService.getUsuarios();
  }

  void _recargar() {
    setState(() => _usuarios = UsuarioService.getUsuarios());
  }

  Future<void> _abrirDetalle(Usuario usuario) async {
    final cambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => EditarScreen(user: usuario)),
    );
    if (cambio == true && mounted) _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Usuarios'),
        actions: [
          IconButton(
            tooltip: 'Actualizar lista',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Usuario>>(
        future: _usuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 42,
                      color: AppColors.muted,
                    ),
                    const SizedBox(height: 12),
                    const Text('No se pudieron cargar los usuarios.'),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _recargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final usuarios = snapshot.data ?? [];
          if (usuarios.isEmpty) {
            return const Center(child: Text('No hay usuarios registrados.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              _recargar();
              await _usuarios;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'GESTIÓN DE ACCESOS',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Usuarios registrados (${usuarios.length})',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                ...usuarios.map(
                  (usuario) => Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => _abrirDetalle(usuario),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.paleCyan,
                        foregroundColor: AppColors.petrol,
                        child: Text(
                          usuario.nombre.isEmpty
                              ? '?'
                              : usuario.nombre[0].toUpperCase(),
                        ),
                      ),
                      title: Text(
                        usuario.nombre,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${usuario.correo} · ${usuario.rol} · ${usuario.estado}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
