import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';

class LocationMapArgs {
  final double latitude;
  final double longitude;
  final String title;
  final String? addressText;

  const LocationMapArgs({
    required this.latitude,
    required this.longitude,
    required this.title,
    this.addressText,
  });
}

class LocationMapScreen extends StatelessWidget {
  final LocationMapArgs args;

  const LocationMapScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final point = LatLng(args.latitude, args.longitude);

    return Scaffold(
      appBar: AppBar(title: Text(args.title)),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(initialCenter: point, initialZoom: 16),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.select',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 64,
                    height: 64,
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.danger,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.13),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      args.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (args.addressText != null &&
                        args.addressText!.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        args.addressText!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${args.latitude}\nLong: ${args.longitude}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
