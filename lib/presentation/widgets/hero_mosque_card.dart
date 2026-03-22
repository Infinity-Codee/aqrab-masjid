import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/map_service.dart';
import '../../core/utils/walking_time.dart';
import '../../data/models/mosque_model.dart';

/// The hero card that floats over the bottom of the map preview.
class HeroMosqueCard extends StatefulWidget {
  const HeroMosqueCard({
    super.key,
    required this.mosque,
    required this.distanceKm,
    required this.userLat,
    required this.userLng,
  });

  final MosqueModel mosque;
  final double distanceKm;
  final double userLat;
  final double userLng;

  @override
  State<HeroMosqueCard> createState() => _HeroMosqueCardState();
}

class _HeroMosqueCardState extends State<HeroMosqueCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _counterCtrl;
  late final Animation<double> _counterAnim;

  @override
  void initState() {
    super.initState();
    _counterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _counterAnim = CurvedAnimation(
      parent: _counterCtrl,
      curve: Curves.easeOutCubic,
    );
    _counterCtrl.forward();
  }

  @override
  void didUpdateWidget(covariant HeroMosqueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.distanceKm != widget.distanceKm) {
      _counterCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _counterCtrl.dispose();
    super.dispose();
  }

  Future<void> _openDirections() async {
    await AdService.instance.showInterstitialAd(
      onAdComplete: () {
        MapService.openDirections(
          mosque: widget.mosque,
          originLat: widget.userLat,
          originLng: widget.userLng,
        ).catchError((error) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', '')),
            ),
          );
        });
      },
    );
  }

  void _showDetails() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.sheetRadius),
        ),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 20),
                Text(
                  widget.mosque.name,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _detailRow(Icons.location_on_outlined, widget.mosque.address),
                const SizedBox(height: 8),
                _detailRow(
                  Icons.straighten_rounded,
                  'المسافة: ${WalkingTime.distanceDisplay(widget.distanceKm)}',
                ),
                const SizedBox(height: 8),
                _detailRow(
                  Icons.pin_drop_outlined,
                  'خط العرض: ${widget.mosque.latitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 4),
                _detailRow(
                  Icons.pin_drop_outlined,
                  'خط الطول: ${widget.mosque.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 8),
                _detailRow(
                  Icons.gps_fixed_rounded,
                  'دقة الموقع: ±${widget.userLat.toStringAsFixed(2)} (حسب GPS)',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppConstants.primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceText = WalkingTime.distanceDisplay(widget.distanceKm);
    final walkingText = WalkingTime.fromKm(widget.distanceKm);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              const Icon(
                Icons.near_me_rounded,
                size: 16,
                color: AppConstants.accentGold,
              ),
              const SizedBox(width: 6),
              Text(
                'أقرب جامع لك',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ),

        // Mosque name
        Text(
          widget.mosque.name,
          style: GoogleFonts.cairo(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Colors.grey[900],
          ),
        ),
        const SizedBox(height: 4),

        // Address (subtle)
        Text(
          widget.mosque.address,
          style: GoogleFonts.cairo(fontSize: 13, color: Colors.grey[500]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 14),

        // Distance + walking time row with counter animation
        AnimatedBuilder(
          animation: _counterAnim,
          builder: (context, _) {
            final animDistance = widget.distanceKm * _counterAnim.value;
            final animDistanceText = WalkingTime.distanceDisplay(animDistance);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Distance
                  Icon(
                    Icons.social_distance_rounded,
                    color: AppConstants.primaryColor,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _counterAnim.isCompleted ? distanceText : animDistanceText,
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Separator
                  Container(
                    width: 1,
                    height: 24,
                    color: AppConstants.primaryColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 16),
                  // Walking time
                  const Text('🚶‍♂️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$walkingText سيراً',
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 18),

        // Primary CTA: Navigate
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _openDirections,
            icon: const Icon(Icons.navigation_rounded, size: 22),
            label: const Text('ابدأ التوجيه الآن'),
            style: FilledButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Secondary: Details
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showDetails,
            icon: const Icon(Icons.info_outline_rounded, size: 18),
            label: const Text('تفاصيل أكثر'),
          ),
        ),
      ],
    );
  }
}
