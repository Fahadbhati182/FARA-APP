import 'dart:async';
import 'package:flutter/material.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _taglineController;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late AnimationController _bgCircleController;

  // Logo animations
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _logoSlide;

  // Text animations
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  // Tagline animations
  late Animation<double> _taglineOpacity;
  late Animation<Offset> _taglineSlide;

  // Pulse glow behind logo
  late Animation<double> _pulseScale;
  late Animation<double> _pulseOpacity;

  // Bottom progress bar
  late Animation<double> _progressValue;

  // Background floating circles
  late Animation<double> _bgCircleScale;

  static const Color primaryOrange = Color(0xFFFF6B2C);
  static const Color darkOrange = Color(0xFFE85A1A);
  static const Color lightOrange = Color(0xFFFFF3EE);

  @override
  void initState() {
    super.initState();

    // ── Background circle float ──────────────────────────────────
    _bgCircleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _bgCircleScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _bgCircleController, curve: Curves.easeInOut),
    );

    // ── Pulse behind logo ────────────────────────────────────────
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseScale = Tween<double>(begin: 0.8, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // ── Logo pop-in ──────────────────────────────────────────────
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.15)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 60),
      TweenSequenceItem(
          tween: Tween(begin: 1.15, end: 0.95)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 0.95, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
    ]).animate(_logoController);

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _logoSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // ── App name slide up ────────────────────────────────────────
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // ── Tagline fade in ──────────────────────────────────────────
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOut),
    );

    // ── Progress bar ─────────────────────────────────────────────
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _progressValue = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // ── Sequence ─────────────────────────────────────────────────
    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    // Slight delay before starting
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Logo + pulse together
    _logoController.forward();
    _pulseController.forward();
    _progressController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // App name
    _textController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Tagline
    _taglineController.forward();

    // Navigate after full splash duration
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _bgCircleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF6B2C), Color(0xFFE85A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative background circles ─────────────────────
            AnimatedBuilder(
              animation: _bgCircleScale,
              builder: (_, __) => Transform.scale(
                scale: _bgCircleScale.value,
                child: Stack(
                  children: [
                    Positioned(
                      top: -size.width * 0.25,
                      right: -size.width * 0.2,
                      child: _decorCircle(size.width * 0.7,
                          Colors.white.withOpacity(0.07)),
                    ),
                    Positioned(
                      bottom: -size.width * 0.3,
                      left: -size.width * 0.2,
                      child: _decorCircle(size.width * 0.8,
                          Colors.white.withOpacity(0.06)),
                    ),
                    Positioned(
                      top: size.height * 0.12,
                      left: -size.width * 0.15,
                      child: _decorCircle(size.width * 0.4,
                          Colors.white.withOpacity(0.05)),
                    ),
                    Positioned(
                      bottom: size.height * 0.18,
                      right: -size.width * 0.1,
                      child: _decorCircle(size.width * 0.35,
                          Colors.white.withOpacity(0.05)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Main content ──────────────────────────────────────
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Pulse ring + Logo
                Center(
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulse ring
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (_, __) => Transform.scale(
                            scale: _pulseScale.value,
                            child: Opacity(
                              opacity: _pulseOpacity.value,
                              child: Container(
                                width: 140,
                                height: 140,
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

                        // Logo container
                        AnimatedBuilder(
                          animation: _logoController,
                          builder: (_, __) => SlideTransition(
                            position: _logoSlide,
                            child: FadeTransition(
                              opacity: _logoOpacity,
                              child: Transform.scale(
                                scale: _logoScale.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 30,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: -4,
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Image.asset(
                                        "assets/app_logo.jpg",
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // App name
                AnimatedBuilder(
                  animation: _textController,
                  builder: (_, __) => SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: const Text(
                        "FARA",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 8,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Tagline
                AnimatedBuilder(
                  animation: _taglineController,
                  builder: (_, __) => SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _taglineOpacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Your service, simplified",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 0, 48, 60),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressValue,
                        builder: (_, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _progressValue.value,
                            minHeight: 3,
                            backgroundColor: Colors.white.withOpacity(0.25),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "v1.0.0",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _decorCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}