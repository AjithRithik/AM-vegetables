import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'details.dart';
import 'product_card.dart';

class MyListScreen extends StatelessWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final shop = st.shop!;
    final lines = st.cart.values.toList();
    if (lines.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.shopping_basket_outlined, size: 64, color: AppColors.muted),
          const SizedBox(height: 12),
          const BiText('Your list is empty', 'பட்டியல் காலியாக உள்ளது', align: CrossAxisAlignment.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => st.openCatalogue(), child: const Text('Browse Catalogue')),
        ]),
      );
    }
    final paired = <Product>{};
    for (final l in lines) {
      for (final id in l.product.pairedWith) {
        final p = st.productById(id);
        if (p != null && !st.inCart(id) && p.inStock) paired.add(p);
      }
    }
    return Column(children: [
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          const StepHeader(1),
          Row(children: [
            const Expanded(child: BiText('My Cart', 'என் கூடை', size: 18)),
            TextButton.icon(
                onPressed: () => st.clearCart(),
                icon: const Icon(Icons.delete_sweep, size: 18, color: Colors.red),
                label: const Text('Clear', style: TextStyle(color: Colors.red))),
          ]),
          SectionCard(
            color: AppColors.mint,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.hourglass_bottom, color: AppColors.green),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                BiText(shop.npTitleEn, shop.npTitleTa, size: 14, color: AppColors.greenDark),
                const SizedBox(height: 4),
                Text(shop.npBodyEn, style: const TextStyle(fontSize: 12)),
              ])),
            ]),
          ),
          for (final l in lines)
            Dismissible(
              key: ValueKey(l.product.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => st.remove(l.product.id),
              background: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.only(right: 24),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: _LineCard(l),
            ),
          if (paired.isNotEmpty) ...[
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: BiText("Don't forget!", 'மறந்துவிடாதீர்கள்!', size: 17)),
            Row(children: [
              for (final p in paired.take(2))
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        ProductImage(p.image, height: 80),
                        const SizedBox(height: 6),
                        Text(p.nameEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(p.nameTa, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                        TextButton.icon(onPressed: () => st.add(p), icon: const Icon(Icons.add, size: 16), label: const Text('Add')),
                      ]),
                    ),
                  ),
                ),
            ]),
          ],
          if (shop.howItWorks.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const BiText('How it works?', 'அடுத்த கட்டம் என்ன?', size: 15),
                const SizedBox(height: 8),
                for (var i = 0; i < shop.howItWorks.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('${i + 1}. ${shop.howItWorks[i][0]}  ${shop.howItWorks[i][1]}', style: const TextStyle(fontSize: 12.5)),
                  ),
              ]),
            ),
          ],
        ]),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: AppColors.green),
            onPressed: () => Navigator.push(context, fadeRoute(const DetailsScreen())),
            icon: const Icon(Icons.arrow_forward),
            iconAlignment: IconAlignment.end,
            label: const Text('Continue • Delivery Details', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    ]);
  }
}

class _LineCard extends StatelessWidget {
  final CartLine l;
  const _LineCard(this.l);

  @override
  Widget build(BuildContext context) {
    final st = context.read<AppState>();
    final p = l.product;
    return SectionCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 72, height: 72, child: ProductImage(p.image, height: 72)),
          const SizedBox(width: 12),
          Expanded(child: BiText(p.nameEn, p.nameTa, size: 15)),
          IconButton(onPressed: () => st.remove(p.id), icon: const Icon(Icons.delete_outline, color: AppColors.muted)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              for (var i = 0; i < p.packs.length; i++)
                OptionChip(p.packs[i].labelEn, selected: l.packIndex == i, onTap: () => st.setPack(p.id, i)),
            ]),
          ),
          Stepper2(value: l.count, onChanged: (v) => st.setCount(p.id, v)),
        ]),
        if (p.allowNote) ...[
          const SizedBox(height: 10),
          TextFormField(
            initialValue: l.note,
            onChanged: (v) => st.setNote(p.id, v),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
                isDense: true,
                hintText: p.noteHint.isEmpty ? 'Preference (optional) / விருப்பம்' : 'Preference: ${p.noteHint}',
                prefixIcon: const Icon(Icons.edit_note, size: 20)),
          ),
        ],
      ]),
    );
  }
}
