import 'package:flutter/material.dart';

import '../../core/config/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../routes/app_routes.dart';

/// Pantalla de acceso a la aplicación.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();
  bool _cargando = false;
  bool _ocultarContrasena = true;
  bool _recordarme = false;
  String? _error;

  @override
  void dispose() {
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  /// Envía las credenciales y abre el inicio únicamente si la API las acepta.
  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate() || _cargando) return;
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await AuthService.iniciarSesion(
        _usuarioController.text,
        _contrasenaController.text,
        recordarSesion: _recordarme,
      );
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo iniciar sesión: $error');
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Pide un correo y solicita a la API el enlace de recuperación.
  Future<void> _recuperarContrasena() async {
    final correoController = TextEditingController(
      text: _usuarioController.text.contains('@')
          ? _usuarioController.text.trim()
          : '',
    );
    final correoKey = GlobalKey<FormState>();

    try {
      final correo = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Recuperar contraseña'),
          content: Form(
            key: correoKey,
            child: TextFormField(
              controller: correoController,
              autofocus: true,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa tu correo electrónico';
                }
                if (!value.contains('@')) return 'Ingresa un correo válido';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (correoKey.currentState!.validate()) {
                  Navigator.pop(dialogContext, correoController.text.trim());
                }
              },
              child: const Text('Enviar enlace'),
            ),
          ],
        ),
      );

      if (correo == null || !mounted) return;
      final mensaje = await AuthService.solicitarRecuperacion(correo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: AppColors.petrol),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo solicitar la recuperación: $error'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      correoController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8D7E5),
      body: Stack(
        children: [
          const Positioned.fill(child: _FondoCostura()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final escritorio = constraints.maxWidth >= 760;
                final margen = constraints.maxWidth < 480 ? 16.0 : 28.0;
                return SingleChildScrollView(
                  padding: EdgeInsets.all(margen),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - margen * 2,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: 22,
                          shadowColor: AppColors.deepPetrol.withValues(
                            alpha: 0.22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: escritorio
                              ? ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 690,
                                  ),
                                  child: Row(
                                    children: [
                                      const Expanded(
                                        flex: 5,
                                        child: _PanelTextil(),
                                      ),
                                      Expanded(
                                        flex: 6,
                                        child: _FormularioLogin(
                                          formKey: _formKey,
                                          usuarioController: _usuarioController,
                                          contrasenaController:
                                              _contrasenaController,
                                          cargando: _cargando,
                                          ocultarContrasena: _ocultarContrasena,
                                          recordarme: _recordarme,
                                          error: _error,
                                          onCambiarVisibilidad: () => setState(
                                            () => _ocultarContrasena =
                                                !_ocultarContrasena,
                                          ),
                                          onCambiarRecordarme: (value) =>
                                              setState(
                                                () => _recordarme =
                                                    value ?? false,
                                              ),
                                          onRecuperar: _recuperarContrasena,
                                          onIniciarSesion: _iniciarSesion,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _FormularioLogin(
                                  formKey: _formKey,
                                  usuarioController: _usuarioController,
                                  contrasenaController: _contrasenaController,
                                  cargando: _cargando,
                                  ocultarContrasena: _ocultarContrasena,
                                  recordarme: _recordarme,
                                  error: _error,
                                  mostrarMarcaCompacta: true,
                                  onCambiarVisibilidad: () => setState(
                                    () => _ocultarContrasena =
                                        !_ocultarContrasena,
                                  ),
                                  onCambiarRecordarme: (value) => setState(
                                    () => _recordarme = value ?? false,
                                  ),
                                  onRecuperar: _recuperarContrasena,
                                  onIniciarSesion: _iniciarSesion,
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibuja un fondo claro con motivos textiles en azul.
class _FondoCostura extends StatelessWidget {
  const _FondoCostura();

  @override
  Widget build(BuildContext context) {
    const iconos = [
      Icons.checkroom_rounded,
      Icons.content_cut_rounded,
      Icons.straighten_rounded,
      Icons.circle_outlined,
      Icons.design_services_rounded,
      Icons.grain_rounded,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnas = (constraints.maxWidth / 105).ceil();
        final filas = (constraints.maxHeight / 92).ceil();
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFFB8D7E5)),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              runAlignment: WrapAlignment.spaceAround,
              children: List.generate(columnas * filas, (index) {
                final icono = iconos[index % iconos.length];
                return SizedBox(
                  width: constraints.maxWidth / columnas,
                  height: 92,
                  child: Transform.rotate(
                    angle: (index % 2 == 0 ? -1 : 1) * 0.28,
                    child: Icon(
                      icono,
                      size: 34 + (index % 3) * 7,
                      color: AppColors.petrol.withValues(alpha: 0.24),
                    ),
                  ),
                );
              }),
            ),
            ColoredBox(color: AppColors.deepPetrol.withValues(alpha: 0.28)),
          ],
        );
      },
    );
  }
}

/// Panel ilustrado con degradado y motivos de confección.
class _PanelTextil extends StatelessWidget {
  const _PanelTextil();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.deepPetrol, AppColors.teal, AppColors.cyan],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(right: -120, top: -90, child: _circulo(360, 0.10)),
          Positioned(left: -175, bottom: -240, child: _circulo(500, 0.08)),
          const Positioned(
            top: 24,
            left: 24,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.mint,
              size: 24,
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _IlustracionCostura(),
                  const SizedBox(height: 32),
                  const Text(
                    'MARQUEZA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Confecciones que inspiran',
                    style: TextStyle(color: Color(0xFFD4E3E8), fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _circulo(double tamano, double opacidad) => Container(
    width: tamano,
    height: tamano,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white.withValues(alpha: opacidad),
        width: 2,
      ),
    ),
  );
}

/// Ilustración vectorial de máquina de coser hecha con elementos Flutter.
class _IlustracionCostura extends StatelessWidget {
  const _IlustracionCostura();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 330,
      height: 245,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          const Positioned(
            left: 6,
            top: 24,
            child: Icon(
              Icons.checkroom_rounded,
              size: 124,
              color: Color(0xFFFFD1C8),
            ),
          ),
          Positioned(
            right: 12,
            top: 42,
            child: Icon(
              Icons.design_services_rounded,
              size: 108,
              color: const Color(0xFFFFF1D2).withValues(alpha: 0.94),
            ),
          ),
          Positioned(
            bottom: 28,
            left: 48,
            child: Container(
              width: 224,
              height: 23,
              decoration: BoxDecoration(
                color: const Color(0xFF20A7A4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8EE6D7), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 66,
            child: Container(
              width: 186,
              height: 75,
              decoration: BoxDecoration(
                color: const Color(0xFF27B5AC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(34),
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(color: const Color(0xFF8EE6D7), width: 2),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 70,
            child: Container(
              width: 37,
              height: 114,
              decoration: BoxDecoration(
                color: const Color(0xFF169C9D),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8EE6D7), width: 2),
              ),
            ),
          ),
          Positioned(
            bottom: 111,
            left: 92,
            child: Container(
              width: 142,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF27B5AC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF8EE6D7), width: 2),
              ),
            ),
          ),
          Positioned(
            top: 88,
            left: 124,
            child: Container(width: 3, height: 49, color: AppColors.mint),
          ),
          const Positioned(
            bottom: 64,
            left: 157,
            child: Icon(
              Icons.settings_rounded,
              color: Color(0xFFFFC56D),
              size: 30,
            ),
          ),
          Positioned(
            right: 32,
            bottom: 48,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF17883),
                border: Border.all(color: const Color(0xFFFFC6BA), width: 3),
              ),
              child: const Icon(
                Icons.circle,
                size: 14,
                color: Color(0xFFFFD5C9),
              ),
            ),
          ),
          const Positioned(
            top: 48,
            right: 66,
            child: Icon(
              Icons.grain_rounded,
              color: Color(0xFFFFB6A8),
              size: 39,
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulario blanco con los campos y controles de acceso.
class _FormularioLogin extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usuarioController;
  final TextEditingController contrasenaController;
  final bool cargando;
  final bool ocultarContrasena;
  final bool recordarme;
  final String? error;
  final bool mostrarMarcaCompacta;
  final VoidCallback onCambiarVisibilidad;
  final ValueChanged<bool?> onCambiarRecordarme;
  final VoidCallback onRecuperar;
  final VoidCallback onIniciarSesion;

  const _FormularioLogin({
    required this.formKey,
    required this.usuarioController,
    required this.contrasenaController,
    required this.cargando,
    required this.ocultarContrasena,
    required this.recordarme,
    required this.error,
    required this.onCambiarVisibilidad,
    required this.onCambiarRecordarme,
    required this.onRecuperar,
    required this.onIniciarSesion,
    this.mostrarMarcaCompacta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: mostrarMarcaCompacta ? 28 : 54,
        vertical: 38,
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (mostrarMarcaCompacta) ...[
              const _Marca(),
              const SizedBox(height: 34),
            ] else ...[
              const _Marca(),
              const SizedBox(height: 46),
            ],
            const Text(
              'Iniciar sesión',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Accede a tu espacio de trabajo y continúa gestionando MARQUEZA.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            const _EtiquetaCampo('Nombre de usuario'),
            const SizedBox(height: 8),
            TextFormField(
              controller: usuarioController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Admin',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa tu usuario o correo'
                  : null,
            ),
            const SizedBox(height: 20),
            const _EtiquetaCampo('Contraseña'),
            const SizedBox(height: 8),
            TextFormField(
              controller: contrasenaController,
              obscureText: ocultarContrasena,
              onFieldSubmitted: (_) => onIniciarSesion(),
              decoration: InputDecoration(
                hintText: 'Ingresa tu contraseña',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  tooltip: ocultarContrasena
                      ? 'Mostrar contraseña'
                      : 'Ocultar contraseña',
                  onPressed: onCambiarVisibilidad,
                  icon: Icon(
                    ocultarContrasena
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                ),
              ),
              validator: (value) => value == null || value.isEmpty
                  ? 'Ingresa tu contraseña'
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: recordarme,
                    activeColor: AppColors.teal,
                    onChanged: onCambiarRecordarme,
                    side: const BorderSide(color: AppColors.muted),
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'Recordarme',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onRecuperar,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: cargando ? null : onIniciarSesion,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  shadowColor: AppColors.teal.withValues(alpha: 0.28),
                ),
                child: cargando
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tus datos se utilizan únicamente para validar el acceso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 30),
            const Text(
              '© 2026 Marqueza.C - Todos los derechos reservados',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logotipo tipográfico acompañado de un símbolo de confección.
class _Marca extends StatelessWidget {
  const _Marca();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome_rounded, color: AppColors.cyan, size: 35),
        SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MARQUEZA',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 23,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Confecciones que inspiran',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

/// Rótulo destacado para los campos del formulario.
class _EtiquetaCampo extends StatelessWidget {
  final String texto;

  const _EtiquetaCampo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
