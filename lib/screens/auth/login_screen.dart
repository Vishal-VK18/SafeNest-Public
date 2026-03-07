// lib/screens/auth/login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../utils/blush_theme.dart';
import '../../services/auth_service.dart';
import 'create_account_screen.dart';
import 'otp_screen.dart';

// ─── Colors matched to design ─────────────────────────────────────────────────
const _primary      = Color(0xFFBCAFD0);
const _primaryDark  = Color(0xFF8E7DA0);
const _bgLight      = Color(0xFFFCFBFC);
const _border       = Color(0xFFBCAFD0);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _phoneCtrl     = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading       = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // ─── Validation helpers ───────────────────────────────────────────────────
  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final emailReg = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,}$');
    if (!emailReg.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  // ─── Login with email + password (credential check) ──────────────────────
  Future<void> _onLogin() async {
    setState(() => _errorMsg = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final error = await AuthService.loginWithCredentials(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  // ─── Continue with Phone → OTP screen ────────────────────────────────────
  void _onPhone() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PhoneInputSheet(
        onSubmit: (phone) {
          Navigator.pop(ctx);
          // Generate OTP (printed to console for demo)
          AuthService.generateOtp(phone);
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)),
          );
        },
      ),
    );
  }

  // ─── Google Sign-In ───────────────────────────────────────────────────────
  Future<void> _onGoogle() async {
    setState(() { _isLoading = true; _errorMsg = null; });
    try {
      final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final account = await googleSignIn.signIn();
      if (!mounted) return;
      if (account == null) {
        setState(() => _isLoading = false);
        return; // User cancelled
      }

      await AuthService.loginWithGoogle(
        name:  account.displayName ?? '',
        email: account.email,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg  = 'Google Sign-In failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Blush gradient background
          Positioned.fill(
            child: Container(decoration: const BoxDecoration(gradient: BlushGradients.background)),
          ),
          SafeArea(
            child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: _primary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_florist_outlined,
                          color: _primary,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SafeNest',
                        style: GoogleFonts.manrope(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: _primaryDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your companion in maternal healthcare',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // ── Login Card ───────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _border.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Email'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            validator: _validateEmail,
                            style: GoogleFonts.manrope(fontSize: 14),
                            decoration: _inputDecoration(
                              hint: 'Enter your email',
                              prefixIcon: Icons.mail_outline,
                            ),
                          ),
                          const SizedBox(height: 20),

                          _fieldLabel('Password'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            validator: _validatePassword,
                            style: GoogleFonts.manrope(fontSize: 14),
                            decoration: _inputDecoration(
                              hint: 'Enter your password',
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                final email = _emailCtrl.text.trim();
                                if (email.isEmpty) {
                                  setState(() => _errorMsg = 'Enter your email to reset password.');
                                  return;
                                }
                                final error = await AuthService.sendPasswordReset(email);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error ?? 'Password reset email sent to $email'),
                                    backgroundColor: error != null ? Colors.red : Colors.green,
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryDark,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Error message
                          if (_errorMsg != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: Colors.red[700], size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMsg!,
                                      style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: Colors.red[700]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Login button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _onLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 4,
                                shadowColor: _primary.withValues(alpha: 0.4),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      'Login',
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── OR Divider ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: _primary.withValues(alpha: 0.3),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'OR',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: _primary.withValues(alpha: 0.3),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Continue with Phone ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _onPhone,
                      icon: const Icon(Icons.phone_outlined,
                          color: _primaryDark, size: 20),
                      label: Text(
                        'Continue with Phone Number',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          color: _primaryDark,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Continue with Google ────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _onGoogle,
                      icon: _googleLogo(),
                      label: Text(
                        'Continue with Google',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade200),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Create Account footer ───────────────────────────────
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const CreateAccountScreen()),
                            ),
                            child: Text(
                              'Create Account',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _primaryDark,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ), // Column
            ), // ConstrainedBox
          ), // SingleChildScrollView
        ), // Close Center
      ), // Close SafeArea
        ], // Close Stack children
      ), // Close Stack
    ); // Close Scaffold
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[400]),
      prefixIcon: Icon(prefixIcon, color: _primary, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _border.withValues(alpha: 0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _border.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _googleLogo() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

// ─── Phone number input bottom sheet ─────────────────────────────────────────
class _PhoneInputSheet extends StatefulWidget {
  final void Function(String phone) onSubmit;
  const _PhoneInputSheet({required this.onSubmit});

  @override
  State<_PhoneInputSheet> createState() => _PhoneInputSheetState();
}

class _PhoneInputSheetState extends State<_PhoneInputSheet> {
  final _ctrl = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Enter Phone Number',
            style: GoogleFonts.manrope(
                fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'We\'ll send a verification code to this number.',
            style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.phone,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '+1 (555) 000-0000',
              hintStyle:
                  GoogleFonts.manrope(color: Colors.grey[400], fontSize: 14),
              prefixIcon: const Icon(Icons.phone_outlined, color: _primary),
              errorText: _err,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: _primary.withValues(alpha: 0.4))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      BorderSide(color: _primary.withValues(alpha: 0.4))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                final phone = _ctrl.text.trim();
                if (phone.length < 7) {
                  setState(
                      () => _err = 'Enter a valid phone number');
                  return;
                }
                widget.onSubmit(phone);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'Send OTP',
                style:
                    GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Google "G" logo – exact SVG paths from official branding (viewBox 0 0 24 24) ──
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Normalize: all SVG coords are in 0..24 space, scale to canvas size
    final double sx = size.width / 24;
    final double sy = size.height / 24;
    final paint = Paint()..style = PaintingStyle.fill;

    // ── Blue (right bar + top of G) ────────────────────────────────────────
    paint.color = const Color(0xFF4285F4);
    final blue = Path()
      ..moveTo(22.56 * sx, 12.25 * sy)
      ..cubicTo(22.56 * sx, 11.47 * sy, 22.49 * sx, 10.72 * sy,
                22.36 * sx, 10.00 * sy)
      ..lineTo(12.00 * sx, 10.00 * sy)
      ..lineTo(12.00 * sx, 14.26 * sy)
      ..lineTo(17.92 * sx, 14.26 * sy)
      ..cubicTo(17.66 * sx, 15.63 * sy, 16.88 * sx, 16.79 * sy,
                15.71 * sx, 17.57 * sy)
      ..lineTo(15.71 * sx, 20.34 * sy)
      ..lineTo(19.28 * sx, 20.34 * sy)
      ..cubicTo(21.36 * sx, 18.42 * sy, 22.56 * sx, 15.60 * sy,
                22.56 * sx, 12.25 * sy)
      ..close();
    canvas.drawPath(blue, paint);

    // ── Green (bottom arc) ─────────────────────────────────────────────────
    paint.color = const Color(0xFF34A853);
    final green = Path()
      ..moveTo(12.00 * sx, 23.00 * sy)
      ..cubicTo(14.97 * sx, 23.00 * sy, 17.46 * sx, 22.02 * sy,
                19.28 * sx, 20.34 * sy)
      ..lineTo(15.71 * sx, 17.57 * sy)
      ..cubicTo(14.73 * sx, 18.23 * sy, 13.48 * sx, 18.63 * sy,
                12.00 * sx, 18.63 * sy)
      ..cubicTo(9.14 * sx, 18.63 * sy, 6.71 * sx, 16.70 * sy,
                5.84 * sx, 14.10 * sy)
      ..lineTo(2.18 * sx, 14.10 * sy)
      ..lineTo(2.18 * sx, 16.94 * sy)
      ..cubicTo(3.99 * sx, 20.53 * sy, 7.70 * sx, 23.00 * sy,
                12.00 * sx, 23.00 * sy)
      ..close();
    canvas.drawPath(green, paint);

    // ── Yellow (left arc) ──────────────────────────────────────────────────
    paint.color = const Color(0xFFFBBC05);
    final yellow = Path()
      ..moveTo(5.84 * sx, 14.09 * sy)
      ..cubicTo(5.62 * sx, 13.43 * sy, 5.49 * sx, 12.73 * sy,
                5.49 * sx, 12.00 * sy)
      ..cubicTo(5.49 * sx, 11.27 * sy, 5.62 * sx, 10.57 * sy,
                5.84 * sx,  9.91 * sy)
      ..lineTo(5.84 * sx,  7.07 * sy)
      ..lineTo(2.18 * sx,  7.07 * sy)
      ..cubicTo(1.43 * sx,  8.55 * sy, 1.00 * sx, 10.22 * sy,
                1.00 * sx, 12.00 * sy)
      ..cubicTo(1.00 * sx, 13.78 * sy, 1.43 * sx, 15.45 * sy,
                2.18 * sx, 16.93 * sy)
      ..lineTo(5.03 * sx, 14.71 * sy)
      ..lineTo(5.84 * sx, 14.09 * sy)
      ..close();
    canvas.drawPath(yellow, paint);

    // ── Red (top arc) ─────────────────────────────────────────────────────
    paint.color = const Color(0xFFEA4335);
    final red = Path()
      ..moveTo(12.00 * sx,  5.38 * sy)
      ..cubicTo(13.62 * sx,  5.38 * sy, 15.06 * sx,  5.94 * sy,
                16.21 * sx,  7.02 * sy)
      ..lineTo(19.36 * sx,  3.87 * sy)
      ..cubicTo(17.45 * sx,  2.09 * sy, 14.97 * sx,  1.00 * sy,
                12.00 * sx,  1.00 * sy)
      ..cubicTo( 7.70 * sx,  1.00 * sy,  3.99 * sx,  3.47 * sy,
                 2.18 * sx,  7.07 * sy)
      ..lineTo(5.84 * sx,  9.91 * sy)
      ..cubicTo(6.71 * sx,  7.31 * sy,  9.14 * sx,  5.38 * sy,
                12.00 * sx,  5.38 * sy)
      ..close();
    canvas.drawPath(red, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
