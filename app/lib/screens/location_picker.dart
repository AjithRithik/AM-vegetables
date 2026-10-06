import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../widgets.dart';

class LatLngResult {
  final double lat, lng;
  const LatLngResult(this.lat, this.lng);
}

/// Full-screen map with a fixed centre pin; the user pans the map under it.
class LocationPickerScreen extends StatefulWidget {
  final double? initialLat, initialLng;
  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Default: Chennai, used until the user picks or GPS resolves.
  static const _fallback = LatLng(13.0827, 80.2707);
  final _map = MapController();
  late LatLng _center = widget.initialLat != null ? LatLng(widget.initialLat!, widget.initialLng!) : _fallback;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat == null) _useCurrent(silent: true);
  }

  Future<void> _useCurrent({bool silent = false}) async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw 'Location services are off.';
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw 'Location permission denied.';
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
      final p = LatLng(pos.latitude, pos.longitude);
      _map.move(p, 17);
      _center = p;
    } catch (e) {
      if (!silent && mounted) showSnack(context, '$e You can still drag the map to your location.');
    }
    if (mounted) setState(() => _locating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: const Text('Select Delivery Location', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: widget.initialLat != null ? 17 : 13,
            onPositionChanged: (cam, _) => _center = cam.center,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.am.vegetables',
            ),
            const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap contributors')]),
          ],
        ),
        const IgnorePointer(
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40),
              child: Icon(Icons.location_on, size: 48, color: Colors.redAccent),
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 100,
          child: FloatingActionButton.small(
            heroTag: 'gps',
            backgroundColor: Colors.white,
            onPressed: _locating ? null : () => _useCurrent(),
            child: _locating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location, color: AppColors.green),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: AppColors.green),
            onPressed: () => Navigator.pop(context, LatLngResult(_center.latitude, _center.longitude)),
            icon: const Icon(Icons.check),
            label: const Text('Confirm this location', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}
