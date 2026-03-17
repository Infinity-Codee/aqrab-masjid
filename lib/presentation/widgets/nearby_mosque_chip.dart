import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_constants.dart';
import '../../core/services/map_service.dart';
import '../../core/utils/walking_time.dart';
import '../controllers/mosque_controller.dart';

/// A small chip card for alternative nearby mosques in the horizontal scroll.
class NearbyMosqueChip extends StatelessWidget {
  const NearbyMosqueChip({
    super.key,
    required this.mosqueWithDistance,
    required this.userLat,
    required this.userLng,
  });

  final MosqueWithDistance mosqueWithDistance;
  final double userLat;
  final double userLng;

  @override
  Widget build(BuildContext context) {
    final mosque = mosqueWithDistance.mosque;
    final distanceText = WalkingTime.distanceDisplay(
      mosqueWithDistance.distanceKm,
    );

    return GestureDetector(
      onTap: () async {
        try {
          await MapService.openDirections(
            mosque: mosque,
            originLat: userLat,
            originLng: userLng,
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', '')),
            ),
          );
        }
      },
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mosque icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.mosque_rounded,
                size: 18,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 10),
            // Mosque name
            Text(
              mosque.name,
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.grey[850],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Distance
            Row(
              children: [
                Icon(
                  Icons.directions_walk_rounded,
                  size: 14,
                  color: AppConstants.accentGold,
                ),
                const SizedBox(width: 4),
                Text(
                  distanceText,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
