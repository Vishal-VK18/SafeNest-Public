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
import '../../core/constants/route_constants.dart';

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
      Navigator.of(context).pushNamedAndRemoveUntil(RouteConstants.dashboard, (route) => false);
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
      Navigator.of(context).pushNamedAndRemoveUntil(RouteConstants.dashboard, (route) => false);
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
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFFFC09D),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFC09D),
                    Color(0xFFFFCACB),
                  ],
                ),
              ),
            ),
          ),
          // Full-bleed Illustration
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_illustration.png',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    const Color(0xFFFFFDFB).withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
          // Content Scroll View
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 48,
                  left: 24,
                  right: 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- form box ---
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 340),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Welcome Back',
                              style: GoogleFonts.inter(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF181818),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Continue your journey',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFFE9A48E),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Email Input
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              validator: _validateEmail,
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818)),
                              decoration: _inputDecoration(
                                hint: 'Email Address',
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Password Input
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              validator: _validatePassword,
                              style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818)),
                              decoration: _inputDecoration(
                                hint: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: const Color(0xFFE9A48E),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            
                            // Forgot Password Link
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password reset link will be sent to your email.'),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFE9A48E),
                                  ),
                                ),
                              ),
                            ),
                            
                            // Error Message
                            if (_errorMsg != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  _errorMsg!,
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.red[700]),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            
                            const SizedBox(height: 8),
                            // Continue Button
                            Container(
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFFC09D).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _onLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _isLoading 
                                    ? const SizedBox(
                                        width: 20, height: 20, 
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                      )
                                    : Text(
                                        'Continue',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Create Account Button
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 340),
                      child: InkWell(
                        onTap: () {
                           Navigator.of(context).pushNamed(RouteConstants.createAccount);
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF4E4DE)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                'New to SafeNest?',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFE9A48E),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create an Account',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE9A48E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Alt Logins (Google & Phone)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _altLoginButton(
                          onTap: _onGoogle,
                          child: _googleLogo(),
                        ),
                        const SizedBox(width: 16),
                        _altLoginButton(
                          onTap: _onPhone,
                          child: const Icon(
                            Icons.phone_iphone_outlined,
                            color: Color(0xFFE9A48E),
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _altLoginButton({required VoidCallback onTap, required Widget child}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 52,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF2DDD7).withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF4E4DE)),
        ),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFF2DDD7),
            shape: BoxShape.circle,
          ),
          child: child,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFE9A48E).withValues(alpha: 0.6)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.60),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE9A48E), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
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
