// Esta es la pantalla de Login y Registro. He querido hacer algo especial con una animación tipo "splash" que se transforma en el formulario.
// La idea es que mientras el usuario se lo piensa, vea carátulas de juegos rebotando por la pantalla como el antiguo logo de DVD.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main_layout.dart';
import '../services/api_service.dart';

// Estas son algunas de las carátulas que irán rebotando por el fondo.
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

const double _logoSize = 350.0; 
const double _cardW    = 150.0; 
const double _cardH    = 220.0; 
const double _speed = 180.0; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // Controlamos en qué fase de la animación estamos.
  int _phase = 1; 

  double _x = 0;
  double _y = 0;
  double _dx = 0;
  double _dy = 0;
  double _currentSpeed = 0.0;
  final double _acceleration = 120.0; 

  String? _coverUrl;
  final _rng = Random();
  AnimationController? _movementController;
  Duration _lastTime = Duration.zero;
  Timer? _timerPhase2;
  Timer? _timerPhase3;

  double _formOpacity = 0.0;
  bool _isLogin = true;
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _userCtrl   = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus  = FocusNode();
  final _userFocus  = FocusNode();
  bool _isEmailFocused = false;
  bool _isPassFocused  = false;
  bool _isUserFocused  = false;
  bool _isLoading      = false;

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

    // Arrancamos la secuencia de la animación: del logo gigante a las carátulas rebotando.
    _timerPhase2 = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _phase = 2;
        _formOpacity = 1.0;
        _coverUrl = _covers[_rng.nextInt(_covers.length)];
      });
    });

    _timerPhase3 = Timer(const Duration(milliseconds: 3400), () {
      if (!mounted) return;
      setState(() {
        _phase = 3;
        _dx = _rng.nextBool() ? 1 : -1;
        _dy = _rng.nextBool() ? 1 : -1;
        _currentSpeed = 10.0;
        _lastTime = Duration.zero;
        _movementController?.repeat(); 
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_phase == 1 && _lastTime == Duration.zero) {
      final size = MediaQuery.of(context).size;
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

  // Este es el motor de los rebotes. He intentado imitar el efecto clásico del logo de DVD.
  void _onFrame() {
    if (!mounted || _phase < 3) return;

    final now = _movementController?.lastElapsedDuration ?? Duration.zero;
    final dt = _lastTime == Duration.zero ? 0.0 : (now - _lastTime).inMicroseconds / 1e6;
    _lastTime = now;

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

      // Cada vez que choca, cambiamos la carátula para que no sea aburrido.
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

  // Cuando el usuario pulsa el botón, mandamos los datos al servidor.
  Future<void> _submit() async {
    if (_isLoading) return;
    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final username = _userCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Por favor, completa todos los campos.');
      return;
    }
    if (!_isLogin && username.isEmpty) {
      _showError('Introduce un nombre de usuario.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isLogin) {
        await ApiService.login(email, password);
      } else {
        await ApiService.register(username, email, password);
        await ApiService.login(email, password);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
    } on ApiException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('No se puede conectar con el servidor. Verifica tu red.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFCC3333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cW         = _phase == 1 ? _logoSize : _cardW;
    final double cH         = _phase == 1 ? _logoSize : _cardH;
    final double cardRadius = _phase == 1 ? 0.0 : 16.0;

    if (_phase == 2) {
      final size = MediaQuery.of(context).size;
      _x = (size.width - _cardW) / 2;
      _y = (size.height - _cardH) / 2;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF292929),
      resizeToAvoidBottomInset: false, 
      body: SizedBox.expand(
        child: Stack(
          children: [
          AnimatedPositioned(
            duration: _phase == 2 ? const Duration(milliseconds: 1400) : Duration.zero,
            curve: Curves.easeInOutCubic,
            left: _x, top: _y,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1400),
              curve: Curves.easeInOutCubic,
              width: cW, height: cH,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardRadius),
                boxShadow: _phase == 1 ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child: AnimatedSwitcher(
                duration: _phase == 2 ? const Duration(milliseconds: 1400) : const Duration(milliseconds: 250),
                child: _coverUrl == null
                    ? Image.asset('assets/images/logo.png', key: const ValueKey('logo'), fit: BoxFit.contain)
                    : Container(key: ValueKey(_coverUrl), decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(_coverUrl!), fit: BoxFit.cover))),
              ),
            ),
          ),
          // El formulario que aparece sobre el fondo.
          AnimatedOpacity(
            opacity: _formOpacity,
            duration: const Duration(milliseconds: 700),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFF1A1A1A).withValues(alpha: 0.85), borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            child: Text(_isLogin ? 'Bienvenido de vuelta' : 'Crea tu cuenta', key: ValueKey(_isLogin), textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                          const SizedBox(height: 4),
                          Text('Tu biblioteca gaming, en tu bolsillo.', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 12, color: const Color(0xFF888888))),
                          const SizedBox(height: 22),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!_isLogin) ...[
                                  _NeonField(controller: _userCtrl, focusNode: _userFocus, isFocused: _isUserFocused, hint: 'Nombre de usuario', icon: Icons.person_outline_rounded),
                                  const SizedBox(height: 12),
                                ],
                                _NeonField(controller: _emailCtrl, focusNode: _emailFocus, isFocused: _isEmailFocused, hint: 'Correo electrónico', icon: Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
                                const SizedBox(height: 12),
                                _NeonField(controller: _passCtrl, focusNode: _passFocus, isFocused: _isPassFocused, hint: 'Contraseña', icon: Icons.lock_outline_rounded, isPassword: true),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _SubmitButton(label: _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta', isLoading: _isLoading, onTap: _submit),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _toggleMode,
                            child: Text(_isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión', textAlign: TextAlign.center, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFFFB800), decoration: TextDecoration.underline)),
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

// El botón principal de la app, con un degradado amarillo y negro.
class _SubmitButton extends StatefulWidget {
  const _SubmitButton({required this.label, required this.onTap, this.isLoading = false});
  final String   label;
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
      onTapDown: widget.isLoading ? null : (_) => setState(() => _pressed = true),
      onTapUp: widget.isLoading ? null : (_) { setState(() => _pressed = false); widget.onTap(); },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFCC9900), Color(0xFFFFB800)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: const Color(0xFFFFB800).withValues(alpha: 0.36), blurRadius: 18, offset: const Offset(0, 4))],
          ),
          child: Center(
            child: widget.isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : Text(widget.label, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black)),
          ),
        ),
      ),
    );
  }
}

// Un pequeño componente para los campos de texto con un efecto de borde iluminado.
class _NeonField extends StatelessWidget {
  const _NeonField({required this.controller, required this.focusNode, required this.isFocused, required this.hint, required this.icon, this.isPassword = false, this.keyboardType = TextInputType.text});
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFocused ? const Color(0xFFFFB800) : const Color(0xFF333333), width: isFocused ? 1.5 : 1.0),
      ),
      child: TextField(
        controller: controller, focusNode: focusNode,
        obscureText: isPassword, keyboardType: keyboardType,
        style: GoogleFonts.outfit(color: Colors.white, fontSize: 14),
        cursorColor: const Color(0xFFFFB800),
        decoration: InputDecoration(
          hintText: hint, hintStyle: GoogleFonts.outfit(color: const Color(0xFF888888), fontSize: 14),
          prefixIcon: Icon(icon, color: isFocused ? const Color(0xFFFFB800) : const Color(0xFF888888), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
