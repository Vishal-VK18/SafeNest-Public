import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingSlide extends StatelessWidget {
  final int index;
  final double currentPage;
  final String title;
  final String? description;
  final Widget imageWidget;
  final Widget? logoWidget;
  final BoxDecoration backgroundDecoration;
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;
  final int totalPages;

  const OnboardingSlide({
    super.key,
    required this.index,
    required this.currentPage,
    required this.title,
    this.description,
    required this.imageWidget,
    this.logoWidget,
    required this.backgroundDecoration,
    required this.onGetStarted,
    required this.onSignIn,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate animation factors based on proximity to current page
    final double diff = (index - currentPage);
    final double opacity = (1 - diff.abs()).clamp(0.0, 1.0);
    // Parallax effect: image moves horizontally a bit as we swipe
    final double parallaxOffset = diff * MediaQuery.of(context).size.width * 0.3;

    final isDarkThemeText = index == 0; // Slide 1 uses white text
    final textColor = isDarkThemeText ? Colors.white : const Color(0xFF181818);
    final descColor = isDarkThemeText ? Colors.white.withOpacity(0.8) : const Color(0xFF181818).withOpacity(0.6);

    return Container(
      decoration: backgroundDecoration,
      child: Stack(
        children: [
          // Graphic / Image Layer (Parallax)
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(parallaxOffset, 0),
              child: imageWidget,
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo or top widget
                if (logoWidget != null) logoWidget!,
                
                const Spacer(),
                
                // Animated Text Content
                Opacity(
                  opacity: opacity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                            color: textColor,
                          ),
                        ),
                        if (description != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            description!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: descColor,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(totalPages, (i) {
                    final dist = (i - currentPage).abs();
                    final double dotOpacity = (1 - dist).clamp(0.4, 1.0);
                    final double dotWidth = i == currentPage.round() ? 24.0 : 8.0;
                    
                    final dotColor = isDarkThemeText ? Colors.white : const Color(0xFFFFC09D);
                    final bgColor = isDarkThemeText ? Colors.white.withOpacity(0.4) : dotColor.withOpacity(0.4);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: dotWidth,
                      decoration: BoxDecoration(
                        color: i == currentPage.round() ? dotColor : bgColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                
                const SizedBox(height: 32),
                
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
                  child: Column(
                    children: [
                      // Scale animation on button
                      Transform.scale(
                        scale: opacity < 0.8 ? max(0.9, opacity) : 1.0,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onGetStarted,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F3D3D), // Primary button from prompt
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              elevation: 4,
                            ),
                            child: Text(
                              'Get Started',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: onSignIn,
                        style: TextButton.styleFrom(
                          foregroundColor: textColor,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                              color: isDarkThemeText ? Colors.white.withOpacity(0.3) : const Color(0xFF181818).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.inter(
                              color: isDarkThemeText ? Colors.white.withOpacity(0.9) : const Color(0xFF181818).withOpacity(0.8),
                              fontSize: 15,
                            ),
                            children: [
                              TextSpan(
                                text: 'Sign In',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double max(double a, double b) => a > b ? a : b;
}
