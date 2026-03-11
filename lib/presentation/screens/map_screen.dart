import 'package:flutter/material.dart';

import '../../core/services/map_service.dart';
import '../../data/models/mosque_model.dart';
import '../widgets/mosque_card.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
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
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Future<void> _openDirections() async {
    try {
      await MapService.openDirections(
        mosque: widget.mosque,
        originLat: widget.userLat,
        originLng: widget.userLng,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _openLocation() async {
    try {
      await MapService.openMosqueLocation(widget.mosque);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الخريطة والاتجاهات')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF0F7A4E), Color(0xFF1B9A62)],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_rounded, color: Colors.white, size: 52),
                  SizedBox(height: 10),
                  Text(
                    'عرض موقع الجامع',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          MosqueCard(
            title: widget.mosque.name,
            subtitle:
                '${widget.mosque.address}\n\n'
                'يبعد عنك: ${widget.distanceKm.toStringAsFixed(2)} كم\n'
                'إحداثيات الجامع: '
                '${widget.mosque.latitude.toStringAsFixed(5)}, '
                '${widget.mosque.longitude.toStringAsFixed(5)}',
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _openDirections,
            icon: const Icon(Icons.directions_rounded),
            label: const Text('فتح الاتجاهات'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openLocation,
            icon: const Icon(Icons.location_on_outlined),
            label: const Text('فتح موقع الجامع'),
          ),
        ],
      ),
    );
  }
}
