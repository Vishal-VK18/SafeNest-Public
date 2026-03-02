// lib/screens/auth/otp_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

const _primary     = Color(0xFFBCAFD0);
const _primaryDark = Color(0xFF8E7DA0);
const _bgLight     = Color(0xFFFCFBFC);

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // 6 separate controllers for each OTP digit box
  final List<TextEditingController> _ctrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _foci = List.generate(6, (_) => FocusNode());

  bool _isLoading  = false;
  bool _canResend  = false;
  int  _resendSecs = 30;
  Timer? _timer;

  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    // OTP was already generated in the previous screen; start countdown
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) { c.dispose(); }
    for (final f in _foci)  { f.dispose(); }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() { _canResend = false; _resendSecs = 30; });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSecs == 1) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _resendSecs--);
      }
    });
  }

  void _onResend() {
    AuthService.generateOtp(widget.phone);
    for (final c in _ctrls) { c.clear(); }
    _foci[0].requestFocus();
    setState(() => _errorMsg = null);
    _startResendTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New OTP sent! Check console for demo.')),
    );
  }

  String get _enteredOtp => _ctrls.map((c) => c.text).join();

  Future<void> _onVerify() async {
    if (_enteredOtp.length < 6) {
      setState(() => _errorMsg = 'Please enter the 6-digit OTP.');
      return;
    }
    setState(() { _isLoading = true; _errorMsg = null; });

    final error = await AuthService.verifyOtp(
      phone: widget.phone,
      enteredOtp: _enteredOtp,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      setState(() => _errorMsg = error);
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: _bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _primaryDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'OTP Verification',
          style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700, color: _primaryDark),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sms_outlined, color: _primaryDark, size: 40),
              ),
              const SizedBox(height: 24),

              Text(
                'Verify Your Phone',
                style: GoogleFonts.manrope(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit OTP sent to',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(fontSize: 13, color: Colors.grey[500]),
              ),
              Text(
                widget.phone,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _primaryDark,
                ),
              ),
              const SizedBox(height: 32),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) => _buildOtpBox(i)),
              ),

              // Error
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMsg!,
                  style: GoogleFonts.manrope(
                      fontSize: 12, color: Colors.red[700]),
                ),
              ],
              const SizedBox(height: 32),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _onVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    shadowColor: _primary.withValues(alpha: 0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Verify OTP',
                          style: GoogleFonts.manrope(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Resend
              _canResend
                  ? TextButton(
                      onPressed: _onResend,
                      child: Text(
                        'Resend OTP',
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          color: _primaryDark,
                        ),
                      ),
                    )
                  : Text(
                      'Resend OTP in ${_resendSecs}s',
                      style: GoogleFonts.manrope(
                          fontSize: 13, color: Colors.grey[400]),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int i) {
    return Container(
      width: 46,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _ctrls[i].text.isNotEmpty ? _primaryDark : _primary,
          width: _ctrls[i].text.isNotEmpty ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextFormField(
        controller: _ctrls[i],
        focusNode: _foci[i],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.manrope(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _primaryDark,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (v) {
          setState(() {}); // update border color
          if (v.length == 1 && i < 5) {
            _foci[i + 1].requestFocus();
          } else if (v.isEmpty && i > 0) {
            _foci[i - 1].requestFocus();
          }
          if (_enteredOtp.length == 6) {
            // Auto-verify when all filled
            Future.microtask(_onVerify);
          }
        },
      ),
    );
  }
}
