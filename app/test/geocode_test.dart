import 'package:flutter_test/flutter_test.dart';
import 'package:am_vegetables/geocode.dart';

void main() {
  test('search result (real Nominatim shape) becomes a usable address', () {
    final g = GeoPlace.fromJson({
      'lat': '9.4470009',
      'lon': '77.8019497',
      'name': 'Sivakasi Bus Stand',
      'display_name': 'Sivakasi Bus Stand, Sattur - Sivakasi - Kalugumalai Road, Vishwanatham, Sivakasi, Virudhunagar, Tamil Nadu, 626123, India',
      'address': {
        'amenity': 'Sivakasi Bus Stand',
        'road': 'Sattur - Sivakasi - Kalugumalai Road',
        'suburb': 'Vishwanatham',
        'city': 'Sivakasi',
        'postcode': '626123',
      },
    });
    expect(g.lat, closeTo(9.447, 0.001));
    expect(g.short, 'Sivakasi Bus Stand, Sattur - Sivakasi - Kalugumalai Road, Vishwanatham, Sivakasi');
    expect(g.postcode, '626123');
  });

  test('reverse result with only a town still gives something to fill in', () {
    final g = GeoPlace.fromJson({
      'lat': '9.4533793',
      'lon': '77.8024453',
      'name': '',
      'display_name': 'Sivakasi, Virudhunagar, Tamil Nadu, 626123, India',
      'address': {'city': 'Sivakasi', 'postcode': '626123'},
    });
    expect(g.short, 'Sivakasi');
    expect(g.postcode, '626123');
  });

  test('a postcode that is not 6 digits is ignored, and no address falls back to the full name', () {
    final g = GeoPlace.fromJson({'lat': '1', 'lon': '2', 'display_name': 'Somewhere, India', 'address': {'postcode': '62 6123 99'}});
    expect(g.postcode, '');
    expect(g.short, 'Somewhere, India');
  });
}
