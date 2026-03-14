import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import '../auth/login_screen.dart';
import '../home_dashboard_screen.dart';
import '../../core/constants/route_constants.dart';
import '../../core/services/auth_flow_manager.dart';
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
    await AuthFlowManager.onGetStartedCompleted();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      RouteConstants.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentPage.round() > 0) {
          _pageController.previousPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        } else {
          // If on first slide, we could either do nothing or allow pop if really needed.
          // According to requirements: "Pressing back on onboarding slides should move between slides only."
          // "It must NOT return to LaunchScreen."
          // So we keep canPop: false and do nothing on the first slide.
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          children: [
            _buildSlide1(),
            _buildSlide2(),
            _buildSlide3(),
          ],
        ),
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
      title: 'Stay Safe with\nSmart Monitoring',
      description: 'Real-time vitals tracking and fall detection help keep you and your baby safe throughout pregnancy.',
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
                color: const Color(0xFF1F4E4A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.favorite, color: Colors.white, size: 22),
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
      imageWidget: Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 220),
          child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glass card background
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF4A38C).withOpacity(0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                ),
                // Spinning peach dashed ring
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 10),
                  builder: (_, v, child) => Transform.rotate(
                    angle: v * 6.283,
                    child: child,
                  ),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF4A38C),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Centre icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8EEE9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.watch_outlined, size: 56, color: Color(0xFFF4A38C)),
                ),
                // Heart badge (top-right)
                Positioned(
                  top: 52,
                  right: 34,
                  child: _slideBadge(Icons.favorite, const Color(0xFFF4A38C)),
                ),
                // Check badge (bottom-left)
                Positioned(
                  bottom: 52,
                  left: 34,
                  child: _slideBadge(Icons.check_circle, const Color(0xFF1F4E4A)),
                ),
              ],
            ),
          ),
        ),
      ),
      onGetStarted: _onGetStarted,
      onSignIn: _onSignIn,
    );
  }

  Widget _slideBadge(IconData icon, Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 20),
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
