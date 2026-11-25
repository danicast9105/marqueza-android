import 'package:flutter_test/flutter_test.dart';
import 'package:registrar/core/services/api_service.dart';
import 'package:registrar/core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.nombreUsuario = null;
    AuthService.sesionActiva = false;
    AuthService.tokenAcceso = null;
    ApiService.setBearerToken(null);
  });

  test('restaura la sesión recordada', () async {
    SharedPreferences.setMockInitialValues({
      'auth.sesionActiva': true,
      'auth.nombreUsuario': 'ana',
      'auth.tokenAcceso': 'token-prueba',
    });

    await AuthService.restaurarSesion();

    expect(AuthService.sesionActiva, isTrue);
    expect(AuthService.nombreUsuario, 'ana');
    expect(AuthService.tokenAcceso, 'token-prueba');
  });

  test('descarta una sesión recordada sin token', () async {
    SharedPreferences.setMockInitialValues({
      'auth.sesionActiva': true,
      'auth.nombreUsuario': 'ana',
    });

    await AuthService.restaurarSesion();

    expect(AuthService.sesionActiva, isFalse);
    expect(AuthService.nombreUsuario, isNull);
    expect(AuthService.tokenAcceso, isNull);
  });

  test('cerrar sesión elimina los datos persistidos', () async {
    SharedPreferences.setMockInitialValues({
      'auth.sesionActiva': true,
      'auth.nombreUsuario': 'ana',
      'auth.tokenAcceso': 'token-prueba',
    });
    await AuthService.restaurarSesion();

    await AuthService.cerrarSesion();

    final preferencias = await SharedPreferences.getInstance();
    expect(AuthService.sesionActiva, isFalse);
    expect(AuthService.nombreUsuario, isNull);
    expect(AuthService.tokenAcceso, isNull);
    expect(preferencias.getKeys(), isEmpty);
  });
}
