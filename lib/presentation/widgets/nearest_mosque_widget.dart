import 'package:flutter/material.dart';

import '../../data/models/mosque_model.dart';

class NearestMosqueWidget extends StatelessWidget {
  const NearestMosqueWidget({
    super.key,
    required this.mosque,
    required this.distanceKm,
    required this.onOpenMap,
    required this.onOpenDetails,
  });

  final MosqueModel mosque;
  final double distanceKm;
  final VoidCallback onOpenMap;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.near_me_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'أقرب جامع لك',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              mosque.name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(mosque.address),
            const SizedBox(height: 6),
            Text(
              'المسافة التقريبية: ${distanceKm.toStringAsFixed(2)} كم',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onOpenMap,
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('عرض على الخريطة'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenDetails,
                  icon: const Icon(Icons.info_outline_rounded),
                  label: const Text('تفاصيل الجامع'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
