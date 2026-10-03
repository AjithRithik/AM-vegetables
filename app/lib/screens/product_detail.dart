import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product p;
  const ProductDetailScreen(this.p, {super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _pack;
  late int _count;

  @override
  void initState() {
    super.initState();
    final line = context.read<AppState>().cart[widget.p.id];
    _pack = line?.packIndex ?? widget.p.defaultPack;
    _count = line?.count ?? 1;
  }

  IconData _icon(String k) => switch (k) {
        'farm' => Icons.agriculture,
        'verified' => Icons.verified_outlined,
        'wash' => Icons.water_drop_outlined,
        'organic' => Icons.eco_outlined,
        'fresh' => Icons.wb_sunny_outlined,
        'delivery' => Icons.local_shipping_outlined,
        _ => Icons.check_circle_outline,
      };

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final p = widget.p;
    final shop = st.shop!;
    final pack = p.packs[_pack];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(p.nameEn, style: const TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 110), children: [
        Stack(children: [
          ProductImage(p.image, height: 260, width: 900, heroTag: 'img-${p.id}', radius: BorderRadius.circular(26)),
          if (p.badge.isNotEmpty) Positioned(left: 12, top: 12, child: Pill(p.badge, bg: Colors.white)),
          if (p.harvestNote.isNotEmpty)
            Positioned(right: 12, bottom: 12, child: Pill(p.harvestNote, bg: Colors.black54, fg: Colors.white, icon: Icons.cloud_upload_outlined)),
        ]),
        const SizedBox(height: 12),
        if (p.trustPoints.isNotEmpty)
          SectionCard(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              for (final t in p.trustPoints)
                Expanded(
                  child: Column(children: [
                    Icon(_icon(t.icon), color: AppColors.green),
                    const SizedBox(height: 4),
                    Text(t.titleEn, textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    if (t.titleTa.isNotEmpty)
                      Text(t.titleTa, textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                  ]),
                ),
            ]),
          ),
        Text(p.nameEn, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        Text('${p.nameTa}${p.nameAlt.isNotEmpty ? ' (${p.nameAlt})' : ''}',
            style: const TextStyle(fontSize: 17, color: AppColors.greenDark, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(p.soldBy == 'weight' ? 'Sold by Weight / எடை அடிப்படையில் மட்டுமே' : p.soldBy == 'bunch' ? 'Sold by Bunch / கட்டு கணக்கில்' : 'Sold by Piece',
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 14),
        if (p.descEn.isNotEmpty || p.highlights.isNotEmpty)
          SectionCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const BiText('Culinary Highlights', 'சுவை & பயன்கள்', size: 15),
              if (p.descEn.isNotEmpty) ...[const SizedBox(height: 8), Text(p.descEn, style: const TextStyle(height: 1.45))],
              if (p.descTa.isNotEmpty) ...[const SizedBox(height: 6), Text(p.descTa, style: const TextStyle(height: 1.45, color: AppColors.muted))],
              if (p.highlights.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [for (final h in p.highlights) Pill(h)]),
              ],
            ]),
          ),
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [Expanded(child: BiText('Select Quantity', 'எடை தேர்வு')), Pill('Fresh Harvested')]),
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (var i = 0; i < p.packs.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _pack = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: (MediaQuery.of(context).size.width - 32 - 32 - 10) / 2,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _pack == i ? AppColors.green : AppColors.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(
                            child: Text(p.packs[i].labelEn,
                                style: TextStyle(fontWeight: FontWeight.w800, color: _pack == i ? Colors.white : AppColors.ink))),
                        if (p.packs[i].popular) const Pill('Popular', bg: AppColors.amber, fg: Colors.black87),
                        if (_pack == i) const Icon(Icons.check_circle, size: 18, color: Colors.white),
                      ]),
                      Text([p.packs[i].labelTa, p.packs[i].note].where((s) => s.isNotEmpty).join(' • '),
                          style: TextStyle(fontSize: 11, color: _pack == i ? Colors.white70 : AppColors.muted)),
                    ]),
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              const Expanded(child: BiText('Number of Packs', 'பாக்கெட் எண்ணிக்கை', size: 13)),
              Stepper2(value: _count, onChanged: (v) => setState(() => _count = v < 1 ? 1 : v)),
            ]),
          ]),
        ),
        SectionCard(
          color: AppColors.mint,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.verified_user, color: AppColors.green),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              BiText(shop.npTitleEn, shop.npTitleTa, size: 14, color: AppColors.greenDark),
              const SizedBox(height: 4),
              Text(shop.npBodyEn, style: const TextStyle(fontSize: 12)),
            ])),
          ]),
        ),
      ]),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            if (st.inCart(p.id)) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 54)),
                onPressed: () {
                  Navigator.popUntil(context, (r) => r.isFirst);
                  st.setTab(AppState.tabCart);
                },
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('View Cart'),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: AppColors.green),
                onPressed: p.inStock
                    ? () {
                        st.add(p, pack: _pack, count: _count);
                        showSnack(context, 'Added: ${p.nameEn} — ${_count == 1 ? pack.labelEn : '$_count × ${pack.labelEn}'}');
                      }
                    : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(st.inCart(p.id) ? 'Update Cart' : 'Add to Cart', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
