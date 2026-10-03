import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'state.dart';

class AppColors {
  static const green = Color(0xFF0B6B3A);
  static const greenDark = Color(0xFF064D29);
  static const mint = Color(0xFFD8F5DF);
  static const bg = Color(0xFFF3F8F2);
  static const card = Colors.white;
  static const ink = Color(0xFF1B2B22);
  static const muted = Color(0xFF6B7C72);
  static const whatsapp = Color(0xFF25D366);
  static const amber = Color(0xFFF5A623);
}

/// English line with a smaller Tamil line below.
class BiText extends StatelessWidget {
  final String en, ta;
  final double size;
  final Color? color;
  final CrossAxisAlignment align;
  final int maxLines;
  const BiText(this.en, this.ta,
      {super.key,
      this.size = 15,
      this.color,
      this.align = CrossAxisAlignment.start,
      this.maxLines = 2});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(en,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: size,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.ink,
                height: 1.2)),
        if (ta.isNotEmpty)
          Text(ta,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: size - 2,
                  color: (color ?? AppColors.ink).withValues(alpha: 0.75),
                  height: 1.3)),
      ],
    );
  }
}

class ProductImage extends StatelessWidget {
  final String path;
  final double? height;
  final BorderRadius radius;
  final String? heroTag;

  /// Max pixel width requested from the image host (Cloudinary photos only).
  final int width;
  const ProductImage(this.path,
      {super.key,
      this.height,
      this.width = 500,
      this.heroTag,
      this.radius = const BorderRadius.all(Radius.circular(16))});

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.resolveImage(path, width: width);
    final placeholder = Container(
      height: height,
      color: AppColors.mint,
      alignment: Alignment.center,
      child: const Opacity(opacity: 0.55, child: AppLogo(size: 56)),
    );
    final img = ClipRRect(
      borderRadius: radius,
      child: url.isEmpty
          ? placeholder
          : CachedNetworkImage(
              imageUrl: url,
              height: height,
              width: double.infinity,
              fit: BoxFit.contain,
              placeholder: (_, __) => placeholder,
              fadeInDuration: const Duration(milliseconds: 300),
              errorWidget: (_, __, ___) => placeholder,
            ),
    );
    return heroTag == null ? img : Hero(tag: heroTag!, child: img);
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color bg, fg;
  final IconData? icon;
  const Pill(this.text,
      {super.key,
      this.bg = AppColors.mint,
      this.fg = AppColors.green,
      this.icon});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4)
          ],
          Flexible(
              child: Text(text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700, color: fg))),
        ]),
      );
}

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color color;
  const SectionCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.color = AppColors.card});

  @override
  Widget build(BuildContext context) => FadeSlide(
        dy: 16,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: padding,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4))
            ],
          ),
          child: child,
        ),
      );
}

/// Chip-style selectable option (pack weights etc).
class OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const OptionChip(this.label,
      {super.key, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.green : AppColors.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? AppColors.green : const Color(0xFFDCE6DD)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.check, size: 13, color: Colors.white))
                  : const SizedBox.shrink(),
            ),
            Text(label,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.ink)),
          ]),
        ),
      );
}

class Stepper2 extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const Stepper2({super.key, required this.value, required this.onChanged});

  Widget _btn(IconData i, VoidCallback f) => InkWell(
        onTap: f,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
              color: AppColors.mint, shape: BoxShape.circle),
          child: Icon(i, size: 18, color: AppColors.green),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        _btn(Icons.remove, () => onChanged(value - 1)),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('$value',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16))),
        _btn(Icons.add, () => onChanged(value + 1)),
      ]);
}

/// Fades + slides its child in after [delay]. Use index * 60ms for staggering.
class FadeSlide extends StatelessWidget {
  final Widget child;
  final int delayMs;
  final double dy;
  const FadeSlide(
      {super.key, required this.child, this.delayMs = 0, this.dy = 24});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 450 + delayMs),
        curve:
            Interval(delayMs / (450 + delayMs), 1, curve: Curves.easeOutCubic),
        builder: (_, v, c) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, (1 - v) * dy), child: c),
        ),
        child: child,
      );
}

/// Scales down slightly while pressed.
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  /// Adds a subtle 3D tilt while pressed (used on product cards).
  final bool tilt;
  const Pressable(
      {super.key, required this.child, this.onTap, this.tilt = false});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _down ? 1.0 : 0.0),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          child: widget.child,
          builder: (_, v, child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(widget.tilt ? -0.07 * v : 0)
              ..scaleByDouble(1 - 0.04 * v, 1 - 0.04 * v, 1, 1),
            child: child,
          ),
        ),
      );
}

/// Springy entrance: scales up from 88% with a small overshoot while fading in.
class PopIn extends StatelessWidget {
  final Widget child;
  final int delayMs;
  const PopIn({super.key, required this.child, this.delayMs = 0});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 600 + delayMs),
        curve:
            Interval(delayMs / (600 + delayMs), 1, curve: Curves.easeOutBack),
        builder: (_, v, c) => Opacity(
          opacity: v.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 30),
            child: Transform.scale(scale: 0.88 + 0.12 * v, child: c),
          ),
        ),
        child: child,
      );
}

/// Flies a thumbnail of [imagePath] from [from] to the cart tab icon.
class FlyToCart {
  static final GlobalKey cartKey = GlobalKey();

  static void run(BuildContext context, GlobalKey from, String imagePath) {
    final fromBox = from.currentContext?.findRenderObject() as RenderBox?;
    final toBox = cartKey.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.maybeOf(context);
    if (fromBox == null ||
        toBox == null ||
        overlay == null ||
        !fromBox.attached ||
        !toBox.attached) {
      return;
    }
    final start = fromBox.localToGlobal(Offset.zero) & fromBox.size;
    final end = toBox.localToGlobal(Offset.zero) & toBox.size;
    late OverlayEntry entry;
    entry = OverlayEntry(
        builder: (_) => _Flyer(
            start: start,
            end: end,
            image: imagePath,
            onDone: () => entry.remove()));
    overlay.insert(entry);
  }
}

class _Flyer extends StatefulWidget {
  final Rect start, end;
  final String image;
  final VoidCallback onDone;
  const _Flyer(
      {required this.start,
      required this.end,
      required this.image,
      required this.onDone});

  @override
  State<_Flyer> createState() => _FlyerState();
}

class _FlyerState extends State<_Flyer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 750))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final move = CurvedAnimation(parent: _c, curve: Curves.easeInOutCubic);
    return IgnorePointer(
      child: Stack(children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final t = move.value;
            final s = widget.start, e = widget.end;
            final size = (s.shortestSide * 0.8) * (1 - t) + 26 * t;
            final cx = s.center.dx + (e.center.dx - s.center.dx) * t;
            // arc: rise above the straight line, peaking mid-flight
            final cy = s.center.dy +
                (e.center.dy - s.center.dy) * t -
                90 * (1 - (2 * t - 1) * (2 * t - 1));
            return Positioned(
              left: cx - size / 2,
              top: cy - size / 2,
              width: size,
              height: size,
              child: Opacity(
                opacity: 1 - 0.35 * t,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55000000), blurRadius: 12)
                    ],
                  ),
                  child: ClipOval(
                      child: ProductImage(widget.image,
                          height: size, radius: BorderRadius.zero)),
                ),
              ),
            );
          },
        ),
      ]),
    );
  }
}

class _SlideGradient extends GradientTransform {
  final double percent;
  const _SlideGradient(this.percent);
  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * percent, 0, 0);
}

/// A soft diagonal light sweep that plays once after [delayMs] (a "shine" on entry).
class ShineSweep extends StatefulWidget {
  final int delayMs;
  const ShineSweep({super.key, this.delayMs = 0});

  @override
  State<ShineSweep> createState() => _ShineSweepState();
}

class _ShineSweepState extends State<ShineSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 500 + widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Color(0x00FFFFFF),
                  Color(0x66FFFFFF),
                  Color(0x00FFFFFF)
                ],
                stops: const [0.35, 0.5, 0.65],
                transform: _SlideGradient(
                    -1.2 + 2.4 * Curves.easeInOut.transform(_c.value)),
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
}

/// Pops (scales) whenever [value] changes — used for cart badges.
class PopBadge extends StatelessWidget {
  final int value;
  final double size;
  const PopBadge(this.value, {super.key, this.size = 18});

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.elasticOut,
        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
        child: value == 0
            ? SizedBox(key: const ValueKey('none'), width: size, height: size)
            : Container(
                key: ValueKey(value),
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.amber, shape: BoxShape.circle),
                child: Text('$value',
                    style: TextStyle(
                        fontSize: size * 0.58,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
              ),
      );
}

/// Gradient header with shop name, call and list buttons + status strip.
class ShopHeader extends StatelessWidget implements PreferredSizeWidget {
  const ShopHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(108);

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final shop = st.shop;
    if (shop == null) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            colors: [AppColors.greenDark, AppColors.green],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
              color: Color(0x33064D29), blurRadius: 14, offset: Offset(0, 5))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                padding: const EdgeInsets.all(5),
                child: const AppLogo(size: 34),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                            child: Text(shop.nameEn,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white))),
                        const SizedBox(width: 6),
                        Pill(shop.badge,
                            bg: AppColors.amber, fg: Colors.black87),
                      ]),
                      Text(shop.nameTa,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70)),
                    ]),
              ),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.white24),
                onPressed: st.call,
                icon: const Icon(Icons.call, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 4),
              Stack(clipBehavior: Clip.none, children: [
                IconButton(
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                  onPressed: () => st.setTab(AppState.tabCart),
                  icon: const Icon(Icons.shopping_basket,
                      size: 20, color: AppColors.green),
                ),
                Positioned(right: -2, top: -2, child: PopBadge(st.cartCount)),
              ]),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.circle,
                  size: 9,
                  color: shop.isOpen ? AppColors.whatsapp : Colors.redAccent),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(
                '${shop.isOpen ? shop.openEn : 'Closed'} • ${shop.openTa}   ${shop.paymentNote}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// 3-step progress: Cart / Details / Review.
class StepHeader extends StatelessWidget {
  final int step; // 1..3
  const StepHeader(this.step, {super.key});

  @override
  Widget build(BuildContext context) {
    const labels = ['Cart', 'Details', 'Review'];
    return SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        for (var i = 1; i <= 3; i++) ...[
          Column(children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: i <= step ? AppColors.green : AppColors.bg,
              child: i < step
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text('$i',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: i == step ? Colors.white : AppColors.muted)),
            ),
            const SizedBox(height: 4),
            Text(labels[i - 1],
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == step ? FontWeight.w800 : FontWeight.w500,
                    color: i <= step ? AppColors.green : AppColors.muted)),
          ]),
          if (i < 3)
            Expanded(
                child: Container(
                    height: 3,
                    margin:
                        const EdgeInsets.only(bottom: 16, left: 6, right: 6),
                    color: i < step ? AppColors.green : AppColors.bg)),
        ],
      ]),
    );
  }
}

void showSnack(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2)));
}

/// The AM Vegetables logo. [full] includes the wordmark; otherwise icon only.
class AppLogo extends StatelessWidget {
  final double size;
  final bool full;
  const AppLogo({super.key, this.size = 40, this.full = false});

  @override
  Widget build(BuildContext context) => Image.asset(
        full ? 'assets/logo_full.png' : 'assets/logo_icon.png',
        width: size,
        height: full ? size * 0.84 : size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      );
}
