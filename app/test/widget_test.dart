import 'package:flutter_test/flutter_test.dart';
import 'package:am_vegetables/models.dart';

Map<String, dynamic> _row() => {
      'id': 'x',
      'name_en': 'Tomato',
      'packs': [
        {'id': 'a', 'label_en': '500 g', 'quantity': 0.5, 'price': 17.0},
        {'id': 'b', 'label_en': '1 kg', 'quantity': 1, 'is_default': true, 'price': 34.5},
      ],
    };

void main() {
  test('Product parses pack defaults', () {
    final p = Product.fromJson(_row());
    expect(p.defaultPack, 1);
    expect(p.matches('tom'), isTrue);
  });

  test('Pack prices are parsed per location row', () {
    final p = Product.fromJson(_row());
    expect(p.packs[0].cost, 17);
    expect(p.packs[1].priceText, '₹34.50');
    expect(p.fromPrice, 17);
  });

  test('Cart line total = pack price x count', () {
    final line = CartLine(Product.fromJson(_row()), 1, count: 3);
    expect(line.total, 103.5);
  });

  test('money() drops a trailing .00', () {
    expect(money(40), '₹40');
    expect(money(40.0), '₹40');
    expect(money(12.5), '₹12.50');
  });

  test('ShopLocation parses the locations table', () {
    final l = ShopLocation.fromJson({'id': '1', 'slug': 'sivakasi', 'name_en': 'Sivakasi', 'name_ta': 'சிவகாசி'});
    expect(l.nameEn, 'Sivakasi');
  });
}
