import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:sensors_plus/sensors_plus.dart';

const Color brandStart = Color(0xFF3C79C1); // Vibrant Light Blue
const Color brandEnd = Color.fromARGB(255, 129, 90, 193); // Vibrant Purple

class OnPageIntro extends StatefulWidget {
  final VoidCallback? onSkip;
  
  const OnPageIntro({super.key, this.onSkip});

  @override
  State<OnPageIntro> createState() => _OnPageIntroState();
}

class _OnPageIntroState extends State<OnPageIntro> with TickerProviderStateMixin {
  late AnimationController _imageController;
  late AnimationController _textController;
  late AnimationController _subtitleController;
  late AnimationController _floatingController;
  late AnimationController _decorativeController;
  
  late Animation<double> _imageScale;
  late Animation<double> _imageFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _floatingPulse;
  late Animation<double> _decorativeRotate;

  double _tiltX = 0;
  double _tiltY = 0;

  @override
  void initState() {
    super.initState();
    
    // Image Animation Controller
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Text Animation Controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Subtitle Animation Controller
    _subtitleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Floating Indicator Animation Controller
    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Decorative Elements Animation Controller
    _decorativeController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    )..repeat();

    // Image Scale and Fade
    _imageScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeOut),
    );

    _imageFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.easeIn),
    );

    // Text Slide
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    // Subtitle Fade
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _subtitleController, curve: Curves.easeIn),
    );

    // Floating Pulse
    _floatingPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    // Decorative Rotation
    _decorativeRotate = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _decorativeController, curve: Curves.linear),
    );

    // Start animations in sequence
    _imageController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _subtitleController.forward();
    });
  }

  @override
  void dispose() {
    _imageController.dispose();
    _textController.dispose();
    _subtitleController.dispose();
    _floatingController.dispose();
    _decorativeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient Background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [brandStart, brandEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        
        // Animated Decorative Background Elements
        _buildDecorativeElements(),
        
        Column(
          children: [
            /// Title at the top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
            child: SlideTransition(
              position: _textSlide,
              child: RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Welcome to\n",
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextSpan(
                      text: "FinTrackU",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),


            /// Space for your image - center it
            Expanded(
              child: Center(
                child: ScaleTransition(
                  scale: _imageScale,
                  child: FadeTransition(
                    opacity: _imageFade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.05),
                                ],
                              ),
                            ),
                          ),
                          // Image
                          Container(
                            color: Colors.transparent,
                            child: Image.asset(
                              'assets/images/onboarding_intro.png',
                              fit: BoxFit.contain,
                              scale: 0.9, // Enlarge the image
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            /// Bottom CTA Text with Floating Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Text(
                    "Swipe to continue",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Floating Arrow Indicator
                  _buildFloatingIndicator(),
                ],
              ),
            ),
          ],
        ),

        /// Skip Button
        Positioned(
          top: 16,
          right: 20,
          child: widget.onSkip != null
              ? TextButton(
                  onPressed: widget.onSkip,
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Build Floating Indicator with pulsing animation
  Widget _buildFloatingIndicator() {
    return AnimatedBuilder(
      animation: _floatingPulse,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatingPulse.value * 8),
          child: Opacity(
            opacity: 0.8 + (_floatingPulse.value * 0.2),
            child: const Icon(
              Icons.arrow_forward,
              color: Colors.white,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  /// Build Decorative Background Elements
  Widget _buildDecorativeElements() {
    return AnimatedBuilder(
      animation: _decorativeRotate,
      builder: (context, child) {
        return Stack(
          children: [
            // Top-left circle
            Positioned(
              top: -50,
              left: -50,
              child: Opacity(
                opacity: 0.15,
                child: Transform.rotate(
                  angle: _decorativeRotate.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Bottom-right circle
            Positioned(
              bottom: -60,
              right: -60,
              child: Opacity(
                opacity: 0.12,
                child: Transform.rotate(
                  angle: -_decorativeRotate.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Center accent circle (subtle)
            Positioned(
              bottom: 100,
              right: 20,
              child: Opacity(
                opacity: 0.1,
                child: Transform.rotate(
                  angle: _decorativeRotate.value * 0.5,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}