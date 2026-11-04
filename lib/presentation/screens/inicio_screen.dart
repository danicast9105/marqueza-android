import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final opciones = [
      _OpcionMenu(
        titulo: 'Productos',
        descripcion: 'Consulta y revisa los productos registrados',
        icono: Icons.inventory_2_rounded,
        color: const Color(0xFF2563EB),
        ruta: AppRoutes.productos,
      ),
      _OpcionMenu(
        titulo: 'Insumos',
        descripcion: 'Consulta los insumos del inventario',
        icono: Icons.warehouse_rounded,
        color: const Color(0xFF0F9D78),
        ruta: AppRoutes.insumos,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Menú principal', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            onSelected: (value) {
              if (value == 'usuarios') Navigator.pushNamed(context, AppRoutes.usuarios);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'usuarios', child: Text('Usuarios')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 14),
            const Text('¡Bienvenido!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF172033))),
            const SizedBox(height: 8),
            const Text('Selecciona el módulo al que deseas ingresar.', style: TextStyle(fontSize: 15, color: Color(0xFF687386))),
            const SizedBox(height: 28),
            ...opciones.map((opcion) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _TarjetaMenu(opcion: opcion),
            )),
          ],
        ),
      ),
    );
  }
}

class _OpcionMenu {
  final String titulo;
  final String descripcion;
  final IconData icono;
  final Color color;
  final String ruta;
  const _OpcionMenu({required this.titulo, required this.descripcion, required this.icono, required this.color, required this.ruta});
}

class _TarjetaMenu extends StatelessWidget {
  final _OpcionMenu opcion;
  const _TarjetaMenu({required this.opcion});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.pushNamed(context, opcion.ruta),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECF2)),
          ),
          child: Row(
            children: [
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(color: opcion.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                child: Icon(opcion.icono, color: opcion.color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(opcion.titulo, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF172033))),
                const SizedBox(height: 5),
                Text(opcion.descripcion, style: const TextStyle(fontSize: 13, color: Color(0xFF687386))),
              ])),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A94A6), size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
