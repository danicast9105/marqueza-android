import 'package:flutter/material.dart';
import '../presentation/screens/PrincipalScreen.dart';
import '../presentation/screens/inicio_screen.dart';
// import '../presentation/screens/inventario_screen.dart';
import '../presentation/screens/registro_screen.dart';

class AppRoutes {
  static const home = '/';
  static const registro = '/registro';
  static const usuarios = '/usuarios';
  static const productos = '/productos';
  static const insumos = '/insumos';

  static Map<String, WidgetBuilder> routes = {
    home: (_) => const InicioScreen(),
    registro: (_) => const RegistroScreen(),
    // usuarios: (_) => const InventarioScreen(),
    productos: (_) => const InventarioScreen(titulo: 'Productos', endpoint: 'productos'),
    // insumos: (_) => const InventarioScreen(titulo: 'Insumos', endpoint: 'insumos'),
  };
}
