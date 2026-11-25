import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/ruta.dart';
import '../../core/services/api_service.dart';

/// Pantalla reutilizable para consultar listas de productos o insumos.
class InventarioScreen extends StatefulWidget {
  /// Texto mostrado como título del módulo.
  final String titulo;

  /// Segmento de la API desde el que se cargan los registros.
  final String endpoint;

  const InventarioScreen({
    super.key,
    required this.titulo,
    required this.endpoint,
  });

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

/// Administra la carga, presentación y actualización del inventario.
class _InventarioScreenState extends State<InventarioScreen> {
  // Future compartido con FutureBuilder para reflejar los estados de carga.
  late Future<List<Map<String, dynamic>>> registros;

  /// Inicia la primera consulta al abrir la pantalla.
  @override
  void initState() {
    super.initState();
    registros = cargar();
  }

  /// Consulta la API y normaliza su respuesta a una lista de objetos.
  Future<List<Map<String, dynamic>>> cargar() async {
    final response = await ApiService.get('${Ruta.baseUrl}${widget.endpoint}');

    // Un estado fuera del rango 2xx indica que la consulta falló.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al cargar los datos');
    }

    final data = json.decode(response.body);
    dynamic lista = data;

    // Acepta tanto una lista directa como listas envueltas en distintas claves.
    if (data is Map) {
      lista =
          data['datos'] ??
          data['data'] ??
          data['productos'] ??
          data['insumos'] ??
          data['resultado'];
    }

    if (lista is! List) {
      throw Exception('Formato de respuesta incorrecto');
    }

    // Descarta elementos no-objeto y convierte cada mapa a claves String.
    return lista
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Busca el primer valor no nulo entre las claves alternativas recibidas.
  String valor(Map<String, dynamic> item, List<String> claves) {
    for (final clave in claves) {
      if (item[clave] != null) {
        return item[clave].toString();
      }
    }
    return '-';
  }

  /// Da formato de moneda al valor numérico y separa los miles con puntos.
  String dinero(dynamic valor) {
    if (valor == null) return '-';

    final numero = double.tryParse(valor.toString());

    if (numero == null) return valor.toString();

    final entero = numero.toInt();
    final texto = entero.toString();

    final formato = texto.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return '\$$formato';
  }

  /// Construye una tabla desplazable con los datos del inventario.
  Widget construirTabla(List<Map<String, dynamic>> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;

        // Ajusta la separación de columnas al ancho disponible.
        final espacioColumnas = ancho < 400
            ? 10.0
            : ancho < 700
            ? 18.0
            : 30.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: ancho),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppColors.petrol),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 60,
              columnSpacing: espacioColumnas,
              horizontalMargin: 12,
              border: TableBorder.all(color: AppColors.border, width: 0.7),
              columns: const [
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Cant.')),
                DataColumn(label: Text('Precio')),
                DataColumn(label: Text('Estado')),
              ],
              rows: items.map((item) {
                final estado = valor(item, ['estado']);

                // Admite nombres alternativos de campo para los datos de API.
                return DataRow(
                  cells: [
                    DataCell(Text(valor(item, ['nombre', 'descripcion']))),
                    DataCell(
                      Text(
                        valor(item, ['cantidad', 'stock', 'existencia']) +
                            (item['unidad'] == null
                                ? ''
                                : ' ${item['unidad']}'),
                      ),
                    ),
                    DataCell(
                      Text(
                        dinero(
                          item['precio'] ??
                              item['costo'] ??
                              item['valor_unitario'] ??
                              item['precioUnitario'],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        estado,
                        style: TextStyle(
                          color:
                              [
                                'activo',
                                'disponible',
                              ].contains(estado.toLowerCase())
                              ? AppColors.teal
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// Dibuja la pantalla y representa carga, error, lista vacía o resultados.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          // Vuelve a solicitar los registros al pulsar actualizar.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                registros = cargar();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: registros,
        builder: (context, snapshot) {
          // Muestra un indicador mientras la solicitud está en curso.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Ofrece reintentar si la solicitud o el parseo produjeron un error.
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Error al cargar los registros'),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        registros = cargar();
                      });
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          // Informa cuando la API respondió correctamente pero no hay elementos.
          if (items.isEmpty) {
            return const Center(child: Text('No hay registros disponibles'));
          }

          // Permite actualizar los datos arrastrando la lista hacia abajo.
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                registros = cargar();
              });
              await registros;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Reduce los márgenes para que la tabla quepa mejor en móviles.
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 400 ? 8 : 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Listado de ${widget.titulo}',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          child: construirTabla(items),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
