import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../app/theme.dart';

class FineLocationMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final bool interactive;
  final ValueChanged<LatLng>? onTap;
  final double height;
  final String? helperText;

  const FineLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.interactive = false,
    this.onTap,
    this.height = 180,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _webFallback();
    }

    final marker = Marker(
      markerId: const MarkerId('fine-location'),
      position: LatLng(latitude, longitude),
      draggable: interactive,
      onDragEnd: interactive && onTap != null ? onTap! : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: GoogleMap(
              key: ValueKey('${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)},$interactive'),
              initialCameraPosition: CameraPosition(
                target: LatLng(latitude, longitude),
                zoom: 15.5,
              ),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              markers: {marker},
              onTap: interactive && onTap != null ? onTap! : null,
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 10),
          Text(
            helperText!,
            style: const TextStyle(
              fontSize: 11,
              color: TomsColors.mutedForeground,
            ),
          ),
        ],
      ],
    );
  }

  Widget _webFallback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                TomsColors.primary.withValues(alpha: 0.08),
                TomsColors.primary.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TomsColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: TomsColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.map_outlined, color: TomsColors.primary, size: 28),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Map preview unavailable on web',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: TomsColors.foreground),
                ),
                const SizedBox(height: 6),
                Text(
                  '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: TomsColors.mutedForeground),
                ),
                if (interactive) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _adjustButton('North', const LatLng(0.0008, 0)),
                      _adjustButton('South', const LatLng(-0.0008, 0)),
                      _adjustButton('West', const LatLng(0, -0.0008)),
                      _adjustButton('East', const LatLng(0, 0.0008)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 10),
          Text(
            helperText!,
            style: const TextStyle(fontSize: 11, color: TomsColors.mutedForeground),
          ),
        ],
      ],
    );
  }

  Widget _adjustButton(String label, LatLng delta) {
    return OutlinedButton(
      onPressed: !interactive || onTap == null
          ? null
          : () => onTap!(
                LatLng(
                  latitude + delta.latitude,
                  longitude + delta.longitude,
                ),
              ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        side: const BorderSide(color: TomsColors.border),
      ),
      child: Text(label, style: const TextStyle(fontSize: 11)),
    );
  }
}
