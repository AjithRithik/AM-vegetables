import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'models.dart';

/// The shop's database refused the order (item sold out, price removed, bad details...).
/// [message] is written for the customer.
class OrderRejected implements Exception {
  final String message;
  OrderRejected(this.message);
  @override
  String toString() => message;
}

class PlacedOrder {
  final int orderNo;
  final double total;
  const PlacedOrder(this.orderNo, this.total);
}

class AppState extends ChangeNotifier {
  Shop? shop;
  List<ShopLocation> locations = [];
  ShopLocation? location; // the customer's chosen shop; null until they pick one
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
  /// GET a Supabase REST url. Falls back to the last good copy when offline.
  Future<dynamic> _get(String cacheKey, Uri uri, SharedPreferences prefs) async {
    try {
      final r = await http.get(uri, headers: AppConfig.headers).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final body = utf8.decode(r.bodyBytes);
      await prefs.setString(cacheKey, body);
      return jsonDecode(body);
    } catch (_) {
      final cached = prefs.getString(cacheKey);
      if (cached != null) return jsonDecode(cached);
      rethrow;
    }
  }

  /// First start-up: locations list, then the saved location's catalogue if there is one.
  Future<void> load() async {
    loading = true;
    error = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      _restoreCustomer(prefs);
      final locs = await _get(
        'cache_locations',
        AppConfig.rest('locations', {'select': 'id,slug,name_en,name_ta', 'is_active': 'eq.true', 'order': 'sort'}),
        prefs,
      ) as List;
      locations = locs.map((e) => ShopLocation.fromJson(Map<String, dynamic>.from(e))).toList();
      final savedId = prefs.getString('location_id');
      location = locations.where((l) => l.id == savedId).firstOrNull;
      if (location != null) await _loadCatalogue(prefs);
    } catch (e) {
      error = 'Could not load. Check your connection.\n$e';
    }
    loading = false;
    notifyListeners();
  }

  /// Re-reads the current location's catalogue (e.g. after the shop changed a price).
  Future<void> refreshCatalogue() async {
    if (location == null) return;
    try {
      await _loadCatalogue(await SharedPreferences.getInstance());
      error = null;
    } catch (_) {/* keep what we have */}
    notifyListeners();
  }

  /// Customer picked (or changed) their location. Returns false if the catalogue could not load.
  Future<bool> selectLocation(ShopLocation l) async {
    loading = true;
    error = null;
    location = l;
    cart.clear(); // each location has its own cart (prices differ); restored below
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('location_id', l.id);
      await _loadCatalogue(prefs);
      tab = tabHome;
      catFilter = 'all';
    } catch (e) {
      error = 'Could not load ${l.nameEn}. Check your connection.\n$e';
    }
    loading = false;
    notifyListeners();
    return error == null;
  }

  Future<void> _loadCatalogue(SharedPreferences prefs) async {
    final id = location!.id;
    final res = await Future.wait([
      _get('cache_catalogue_$id', AppConfig.rest('v_catalogue', {'select': '*', 'location_id': 'eq.$id', 'order': 'sort', 'limit': '2000'}), prefs),
      _get('cache_settings_$id', AppConfig.rest('location_settings', {'select': '*', 'location_id': 'eq.$id'}), prefs),
      _get('cache_app_shop', AppConfig.rest('app_settings', {'select': 'value', 'key': 'eq.shop'}), prefs),
      _get('cache_categories', AppConfig.rest('categories', {'select': 'name_en,icon'}), prefs),
    ]);

    final rows = res[0] as List;
    final settings = (res[1] as List).isNotEmpty ? Map<String, dynamic>.from((res[1] as List).first) : <String, dynamic>{};
    final global = (res[2] as List).isNotEmpty
        ? Map<String, dynamic>.from((res[2] as List).first['value'] as Map)
        : <String, dynamic>{};

    shop = Shop.fromJson({
      ...global,
      'whatsapp': settings['whatsapp'],
      'phone': settings['phone'],
      'hours': settings['hours'],
      'is_open': settings['is_open'],
      'payment_note': settings['payment_note'],
      'banner': settings['banner'] ?? {},
      'pincodes': settings['pincodes'] ?? [],
      'address': settings['address'],
      'maps_url': settings['maps_url'],
      'category_icons': [
        for (final c in (res[3] as List)) {'category': c['name_en'], 'icon': c['icon']},
      ],
    });

    products = rows
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.packs.isNotEmpty)
        .toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
    // Categories are built from the products sold at this location, in order of first appearance.
    final seen = <String, ProductCategory>{};
    for (final p in products) {
      if (p.categoryEn.trim().isEmpty) continue;
      seen.putIfAbsent(p.categoryId, () => ProductCategory(p.categoryId, p.categoryEn.trim(), p.categoryTa));
    }
    categories = seen.values.toList();
    _restoreCart(prefs);
  }

  void _restoreCustomer(SharedPreferences prefs) {
    final c = prefs.getString('customer');
    if (c != null) {
      customer = Customer.fromJson(jsonDecode(c));
      customerLoadedFromSaved = !customer.isEmpty;
    }
  }

  String get _cartKey => 'cart_${location?.id}';

  void _restoreCart(SharedPreferences prefs) {
    cart.clear();
    final cartJson = prefs.getString(_cartKey);
    if (cartJson == null) return;
    for (final e in jsonDecode(cartJson) as List) {
      final p = productById('${e['id']}');
      if (p == null) continue; // no longer sold or priced here
      cart[p.id] = CartLine(p, (e['pack'] as int).clamp(0, p.packs.length - 1), count: e['count'] ?? 1, note: e['note'] ?? '');
    }
  }

  Future<void> _persistCart() async {
    if (location == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _cartKey,
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
  double get cartTotal => cart.values.fold(0.0, (sum, l) => sum + l.total);

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
  String _lineText(CartLine l) =>
      '• ${l.product.nameEn} / ${l.product.nameTa} — ${l.label} = ${money(l.total)}${l.note.isNotEmpty ? ' (${l.note})' : ''}';

  String fullMessage({int? orderNo}) {
    final s = shop!;
    final c = customer;
    final b = StringBuffer()
      ..writeln('*${s.nameEn} (${location!.nameEn}) — New Order${orderNo != null ? ' #$orderNo' : ''}*')
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
    if (c.hasLocation) b.writeln('Map Location: ${c.mapLink}');
    if (c.notes.isNotEmpty) b.writeln('Note: ${c.notes}');
    b
      ..writeln()
      ..writeln('*Required Products / காய்கறிகள்:*');
    for (final l in cart.values) {
      b.writeln(_lineText(l));
    }
    b
      ..writeln()
      ..writeln('*Estimated total: ${money(cartTotal)}*')
      ..writeln()
      ..writeln('வணக்கம் ${s.nameEn}. Please confirm availability, final price and delivery time for this order. Thank you!');
    return b.toString();
  }

  /// Saves the order in the shop's database so the owner and vendor see it in the admin.
  /// Prices are taken from the database, never from the phone.
  /// Returns null if the phone is offline (the caller may still send the WhatsApp message);
  /// throws [OrderRejected] if the shop refused the order.
  Future<PlacedOrder?> placeOrder() async {
    final c = customer;
    final body = jsonEncode({
      'p_location': location!.id,
      'p_customer': {
        'name': c.name,
        'phone': c.phone,
        'alt_phone': c.altPhone,
        'address': c.address,
        'landmark': c.landmark,
        'pincode': c.pincode,
        'map_link': c.hasLocation ? c.mapLink : '',
        'notes': c.notes,
      },
      'p_items': [
        for (final l in cart.values) {'pack_id': l.pack.id, 'count': l.count, 'note': l.note},
      ],
    });
    http.Response r;
    try {
      r = await http
          .post(AppConfig.rest('rpc/place_order'),
              headers: {...AppConfig.headers, 'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      return null;
    }
    final text = utf8.decode(r.bodyBytes);
    if (r.statusCode == 200) {
      final j = jsonDecode(text) as Map<String, dynamic>;
      return PlacedOrder((j['order_no'] as num).toInt(), (j['total'] as num).toDouble());
    }
    if (r.statusCode >= 400 && r.statusCode < 500) {
      String msg = 'The shop could not accept this order.';
      try {
        msg = (jsonDecode(text) as Map)['message']?.toString() ?? msg;
      } catch (_) {}
      throw OrderRejected(msg);
    }
    return null;
  }

  /// Opens WhatsApp to THIS location's number. Returns false if it has none or cannot open.
  Future<bool> sendWhatsApp(String message) async {
    final number = (shop?.whatsapp ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (number.isEmpty) return false;
    final uri = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent(message)}');
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  Future<void> call() async {
    final number = (shop?.phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) return;
    await launchUrl(Uri.parse('tel:$number'));
  }
}
