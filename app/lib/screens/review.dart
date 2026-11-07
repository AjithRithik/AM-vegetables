import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _sending = false;

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(fontSize: 12, color: AppColors.muted))),
          Expanded(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        ]),
      );

  Future<void> _send(AppState st, Shop shop) async {
    if (!shop.deliversTo(st.customer.pincode)) {
      showSnack(context, "Sorry, we don't deliver to ${st.customer.pincode} from ${st.location?.nameEn ?? 'this location'}. Please change your address or location.");
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    setState(() => _sending = true);
    PlacedOrder? placed;
    try {
      placed = await st.placeOrder(); // null = offline, still let the customer send on WhatsApp
    } on OrderRejected catch (e) {
      st.refreshCatalogue(); // prices / stock may have changed
      if (!mounted) return;
      setState(() => _sending = false);
      showSnack(context, e.message);
      return;
    }
    final ok = await st.sendWhatsApp(st.fullMessage(orderNo: placed?.orderNo));
    if (!mounted) return;
    setState(() => _sending = false);
    if (!ok && placed == null) {
      showSnack(context, shop.whatsapp.isEmpty ? 'This shop has no WhatsApp number yet. Please call instead.' : 'Could not open WhatsApp.');
      return;
    }
    st.clearCart();
    st.setTab(0);
    nav.popUntil((r) => r.isFirst);
    final text = placed == null
        ? 'Order sent on WhatsApp. We will confirm shortly.'
        : ok
            ? 'Order #${placed.orderNo} placed. We will confirm on WhatsApp.'
            : 'Order #${placed.orderNo} placed. The shop has it, but WhatsApp could not open.';
    messenger.showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

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
                trailing: Pill('${l.label} · ${money(l.total)}', bg: AppColors.mint),
              ),
            const Divider(),
            Row(children: [
              const Expanded(child: BiText('Estimated total', 'மொத்த தொகை', size: 14)),
              Text(money(st.cartTotal), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.green)),
            ]),
            const SizedBox(height: 4),
            const Text('Final price and availability are confirmed by the shop on WhatsApp.', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
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
            if (c.hasLocation) ...[
              const SizedBox(height: 4),
              const Row(children: [
                Icon(Icons.location_on, size: 14, color: AppColors.green),
                SizedBox(width: 4),
                Text('Map pin attached', style: TextStyle(fontSize: 12.5, color: AppColors.green, fontWeight: FontWeight.w700)),
              ]),
            ],
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
            Text('Live WhatsApp Preview → ${shop.nameEn} (${st.location?.nameEn ?? ''}, ${shop.whatsapp})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(height: 8),
            Text(st.fullMessage().replaceAll('*', ''), style: const TextStyle(fontSize: 12.5, height: 1.4)),
          ]),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(58), backgroundColor: AppColors.whatsapp, foregroundColor: Colors.black87),
          onPressed: _sending ? null : () => _send(st, shop),
          icon: _sending
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black87))
              : const Icon(Icons.send),
          label: Text(_sending ? 'Sending…' : 'Send Order on WhatsApp', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
        const SizedBox(height: 8),
        Wrap(alignment: WrapAlignment.center, spacing: 12, children: [
          for (final b in shop.footerBadges) Pill(b[0], bg: Colors.white),
        ]),
      ]),
    );
  }
}
