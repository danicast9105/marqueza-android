import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/services/recurso_api_service.dart';
import '../../data/model/modulo_api.dart';

String _etiquetaCampo(String clave) => clave
    .split('_')
    .map(
      (parte) => parte.isEmpty
          ? parte
          : '${parte[0].toUpperCase()}${parte.substring(1)}',
    )
    .join(' ');

/// Lista, consulta y administra registros de un módulo de la API.
class RecursoScreen extends StatefulWidget {
  final ModuloApi modulo;
  final VoidCallback? onRegresar;

  const RecursoScreen({super.key, required this.modulo, this.onRegresar});

  @override
  State<RecursoScreen> createState() => _RecursoScreenState();
}

class _RecursoScreenState extends State<RecursoScreen> {
  late Future<List<Map<String, dynamic>>> _registros;
  Map<String, dynamic> _plantilla = {};
  bool _procesando = false;

  @override
  void initState() {
    super.initState();
    _registros = _consultar();
  }

  Future<List<Map<String, dynamic>>> _consultar() async {
    final registros = await RecursoApiService.listar(widget.modulo);
    if (registros.isNotEmpty) _plantilla = registros.first;
    return registros;
  }

  void _recargar() {
    setState(() => _registros = _consultar());
  }

  String _texto(dynamic valor) {
    if (valor == null) return '—';
    if (valor is Map || valor is List) {
      return const JsonEncoder.withIndent('  ').convert(valor);
    }
    return valor.toString();
  }

  String _resumen(Map<String, dynamic> registro) {
    final partes = <String>[];
    for (final campo in widget.modulo.camposResumen) {
      final valor = registro[campo];
      if (valor != null && valor.toString().trim().isNotEmpty) {
        partes.add('${_etiquetaCampo(campo)}: ${_texto(valor)}');
      }
    }
    if (partes.isEmpty) {
      for (final campo
          in registro.keys
              .where((key) => key != 'id' && key != 'uuid')
              .take(2)) {
        partes.add('${_etiquetaCampo(campo)}: ${_texto(registro[campo])}');
      }
    }
    return partes.join('\n');
  }

  int? _id(Map<String, dynamic> registro) {
    final value = registro['id'];
    if (value is int && value > 0) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _verDetalle(Map<String, dynamic> registro) async {
    final navigator = Navigator.of(context);
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _DetalleRecursoScreen(
          modulo: widget.modulo,
          registro: registro,
          procesando: _procesando,
          soloLectura: widget.modulo.soloLectura,
          onRegresar: () => navigator.pop(),
          onEditar: () async {
            final editado = await _abrirFormulario(registro: registro);
            if (editado && mounted) Navigator.of(context).pop();
          },
          onEliminar: () => _confirmarEliminacion(registro),
        ),
      ),
    );
  }

  Future<bool> _abrirFormulario({Map<String, dynamic>? registro}) async {
    final campos = registro == null
        ? _plantilla.keys.where((key) => key != 'id' && key != 'uuid').toList()
        : registro.keys.where((key) => key != 'id' && key != 'uuid').toList();

    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _FormularioRecursoScreen(
          modulo: widget.modulo,
          registro: registro,
          campos: campos,
          plantilla: _plantilla,
        ),
      ),
    );
    if (resultado == true && mounted) {
      _recargar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.modulo.titulo}: operación completada.'),
        ),
      );
    }
    return resultado == true;
  }

  Future<void> _confirmarEliminacion(Map<String, dynamic> registro) async {
    final id = _id(registro);
    if (id == null || _procesando) return;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar ${widget.modulo.titulo.toLowerCase()}'),
        content: const Text(
          'Esta acción eliminará el registro de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;

    setState(() => _procesando = true);
    try {
      final mensaje = await RecursoApiService.eliminar(widget.modulo, id);
      if (!mounted) return;
      _recargar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: AppColors.petrol),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo eliminar: $error'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _crearRegistro() async => _abrirFormulario();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.modulo.titulo),
        leading: IconButton(
          tooltip: 'Regresar',
          onPressed: widget.onRegresar ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _recargar,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: widget.modulo.soloLectura
          ? null
          : FloatingActionButton.extended(
              onPressed: _procesando ? null : _crearRegistro,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo registro'),
            ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _registros,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EstadoRecurso(
              mensaje: 'No se pudo consultar ${widget.modulo.titulo}.',
              detalle: '${snapshot.error}',
              onReintentar: _recargar,
            );
          }

          final registros = snapshot.data ?? [];
          if (registros.isEmpty) {
            return _EstadoRecurso(
              mensaje: 'No hay registros en ${widget.modulo.titulo}.',
              detalle: widget.modulo.soloLectura
                  ? 'Este módulo es de solo lectura y no hay registros para mostrar.'
                  : 'La documentación no describe un esquema para generar '
                        'campos automáticamente. Puedes crear el registro '
                        'especificando el JSON del recurso.',
              onReintentar: _recargar,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _recargar();
              await _registros;
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              children: [
                Text(
                  widget.modulo.descripcion,
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  '${registros.length} registros',
                  style: const TextStyle(
                    color: AppColors.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...registros.map(
                  (registro) => Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      onTap: () => _verDetalle(registro),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.paleCyan,
                        foregroundColor: AppColors.petrol,
                        child: Text('${registro['id'] ?? '•'}'),
                      ),
                      title: Text(
                        _texto(
                          _valorPrincipal(registro) ?? 'Registro sin nombre',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _resumen(registro),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  dynamic _valorPrincipal(Map<String, dynamic> registro) {
    for (final key in [
      'nombre',
      'empresa',
      'numero',
      'factura',
      'codigo',
      'tipo_dato',
      'action',
      'correo',
      'contenido',
    ]) {
      final value = registro[key];
      if (value != null && value.toString().trim().isNotEmpty) return value;
    }
    return registro['id'];
  }
}

/// Presenta cada campo de un registro y las acciones CRUD.
class _DetalleRecursoScreen extends StatelessWidget {
  final ModuloApi modulo;
  final Map<String, dynamic> registro;
  final bool procesando;
  final bool soloLectura;
  final VoidCallback onRegresar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const _DetalleRecursoScreen({
    required this.modulo,
    required this.registro,
    required this.procesando,
    required this.soloLectura,
    required this.onRegresar,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Detalle de ${modulo.titulo.toLowerCase()}'),
        leading: IconButton(
          tooltip: 'Regresar',
          onPressed: onRegresar,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entrada in registro.entries) ...[
                    Text(
                      _etiquetaCampo(entrada.key).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.teal,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      entrada.value is Map || entrada.value is List
                          ? const JsonEncoder.withIndent('  ')
                                .convert(entrada.value)
                          : entrada.value?.toString() ?? 'No registrado',
                      style: const TextStyle(color: AppColors.text),
                    ),
                    const Divider(height: 22),
                  ],
                ],
              ),
            ),
          ),
          if (!soloLectura) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: procesando ? null : onEditar,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar registro'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: procesando ? null : onEliminar,
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar registro'),
            ),
          ],
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Regresar'),
          ),
        ],
      ),
    );
  }
}

/// Formulario generado con campos observados y un editor JSON complementario.
class _FormularioRecursoScreen extends StatefulWidget {
  final ModuloApi modulo;
  final Map<String, dynamic>? registro;
  final List<String> campos;
  final Map<String, dynamic> plantilla;

  const _FormularioRecursoScreen({
    required this.modulo,
    required this.registro,
    required this.campos,
    required this.plantilla,
  });

  @override
  State<_FormularioRecursoScreen> createState() =>
      _FormularioRecursoScreenState();
}

class _FormularioRecursoScreenState extends State<_FormularioRecursoScreen> {
  late final Map<String, TextEditingController> _controladores;
  final _jsonController = TextEditingController(text: '{}');
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _controladores = {
      for (final campo in widget.campos)
        campo: TextEditingController(
          text: _valorInicial(widget.registro?[campo]),
        ),
    };
  }

  String _valorInicial(dynamic valor) {
    if (valor == null) return '';
    if (valor is Map || valor is List) {
      return const JsonEncoder.withIndent('  ').convert(valor);
    }
    return valor.toString();
  }

  dynamic _convertir(String clave, String valor) {
    final muestra = widget.registro?[clave] ?? widget.plantilla[clave];
    if (muestra is int) {
      final numero = int.tryParse(valor);
      if (numero == null) {
        throw FormatException('${_etiquetaCampo(clave)} debe ser entero.');
      }
      return numero;
    }
    if (muestra is double) {
      final numero = double.tryParse(valor);
      if (numero == null) {
        throw FormatException('${_etiquetaCampo(clave)} debe ser numérico.');
      }
      return numero;
    }
    if (muestra is num) {
      final numero = num.tryParse(valor);
      if (numero == null) {
        throw FormatException('${_etiquetaCampo(clave)} debe ser numérico.');
      }
      return numero;
    }
    if (muestra is bool) {
      if (valor.toLowerCase() == 'true' || valor == '1') return true;
      if (valor.toLowerCase() == 'false' || valor == '0') return false;
      throw FormatException('${_etiquetaCampo(clave)} debe ser true o false.');
    }
    if (muestra is List || muestra is Map) return json.decode(valor);
    return valor;
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate() || _guardando) return;

    final datos = <String, dynamic>{};
    try {
      for (final entrada in _controladores.entries) {
        final texto = entrada.value.text.trim();
        if (texto.isNotEmpty) {
          datos[entrada.key] = _convertir(entrada.key, texto);
        }
      }

      final extrasTexto = _jsonController.text.trim();
      if (extrasTexto.isNotEmpty) {
        final extras = json.decode(extrasTexto);
        if (extras is! Map) {
          throw const FormatException(
            'Los campos JSON adicionales deben ser un objeto JSON.',
          );
        }
        for (final entrada in extras.entries) {
          if (entrada.key is! String) {
            throw const FormatException(
              'Las claves del objeto JSON deben ser texto.',
            );
          }
          datos[entrada.key as String] = entrada.value;
        }
      }

      final id = widget.registro?['id'];
      setState(() => _guardando = true);
      if (widget.registro == null) {
        await RecursoApiService.crear(widget.modulo, datos);
      } else if (id is int) {
        await RecursoApiService.actualizar(widget.modulo, id, datos);
      } else {
        throw const FormatException(
          'El registro no contiene un ID entero para actualizar.',
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo guardar: $error'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  void dispose() {
    for (final controlador in _controladores.values) {
      controlador.dispose();
    }
    _jsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editando = widget.registro != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${editando ? 'Editar' : 'Nuevo'} ${widget.modulo.titulo.toLowerCase()}',
        ),
        leading: IconButton(
          tooltip: 'Regresar',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.campos.isEmpty
                  ? 'La respuesta no contiene registros de ejemplo. '
                        'Usa el JSON para indicar los campos admitidos por la API.'
                  : 'Campos inferidos de los registros devueltos por la API. '
                        'Revisa la respuesta del servidor al guardar.',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            for (final campo in widget.campos)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _controladores[campo],
                  keyboardType: _tipoTeclado(
                    widget.registro?[campo] ?? widget.plantilla[campo],
                  ),
                  maxLines:
                      (widget.registro?[campo] ?? widget.plantilla[campo])
                              is List ||
                          (widget.registro?[campo] ?? widget.plantilla[campo])
                              is Map
                      ? 4
                      : 1,
                  decoration: InputDecoration(
                    labelText: _etiquetaCampo(campo),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Campos JSON adicionales',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _jsonController,
              minLines: 4,
              maxLines: 10,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(
                hintText: '{"campo": "valor"}',
                helperText: 'Debe ser un objeto JSON. Sus claves se combinan con los campos anteriores.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                try {
                  if (json.decode(value) is! Map) {
                    return 'Ingresa un objeto JSON entre llaves.';
                  }
                } on FormatException {
                  return 'El JSON no tiene un formato válido.';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon: _guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(editando ? 'Guardar cambios' : 'Crear registro'),
            ),
          ],
        ),
      ),
    );
  }

  TextInputType _tipoTeclado(dynamic muestra) {
    if (muestra is int || muestra is double) {
      return const TextInputType.numberWithOptions(decimal: true);
    }
    return TextInputType.text;
  }
}

/// Muestra un mensaje informativo con acción para reintentar.
class _EstadoRecurso extends StatelessWidget {
  final String mensaje;
  final String detalle;
  final VoidCallback onReintentar;

  const _EstadoRecurso({
    required this.mensaje,
    required this.detalle,
    required this.onReintentar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.teal,
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              detalle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar consulta'),
            ),
          ],
        ),
      ),
    );
  }
}
