import 'package:flutter/material.dart';

import 'core/config/app_colors.dart';
import 'core/services/auth_service.dart';
import 'routes/app_routes.dart';

/// Punto de entrada de la aplicación Flutter.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.restaurarSesion();
  // Crea el widget raíz y monta la aplicación en la pantalla.
  runApp(const MyApp());
}

/// Configura la navegación y la apariencia global de la aplicación.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Construye la configuración raíz de Flutter.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Oculta la etiqueta de depuración de Flutter.
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.petrol,
          primary: AppColors.petrol,
          secondary: AppColors.cyan,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: AppColors.text,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 1,
          shadowColor: AppColors.deepPetrol.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.cyan,
          foregroundColor: Colors.white,
        ),
      ),
      // Solicita autenticación antes de mostrar los módulos de la aplicación.
      initialRoute: AuthService.sesionActiva ? AppRoutes.home : AppRoutes.login,
      // Registra los nombres de ruta y sus pantallas asociadas.
      routes: AppRoutes.routes,
    );
  }
}
