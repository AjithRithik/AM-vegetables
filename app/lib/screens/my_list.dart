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
          if (lines.length > 3)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                const Icon(Icons.verified_user, size: 16, color: AppColors.green),
                const SizedBox(width: 8),
                Expanded(child: Text('${shop.npTitleEn} · pay on receipt', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.greenDark))),
              ]),
            )
          else
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
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.only(right: 24),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(color: Colors.red.shade400, borderRadius: BorderRadius.circular(18)),
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
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(children: [
                const Expanded(child: BiText('Estimated total', 'மொத்த தொகை', size: 14)),
                Text(money(st.cartTotal), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.green)),
              ]),
            ),
            FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: AppColors.green),
            onPressed: () => Navigator.push(context, fadeRoute(const DetailsScreen())),
            icon: const Icon(Icons.arrow_forward),
            iconAlignment: IconAlignment.end,
            label: const Text('Continue • Delivery Details', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          ]),
        ),
      ),
    ]);
  }
}

/// One cart item as a short row. Tap the size pill to change the size or add a note, so a long
/// cart stays easy to scan and scroll.
class _LineCard extends StatefulWidget {
  final CartLine l;
  const _LineCard(this.l);

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final st = context.read<AppState>();
    final l = widget.l;
    final p = l.product;
    final canEdit = p.packs.length > 1 || p.allowNote;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(width: 56, height: 56, child: ProductImage(p.image, height: 56)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.nameEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
              Text(p.nameTa, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              const SizedBox(height: 5),
              InkWell(
                onTap: canEdit ? () => setState(() => _open = !_open) : null,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(12)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Flexible(
                      child: Text('${l.pack.labelEn} · ${l.pack.priceText}',
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.greenDark)),
                    ),
                    if (canEdit) Icon(_open ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16, color: AppColors.green),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Stepper2(value: l.count, onChanged: (v) => st.setCount(p.id, v)),
            const SizedBox(height: 6),
            Text(money(l.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.green)),
          ]),
        ]),
        if (l.note.isNotEmpty && !_open)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Note: ${l.note}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.muted)),
            ),
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: !_open
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (p.packs.length > 1)
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        for (var i = 0; i < p.packs.length; i++)
                          OptionChip('${p.packs[i].labelEn} · ${p.packs[i].priceText}', selected: l.packIndex == i, onTap: () => st.setPack(p.id, i)),
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
                ),
        ),
      ]),
    );
  }
}
