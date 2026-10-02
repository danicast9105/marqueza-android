import 'package:flutter/material.dart';

import '/theme/app_colors.dart';
import '/widgets/input_shell.dart';
import '/widgets/marqueza_alert.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _rememberMe = false;
  bool _obscure = true;
  bool _loading = false;

  // @keyframes float → translateY(0) ↔ translateY(-10px) cada 6s
  late final AnimationController _floatCtrl;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    // Simula el tiempo de respuesta
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    setState(() => _loading = false);

    // Logica del negocio aqui, para cuando se haga la api
    await showMarquezaAlert(
      context,
      title: 'Inicio de sesión exitoso',
      text: 'Bienvenido ${_userCtrl.text.trim()}',
      type: MarquezaAlertType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    // fondo con gradiente imagen
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_4.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Color(0xC212304A), // rgba(18,48,74,.76)
              BlendMode.srcOver,
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildGradientHeader(), // .fondo.left
                _buildForm(), // .formulario.right
              ],
            ),
          ),
        ),
      ),
    );
  }

  // degradado azul + imagen flotante

  Widget _buildGradientHeader() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 230),
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark, // #12304a  → 0%
            AppColors.gradientMid, // #176b86  → 58%
            AppColors.blue, // #27b7f5  → 100%
          ],
          stops: [0.0, 0.58, 1.0],
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _floatAnim,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _floatAnim.value),
            child: child,
          ),
          child: Image.asset(
            'assets/images/fondo_3.png',
            width: MediaQuery.of(context).size.width * 0.7,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.checkroom, size: 100, color: Colors.white54),
          ),
        ),
      ),
    );
  }

  // la columna del formulario
  Widget _buildForm() {
    return Container(
      width: double.infinity,
      color: AppColors.cardBg,
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // .cabecera_titulo icono + MARQUEZA + subtítulo
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/icono_3.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: AppColors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MARQUEZA',
                      style: TextStyle(
                        color: AppColors.textTitle,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.8,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Confecciones que inspiran',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 42),

            // Inicuar sesion
            const Text(
              'Iniciar sesión',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textTitle,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 8),

            const Text(
              'Accede a tu espacio de trabajo y continúa gestionando MARQUEZA.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 26),

            InputShell(
              label: 'Nombre de usuario',
              hint: 'Ingresa tu nombre de usuario',
              icon: Icons.person_outline,
              controller: _userCtrl,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return 'Ingresa tu nombre de usuario';
                final regex = RegExp(r'^[A-Za-z0-9]{3,20}$');
                if (!regex.hasMatch(value)) {
                  return 'Debe tener 3-20 caracteres alfanuméricos';
                }
                return null;
              },
            ),
            const SizedBox(height: 17),

            InputShell(
              label: 'Contraseña',
              hint: 'Ingresa tu contraseña',
              icon: Icons.lock_outline,
              controller: _passCtrl,
              obscure: _obscure,
              suffix: IconButton(
                iconSize: 20,
                splashRadius: 20,
                color: AppColors.textMuted,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) {
                if ((v ?? '').isEmpty) return 'Ingresa tu contraseña';
                return null;
              },
            ),
            const SizedBox(height: 17),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _rememberMe,
                        activeColor: AppColors.blue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        side: const BorderSide(
                          color: AppColors.border,
                          width: 1.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'Recordarme',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    //apartado de recuperar contraseña
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.blueMid,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // botón con degradado
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.blue, AppColors.blueDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blue.withValues(alpha: 0.25),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Iniciar sesión',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 18),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, size: 16, color: AppColors.blue),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Tus datos se utilizan únicamente para validar el acceso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textNote),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ─── .footer ───
            const Center(
              child: Text(
                '© 2026 Marqueza.C - Todos los derechos reservados',
                style: TextStyle(fontSize: 10, color: AppColors.textLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
