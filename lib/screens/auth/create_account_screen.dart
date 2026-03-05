// lib/screens/auth/create_account_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../utils/blush_theme.dart';
import '../../providers/providers.dart';
import '../../services/auth_service.dart';

// ─── Colors ───────────────────────────────────────────────────────────────────
const _primary     = Color(0xFFBCAFD0);
const _primaryDark = Color(0xFF8E7DA0);
const _bgLight     = Color(0xFFF7F6F7);

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
  bool _showAdditional = false;

  DateTime? _pregnancyStartDate;
  String _selectedBloodGroup = 'B+';

  // ─── Auto-calculated pregnancy info ───────────────────────────────────────
  int get _currentWeek {
    if (_pregnancyStartDate == null) return 0;
    final days = DateTime.now().difference(_pregnancyStartDate!).inDays;
    return (days / 7).floor().clamp(1, 42);
  }

  String get _trimesterLabel {
    if (_currentWeek == 0) return '–';
    if (_currentWeek <= 13) return 'First Trimester';
    if (_currentWeek <= 26) return 'Second Trimester';
    return 'Third Trimester';
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
          // ── Blush gradient background
          Positioned.fill(
            child: Container(decoration: const BoxDecoration(gradient: BlushGradients.background)),
          ),
          SafeArea(
            child: Column(
          children: [
            // ── Top navigation bar ─────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0x1FBCAFD0)),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios,
                        color: _primary, size: 22),
                  ),
                  Expanded(
                    child: Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.manrope(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 32), // balance back button
                ],
              ),
            ),

            // ── Scrollable body ────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome text
                      Text(
                        'Join SafeNest',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: _primaryDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Start your maternal health journey with us today.',
                        style: GoogleFonts.manrope(
                            fontSize: 13, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 24),

                      // ── Account Details Card ──────────────────────────────
                      _card(
                        icon: Icons.person_outline,
                        title: 'Account Details',
                        child: Column(
                          children: [
                            _labeledField('FULL NAME',
                                _buildTextField(
                                  _nameCtrl,
                                  hint: 'Enter your full name',
                                  validator: (v) => _req(v, 'Full Name'),
                                )),
                            const SizedBox(height: 16),
                            _labeledField('EMAIL ADDRESS',
                                _buildTextField(
                                  _emailCtrl,
                                  hint: 'email@safenest.com',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                )),
                            const SizedBox(height: 16),
                            _labeledField('PHONE NUMBER',
                                _buildTextField(
                                  _phoneCtrl,
                                  hint: '+1 (555) 000-0000',
                                  keyboardType: TextInputType.phone,
                                  validator: _validatePhone,
                                )),
                            const SizedBox(height: 16),
                            // Password row (2 columns)
                            Row(
                              children: [
                                Expanded(
                                  child: _labeledField(
                                    'PASSWORD',
                                    _buildTextField(
                                      _passwordCtrl,
                                      hint: '••••••••',
                                      obscure: _obscurePass,
                                      validator: _validatePassword,
                                      suffix: _visibilityToggle(
                                          _obscurePass,
                                          () => setState(
                                              () => _obscurePass = !_obscurePass)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _labeledField(
                                    'CONFIRM',
                                    _buildTextField(
                                      _confirmCtrl,
                                      hint: '••••••••',
                                      obscure: _obscureConfirm,
                                      validator: _validateConfirm,
                                      suffix: _visibilityToggle(
                                          _obscureConfirm,
                                          () => setState(() =>
                                              _obscureConfirm =
                                                  !_obscureConfirm)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Pregnancy Information Card ──────────────────────
                      _card(
                        icon: Icons.child_care_outlined,
                        title: 'Pregnancy Information',
                        child: Column(
                          children: [
                            _labeledField(
                              'PREGNANCY START DATE',
                              GestureDetector(
                                onTap: _pickPregnancyDate,
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: _primary.withValues(alpha: 0.4)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined,
                                          color: _primary, size: 18),
                                      const SizedBox(width: 10),
                                      Text(
                                        _pregnancyStartDate == null
                                            ? 'Select date'
                                            : '${_pregnancyStartDate!.month}/${_pregnancyStartDate!.day}/${_pregnancyStartDate!.year}',
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          color: _pregnancyStartDate == null
                                              ? Colors.grey[400]
                                              : const Color(0xFF111827),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Current week (auto-calc)
                                Expanded(
                                  child: _labeledField(
                                    'CURRENT WEEK',
                                    Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      decoration: BoxDecoration(
                                        color: _primary.withValues(alpha: 0.08),
                                        border: Border.all(
                                            color:
                                                _primary.withValues(alpha: 0.25)),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _currentWeek == 0
                                              ? '—'
                                              : 'Week $_currentWeek',
                                          style: GoogleFonts.manrope(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _primaryDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Trimester (auto-calc)
                                Expanded(
                                  child: _labeledField(
                                    'TRIMESTER',
                                    Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: _primary.withValues(alpha: 0.1),
                                        border: Border.all(
                                            color:
                                                _primary.withValues(alpha: 0.25)),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _trimesterLabel,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.manrope(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _primaryDark,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Show estimated due date if date selected
                            if (_estimatedDueDate != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.event_available,
                                        color: _primaryDark, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Estimated Due Date: ${_estimatedDueDate!.month}/${_estimatedDueDate!.day}/${_estimatedDueDate!.year}',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Additional Health Info (collapsible) ───────────
                      GestureDetector(
                        onTap: () => setState(
                            () => _showAdditional = !_showAdditional),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: _primary.withValues(alpha: 0.25)),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.medical_information_outlined,
                                      color: _primary, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Additional Health Info',
                                    style: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1F2937),
                                    ),
                                  ),
                                  const Spacer(),
                                  AnimatedRotation(
                                    turns: _showAdditional ? 0.5 : 0,
                                    duration:
                                        const Duration(milliseconds: 200),
                                    child: const Icon(Icons.expand_more,
                                        color: _primary),
                                  ),
                                ],
                              ),
                              if (_showAdditional) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _labeledField(
                                        'AGE',
                                        _buildTextField(
                                          _ageCtrl,
                                          hint: '28',
                                          keyboardType: TextInputType.number,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _labeledField(
                                        'BLOOD GROUP',
                                        _buildDropdown(
                                          value: _selectedBloodGroup,
                                          items: const [
                                            'A+', 'A-', 'B+', 'B-',
                                            'O+', 'O-', 'AB+', 'AB-'
                                          ],
                                          onChanged: (v) => setState(
                                              () => _selectedBloodGroup =
                                                  v ?? _selectedBloodGroup),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _labeledField(
                                  'EMERGENCY CONTACT',
                                  Column(
                                    children: [
                                      _buildTextField(
                                        _emergencyCtrl,
                                        hint: 'Name & Relationship',
                                      ),
                                      const SizedBox(height: 8),
                                      _buildTextField(
                                        _emergencyPhoneCtrl,
                                        hint: 'Emergency Phone',
                                        keyboardType: TextInputType.phone,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Create Account button ──────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onCreate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                            shadowColor: _primary.withValues(alpha: 0.4),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),

                      // ── OR divider ─────────────────────────────────────
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Colors.grey.shade300, thickness: 1)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or',
                              style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[400],
                                  letterSpacing: 1.5),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Colors.grey.shade300, thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Continue with Google ───────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _onGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade200, width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            backgroundColor: Colors.white,
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
                                style: GoogleFonts.manrope(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: const Color(0xFF374151),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Already have account ───────────────────────────
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.manrope(
                                fontSize: 13, color: Colors.grey[500]),
                            children: [
                              const TextSpan(text: 'Already have an account? '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Text(
                                    'Login',
                                    style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _primary,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Home indicator ─────────────────────────────────
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          width: 128,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ), // Close Column
      ), // Close SafeArea
        ], // Close Stack children
      ), // Close Stack
    ); // Close Scaffold
  }

  // ─── Component helpers ────────────────────────────────────────────────────
  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _primary, size: 22),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _labeledField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 6),
        field,
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl, {
    String hint = '',
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.manrope(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.manrope(fontSize: 13, color: Colors.grey[400]),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primary.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primary.withValues(alpha: 0.3)),
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
        errorStyle: GoogleFonts.manrope(fontSize: 10),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: Colors.white,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      iconSize: 22,
      iconEnabledColor: _primaryDark,
      iconDisabledColor: _primary,
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      color: _primaryDark,
                    )),
              ))
          .toList(),
      onChanged: onChanged,
      style: GoogleFonts.manrope(fontSize: 13, color: _primaryDark),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primary.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: _primary.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primaryDark, width: 2),
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
