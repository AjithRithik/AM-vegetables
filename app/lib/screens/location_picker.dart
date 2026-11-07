import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../geocode.dart';
import '../state.dart';
import '../widgets.dart';

class LatLngResult {
  final double lat, lng;
  final GeoPlace? place; // address at the pin, if it could be looked up
  const LatLngResult(this.lat, this.lng, [this.place]);
}

/// Full-screen map with a fixed centre pin; the user pans the map under it.
class LocationPickerScreen extends StatefulWidget {
  final double? initialLat, initialLng;
  const LocationPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  // Until GPS answers: Sivakasi area. If GPS is unavailable we move to the shop's town (see _centerOnShop).
  static const _fallback = LatLng(9.4533, 77.8024);
  final _map = MapController();
  late LatLng _center = widget.initialLat != null ? LatLng(widget.initialLat!, widget.initialLng!) : _fallback;
  bool _locating = false;
  bool _confirming = false, _searching = false, _searched = false;
  final _query = TextEditingController();
  List<GeoPlace> _results = [];

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
      if (silent) await _centerOnShop();
    }
    if (mounted) setState(() => _locating = false);
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// No GPS: start the map in the chosen shop's town instead of somewhere random.
  Future<void> _centerOnShop() async {
    if (!mounted || widget.initialLat != null) return;
    final name = context.read<AppState>().location?.nameEn;
    if (name == null) return;
    final found = await Geocoder.search('$name, Tamil Nadu');
    if (!mounted || found.isEmpty) return;
    final p = LatLng(found.first.lat, found.first.lng);
    _map.move(p, 14);
    _center = p;
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    setState(() { _searching = true; _searched = false; });
    final found = await Geocoder.search(_query.text);
    if (!mounted) return;
    setState(() { _results = found; _searching = false; _searched = true; });
  }

  void _pickResult(GeoPlace g) {
    final p = LatLng(g.lat, g.lng);
    _map.move(p, 17);
    _center = p;
    setState(() { _results = []; _searched = false; _query.text = g.short; });
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    final place = await Geocoder.reverse(_center.latitude, _center.longitude);
    if (!mounted) return;
    Navigator.pop(context, LatLngResult(_center.latitude, _center.longitude, place));
  }

  Widget _searchBox() => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Search area, street or landmark',
              filled: false,
              prefixIcon: const Icon(Icons.search, color: AppColors.green),
              suffixIcon: _searching
                  ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))
                  : IconButton(icon: const Icon(Icons.arrow_forward, color: AppColors.green), onPressed: _search),
            ),
          ),
          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView(shrinkWrap: true, padding: EdgeInsets.zero, children: [
                for (final g in _results)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.place_outlined, color: AppColors.green),
                    title: Text(g.short, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(g.displayName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5)),
                    onTap: () => _pickResult(g),
                  ),
              ]),
            )
          else if (_searched)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Text('No places found. Try a nearby landmark or town, or drag the map.', style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ),
        ]),
      );

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
        Positioned(top: 12, left: 12, right: 12, child: _searchBox()),
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
            onPressed: _confirming ? null : _confirm,
            icon: _confirming
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: Text(_confirming ? 'Finding address…' : 'Confirm this location', style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}
