import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseScale = Tween<double>(begin: 0.0, end: 3.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _pulseOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    _navTimer = Timer(AppConstants.splashDuration, _goToHome);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const HomeScreen(),
        ),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppConstants.primaryColor,
              AppConstants.primaryDark,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pulse ring behind mosque icon
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated pulse ring
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, _) {
                        return Transform.scale(
                          scale: _pulseScale.value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppConstants.accentGold.withValues(
                                  alpha: _pulseOpacity.value,
                                ),
                                width: 3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    // Core circle with mosque icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppConstants.accentGold.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.mosque_rounded,
                        size: 42,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: GoogleFonts.cairo(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ابحث عن أقرب جامع فوراً',
                style: GoogleFonts.cairo(
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
