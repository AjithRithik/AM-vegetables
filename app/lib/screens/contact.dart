import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import '../widgets.dart';
import 'server_dialog.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final s = st.shop!;
    return ListView(padding: const EdgeInsets.all(16), children: [
      SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => showServerDialog(context),
            child: BiText(s.nameEn, s.nameTa, size: 20),
          ),
          const SizedBox(height: 12),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.schedule, color: AppColors.green), title: Text(s.hours), subtitle: Text(s.isOpen ? s.openEn : 'Closed')),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.payments_outlined, color: AppColors.green), title: Text(s.paymentNote)),
          const SizedBox(height: 8),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: AppColors.green),
            onPressed: st.call,
            icon: const Icon(Icons.call),
            label: Text('Call ${s.phone}'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: AppColors.whatsapp, foregroundColor: Colors.black87),
            onPressed: () => st.sendWhatsApp('வணக்கம் ${s.nameEn}, I have a question.'),
            icon: const Icon(Icons.chat),
            label: const Text('Chat on WhatsApp'),
          ),
        ]),
      ),
      if (s.pincodes.isNotEmpty)
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const BiText('Delivery Areas', 'டெலிவரி பகுதிகள்', size: 15),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in s.pincodes.where((p) => p.active)) Pill('${p.pincode} · ${p.area}'),
            ]),
          ]),
        ),
    ]);
  }
}
