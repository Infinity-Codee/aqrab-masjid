import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../controllers/mosque_controller.dart';
import '../widgets/mosque_card.dart';
import '../widgets/nearest_mosque_widget.dart';
import 'map_screen.dart';
import 'mosque_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final MosqueController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MosqueController()..loadNearestMosque();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            onPressed: _controller.refresh,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
          ),
        ],
      ),
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              MosqueCard(
                title: 'موقعك الحالي',
                subtitle:
                    'خط العرض: ${userPosition.latitude.toStringAsFixed(5)}\n'
                    'خط الطول: ${userPosition.longitude.toStringAsFixed(5)}\n'
                    'دقة الموقع: ±${(_controller.locationAccuracyMeters ?? 0).toStringAsFixed(0)} متر',
                icon: Icons.my_location_rounded,
              ),
              const SizedBox(height: 10),
              if (_controller.locationNotice != null) ...[
                Card(
                  color: const Color(0xFFFFF8E1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      _controller.locationNotice!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              NearestMosqueWidget(
                mosque: nearestMosque,
                distanceKm: nearestDistanceKm,
                onOpenMap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MapScreen(
                        mosque: nearestMosque,
                        distanceKm: nearestDistanceKm,
                        userLat: userPosition.latitude,
                        userLng: userPosition.longitude,
                      ),
                    ),
                  );
                },
                onOpenDetails: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MosqueDetailsScreen(
                        mosque: nearestMosque,
                        distanceKm: nearestDistanceKm,
                        userLat: userPosition.latitude,
                        userLng: userPosition.longitude,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'تم تحميل ${_controller.mosques.length} جامع.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('جارٍ تحديد موقعك وحساب أقرب جامع...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.red,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
