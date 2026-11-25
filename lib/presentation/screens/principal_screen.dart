import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/config/ruta.dart';
import '../../core/services/api_service.dart';

/// Pantalla alternativa de inventario; mantiene una implementación previa.
class InventarioScreen extends StatefulWidget {
  /// Título que identifica el tipo de registros mostrados.
  final String titulo;

  /// Endpoint de la API utilizado para cargar los registros.
  final String endpoint;

  const InventarioScreen({
    super.key,
    required this.titulo,
    required this.endpoint,
  });

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

/// Gestiona la consulta y visualización de los registros.
class _InventarioScreenState extends State<InventarioScreen> {
  // Resultado asíncrono que consume el FutureBuilder.
  late Future<List<Map<String, dynamic>>> registros;

  /// Carga los datos una vez al crear el estado de la pantalla.
  @override
  void initState() {
    super.initState();
    registros = cargar();
  }

  /// Descarga y convierte los registros devueltos por la API.
  Future<List<Map<String, dynamic>>> cargar() async {
    final response = await ApiService.get('${Ruta.baseUrl}${widget.endpoint}');

    // Rechaza respuestas HTTP que no indiquen éxito.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Error al cargar los datos');
    }

    final data = json.decode(response.body);
    dynamic lista = data;

    // La respuesta puede ser una lista directa o estar dentro de un objeto.
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

    // Conserva solamente elementos tipo mapa y normaliza sus claves.
    return lista
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Obtiene el primer valor existente entre los nombres de campo indicados.
  String valor(Map<String, dynamic> item, List<String> claves) {
    for (final clave in claves) {
      if (item[clave] != null) {
        return item[clave].toString();
      }
    }
    return '-';
  }

  /// Convierte un importe a texto con símbolo de moneda y miles agrupados.
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

  /// Presenta los registros en una tabla con desplazamiento horizontal.
  Widget construirTabla(List<Map<String, dynamic>> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;

        // Ajusta el espaciado para distintos tamaños de pantalla.
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
              border: TableBorder.all(color: Colors.grey.shade300, width: 0.7),
              columns: const [
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Cant.')),
                DataColumn(label: Text('Precio')),
                DataColumn(label: Text('Estado')),
              ],
              rows: items.map((item) {
                final estado = valor(item, ['estado']);

                // Construye las celdas usando los campos disponibles.
                return DataRow(
                  cells: [
                    DataCell(Text(valor(item, ['nombre', 'descripcion']))),
                    DataCell(
                      Text(valor(item, ['cantidad', 'stock', 'existencia'])),
                    ),
                    DataCell(
                      Text(
                        dinero(
                          item['precio'] ??
                              item['costo'] ??
                              item['valor_unitario'],
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        estado,
                        style: TextStyle(
                          color: estado.toLowerCase() == 'activo'
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

  /// Gestiona los estados de espera, error, lista vacía y datos cargados.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.titulo),
        actions: [
          // Repite la consulta a la API manualmente.
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
          // Señala que la carga está en curso.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Permite volver a intentar cuando se produce un error.
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

          // Muestra un mensaje cuando todavía no hay registros.
          if (items.isEmpty) {
            return const Center(child: Text('No hay registros disponibles'));
          }

          // Actualiza el inventario al realizar el gesto de arrastre.
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                registros = cargar();
              });
              await registros;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Usa márgenes más pequeños en pantallas estrechas.
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
