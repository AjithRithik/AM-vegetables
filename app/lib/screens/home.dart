import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import '../widgets.dart';
import '../category_icon.dart';
import 'product_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final shop = st.shop!;
    final featured = st.products.where((p) => p.featured && p.inStock).toList();

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: st.load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ---- hero ----
          FadeSlide(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      colors: [Color(0xFFD8F5DF), Color(0xFFA9E6BC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Stack(children: [
                  Positioned(
                      right: -20, bottom: -26, child: Icon(Icons.eco, size: 130, color: AppColors.green.withValues(alpha: 0.14))),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Pill(shop.bannerChip, bg: Colors.white),
                    const SizedBox(height: 12),
                    Text(shop.bannerTitleEn,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.greenDark, height: 1.15)),
                    const SizedBox(height: 2),
                    Text(shop.bannerTitleTa, style: const TextStyle(fontSize: 14, color: AppColors.greenDark)),
                    const SizedBox(height: 10),
                    Text(shop.bannerBody, style: const TextStyle(fontSize: 12.5, color: AppColors.greenDark, height: 1.4)),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.greenDark,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: () => st.openCatalogue(),
                      icon: const Icon(Icons.grid_view_rounded, size: 18),
                      label: const Text('Browse Catalogue', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ]),
                ]),
              ),
            ),
          ),

          // ---- categories ----
          if (st.categories.isNotEmpty) ...[
            const _Heading('Shop by Category', 'வகைகள்'),
            LayoutBuilder(builder: (context, c) {
              final w = (c.maxWidth - 12) / 2;
              return Wrap(spacing: 12, runSpacing: 12, children: [
                for (var i = 0; i < st.categories.length; i++)
                  FadeSlide(
                    delayMs: 70 * i,
                    child: SizedBox(
                      width: w,
                      child: Pressable(
                        onTap: () => st.openCatalogue(st.categories[i].id),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4))],
                          ),
                          child: Row(children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
                              child: Center(
                                child: CategoryIcon(
                                  icon: shop.categoryIcons[st.categories[i].id] ?? '',
                                  color: AppColors.green,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(st.categories[i].nameEn,
                                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                Text(st.categories[i].nameTa,
                                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                                Text('${st.products.where((p) => p.categoryId == st.categories[i].id).length} item(s)',
                                    style: const TextStyle(fontSize: 10.5, color: AppColors.green, fontWeight: FontWeight.w700)),
                              ]),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ]);
            }),
          ],

          // ---- fresh picks ----
          if (featured.isNotEmpty) ...[
            _Heading('Fresh Picks Today', 'இன்றைய சிறப்பு வரத்து', action: 'See all', onAction: () => st.openCatalogue()),
            SizedBox(
              height: 200,
              child: ListView.separated(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => FadeSlide(delayMs: 60 * i, dy: 0, child: FeaturedCard(featured[i])),
              ),
            ),
          ],

          // ---- no payment ----
          const SizedBox(height: 22),
          SectionCard(
            color: AppColors.mint,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.verified_user, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  BiText(shop.npTitleEn, shop.npTitleTa, size: 14, color: AppColors.greenDark),
                  const SizedBox(height: 4),
                  Text(shop.npBodyEn, style: const TextStyle(fontSize: 12, height: 1.35)),
                ]),
              ),
            ]),
          ),

          // ---- how it works ----
          if (shop.howItWorks.isNotEmpty)
            SectionCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const BiText('How it works', 'எப்படி செயல்படுகிறது?', size: 15),
                const SizedBox(height: 10),
                for (var i = 0; i < shop.howItWorks.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(children: [
                      CircleAvatar(
                          radius: 13,
                          backgroundColor: AppColors.green,
                          child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('${shop.howItWorks[i][0]}${shop.howItWorks[i][1].isEmpty ? '' : '\n${shop.howItWorks[i][1]}'}',
                            style: const TextStyle(fontSize: 12.5, height: 1.3)),
                      ),
                    ]),
                  ),
              ]),
            ),

          // ---- footer badges ----
          if (shop.footerBadges.isNotEmpty)
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
              for (final b in shop.footerBadges) Pill(b[0], bg: Colors.white),
            ]),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String en, ta;
  final String? action;
  final VoidCallback? onAction;
  const _Heading(this.en, this.ta, {this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Row(children: [
          Container(width: 4, height: 34, decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Expanded(child: BiText(en, ta, size: 18)),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w800))),
        ]),
      );
}
