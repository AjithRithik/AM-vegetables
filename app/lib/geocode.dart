import 'dart:convert';

import 'package:http/http.dart' as http;

/// A place found on the map: coordinates plus an address the customer can use.
class GeoPlace {
  final double lat, lng;
  final String displayName; // full OpenStreetMap name
  final String short; // "12 Main Road, Anna Nagar, Sivakasi"
  final String postcode; // 6 digits, or '' if unknown
  const GeoPlace(this.lat, this.lng, this.displayName, this.short, this.postcode);

  factory GeoPlace.fromJson(Map<String, dynamic> j) {
    final a = (j['address'] as Map?)?.cast<String, dynamic>() ?? {};
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = a[k];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
      return '';
    }

    final display = (j['display_name'] ?? '').toString();
    final street = [pick(['house_number']), pick(['road', 'pedestrian', 'footway'])].where((s) => s.isNotEmpty).join(' ');
    final parts = <String>[];
    final name = (j['name'] ?? '').toString().trim(); // a landmark such as 'Sivakasi Bus Stand'
    for (final p in [name, street, pick(['neighbourhood', 'suburb', 'quarter', 'hamlet']), pick(['village', 'town', 'city', 'municipality', 'county'])]) {
      if (p.isNotEmpty && !parts.contains(p)) parts.add(p);
    }
    final pin = pick(['postcode']).replaceAll(RegExp(r'\s'), '');
    return GeoPlace(
      double.tryParse('${j['lat']}') ?? 0,
      double.tryParse('${j['lon']}') ?? 0,
      display,
      parts.isEmpty ? display : parts.join(', '),
      RegExp(r'^\d{6}$').hasMatch(pin) ? pin : '',
    );
  }
}

/// Free address search and "what is at this pin" using OpenStreetMap's Nominatim service.
/// Its usage policy allows light use (about 1 request per second, no search-as-you-type), which fits
/// a shop app: we search only when the customer submits, and look up once when they confirm the pin.
/// If order volume grows a lot, swap the base URL for a paid/hosted geocoder (LocationIQ, MapTiler, Google).
class Geocoder {
  static const _base = 'https://nominatim.openstreetmap.org';
  static const _headers = {'User-Agent': 'AMVegetablesApp/1.0 (https://am-veg.vercel.app)', 'Accept-Language': 'en'};

  static Future<List<GeoPlace>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return [];
    try {
      final uri = Uri.parse('$_base/search').replace(queryParameters: {
        'q': q,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '6',
        'countrycodes': 'in',
      });
      final r = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return [];
      return (jsonDecode(utf8.decode(r.bodyBytes)) as List)
          .map((e) => GeoPlace.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<GeoPlace?> reverse(double lat, double lng) async {
    try {
      final uri = Uri.parse('$_base/reverse').replace(queryParameters: {
        'lat': '$lat',
        'lon': '$lng',
        'format': 'jsonv2',
        'addressdetails': '1',
        'zoom': '18',
      });
      final r = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final j = Map<String, dynamic>.from(jsonDecode(utf8.decode(r.bodyBytes)) as Map);
      if (j['error'] != null) return null;
      return GeoPlace.fromJson(j);
    } catch (_) {
      return null;
    }
  }
}
