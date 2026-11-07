import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:am_vegetables/models.dart';
import 'package:am_vegetables/state.dart';

Product _p(String id, String name, double price) => Product.fromJson({
      'id': id,
      'name_en': name,
      'name_ta': 'த',
      'packs': [
        {'id': '$id-1', 'label_en': '1 kg', 'quantity': 1, 'is_default': true, 'price': price},
      ],
    });

AppState _state({String whatsapp = '919940379601'}) {
  final st = AppState();
  st.location = const ShopLocation('l1', 'sivakasi', 'Sivakasi', 'சிவகாசி');
  st.shop = Shop.fromJson({'name_en': 'AM Vegetables', 'whatsapp': whatsapp, 'address': 'Main Road, Sivakasi'});
  st.products = [_p('tomato', 'Tomato', 34), _p('onion', 'Onion', 72)];
  st.customer = Customer(name: 'Ravi', phone: '9876543210', address: '5 Temple St', pincode: '626123', landmark: 'Temple');
  return st;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('WhatsApp message lists prices, total and the chosen location', () {
    final st = _state();
    st.add(st.products[0], count: 2);
    st.add(st.products[1]);
    expect(st.cartTotal, 140); // 2 x 34 + 72
    final m = st.fullMessage();
    expect(m, contains('(Sivakasi)'));
    expect(m, contains('2 × 1 kg = ₹68'));
    expect(m, contains('1 kg = ₹72'));
    expect(m, contains('Estimated total: ₹140'));
  });

  test('a shop with no WhatsApp number cannot send an order', () async {
    final st = _state(whatsapp: '');
    expect(await st.sendWhatsApp('hi'), isFalse);
  });
}
