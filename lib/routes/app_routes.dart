import 'package:flutter/material.dart';

import '../presentation/screens/inventario_screen.dart';
import '../presentation/screens/inicio_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/registro_screen.dart';
import '../presentation/screens/usuarios_screen.dart';

/// Define los nombres de navegación y la pantalla correspondiente a cada ruta.
class AppRoutes {
  // Rutas nombradas utilizadas por la navegación de la aplicación.
  static const home = '/';
  static const login = '/login';
  static const registro = '/registro';
  static const usuarios = '/usuarios';
  static const productos = '/productos';
  static const insumos = '/insumos';

  /// Mapa que conecta cada ruta con el constructor de su pantalla.
  static Map<String, WidgetBuilder> routes = {
    home: (_) => const InicioScreen(),
    login: (_) => const LoginScreen(),
    registro: (_) => const RegistroScreen(),
    usuarios: (_) => const UsuariosScreen(),
    productos: (_) =>
        const InventarioScreen(titulo: 'Productos', endpoint: 'productos'),
    insumos: (_) =>
        const InventarioScreen(titulo: 'Insumos', endpoint: 'insumos'),
  };
}
