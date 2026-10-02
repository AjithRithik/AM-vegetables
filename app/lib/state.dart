import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  Shop? shop;
  List<ProductCategory> categories = [];
  List<Product> products = [];
  bool loading = true;
  String? error;

  final Map<String, CartLine> cart = {};
  Customer customer = Customer();
  bool rememberDetails = true;
  bool customerLoadedFromSaved = false;

  /// Bottom tabs: 0 Home, 1 Catalogue, 2 Cart, 3 Contact.
  static const tabHome = 0, tabCatalogue = 1, tabCart = 2, tabContact = 3;
  int tab = 0;
  void setTab(int i) {
    tab = i;
    notifyListeners();
  }

  String catFilter = 'all';
  void setCat(String id) {
    catFilter = id;
    notifyListeners();
  }

  void openCatalogue([String cat = 'all']) {
    catFilter = cat;
    tab = tabCatalogue;
    notifyListeners();
  }

  // ------------------------------------------------------------------ load
  Future<Map<String, dynamic>> _fetch(String name, SharedPreferences prefs) async {
    final key = 'cache_$name';
    try {
      final r = await http
          .get(Uri.parse('${AppConfig.baseUrl}/content/$name.json'))
          .timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final body = utf8.decode(r.bodyBytes);
      await prefs.setString(key, body);
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      final cached = prefs.getString(key);
      if (cached != null) return jsonDecode(cached) as Map<String, dynamic>;
      rethrow;
    }
  }

  Future<void> load() async {
    loading = true;
    error = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final res = await Future.wait([
        _fetch('shop', prefs),
        _fetch('products', prefs),
      ]);
      shop = Shop.fromJson(res[0]);
      products = ((res[1]['products'] as List?) ?? [])
          .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.packs.isNotEmpty)
          .toList()
        ..sort((a, b) => a.sort.compareTo(b.sort));
      // Categories come straight from products.json, in order of first appearance.
      final seen = <String, ProductCategory>{};
      for (final p in products) {
        if (p.categoryEn.trim().isEmpty) continue;
        seen.putIfAbsent(p.categoryId, () => ProductCategory(p.categoryId, p.categoryEn.trim(), p.categoryTa));
      }
      categories = seen.values.toList();
      _restoreLocal(prefs);
    } catch (e) {
      error = 'Could not load catalogue. Check your connection.\n$e';
    }
    loading = false;
    notifyListeners();
  }

  void _restoreLocal(SharedPreferences prefs) {
    final c = prefs.getString('customer');
    if (c != null) {
      customer = Customer.fromJson(jsonDecode(c));
      customerLoadedFromSaved = !customer.isEmpty;
    }
    final cartJson = prefs.getString('cart');
    if (cartJson != null) {
      cart.clear();
      for (final e in jsonDecode(cartJson) as List) {
        final idx = products.indexWhere((p) => p.id == e['id']);
        if (idx < 0) continue;
        final p = products[idx];
        cart[p.id] = CartLine(p, (e['pack'] as int).clamp(0, p.packs.length - 1),
            count: e['count'] ?? 1, note: e['note'] ?? '');
      }
    }
  }

  Future<void> _persistCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'cart',
        jsonEncode(cart.values
            .map((l) => {'id': l.product.id, 'pack': l.packIndex, 'count': l.count, 'note': l.note})
            .toList()));
  }

  Future<void> saveCustomer() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberDetails) {
      await prefs.setString('customer', jsonEncode(customer.toJson()));
    } else {
      await prefs.remove('customer');
    }
  }

  // ------------------------------------------------------------------ cart
  Product? productById(String id) {
    for (final p in products) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool inCart(String id) => cart.containsKey(id);
  int get cartCount => cart.length;

  void add(Product p, {int? pack, int count = 1}) {
    final line = cart[p.id];
    if (line != null) {
      if (pack != null) line.packIndex = pack;
      line.count = count;
    } else {
      cart[p.id] = CartLine(p, pack ?? p.defaultPack, count: count);
    }
    _persistCart();
    notifyListeners();
  }

  void setPack(String id, int pack) {
    cart[id]?.packIndex = pack;
    _persistCart();
    notifyListeners();
  }

  void setCount(String id, int count) {
    if (count < 1) return remove(id);
    cart[id]?.count = count;
    _persistCart();
    notifyListeners();
  }

  void setNote(String id, String note) {
    cart[id]?.note = note;
    _persistCart();
  }

  void remove(String id) {
    cart.remove(id);
    _persistCart();
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    _persistCart();
    notifyListeners();
  }

  // -------------------------------------------------------------- whatsapp
  String _lineText(Product p, String label, [String note = '']) =>
      '• ${p.nameEn} / ${p.nameTa} — $label${note.isNotEmpty ? ' ($note)' : ''}';

  String fullMessage() {
    final s = shop!;
    final c = customer;
    final b = StringBuffer()
      ..writeln('*${s.nameEn} — New Produce Enquiry*')
      ..writeln()
      ..writeln('*Customer Details / விவரம்:*')
      ..writeln('Name: ${c.name}')
      ..writeln('Phone: ${c.phone}');
    if (c.altPhone.isNotEmpty) b.writeln('Alt: ${c.altPhone}');
    if (c.email.isNotEmpty) b.writeln('Email: ${c.email}');
    b
      ..writeln()
      ..writeln('*Delivery Details / முகவரி:*')
      ..writeln('Address: ${c.address}')
      ..writeln('Landmark: ${c.landmark}')
      ..writeln('Pincode: ${c.pincode}');
    if (c.notes.isNotEmpty) b.writeln('Note: ${c.notes}');
    b
      ..writeln()
      ..writeln('*Required Products / காய்கறிகள்:*');
    for (final l in cart.values) {
      b.writeln(_lineText(l.product, l.label, l.note));
    }
    b
      ..writeln()
      ..writeln('வணக்கம் ${s.nameEn}. Please confirm today\'s harvest prices and home delivery schedule for this list. Thank you!');
    return b.toString();
  }

  Future<bool> sendWhatsApp(String message) async {
    final number = shop!.whatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> call() async {
    final number = shop!.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    await launchUrl(Uri.parse('tel:$number'));
  }
}
