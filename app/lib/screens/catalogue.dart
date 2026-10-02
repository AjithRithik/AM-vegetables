import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'product_card.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final cat = st.catFilter;
    final list = st.products.where((p) => (cat == 'all' || p.categoryId == cat) && p.matches(_q)).toList();
    final chips = [const ProductCategory('all', 'All Items', 'அனைத்தும்'), ...st.categories];

    return Stack(children: [
      RefreshIndicator(
        color: AppColors.green,
        onRefresh: st.load,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeSlide(
                    child: Material(
                      elevation: 3,
                      shadowColor: Colors.black12,
                      borderRadius: BorderRadius.circular(18),
                      child: TextField(
                        onChanged: (v) => setState(() => _q = v),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Search in English, தமிழ் (e.g. தக்காளி)',
                          hintStyle: const TextStyle(fontSize: 13.5),
                          prefixIcon: const Icon(Icons.search, color: AppColors.green),
                          suffixIcon: _q.isEmpty
                              ? null
                              : IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _q = '')),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FadeSlide(
                    delayMs: 80,
                    child: SizedBox(
                      height: 42,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: chips.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => _CategoryChip(
                          chips[i],
                          selected: cat == chips[i].id,
                          count: chips[i].id == 'all'
                              ? st.products.length
                              : st.products.where((p) => p.categoryId == chips[i].id).length,
                          onTap: () => st.setCat(chips[i].id),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(2, 16, 2, 12),
                    child: Text('${list.length} ${list.length == 1 ? 'item' : 'items'}',
                        style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ),
                ]),
              ),
            ),
            if (list.isEmpty)
              const SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No items found / பொருட்கள் இல்லை'))))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 12,
                    mainAxisExtent: kProductCardHeight,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => PopIn(delayMs: 80 * (i % 4), child: ProductCard(list[i], key: ValueKey(list[i].id))),
                    childCount: list.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      Positioned(
        left: 16,
        right: 16,
        bottom: 8,
        child: AnimatedSlide(
          offset: st.cartCount > 0 ? Offset.zero : const Offset(0, 2),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: st.cartCount > 0 ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(ignoring: st.cartCount == 0, child: _CartBar(st)),
          ),
        ),
      ),
    ]);
  }
}

class _CartBar extends StatelessWidget {
  final AppState st;
  const _CartBar(this.st);

  @override
  Widget build(BuildContext context) {
    final names = st.cart.values.map((l) => '${l.product.nameEn} ${l.pack.labelEn}').join(', ');
    return Pressable(
      onTap: () => st.setTab(AppState.tabCart),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 16, 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.greenDark, AppColors.green]),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: AppColors.greenDark.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          PopBadge(st.cartCount, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${st.cartCount} ${st.cartCount == 1 ? 'Item' : 'Items'} in Cart',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5)),
              Text(names, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
            ]),
          ),
          const SizedBox(width: 8),
          const Text('View Cart', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
        ]),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final ProductCategory c;
  final bool selected;
  final int count;
  final VoidCallback onTap;
  const _CategoryChip(this.c, {required this.selected, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.green : Colors.white,
            borderRadius: BorderRadius.circular(21),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.green.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]
                : [const BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(c.nameTa.isEmpty ? c.nameEn : '${c.nameEn} / ${c.nameTa}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: selected ? Colors.white : AppColors.ink)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white24 : AppColors.mint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.green)),
            ),
          ]),
        ),
      );
}
