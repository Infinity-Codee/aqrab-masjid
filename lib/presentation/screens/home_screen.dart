import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../controllers/mosque_controller.dart';
import '../widgets/hero_mosque_card.dart';
import '../widgets/map_preview_widget.dart';
import '../widgets/nearby_mosque_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final MosqueController _controller;
  late final AnimationController _sheetCtrl;
  late final Animation<Offset> _sheetSlide;
  late final Animation<double> _sheetFade;

  @override
  void initState() {
    super.initState();
    _controller = MosqueController()..loadNearestMosque();

    _sheetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeOutCubic));
    _sheetFade = CurvedAnimation(parent: _sheetCtrl, curve: Curves.easeIn);

    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!_controller.isLoading && _controller.nearestMosque != null) {
      _sheetCtrl.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const _LoadingView();
          }

          if (_controller.errorMessage != null) {
            return _ErrorView(
              message: _controller.errorMessage!,
              onRetry: _controller.refresh,
            );
          }

          final nearestMosque = _controller.nearestMosque;
          final nearestDistanceKm = _controller.nearestDistanceKm;
          final userPosition = _controller.userPosition;

          if (nearestMosque == null ||
              nearestDistanceKm == null ||
              userPosition == null) {
            return _ErrorView(
              message: 'تعذر تحديد أقرب جامع حالياً.',
              onRetry: _controller.refresh,
            );
          }

          return Stack(
            children: [
              // ─── Map Preview (Top Half) ─────────────────────────
              Positioned.fill(
                bottom: MediaQuery.of(context).size.height * 0.42,
                child: MapPreviewWidget(
                  userLat: userPosition.latitude,
                  userLng: userPosition.longitude,
                  mosqueLat: nearestMosque.latitude,
                  mosqueLng: nearestMosque.longitude,
                  mosqueName: nearestMosque.name,
                ),
              ),

              // ─── Floating Refresh Button (Top Right) ────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: _GlassButton(
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    _sheetCtrl.reset();
                    _controller.refresh();
                  },
                ),
              ),

              // ─── Connection Status (Top Left) ───────────────────
              Positioned(
                top: MediaQuery.of(context).padding.top + 18,
                left: 16,
                child: _ConnectionBadge(isOnline: _controller.isOnline),
              ),

              // ─── Location Notice (below status bar) ─────────────
              if (_controller.locationNotice != null)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 56,
                  left: 16,
                  right: 16,
                  child: _NoticeBanner(text: _controller.locationNotice!),
                ),

              // ─── Hero Bottom Sheet ──────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: MediaQuery.of(context).size.height * 0.56,
                child: SlideTransition(
                  position: _sheetSlide,
                  child: FadeTransition(
                    opacity: _sheetFade,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppConstants.cardBackground,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppConstants.sheetRadius),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          16,
                          24,
                          MediaQuery.of(context).padding.bottom + 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drag handle
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Hero Card
                            HeroMosqueCard(
                              mosque: nearestMosque,
                              distanceKm: nearestDistanceKm,
                              userLat: userPosition.latitude,
                              userLng: userPosition.longitude,
                            ),

                            // Nearby mosques section
                            if (_controller.nearbyMosques.isNotEmpty) ...[
                              const SizedBox(height: 24),
                              Text(
                                'جوامع أخرى قريبة',
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 120,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _controller.nearbyMosques.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    return NearbyMosqueChip(
                                      mosqueWithDistance:
                                          _controller.nearbyMosques[index],
                                      userLat: userPosition.latitude,
                                      userLng: userPosition.longitude,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Glassmorphism Button ─────────────────────────────────────────

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.65),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 22, color: AppConstants.primaryColor),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Connection Status Badge ──────────────────────────────────────

class _ConnectionBadge extends StatelessWidget {
  const _ConnectionBadge({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isOnline
                          ? AppConstants.onlineGreen
                          : AppConstants.offlineOrange,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isOnline ? 'متصل' : 'غير متصل',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Location Notice Banner ───────────────────────────────────────

class _NoticeBanner extends StatelessWidget {
  const _NoticeBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppConstants.accentGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: AppConstants.accentGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppConstants.mapBackground, AppConstants.creamBackground],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pulsing search animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.2),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              onEnd: () {},
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                ),
                child: const Icon(
                  Icons.explore_rounded,
                  size: 40,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'جارٍ تحديد موقعك...',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'قد يستغرق الأمر حتى ٣٠ ثانية',
              style: GoogleFonts.cairo(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: AppConstants.primaryColor.withValues(
                  alpha: 0.1,
                ),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppConstants.primaryColor,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppConstants.mapBackground, AppConstants.creamBackground],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.08),
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  size: 36,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
