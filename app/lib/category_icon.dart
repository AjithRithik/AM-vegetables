import 'package:flutter/material.dart';

/// The CMS selects a named icon; the app displays its bundled transparent glyph.
class CategoryIcon extends StatelessWidget {
  final String icon;
  final Color color;
  const CategoryIcon({super.key, required this.icon, required this.color});

  static const _assets = {
    'vegetables': 'assets/category-icons/small/vegetables.png',
    'leafy-greens': 'assets/category-icons/small/leafy-greens.png',
    'roots-tubers': 'assets/category-icons/small/roots-tubers.png',
    'herbs': 'assets/category-icons/small/herbs.png',
    'leaves': 'assets/category-icons/small/leaves.png',
    'fresh-essentials': 'assets/category-icons/small/fresh-essentials.png',
    'fruits': 'assets/category-icons/small/fruits.png',
  };

  @override
  Widget build(BuildContext context) {
    final asset = _assets[icon];
    final fallback = Icon(Icons.grid_view_rounded, size: 28, color: color);
    return ExcludeSemantics(
      child: asset == null
          ? fallback
          : Image.asset(
              asset,
              width: 34,
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}
