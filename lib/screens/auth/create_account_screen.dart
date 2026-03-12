// lib/screens/auth/create_account_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _primaryDark = Color(0xFF8E7DA0);

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  final _ageCtrl        = TextEditingController();
  final _emergencyCtrl  = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _isLoading      = false;

  DateTime? _pregnancyStartDate;
  String _selectedBloodGroup = 'B+';

  // ─── Auto-calculated pregnancy info ───────────────────────────────────────
  int get _currentWeek {
    if (_pregnancyStartDate == null) return 0;
    final days = DateTime.now().difference(_pregnancyStartDate!).inDays;
    return (days / 7).floor().clamp(1, 42);
  }

  DateTime? get _estimatedDueDate {
    if (_pregnancyStartDate == null) return null;
    return _pregnancyStartDate!.add(const Duration(days: 280));
  }

  // ─── Validators ───────────────────────────────────────────────────────────
  String? _req(String? v, String field) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final reg = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w]{2,}$');
    if (!reg.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone is required';
    if (v.trim().replaceAll(RegExp(r'[^\d]'), '').length < 7) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Min 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add an uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(v)) return 'Add a number';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (v != _passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  // ─── Submit ───────────────────────────────────────────────────────────────
  Future<void> _onCreate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pregnancyStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your pregnancy start date.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Register through AuthService (handles hashing + all persistence)
    await AuthService.register(
      name:                _nameCtrl.text.trim(),
      email:               _emailCtrl.text.trim(),
      phone:               _phoneCtrl.text.trim(),
      password:            _passwordCtrl.text,
      pregnancyStartDate:  _pregnancyStartDate,
      bloodGroup:          _selectedBloodGroup,
      age:                 int.tryParse(_ageCtrl.text.trim()),
      emergencyContact:    _emergencyCtrl.text.isNotEmpty
          ? '${_emergencyCtrl.text.trim()} | ${_emergencyPhoneCtrl.text.trim()}'
          : null,
    );

    // Update pregnancy provider
    ref.read(pregnancyProvider.notifier).updateName(_nameCtrl.text.trim());
    if (_pregnancyStartDate != null) {
      ref.read(pregnancyProvider.notifier).updateStartDate(_pregnancyStartDate!);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Navigate to dashboard, replacing the create-account screen in the stack
    Navigator.of(context).pushReplacementNamed('/home');
  }

  // ─── Pregnancy date picker ────────────────────────────────────────────────
  Future<void> _pickPregnancyDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _pregnancyStartDate ?? now.subtract(const Duration(days: 70)),
      firstDate: now.subtract(const Duration(days: 294)), // max 42 weeks
      lastDate: now,
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryDark),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _pregnancyStartDate = picked);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _ageCtrl.dispose();
    _emergencyCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Blush gradient background mapping the original style ──
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
          // ── Soft Overlay diffusion effect ──
          Positioned.fill(
            child: Container(
              color: const Color.fromRGBO(255, 253, 251, 0.35),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      // ── Header ──
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF181818), size: 20),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create Account',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181818),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Join SafeNest — start your maternal health journey',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF181818).withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Main Form Card ──
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.75),
                          borderRadius: BorderRadius.circular(22),
                          // Optional blur effect fallback manually
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Account Details Section ──
                              Text(
                                'ACCOUNT DETAILS',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: const Color(0xFF181818).withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInputField(
                                ctrl: _nameCtrl,
                                hint: 'Full Name',
                                icon: Icons.person_outline_rounded,
                                validator: (v) => _req(v, 'Full Name'),
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                ctrl: _emailCtrl,
                                hint: 'Email',
                                icon: Icons.mail_outline_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                ctrl: _phoneCtrl,
                                hint: 'Phone Number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: _validatePhone,
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                ctrl: _passwordCtrl,
                                hint: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePass,
                                validator: _validatePassword,
                                suffix: _visibilityToggle(
                                  _obscurePass,
                                  () => setState(() => _obscurePass = !_obscurePass),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                ctrl: _confirmCtrl,
                                hint: 'Confirm Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscureConfirm,
                                validator: _validateConfirm,
                                suffix: _visibilityToggle(
                                  _obscureConfirm,
                                  () => setState(() => _obscureConfirm = !_obscureConfirm),
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // ── Pregnancy Information Section ──
                              Text(
                                'PREGNANCY INFORMATION',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: const Color(0xFF181818).withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: _pickPregnancyDate,
                                child: Container(
                                  height: 52,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF3EF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, color: Color(0xFFE8907E), size: 18),
                                      const SizedBox(width: 14),
                                      Text(
                                        _pregnancyStartDate == null
                                            ? 'Pregnancy Start Date'
                                            : '${_pregnancyStartDate!.month}/${_pregnancyStartDate!.day}/${_pregnancyStartDate!.year}',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: _pregnancyStartDate == null ? Colors.grey[400] : const Color(0xFF181818),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // Current Week input display (read-only mapping)
                                  Expanded(
                                    child: Container(
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAF3EF),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          _currentWeek == 0 ? 'Current Week' : 'Week $_currentWeek',
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: _currentWeek == 0 ? Colors.grey[400] : const Color(0xFF181818),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Trimester Dropdown replacement mapper 
                                  Expanded(
                                    child: Container(
                                      height: 52,
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFAF3EF),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _currentWeek == 0 ? null : (_currentWeek <= 13 ? "1st Trimester" : (_currentWeek <= 26 ? "2nd Trimester" : "3rd Trimester")),
                                          hint: Text('Trimester', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400])),
                                          isExpanded: true,
                                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFE8907E)),
                                          items: const [
                                            DropdownMenuItem(value: '1st Trimester', child: Text('1st Trimester')),
                                            DropdownMenuItem(value: '2nd Trimester', child: Text('2nd Trimester')),
                                            DropdownMenuItem(value: '3rd Trimester', child: Text('3rd Trimester')),
                                          ],
                                          onChanged: (v) {}, // Disabled change, mapped to date picker like original code
                                          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818)),
                                          dropdownColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Estimated Due date (read-only map)
                              Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF3EF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle_outline, color: Color(0xFFE8907E), size: 18),
                                    const SizedBox(width: 14),
                                    Text(
                                      _estimatedDueDate == null
                                          ? 'Estimated Due Date'
                                          : '${_estimatedDueDate!.month}/${_estimatedDueDate!.day}/${_estimatedDueDate!.year}',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: _estimatedDueDate == null ? Colors.grey[400] : const Color(0xFF181818),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // ── Health Information Section ──
                              Text(
                                'HEALTH INFORMATION',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                  color: const Color(0xFF181818).withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 52,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF3EF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    hint: Text('Select Primary Health Concern', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400])),
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFE8907E)),
                                    items: [
                                      'Nutrition & Diet',
                                      'Mental Wellness',
                                      'Physical Activity',
                                      'Sleep Patterns',
                                      'Other'
                                    ].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      // Health concern mapping not actively saved in auth but provides UI parity
                                    },
                                    style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818)),
                                    dropdownColor: Colors.white,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 36),
                              
                              // ── Form Actions ──
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFFF2A38A), Color(0xFFE8907E)]),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(232, 144, 126, 0.25),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    )
                                  ]
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _onCreate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22, height: 22,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : Text(
                                          'Create Account',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Continue with Google secondary styling mapped over 
                              ElevatedButton(
                                onPressed: _isLoading ? null : _onGoogleSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF8EEE9),
                                  foregroundColor: const Color(0xFF181818),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  minimumSize: const Size(double.infinity, 56),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CustomPaint(painter: _GoogleSvgPainter()),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      // ── Footer ──
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181818).withValues(alpha: 0.7)),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Login',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF181818),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Component helpers ────────────────────────────────────────────────────
  Widget _buildInputField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF181818)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: const Color(0xFFE8907E), size: 18),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFFAF3EF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _visibilityToggle(bool obscure, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Colors.grey[400],
        size: 18,
      ),
      onPressed: onTap,
    );
  }

  // ─── Google Sign-In ────────────────────────────────────────────────────────
  Future<void> _onGoogleSignIn() async {
    setState(() => _isLoading = true);
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
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Sign-In failed. Please try again.')),
      );
    }
  }
}

// ─── Google "G" logo – exact SVG paths from official branding (viewBox 0 0 24 24) ──
class _GoogleSvgPainter extends CustomPainter {
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
