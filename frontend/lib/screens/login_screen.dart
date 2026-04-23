// =============================================================================
// login_screen.dart — Bound2Game Flutter
//
// Pantalla de inicio de sesión y registro.
// Estética minimalista oscura con bordes Cyan Neón y énfasis en el logo.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'main_layout.dart'; // Destino del bypass temporal

// ── Color Tokens ─────────────────────────────────────────────────────────────
const _bg         = Color(0xFF0A0A0A);
const _bgInput    = Color(0xFF151515);
const _cyan       = Color(0xFF00E5FF);
const _cyanDark   = Color(0xFF008B99);
const _textMain   = Color(0xFFE8E8E8);
const _textMuted  = Color(0xFF666666);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _userFocus = FocusNode();

  bool _isEmailFocused = false;
  bool _isPassFocused = false;
  bool _isUserFocused = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() => _isEmailFocused = _emailFocus.hasFocus));
    _passFocus.addListener(() => setState(() => _isPassFocused = _passFocus.hasFocus));
    _userFocus.addListener(() => setState(() => _isUserFocused = _userFocus.hasFocus));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _userCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    _userFocus.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  void _submit() {
    // TODO(backend): Implementar validación real de Firebase/Node.js.
    // Bypass temporal hacia MainLayout.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainLayout()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Logo ─────────────────────────────────────────────────────
                Hero(
                  tag: 'b2g_logo',
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback si la imagen no se encuentra aún
                      return Container(
                        height: 120, width: 120,
                        decoration: BoxDecoration(
                          color: _bgInput,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _cyan.withValues(alpha: 0.3)),
                        ),
                        child: const Center(
                          child: Icon(Icons.videogame_asset_rounded, 
                                      size: 50, color: _cyan),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 60),

                // ── Campos Animados ──────────────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutBack,
                  child: Column(
                    children: [
                      // Nombre de usuario (Solo en Registro)
                      if (!_isLogin) ...[
                        _NeonTextField(
                          controller: _userCtrl,
                          focusNode: _userFocus,
                          isFocused: _isUserFocused,
                          hint: 'Nombre de usuario',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Email
                      _NeonTextField(
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        isFocused: _isEmailFocused,
                        hint: 'Correo electrónico',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Contraseña
                      _NeonTextField(
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

                const SizedBox(height: 32),

                // ── Botón Principal ──────────────────────────────────────────
                GestureDetector(
                  onTap: _submit,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_cyanDark, _cyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _cyan.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _isLogin ? 'Iniciar Sesión' : 'Crear Cuenta',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Toggle Login / Registro ──────────────────────────────────
                GestureDetector(
                  onTap: _toggleMode,
                  child: Text(
                    _isLogin 
                        ? '¿No tienes cuenta? Regístrate' 
                        : '¿Ya tienes cuenta? Inicia sesión',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _textMuted,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET: _NeonTextField
// ─────────────────────────────────────────────────────────────────────────────

class _NeonTextField extends StatefulWidget {
  const _NeonTextField({
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
  State<_NeonTextField> createState() => _NeonTextFieldState();
}

class _NeonTextFieldState extends State<_NeonTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 54,
      decoration: BoxDecoration(
        color: _bgInput,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isFocused ? _cyan : const Color(0xFF2A2A2A),
          width: widget.isFocused ? 1.5 : 1,
        ),
        boxShadow: widget.isFocused
            ? [BoxShadow(color: _cyan.withValues(alpha: 0.15), blurRadius: 10)]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.isPassword && _obscureText,
        keyboardType: widget.keyboardType,
        style: const TextStyle(color: _textMain, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(widget.icon, color: widget.isFocused ? _cyan : _textMuted, size: 20),
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: () => setState(() => _obscureText = !_obscureText),
                  child: Icon(
                    _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: _textMuted,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
