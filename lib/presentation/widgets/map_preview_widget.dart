import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_constants.dart';

/// A live OpenStreetMap preview showing user position + mosque pin.
class MapPreviewWidget extends StatefulWidget {
  const MapPreviewWidget({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.mosqueLat,
    required this.mosqueLng,
    required this.mosqueName,
  });

  final double userLat;
  final double userLng;
  final double mosqueLat;
  final double mosqueLng;
  final String mosqueName;

  @override
  State<MapPreviewWidget> createState() => _MapPreviewWidgetState();
}

class _MapPreviewWidgetState extends State<MapPreviewWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userLatLng = LatLng(widget.userLat, widget.userLng);
    final mosqueLatLng = LatLng(widget.mosqueLat, widget.mosqueLng);

    // Calculate center point between user & mosque
    final centerLat = (widget.userLat + widget.mosqueLat) / 2;
    final centerLng = (widget.userLng + widget.mosqueLng) / 2;

    // Calculate zoom based on distance
    final distance = const Distance().as(
      LengthUnit.Meter,
      userLatLng,
      mosqueLatLng,
    );
    final zoom = _zoomForDistance(distance);

    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(centerLat, centerLng),
        initialZoom: zoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        // OpenStreetMap tile layer (free, no API key)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.aqrabmasjid.app',
          maxZoom: 19,
        ),

        // Connection line between user and mosque
        PolylineLayer(
          polylines: [
            Polyline(
              points: [userLatLng, mosqueLatLng],
              strokeWidth: 3.0,
              color: AppConstants.primaryColor.withValues(alpha: 0.4),
              pattern: const StrokePattern.dotted(),
            ),
          ],
        ),

        // Markers
        MarkerLayer(
          markers: [
            // User location — animated pulse dot
            Marker(
              point: userLatLng,
              width: 60,
              height: 60,
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, _) {
                  final pulseScale = 1.0 + (_pulseCtrl.value * 1.5);
                  final pulseAlpha = (1.0 - _pulseCtrl.value) * 0.3;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse ring
                      Transform.scale(
                        scale: pulseScale,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppConstants.userDotColor.withValues(
                              alpha: pulseAlpha,
                            ),
                          ),
                        ),
                      ),
                      // Core dot
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppConstants.userDotColor,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppConstants.userDotColor.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Mosque pin
            Marker(
              point: mosqueLatLng,
              width: 50,
              height: 60,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pin body
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppConstants.primaryColor,
                          AppConstants.primaryDark,
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.accentGold,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryDark.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  // Pin pointer
                  CustomPaint(
                    size: const Size(12, 8),
                    painter: _PinPointerPainter(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _zoomForDistance(double meters) {
    if (meters < 200) return 17.0;
    if (meters < 500) return 16.0;
    if (meters < 1000) return 15.0;
    if (meters < 2000) return 14.0;
    if (meters < 5000) return 13.0;
    if (meters < 10000) return 12.0;
    if (meters < 20000) return 11.0;
    return 10.0;
  }
}

/// Draws the small triangle pointer below the mosque pin circle.
class _PinPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = AppConstants.primaryDark,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
