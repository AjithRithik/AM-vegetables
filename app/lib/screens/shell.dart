import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import '../widgets.dart';
import 'catalogue.dart';
import 'contact.dart';
import 'home.dart';
import 'my_list.dart';

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return Scaffold(
      appBar: const ShopHeader(),
      extendBody: false,
      body: _FadeStack(index: st.tab, children: const [
        HomeScreen(),
        CatalogueScreen(),
        MyListScreen(),
        ContactScreen(),
      ]),
      bottomNavigationBar: _FloatingNav(index: st.tab, cartCount: st.cartCount, onTap: st.setTab),
    );
  }
}

/// IndexedStack (keeps each tab's state) with a fade/slide when the tab changes.
class _FadeStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  const _FadeStack({required this.index, required this.children});

  @override
  State<_FadeStack> createState() => _FadeStackState();
}

class _FadeStackState extends State<_FadeStack> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320))..value = 1;

  @override
  void didUpdateWidget(covariant _FadeStack old) {
    super.didUpdateWidget(old);
    if (old.index != widget.index) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return AnimatedBuilder(
      animation: curved,
      builder: (_, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(offset: Offset(0, (1 - curved.value) * 18), child: child),
      ),
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  final int index, cartCount;
  final ValueChanged<int> onTap;
  const _FloatingNav({required this.index, required this.cartCount, required this.onTap});

  static const _items = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.grid_view_outlined, Icons.grid_view_rounded, 'Catalogue'),
    (Icons.shopping_cart_outlined, Icons.shopping_cart, 'Cart'),
    (Icons.storefront_outlined, Icons.storefront, 'Contact'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: AppColors.greenDark.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          for (var i = 0; i < _items.length; i++)
            Expanded(
              flex: i == index ? 3 : 2,
              child: _NavItem(
                icon: i == index ? _items[i].$2 : _items[i].$1,
                label: _items[i].$3,
                selected: i == index,
                badge: i == 2 ? cartCount : 0,
                iconKey: i == 2 ? FlyToCart.cartKey : null,
                onTap: () => onTap(i),
              ),
            ),
        ]),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;
  final GlobalKey? iconKey;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.badge, required this.onTap, this.iconKey});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: 48,
        decoration: BoxDecoration(
          gradient: selected ? const LinearGradient(colors: [AppColors.green, Color(0xFF14864C)]) : null,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(key: iconKey, clipBehavior: Clip.none, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(icon, key: ValueKey(icon), size: 24, color: selected ? Colors.white : AppColors.muted),
            ),
            if (badge > 0) Positioned(right: -8, top: -8, child: PopBadge(badge, size: 16)),
          ]),
          Flexible(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ]),
      ),
    );
  }
}
