import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../data/model/modulo_api.dart';
import '../../routes/app_routes.dart';
import 'recurso_screen.dart';

const _iconos = <String, IconData>{
  'insumos': Icons.inventory_rounded,
  'productos': Icons.checkroom_rounded,
  'ventas': Icons.point_of_sale_rounded,
  'cotizaciones': Icons.request_quote_rounded,
  'clientes': Icons.people_alt_rounded,
  'proveedores': Icons.inventory_2_outlined,
  'usuarios': Icons.account_circle_outlined,
  'bitacora-auditoria': Icons.history_rounded,
};

const _colores = <String, Color>{
  'insumos': AppColors.teal,
  'productos': AppColors.cyan,
  'ventas': AppColors.petrol,
  'cotizaciones': AppColors.teal,
  'clientes': AppColors.cyan,
  'proveedores': AppColors.petrol,
  'usuarios': AppColors.teal,
  'bitacora-auditoria': AppColors.cyan,
};

/// Pantalla principal con accesos a los módulos disponibles.
class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  /// Define las opciones disponibles y dibuja el menú.
  @override
  Widget build(BuildContext context) {
    final opciones = ModuloApi.disponibles
        .map(
          (modulo) => _OpcionMenu(
            modulo: modulo,
            icono: _iconos[modulo.endpoint] ?? Icons.grid_view_rounded,
            color: _colores[modulo.endpoint] ?? AppColors.teal,
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Marqueza'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Opciones',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              if (value == 'usuarios') {
                Navigator.pushNamed(context, AppRoutes.usuarios);
              } else if (value == 'registro') {
                Navigator.pushNamed(context, AppRoutes.registro);
              } else if (value == 'salir') {
                await AuthService.cerrarSesion();
                if (!context.mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  AuthService.nombreUsuario ?? 'Sesión iniciada',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const PopupMenuItem(
                value: 'usuarios',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.people_outline),
                  title: Text('Usuarios'),
                ),
              ),
              const PopupMenuItem(
                value: 'registro',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.person_add_alt_1),
                  title: Text('Registrar usuario'),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'salir',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        // SafeArea evita que el contenido quede debajo de elementos del sistema.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final margen = constraints.maxWidth < 480 ? 16.0 : 28.0;
            return ListView(
              padding: EdgeInsets.all(margen),
              children: [
                _BannerInicio(ancho: constraints.maxWidth),
                const SizedBox(height: 30),
                const Text(
                  'LECTURA OPERATIVA',
                  style: TextStyle(
                    color: AppColors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'El pulso del negocio',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Selecciona el módulo al que deseas ingresar.',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, gridConstraints) {
                    final columnas = gridConstraints.maxWidth >= 1000
                        ? 3
                        : gridConstraints.maxWidth >= 600
                        ? 2
                        : 1;
                    const espacio = 16.0;
                    final anchoTarjeta =
                        (gridConstraints.maxWidth - espacio * (columnas - 1)) /
                        columnas;
                    return Wrap(
                      spacing: espacio,
                      runSpacing: espacio,
                      children: opciones
                          .map(
                            (opcion) => SizedBox(
                              width: anchoTarjeta,
                              child: _TarjetaMenu(opcion: opcion),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Encabezado en degradado inspirado en el panel de control de Marqueza.
class _BannerInicio extends StatelessWidget {
  final double ancho;

  const _BannerInicio({required this.ancho});

  @override
  Widget build(BuildContext context) {
    final compacto = ancho < 520;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 208),
            padding: EdgeInsets.all(compacto ? 22 : 34),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.deepPetrol, AppColors.teal],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'PANEL DE CONTROL',
                  style: TextStyle(
                    color: AppColors.mint,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Una vista clara para hacer crecer Marqueza',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compacto ? 28 : 36,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Inventario, producción y oportunidades comerciales reunidos en un solo lugar.',
                  style: TextStyle(
                    color: Color(0xFFD4E3E8),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -74,
            bottom: -148,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 2,
                ),
              ),
            ),
          ),
          Positioned(
            right: -25,
            bottom: -100,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Datos visuales y de navegación de una opción del menú.
class _OpcionMenu {
  final ModuloApi modulo;
  final IconData icono;
  final Color color;

  const _OpcionMenu({
    required this.modulo,
    required this.icono,
    required this.color,
  });
}

/// Tarjeta interactiva que navega al módulo seleccionado.
class _TarjetaMenu extends StatelessWidget {
  final _OpcionMenu opcion;
  const _TarjetaMenu({required this.opcion});

  /// Presenta la opción como una tarjeta con icono, descripción y flecha.
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          final navigator = Navigator.of(context);
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => RecursoScreen(
                modulo: opcion.modulo,
                onRegresar: () => navigator.pop(),
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 5, child: ColoredBox(color: AppColors.cyan)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: opcion.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(opcion.icono, color: opcion.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opcion.modulo.titulo,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          opcion.modulo.descripcion,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                    size: 26,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
