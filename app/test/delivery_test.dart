import 'package:flutter_test/flutter_test.dart';
import 'package:am_vegetables/models.dart';

Shop _shop(List<Map<String, dynamic>> pins) => Shop.fromJson({'name_en': 'AM', 'pincodes': pins});

void main() {
  test('a location with delivery pincodes only delivers to those', () {
    final s = _shop([
      {'pincode': '626123', 'area': 'Sivakasi', 'active': true},
      {'pincode': '626124', 'area': 'Thiruthangal', 'active': true},
    ]);
    expect(s.limitsDelivery, isTrue);
    expect(s.deliversTo('626123'), isTrue);
    expect(s.deliversTo(' 626124 '), isTrue);
    expect(s.deliversTo('600025'), isFalse);
    expect(s.areaFor('626123'), 'Sivakasi');
  });

  test('switched-off pincodes do not count', () {
    final s = _shop([
      {'pincode': '626123', 'area': 'Sivakasi', 'active': true},
      {'pincode': '626130', 'area': 'Old area', 'active': false},
    ]);
    expect(s.deliversTo('626130'), isFalse);
    expect(s.servedPincodes.length, 1);
  });

  test('a location with no pincodes set is not restricted', () {
    final s = _shop([]);
    expect(s.limitsDelivery, isFalse);
    expect(s.deliversTo('600025'), isTrue);
    // only inactive entries also means "not restricted", not "deliver nowhere"
    expect(_shop([{'pincode': '626130', 'area': 'x', 'active': false}]).deliversTo('600025'), isTrue);
  });
}
