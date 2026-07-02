import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/premium_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();
  bool _isRegister = false;
  bool _loading    = false;
  bool _obscure    = true;
  String? _errorMsg;

  Future<void> _submit() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all fields');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });

    String? error;
    if (_isRegister) {
      error = await AuthService.instance.register(email, password, _nameCtrl.text.trim());
    } else {
      error = await AuthService.instance.login(email, password);
    }

    if (!mounted) return;
    if (error != null) {
      setState(() { _loading = false; _errorMsg = error; });
    } else {
      // GoRouter refreshListenable will auto-redirect via the redirect guard
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); _passwordCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=900&q=85',
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0A3D2E), Color(0xFF1B6B3A)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
              ),
              errorWidget: (_, _, _) => Container(color: const Color(0xFF0A3D2E)),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x44000000), Color(0xCC000000)],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: ParticleBackground(
              color: Colors.white, count: 20,
              child: const SizedBox.expand(),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 48),

                  // Logo
                  Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1B6B3A), Color(0xFF2E9E58)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: kPrimary.withValues(alpha: 0.5), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 14),
                    Text('CROP+', style: GoogleFonts.plusJakartaSans(
                        color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 3)),
                    const SizedBox(height: 4),
                    Text('Carbon + Nutrition Intelligence', style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.65), fontSize: 12, letterSpacing: 0.5)),
                  ]).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

                  const SizedBox(height: 40),

                  PremiumGlassCard(
                    dark: false, tint: Colors.white, blur: 20,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isRegister ? 'Create Account' : 'Welcome Back 👋',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 24, fontWeight: FontWeight.w800, color: kTextDark)),
                        const SizedBox(height: 4),
                        Text(_isRegister ? 'Sign up to get started' : 'Sign in to continue',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey)),
                        const SizedBox(height: 24),

                        if (_isRegister) ...[
                          _input(_nameCtrl, 'Full Name', Icons.person_outline_rounded),
                          const SizedBox(height: 14),
                        ],
                        _input(_emailCtrl, 'Email', Icons.email_outlined,
                            keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: _obscure,
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, color: kTextDark),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: kPrimary, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: kTextGrey, size: 20),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),

                        if (_errorMsg != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: kAccentRed.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: kAccentRed.withValues(alpha: 0.3)),
                            ),
                            child: Row(children: [
                              const Icon(Icons.error_outline_rounded, color: kAccentRed, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMsg!,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: kAccentRed))),
                            ]),
                          ),
                        ],

                        const SizedBox(height: 20),

                        TapScale(
                          onTap: _loading ? null : _submit,
                          child: Container(
                            width: double.infinity, height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A3D2E), Color(0xFF1B6B3A)],
                                begin: Alignment.centerLeft, end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: kPrimary.withValues(alpha: 0.45),
                                  blurRadius: 16, offset: const Offset(0, 6))],
                            ),
                            child: Center(
                              child: _loading
                                  ? const SizedBox(width: 22, height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Text(_isRegister ? 'Create Account →' : 'Sign In →',
                                      style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Center(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _isRegister = !_isRegister;
                              _errorMsg = null;
                            }),
                            child: RichText(
                              text: TextSpan(
                                text: _isRegister ? 'Already have an account? ' : "Don't have an account? ",
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: kTextGrey),
                                children: [TextSpan(
                                  text: _isRegister ? 'Sign In' : 'Sign Up',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13, color: kPrimary, fontWeight: FontWeight.w700),
                                )],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.3, end: 0),

                  const SizedBox(height: 24),
                  Text('By continuing you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11, color: Colors.white.withValues(alpha: 0.55)))
                      .animate().fadeIn(duration: 600.ms, delay: 600.ms),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text}) =>
      TextField(
        controller: ctrl,
        keyboardType: keyboard,
        style: GoogleFonts.plusJakartaSans(fontSize: 15, color: kTextDark),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: kPrimary, size: 20),
        ),
      );
}
