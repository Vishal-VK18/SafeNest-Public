import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../auth/login_screen.dart';
import '../../widgets/onboarding_slide.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    if (_currentPage.round() < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeAndNavigate();
    }
  }

  void _onSignIn() {
    _completeAndNavigate();
  }

  void _completeAndNavigate() async {
    await StorageService.setOnboardingComplete(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSlide1(),
          _buildSlide2(),
          _buildSlide3(),
        ],
      ),
    );
  }

  Widget _buildSlide1() {
    return OnboardingSlide(
      index: 0,
      currentPage: _currentPage,
      totalPages: 3,
      title: 'Track your\nPregnancy Journey',
      description: null,
      backgroundDecoration: const BoxDecoration(color: Color(0xFF0F1717)),
      logoWidget: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
            const Text(
              'SafeNest',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      imageWidget: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCASuT9Ap8Q0OFdaRBf0mIHnsnqFRg1CifIxFCz03XutaFxkluqASf20BrtaVOo_Glw9vllZyfJ7xsyJFBysG49bLOpufrgB-w5El8FYCo5hYNNOGyh7OKO6Hq6x2tx84WY37VydoP99nfAjpQUWgLjTMdE4O3q6ZEtJomQ0UIOM7cc0ubbMoDOWbPeCgUCZ-kCUfqaQfbMgkXDCmPXcP5ej_1toE4RwmSTODzd3jOB0CAiovQttm53gDGA6OfqeCAAFxAnKogMUSo8',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x000F1717),
                  Color(0x990F1717),
                  Color(0xFF0F1717),
                ],
                stops: [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ],
      ),
      onGetStarted: _onGetStarted,
      onSignIn: _onSignIn,
    );
  }

  Widget _buildSlide2() {
    return OnboardingSlide(
      index: 1,
      currentPage: _currentPage,
      totalPages: 3,
      title: 'Watch your baby grow every day',
      description: null,
      backgroundDecoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
        ),
      ),
      logoWidget: null,
      imageWidget: Padding(
        padding: const EdgeInsets.only(bottom: 200), // Push icon up to middle area
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _Slide2GraphicPainter(),
                ),
              ),
            ],
          ),
        ),
      ),
      onGetStarted: _onGetStarted,
      onSignIn: _onSignIn,
    );
  }

  Widget _buildSlide3() {
    return OnboardingSlide(
      index: 2,
      currentPage: _currentPage,
      totalPages: 3,
      title: 'Book online\nappointment',
      description: 'Instantly connect with expert doctors from the comfort of your home.',
      backgroundDecoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
        ),
      ),
      logoWidget: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.eco, color: Color(0xFFFFC09D)),
            ),
            const SizedBox(height: 4),
            const Text(
              'SAFENEST',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                color: Color(0xFF181818),
              ),
            ),
          ],
        ),
      ),
      imageWidget: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.white.withOpacity(0.9))),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 120, 32, 0),
            child: Container(
                height: MediaQuery.of(context).size.height * 0.45,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 20))],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuBneNQF3RGGdZq4L4PBL5DakA5i_f4s2K62Cbz5LYWsu0yIVsmecWRAjgn4qvMzAeEEYno_tizXyZVTt_K_pQFS3BRy4gjsp9x10St8Ec05EznMGGXOX8qVW-U2X4EQBa-0T_vJuTdkfUiV6T0HtBm19lMZSDbL5cvC0oBckCQb3QW2TyvdOKaXgUJIVuXeKq4N9uii8acbUz_StgsFrdGQwmVh-08FDu_IFpXsG_07bgGBKyZ8gNsQUaJUnc7QjFpw1yZ1v1q7JqaP',
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8, height: 8,
                                      decoration: const BoxDecoration(color: Color(0xFFFFC09D), shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('04:20', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF181818))),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                width: 96,
                                height: 128,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBlW9m3A68ESZyH0Xm_WxKwlg3csoNBkU1XzyvYn7u48oYJtPuLtFuwsuN7TSoAXpW2oDlrm5DQQAAYwD8GxTzNp-0Vfsc4tcfkJ-ki6F0JjF-iaeDVpsBu-Punzb_4zTnTgnrjraYyM0rRtQjwrAlqRIacFeOaOPPUp-5sg0fLpeF_EevEA1GlYG5skhGeDfWyUTqXVaFE443_dhVBuYZxENKxxIZYYCvQb-6R3xv9XL4lKHWP6o2kOG8LFMzdy6FGDM35RdSoHOXk',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildCallIcon(Icons.mic, Colors.grey[200]!, Colors.grey[600]!),
                        const SizedBox(width: 16),
                        _buildCallIcon(Icons.call_end, const Color(0xFFFF6B6B), Colors.white),
                        const SizedBox(width: 16),
                        _buildCallIcon(Icons.videocam, Colors.grey[200]!, Colors.grey[600]!),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      onGetStarted: _onGetStarted,
      onSignIn: _onSignIn,
    );
  }

  Widget _buildCallIcon(IconData icon, Color bgColor, Color iconColor) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}

class _Slide2GraphicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(0, size.height * 0.1);
    
    // The leaf/shield SVG path from the HTML
    final path = Path();
    path.moveTo(100, 170);
    path.lineTo(88.5, 159.5);
    path.cubicTo(47.5, 122.3, 20, 97.4, 20, 67);
    path.cubicTo(20, 42.1, 39.5, 22.5, 64.4, 22.5);
    path.cubicTo(78.5, 22.5, 92, 29, 100, 39.4);
    path.cubicTo(108, 29, 121.5, 22.5, 135.6, 22.5);
    path.cubicTo(160.5, 22.5, 180, 42.1, 180, 67);
    path.cubicTo(180, 97.4, 152.5, 122.3, 111.5, 159.6);
    path.lineTo(100, 170);
    path.close();

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Circle
    final circlePaint = Paint()
      ..color = const Color(0xFFFFC09D).withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(100, 85), 25, circlePaint);

    // Arc stroke
    final arcPath = Path();
    arcPath.moveTo(75, 110);
    arcPath.cubicTo(75, 110, 85, 135, 100, 135);
    arcPath.cubicTo(115, 135, 125, 110, 125, 110);
    
    final arcPaint = Paint()
      ..color = const Color(0xFFFFC09D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(arcPath, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
