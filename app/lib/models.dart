String _s(dynamic v) => v?.toString() ?? '';
List<String> _ls(dynamic v) => (v as List?)?.map((e) => e.toString()).toList() ?? [];
bool _b(dynamic v, [bool d = false]) => v is bool ? v : d;

class ProductCategory {
  /// Built from products: id is the normalised English name.
  final String id, nameEn, nameTa;
  const ProductCategory(this.id, this.nameEn, this.nameTa);

  static String keyOf(String en) => en.trim().toLowerCase();
}

class Pack {
  final String labelEn, labelTa, note, unit;
  final double quantity;
  final bool isDefault, popular;
  Pack.fromJson(Map<String, dynamic> j)
      : labelEn = _s(j['label_en']),
        labelTa = _s(j['label_ta']),
        note = _s(j['note']),
        unit = _s(j['unit']),
        quantity = (j['quantity'] as num?)?.toDouble() ?? 1,
        isDefault = _b(j['is_default']),
        popular = _b(j['popular']);
}

class TrustPoint {
  final String titleEn, titleTa, icon;
  TrustPoint.fromJson(Map<String, dynamic> j)
      : titleEn = _s(j['title_en']),
        titleTa = _s(j['title_ta']),
        icon = _s(j['icon']);
}

class Product {
  final String categoryEn, categoryTa;
  final String id, nameEn, nameTa, nameAlt, image, origin, tagline, badge;
  final String descEn, descTa, harvestNote, soldBy, noteHint;
  final List<String> highlights, pairedWith, keywords;
  final List<TrustPoint> trustPoints;
  final List<Pack> packs;
  final bool allowNote, featured, inStock;
  final int sort;
  final int defaultPack;

  Product.fromJson(Map<String, dynamic> j)
      : id = _s(j['id']),
        nameEn = _s(j['name_en']),
        nameTa = _s(j['name_ta']),
        nameAlt = _s(j['name_alt']),
        categoryEn = _s(j['category_en']),
        categoryTa = _s(j['category_ta']),
        image = _s(j['image']),
        origin = _s(j['origin']),
        tagline = _s(j['tagline']),
        badge = _s(j['badge']),
        descEn = _s(j['description_en']),
        descTa = _s(j['description_ta']),
        harvestNote = _s(j['harvest_note']),
        soldBy = _s(j['sold_by']),
        noteHint = _s(j['note_hint']),
        highlights = _ls(j['highlights']),
        pairedWith = _ls(j['paired_with']),
        keywords = _ls(j['keywords']),
        trustPoints = ((j['trust_points'] as List?) ?? [])
            .map((e) => TrustPoint.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        packs = ((j['packs'] as List?) ?? [])
            .map((e) => Pack.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        allowNote = _b(j['allow_note'], true),
        featured = _b(j['featured']),
        inStock = _b(j['in_stock'], true),
        sort = (j['sort'] as num?)?.toInt() ?? 100,
        defaultPack = _defaultIndex(j['packs']);

  static int _defaultIndex(dynamic packs) {
    final l = (packs as List?) ?? [];
    final i = l.indexWhere((p) => p is Map && p['is_default'] == true);
    return i < 0 ? 0 : i;
  }

  String get categoryId => ProductCategory.keyOf(categoryEn);

  bool matches(String q) {
    q = q.toLowerCase().trim();
    if (q.isEmpty) return true;
    return [nameEn, nameTa, nameAlt, ...keywords].any((s) => s.toLowerCase().contains(q));
  }
}

class Pincode {
  final String pincode, area;
  final bool active;
  Pincode.fromJson(Map<String, dynamic> j)
      : pincode = _s(j['pincode']),
        area = _s(j['area']),
        active = _b(j['active'], true);
}

class Shop {
  final String nameEn, nameTa, badge, logo, splashEn, splashTa, whatsapp, phone;
  final String openEn, openTa, hours, paymentNote;
  final bool isOpen;
  final String bannerTitleEn, bannerTitleTa, bannerChip, bannerBody;
  final String npTitleEn, npTitleTa, npBodyEn, npBodyTa;
  final List<List<String>> howItWorks; // [en, ta]
  final List<List<String>> footerBadges; // [en, ta]
  final List<Pincode> pincodes;
  final Map<String, String> categoryIcons;

  Shop.fromJson(Map<String, dynamic> j)
      : categoryIcons = {
          for (final entry in (j['category_icons'] as List?) ?? [])
            ProductCategory.keyOf(_s(entry['category'])): _s(entry['icon']),
        },
        nameEn = _s(j['name_en']),
        nameTa = _s(j['name_ta']),
        badge = _s(j['badge']),
        logo = _s(j['logo']),
        splashEn = _s(j['splash_tagline_en']),
        splashTa = _s(j['splash_tagline_ta']),
        whatsapp = _s(j['whatsapp']),
        phone = _s(j['phone']),
        openEn = _s(j['open_label_en']),
        openTa = _s(j['open_label_ta']),
        hours = _s(j['hours']),
        paymentNote = _s(j['payment_note']),
        isOpen = _b(j['is_open'], true),
        bannerTitleEn = _s((j['banner'] ?? {})['title_en']),
        bannerTitleTa = _s((j['banner'] ?? {})['title_ta']),
        bannerChip = _s((j['banner'] ?? {})['chip']),
        bannerBody = _s((j['banner'] ?? {})['body']),
        npTitleEn = _s((j['no_payment'] ?? {})['title_en']),
        npTitleTa = _s((j['no_payment'] ?? {})['title_ta']),
        npBodyEn = _s((j['no_payment'] ?? {})['body_en']),
        npBodyTa = _s((j['no_payment'] ?? {})['body_ta']),
        howItWorks = ((j['how_it_works'] as List?) ?? [])
            .map((e) => [_s(e['title_en']), _s(e['title_ta'])])
            .toList(),
        footerBadges = ((j['footer_badges'] as List?) ?? [])
            .map((e) => [_s(e['text_en']), _s(e['text_ta'])])
            .toList(),
        pincodes = ((j['pincodes'] as List?) ?? [])
            .map((e) => Pincode.fromJson(Map<String, dynamic>.from(e)))
            .toList();
}

class Customer {
  String name, phone, altPhone, email, address, pincode, landmark, notes;
  Customer({
    this.name = '',
    this.phone = '',
    this.altPhone = '',
    this.email = '',
    this.address = '',
    this.pincode = '',
    this.landmark = '',
    this.notes = '',
  });

  bool get isEmpty => name.isEmpty && phone.isEmpty && address.isEmpty;

  Map<String, dynamic> toJson() => {
        'name': name, 'phone': phone, 'altPhone': altPhone, 'email': email,
        'address': address, 'pincode': pincode, 'landmark': landmark, 'notes': notes,
      };

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        name: _s(j['name']), phone: _s(j['phone']), altPhone: _s(j['altPhone']),
        email: _s(j['email']), address: _s(j['address']), pincode: _s(j['pincode']),
        landmark: _s(j['landmark']), notes: _s(j['notes']),
      );
}

class CartLine {
  final Product product;
  int packIndex;
  int count;
  String note;
  CartLine(this.product, this.packIndex, {this.count = 1, this.note = ''});

  Pack get pack => product.packs[packIndex.clamp(0, product.packs.length - 1)];
  String get label => count == 1 ? pack.labelEn : '$count × ${pack.labelEn}';
}
