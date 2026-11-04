import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/config/ruta.dart';
import '../../core/services/api_service.dart';

class InventarioScreen extends StatefulWidget {
  final String titulo;
  final String endpoint;

  const InventarioScreen({
    super.key,
    required this.titulo,
    required this.endpoint,
  });

  @override
  State<InventarioScreen> createState() =>
      _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  late Future<List<Map<String, dynamic>>> registros;

  @override
  void initState() {
    super.initState();
    registros = cargar();
  }

  Future<List<Map<String, dynamic>>> cargar() async {
    final response = await ApiService.get(
      '${Ruta.baseUrl}${widget.endpoint}',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception('Error al cargar los datos');
    }

    final data = json.decode(response.body);
    dynamic lista = data;

    if (data is Map) {
      lista = data['datos'] ??
          data['data'] ??
          data['productos'] ??
          data['insumos'] ??
          data['resultado'];
    }

    if (lista is! List) {
      throw Exception('Formato de respuesta incorrecto');
    }

    return lista
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String valor(Map<String, dynamic> item, List<String> claves) {
    for (final clave in claves) {
      if (item[clave] != null) {
        return item[clave].toString();
      }
    }
    return '-';
  }

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

  Widget construirTabla(List<Map<String, dynamic>> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth;

        final espacioColumnas = ancho < 400
            ? 10.0
            : ancho < 700
                ? 18.0
                : 30.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: ancho,
            ),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                const Color(0xFF1E3A5F),
              ),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 60,
              columnSpacing: espacioColumnas,
              horizontalMargin: 12,
              border: TableBorder.all(
                color: Colors.grey.shade300,
                width: 0.7,
              ),
              columns: const [
                DataColumn(label: Text('Nombre')),
                DataColumn(label: Text('Cant.')),
                DataColumn(label: Text('Precio')),
                DataColumn(label: Text('Estado')),
              ],
              rows: items.map((item) {
                final estado = valor(item, ['estado']);

                return DataRow(
                  cells: [
                    DataCell(
                      Text(valor(item, ['nombre', 'descripcion'])),
                    ),
                    DataCell(
                      Text(valor(
                        item,
                        ['cantidad', 'stock', 'existencia'],
                      )),
                    ),
                    DataCell(
                      Text(dinero(
                        item['precio'] ??
                            item['costo'] ??
                            item['valor_unitario'],
                      )),
                    ),
                    DataCell(
                      Text(
                        estado,
                        style: TextStyle(
                          color: estado.toLowerCase() == 'activo'
                              ? Colors.green
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(widget.titulo),
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        actions: [
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

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

          if (items.isEmpty) {
            return const Center(
              child: Text('No hay registros disponibles'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                registros = cargar();
              });
              await registros;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
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