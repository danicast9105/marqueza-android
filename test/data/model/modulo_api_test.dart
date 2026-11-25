import 'package:flutter_test/flutter_test.dart';
import 'package:registrar/data/model/modulo_api.dart';

void main() {
  test('expone únicamente los módulos visibles en el sitio', () {
    expect(ModuloApi.disponibles.map((modulo) => modulo.endpoint).toList(), [
      'insumos',
      'productos',
      'ventas',
      'cotizaciones',
      'clientes',
      'proveedores',
      'usuarios',
      'bitacora-auditoria',
    ]);
    expect(
      ModuloApi.disponibles.map((modulo) => modulo.titulo).last,
      'Registro de actividad',
    );
    expect(ModuloApi.disponibles.last.soloLectura, isTrue);
  });
}
