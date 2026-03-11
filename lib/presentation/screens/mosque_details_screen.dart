import 'package:flutter/material.dart';

import '../../core/services/map_service.dart';
import '../../data/models/mosque_model.dart';
import '../widgets/mosque_card.dart';

class MosqueDetailsScreen extends StatefulWidget {
  const MosqueDetailsScreen({
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
  State<MosqueDetailsScreen> createState() => _MosqueDetailsScreenState();
}

class _MosqueDetailsScreenState extends State<MosqueDetailsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الجامع')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MosqueCard(
            title: widget.mosque.name,
            subtitle:
                '${widget.mosque.address}\n\n'
                'المسافة: ${widget.distanceKm.toStringAsFixed(2)} كم',
          ),
          const SizedBox(height: 12),
          MosqueCard(
            title: 'الإحداثيات',
            subtitle:
                'خط العرض: ${widget.mosque.latitude.toStringAsFixed(6)}\n'
                'خط الطول: ${widget.mosque.longitude.toStringAsFixed(6)}',
            icon: Icons.pin_drop_outlined,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _openDirections,
            icon: const Icon(Icons.navigation_rounded),
            label: const Text('التوجه إلى الجامع'),
          ),
        ],
      ),
    );
  }
}
