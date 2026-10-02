import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import '../widgets.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
          Expanded(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final shop = st.shop!;
    final c = st.customer;
    return Scaffold(
      appBar: AppBar(backgroundColor: AppColors.bg, title: const Text('Review & Send', style: TextStyle(fontWeight: FontWeight.w800))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        const StepHeader(3),
        const BiText('Final Enquiry Review', 'இறுதி சரிபார்ப்பு', size: 20),
        const SizedBox(height: 10),
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
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: BiText('Required Products (${st.cartCount})', 'தேவையான காய்கறிகள்', size: 15)),
              TextButton.icon(
                  onPressed: () {
                    Navigator.popUntil(context, (r) => r.isFirst);
                    st.setTab(AppState.tabCart);
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit')),
            ]),
            for (final l in st.cart.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(width: 52, height: 52, child: ProductImage(l.product.image, height: 52, radius: BorderRadius.circular(12))),
                title: Text(l.product.nameEn, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text([l.product.nameTa, if (l.note.isNotEmpty) l.note].join(' • '), style: const TextStyle(fontSize: 12)),
                trailing: Pill(l.label, bg: AppColors.mint),
              ),
          ]),
        ),
        SectionCard(
          child: Column(children: [
            Row(children: [
              const Expanded(child: BiText('Customer Details', 'வாடிக்கையாளர் தகவல்', size: 15)),
              IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.edit, size: 18)),
            ]),
            _row('Full Name', c.name),
            _row('WhatsApp', c.phone),
            if (c.altPhone.isNotEmpty) _row('Alt Phone', c.altPhone),
            if (c.email.isNotEmpty) _row('Email', c.email),
          ]),
        ),
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const BiText('Delivery Location', 'டெலிவரி முகவரி', size: 15),
            const SizedBox(height: 8),
            Text('${c.address} — ${c.pincode}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Landmark: ${c.landmark}', style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
            if (c.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(12)),
                child: Text('"${c.notes}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12.5)),
              ),
            ],
          ]),
        ),
        SectionCard(
          color: const Color(0xFFE5F7D8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Live WhatsApp Preview → ${shop.nameEn} (${shop.phone})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 8),
            Text(st.fullMessage().replaceAll('*', ''), style: const TextStyle(fontSize: 12.5, height: 1.4)),
          ]),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58), backgroundColor: AppColors.whatsapp, foregroundColor: Colors.black87),
          onPressed: () async {
            final messenger = ScaffoldMessenger.of(context);
            final ok = await st.sendWhatsApp(st.fullMessage());
            if (!context.mounted) return;
            if (ok) {
              st.clearCart();
              st.setTab(0);
              Navigator.popUntil(context, (r) => r.isFirst);
              messenger.showSnackBar(const SnackBar(content: Text('Enquiry sent. We will confirm on WhatsApp.'), behavior: SnackBarBehavior.floating));
            } else {
              showSnack(context, 'Could not open WhatsApp.');
            }
          },
          icon: const Icon(Icons.send),
          label: const Text('Send Enquiry on WhatsApp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, spacing: 12, children: [
          for (final b in shop.footerBadges) Pill(b[0], bg: Colors.white),
        ]),
      ]),
    );
  }
}
