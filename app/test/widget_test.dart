import 'package:flutter_test/flutter_test.dart';
import 'package:am_vegetables/models.dart';

void main() {
  test('Product parses pack defaults', () {
    final p = Product.fromJson({
      'id': 'x',
      'name_en': 'Tomato',
      'packs': [
        {'label_en': '500 g', 'quantity': 0.5},
        {'label_en': '1 kg', 'quantity': 1, 'is_default': true},
      ],
    });
    expect(p.defaultPack, 1);
    expect(p.matches('tom'), isTrue);
  });
}
