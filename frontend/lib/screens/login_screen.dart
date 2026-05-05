// =============================================================================
// login_screen.dart — Bound2Game · Morphing Splash + Login sin scroll
//
//  FASE 1 (0-3s): Logo 120×120, centro-arriba, fondo transparente, nítido.
//  FASE 2 (viaje): AnimatedContainer crece a 150×220, logo hace fade-out,
//                  fondo oscuro con bordes redondeados aparece.
//  FASE 3 (choques): Carátula cubre el contenedor, rota en cada rebote.
//
//  Stack: negro → elemento morphing → BackdropFilter σ=3 → formulario FadeIn.
//  Formulario: NeverScrollableScrollPhysics, cabe sin scroll en cualquier mov.
// =============================================================================

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main_layout.dart';
import '../services/auth_service.dart';

// ── Paleta (Ahora importada de app_theme.dart) ──────────────────────────────
import '../theme/app_theme.dart';

// ── Carátulas ─────────────────────────────────────────────────────────────────
const List<String> _covers = [
  'https://images.igdb.com/igdb/image/upload/t_cover_big/co1wyy.jpg',
  'https://images.igdb.com/igdb/image/upload/t_cover_big/co2lbd.jpg',
  'https://images.igdb.com/igdb/image/upload/t_cover_big/co4jni.jpg',
  'https://images.igdb.com/igdb/image/upload/t_cover_big/co1r7f.jpg',
  'https://images.igdb.com/igdb/image/upload/t_cover_big/co5vmg.jpg',
  'https://images.igdb.com/igdb/image/upload/t_cover_big/co3wk8.jpg',
  'https://images.igdb.com/igdb/image/upload/t_cover_big/co1yww.jpg',
  'https://images.igdb.com/igdb/image/upload/t_cover_big/co20ke.jpg',
  'https://images.igdb.com/igdb/image/upload/t_cover_big/co5w9d.jpg',
  'https://images.igdb.com/igdb/image/upload/t_cover_big/co4hk5.jpg',
];

// ── Fases ─────────────────────────────────────────────────────────────────────
// Tamaños del AnimatedContainer por fase
const double _logoSize = 350.0; // Fase 1: Colosal y céntrico
const double _cardW    = 150.0; // Fases 2/3/4: ancho normal
const double _cardH    = 220.0; // Fases 2/3/4: alto normal

// Velocidad de rebote
const double _speed = 180.0; // px/s

// =============================================================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // ── Máquina de estados ────────────────────────────────────────────────────
  int _phase = 1; // 1=centro, 2=z-depth, 3=espera, 4=arranque/movimiento

  // ── Posición del elemento ─────────────────────────────────────────────────
  double _x = 0;
  double _y = 0;

  // ── Velocidad y aceleración (Fase 4) ──────────────────────────────────────
  double _dx = 0;
  double _dy = 0;
  double _currentSpeed = 0.0;
  final double _acceleration = 120.0; // px/s^2

  // ── Imagen activa ─────────────────────────────────────────────────────────
  // null → logo | String → URL carátula
  String? _coverUrl;

  final _rng = Random();
  AnimationController? _movementController;
  Duration _lastTime = Duration.zero;
  
  Timer? _timerPhase2;
  Timer? _timerPhase3;
  Timer? _timerPhase4;

  // ── Formulario ─────────────────────────────────────────────────────────────
  double _formOpacity = 0.0;
  bool _isLogin = true;
  bool _isLoading = false;
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _userCtrl   = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  final _userFocus  = FocusNode();
  bool _isEmailFocused = false;
  bool _isPassFocused  = false;
  bool _isUserFocused  = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() => setState(() => _isEmailFocused = _emailFocus.hasFocus));
    _passFocus .addListener(() => setState(() => _isPassFocused  = _passFocus .hasFocus));
    _userFocus .addListener(() => setState(() => _isUserFocused  = _userFocus .hasFocus));

    _movementController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(_onFrame);

    // FASE 2: Reducción y Transformación simultánea (2s)
    _timerPhase2 = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _phase = 2;
        _formOpacity = 1.0;
        _coverUrl = _covers[_rng.nextInt(_covers.length)]; // Inicia el crossfade
      });
    });

    // FASE 3: Arranque y rebote (3.4s - Sincronizado exacto con el fin de la Fase 2)
    _timerPhase3 = Timer(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      setState(() {
        _phase = 3;
        _dx = _rng.nextBool() ? 1 : -1;
        _dy = _rng.nextBool() ? 1 : -1;
        _currentSpeed = 10.0; // Inicia casi en 0
        _lastTime = Duration.zero; // Reiniciar tiempo para un dt limpio
        _movementController?.repeat(); // ARRANQUE DEL MOVIMIENTO
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_phase == 1 && _lastTime == Duration.zero) {
      final size = MediaQuery.of(context).size;
      // CENTRO PURO: Centro absoluto de la pantalla
      _x = (size.width - _logoSize) / 2;
      _y = (size.height - _logoSize) / 2;
    }
  }

  @override
  void dispose() {
    _movementController?.dispose();
    _timerPhase2?.cancel();
    _timerPhase3?.cancel();
    _emailCtrl.dispose(); _passCtrl.dispose(); _userCtrl.dispose();
    _emailFocus.dispose(); _passFocus.dispose(); _userFocus.dispose();
    super.dispose();
  }

  // ── Motor de rebote ───────────────────────────────────────────────────────
  //
  // Física de rebote elástico (restitución = 1):
  //   pos_nueva = pos + velocidad × Δt
  //
  // Colisión:
  //   x < 0    → x = 0,    dx =  |dx|   (rebote →)
  //   x > maxX → x = maxX, dx = −|dx|   (rebote ←)
  //   y < 0    → y = 0,    dy =  |dy|   (rebote ↓)
  //   y > maxY → y = maxY, dy = −|dy|   (rebote ↑)
  //
  // El tamaño de la tarjeta en fases 2/3 es _cardW×_cardH.
  // En el primer choque (fase 2→3): _coverUrl recibe la primera carátula.
  // En choques posteriores: se rota _coverUrl aleatoriamente.

  void _onFrame() {
    if (!mounted || _phase < 3) return;

    final now = _movementController?.lastElapsedDuration ?? Duration.zero;
    final dt = _lastTime == Duration.zero
        ? 0.0
        : (now - _lastTime).inMicroseconds / 1e6;
    _lastTime = now;

    // Aceleración progresiva
    if (_currentSpeed < _speed) {
      _currentSpeed += _acceleration * dt;
      if (_currentSpeed > _speed) _currentSpeed = _speed;
    }

    final size = MediaQuery.of(context).size;
    final maxX = size.width  - _cardW;
    final maxY = size.height - _cardH;

    double mag = sqrt(_dx * _dx + _dy * _dy);
    if (mag > 0) {
      double dirX = _dx / mag;
      double dirY = _dy / mag;

      double nx = _x + dirX * _currentSpeed * dt;
      double ny = _y + dirY * _currentSpeed * dt;
      bool collided = false;

      if (nx < 0)    { nx = 0;    dirX =  dirX.abs(); collided = true; }
      if (nx > maxX) { nx = maxX; dirX = -dirX.abs(); collided = true; }
      if (ny < 0)    { ny = 0;    dirY =  dirY.abs(); collided = true; }
      if (ny > maxY) { ny = maxY; dirY = -dirY.abs(); collided = true; }

      if (collided) {
        String next;
        do {
          next = _covers[_rng.nextInt(_covers.length)];
        } while (next == _coverUrl && _covers.length > 1);
        _coverUrl = next;
      }

      _dx = dirX;
      _dy = dirY;
      setState(() { _x = nx; _y = ny; });
    }
  }

  void _toggleMode() => setState(() => _isLogin = !_isLogin);

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    // 1. Validación de campos vacíos
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      _showError('Por favor, rellena el email y contraseña');
      return;
    }
    if (!_isLogin && _userCtrl.text.trim().isEmpty) {
      _showError('Por favor, indica un nombre de usuario');
      return;
    }

    // 2. Estado de carga
    setState(() => _isLoading = true);

    // 3. Llamada al Backend
    final authService = AuthService();
    Map<String, dynamic> result;

    if (_isLogin) {
      result = await authService.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    } else {
      result = await authService.register(
        _userCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );
    }

    setState(() => _isLoading = false);

    // 4. Navegación o Error
    if (result['success']) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } else {
      _showError(result['error']);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Propiedades del AnimatedContainer según la fase
    final double cW         = _phase == 1 ? _logoSize : _cardW;
    final double cH         = _phase == 1 ? _logoSize : _cardH;
    final Color  cardBg     = Colors.transparent; // Sin fondo residual, solo la carátula
    final double cardRadius = _phase == 1 ? 0.0 : 16.0;

    // Asegurar centrado ÚNICAMENTE durante la Fase 2
    if (_phase == 2) {
      final size = MediaQuery.of(context).size;
      _x = (size.width - _cardW) / 2;
      _y = (size.height - _cardH) / 2;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF292929),
      extendBody: true,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false, // Nunca redimensionar por teclado
      body: SizedBox.expand(
        child: Stack(
          children: [

          // ── CAPA 1: Fondo negro (Scaffold) ───────────────────────────────

          // ── CAPA 2: Elemento morphing ─────────────────────────────────────
          AnimatedPositioned(
            duration: _phase == 2 ? const Duration(milliseconds: 1400) : Duration.zero,
            curve: Curves.easeInOutCubic,
            left: _x,
            top: _y,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeInOutCubic,
              width: cW,
              height: cH,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(cardRadius),
                boxShadow: _phase == 1
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.6),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: AnimatedSwitcher(
                duration: _phase == 2 ? const Duration(milliseconds: 1400) : const Duration(milliseconds: 250),
                switchInCurve: Curves.easeInOutCubic,
                switchOutCurve: Curves.easeInOutCubic,
                child: _coverUrl == null
                    ? Image.asset(
                        'assets/images/logo.png',
                        key: const ValueKey('logo'),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (ctx, e, st) => const Icon(
                          Icons.videogame_asset_rounded,
                          color: AppColors.accent, size: 48,
                        ),
                      )
                    : Container(
                        key: ValueKey(_coverUrl),
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(_coverUrl!),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // ── CAPA 3: Formulario Flotante ──────────────────────────────────────
          AnimatedOpacity(
            opacity: _formOpacity,
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeIn,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.85), // Contraste oscuro sólido
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Título
                              AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        child: Text(
                          _isLogin ? 'Bienvenido de vuelta' : 'Crea tu cuenta',
                          key: ValueKey(_isLogin),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tu biblioteca gaming, en tu bolsillo.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── Campos — expansión suave en registro ──────────────
                      // AnimatedSize 500ms + easeInOutCubic: el campo "Nombre
                      // de usuario" se abre sin overflow ni corte brusco.
                      AnimatedSize(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!_isLogin) ...[
                              _NeonField(
                                controller: _userCtrl,
                                focusNode: _userFocus,
                                isFocused: _isUserFocused,
                                hint: 'Nombre de usuario',
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 12),
                            ],
                            _NeonField(
                              controller: _emailCtrl,
                              focusNode: _emailFocus,
                              isFocused: _isEmailFocused,
                              hint: 'Correo electrónico',
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 12),
                            _NeonField(
                              controller: _passCtrl,
                              focusNode: _passFocus,
                              isFocused: _isPassFocused,
                              hint: 'Contraseña',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      _SubmitButton(
                        label: _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                        isLoading: _isLoading,
                        onTap: _isLoading ? () {} : _submit,
                      ),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: _toggleMode,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, anim) =>
                              FadeTransition(opacity: anim, child: child),
                          child: Text(
                            _isLogin
                                ? '¿No tienes cuenta? Regístrate'
                                : '¿Ya tienes cuenta? Inicia sesión',
                            key: ValueKey('toggle_$_isLogin'),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent.withValues(alpha: 0.85),
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.accent.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGET: _SubmitButton
// =============================================================================

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({required this.label, required this.onTap, this.isLoading = false});
  final String label;
  final VoidCallback onTap;
  final bool isLoading;
  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _pressed
                  ? [AppColors.accentDark, AppColors.accentDark]
                  : [AppColors.accentDark, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: _pressed ? 0.10 : 0.36),
                blurRadius: _pressed ? 4 : 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      widget.label,
                      key: ValueKey(widget.label),
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 0.6,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// WIDGET: _NeonField
// =============================================================================

class _NeonField extends StatefulWidget {
  const _NeonField({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  @override
  State<_NeonField> createState() => _NeonFieldState();
}

class _NeonFieldState extends State<_NeonField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isFocused ? AppColors.accent : const Color(0xFF222222),
          width: widget.isFocused ? 1.5 : 1.0,
        ),
        boxShadow: [
          // Sombra paralela sutil negra
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          if (widget.isFocused)
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.20),
              blurRadius: 12,
            ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.isPassword && _obscure,
        keyboardType: widget.keyboardType,
        style: GoogleFonts.outfit(color: AppColors.foreground, fontSize: 14),
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.outfit(color: AppColors.mutedForeground, fontSize: 14),
          prefixIcon: Icon(
            widget.icon,
            color: widget.isFocused ? AppColors.accent : AppColors.mutedForeground,
            size: 20,
          ),
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: AppColors.mutedForeground,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
