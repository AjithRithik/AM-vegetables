import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'product_detail.dart';

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
    );

/// Photo shape used by [ProductCard] (width / height).
const double _kImageAspect = 1.05;

/// Height a [ProductCard] needs when its grid cell is [cellWidth] wide — use as the
/// grid's mainAxisExtent. The photo scales with the width and the text with the
/// phone's font-size setting, so a fixed height overflows on wider phones or larger fonts.
double productCardHeight(BuildContext context, double cellWidth) {
  const padding = 8.0 * 2 + 1.6 * 2; // card padding + border
  const nameGap = 10.0, actionRow = 44.0, minGap = 8.0;
  final scaler = MediaQuery.textScalerOf(context);
  final image = (cellWidth - padding) / _kImageAspect;
  final text = scaler.scale(15) * 1.2 + scaler.scale(12.5) * 1.3; // English + Tamil name
  return (padding + image + nameGap + text + minGap + actionRow).ceilToDouble() + 2;
}

const _grayscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0.2126, 0.7152, 0.0722, 0, 0,
  0, 0, 0, 1, 0,
]);

class ProductCard extends StatefulWidget {
  final Product p;
  const ProductCard(this.p, {super.key});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late int _pack = widget.p.defaultPack;
  final _imgKey = GlobalKey();
  bool _bump = false;

  void _add(AppState st) {
    final p = widget.p;
    FlyToCart.run(context, _imgKey, p.image);
    st.add(p, pack: _pack);
    setState(() => _bump = true);
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) setState(() => _bump = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final p = widget.p;
    final line = st.cart[p.id];
    final pack = line?.packIndex ?? _pack;
    final inCart = line != null;
    final out = !p.inStock;

    Widget image = ProductImage(p.image, heroTag: 'img-${p.id}', radius: BorderRadius.zero);
    if (out) image = ColorFiltered(colorFilter: _grayscale, child: image);

    return AnimatedScale(
      scale: _bump ? 1.045 : 1,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: Pressable(
        tilt: true,
        onTap: () => Navigator.push(context, fadeRoute(ProductDetailScreen(p))),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: inCart ? AppColors.green.withValues(alpha: 0.6) : Colors.transparent, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: (inCart ? AppColors.green : Colors.black).withValues(alpha: inCart ? 0.22 : 0.09),
                blurRadius: inCart ? 24 : 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ---- image ----
            ClipRRect(
              key: _imgKey,
              borderRadius: BorderRadius.circular(22),
              child: AspectRatio(
                aspectRatio: _kImageAspect,
                child: Stack(fit: StackFit.expand, children: [
                  image,
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 58,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x80000000)],
                        ),
                      ),
                    ),
                  ),
                  if (!out) const ShineSweep(),
                  if (p.origin.isNotEmpty)
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 8,
                      child: Row(children: [
                        const Icon(Icons.location_on, size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(p.origin,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    ),
                  if (p.badge.isNotEmpty && !out)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.white, Color(0xFFEFFBF2)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))],
                        ),
                        child: Text(p.badge,
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.greenDark)),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: AnimatedScale(
                      scale: inCart ? 1 : 0,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.elasticOut,
                      child: const CircleAvatar(
                          radius: 13, backgroundColor: AppColors.green, child: Icon(Icons.check_rounded, size: 17, color: Colors.white)),
                    ),
                  ),
                  if (out)
                    Container(
                      color: Colors.white.withValues(alpha: 0.5),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(20)),
                        child: const Text('Sold out',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                      ),
                    ),
                ]),
              ),
            ),
            // ---- name ----
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Opacity(
                opacity: out ? 0.55 : 1,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.nameEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, height: 1.2)),
                  Text(p.nameTa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.green, fontWeight: FontWeight.w600, height: 1.3)),
                ]),
              ),
            ),
            const Spacer(),
            // ---- action row ----
            SizedBox(
              height: 44,
              child: out
                  ? Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: const Color(0xFFEFF2EE), borderRadius: BorderRadius.circular(22)),
                      child: const Text('Currently unavailable',
                          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700, fontSize: 12)),
                    )
                  : LayoutBuilder(builder: (context, box) {
                      final w = box.maxWidth;
                      return Stack(children: [
                        // pack picker fades out as the green capsule grows over it
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedOpacity(
                            opacity: inCart ? 0 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: IgnorePointer(
                              ignoring: inCart,
                              child: SizedBox(
                                width: w - 52,
                                child: _PackPill(
                                  label: p.packs[pack].labelEn,
                                  onTap: () => showPackSheet(context, p, pack, (i) => setState(() => _pack = i)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // the + button morphs into the quantity capsule
                        Align(
                          alignment: Alignment.centerRight,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutCubic,
                            width: inCart ? w : 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: const LinearGradient(
                                colors: [AppColors.greenDark, AppColors.green],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              boxShadow: [BoxShadow(color: AppColors.green.withValues(alpha: 0.38), blurRadius: 12, offset: const Offset(0, 5))],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                transitionBuilder: (c, a) => FadeTransition(opacity: a, child: ScaleTransition(scale: a, child: c)),
                                child: inCart
                                    ? OverflowBox(
                                        key: const ValueKey('qty'),
                                        minWidth: w,
                                        maxWidth: w,
                                        child: _QtyContent(
                                          line: line,
                                          onChanged: (v) => st.setCount(p.id, v),
                                          onPickPack: () => showPackSheet(context, p, line.packIndex, (i) => st.setPack(p.id, i)),
                                        ),
                                      )
                                    : InkWell(
                                        key: const ValueKey('plus'),
                                        onTap: () => _add(st),
                                        child: const Center(child: Icon(Icons.add_rounded, color: Colors.white, size: 26)),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ]);
                    }),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PackPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PackPill({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.only(left: 12, right: 6),
          decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(22)),
          child: Row(children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.muted, size: 20),
          ]),
        ),
      );
}

/// Contents of the green capsule once in cart: - [count x pack v] +
class _QtyContent extends StatelessWidget {
  final CartLine line;
  final ValueChanged<int> onChanged;
  final VoidCallback onPickPack;
  const _QtyContent({required this.line, required this.onChanged, required this.onPickPack});

  Widget _btn(IconData i, VoidCallback f) => InkWell(
        onTap: f,
        customBorder: const CircleBorder(),
        child: SizedBox(width: 40, height: 44, child: Icon(i, color: Colors.white, size: 20)),
      );

  @override
  Widget build(BuildContext context) => Row(children: [
        _btn(line.count == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded, () => onChanged(line.count - 1)),
        Expanded(
          child: InkWell(
            onTap: onPickPack,
            child: SizedBox(
              height: 44,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (c, a) => ScaleTransition(scale: a, child: FadeTransition(opacity: a, child: c)),
                    child: Text(line.label,
                        key: ValueKey(line.label),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70, size: 16),
                ]),
              ),
            ),
          ),
        ),
        _btn(Icons.add_rounded, () => onChanged(line.count + 1)),
      ]);
}

/// Bottom sheet listing a product's pack sizes.
void showPackSheet(BuildContext context, Product product, int selected, ValueChanged<int> onSelected) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4))),
          ),
          const SizedBox(height: 14),
          BiText(product.nameEn, 'Select quantity / ${product.nameTa}', size: 17),
          const SizedBox(height: 8),
          for (var i = 0; i < product.packs.length; i++)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: i == selected ? AppColors.mint : null,
              onTap: () {
                onSelected(i);
                Navigator.pop(ctx);
              },
              title: Row(children: [
                Text(product.packs[i].labelEn, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (product.packs[i].popular) ...[const SizedBox(width: 8), const Pill('Popular', bg: AppColors.amber, fg: Colors.black87)],
              ]),
              subtitle: Text([product.packs[i].labelTa, product.packs[i].note].where((s) => s.isNotEmpty).join(' • ')),
              trailing: Icon(i == selected ? Icons.check_circle : Icons.circle_outlined,
                  color: i == selected ? AppColors.green : AppColors.muted),
            ),
        ]),
      ),
    ),
  );
}

/// Compact card for the horizontal "Fresh Picks" row on Home.
class FeaturedCard extends StatelessWidget {
  final Product p;
  const FeaturedCard(this.p, {super.key});

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: () => Navigator.push(context, fadeRoute(ProductDetailScreen(p))),
        child: Container(
          width: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Stack(fit: StackFit.expand, children: [
                ProductImage(p.image,
                    heroTag: 'feat-${p.id}',
                    radius: const BorderRadius.vertical(top: Radius.circular(20))),
                if (p.badge.isNotEmpty) Positioned(left: 8, top: 8, child: Pill(p.badge, bg: Colors.white)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.nameEn,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                Text(p.nameTa,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
              ]),
            ),
          ]),
        ),
      );
}
