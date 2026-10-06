import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import '../widgets.dart';
import 'location_picker.dart';
import 'review.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController();
  late final _phone = TextEditingController();
  late final _alt = TextEditingController();
  late final _email = TextEditingController();
  late final _address = TextEditingController();
  late final _pin = TextEditingController();
  late final _landmark = TextEditingController();
  late final _notes = TextEditingController();
  bool _bannerOpen = true;
  double? _lat, _lng;

  @override
  void initState() {
    super.initState();
    final c = context.read<AppState>().customer;
    _name.text = c.name;
    _phone.text = c.phone;
    _alt.text = c.altPhone;
    _email.text = c.email;
    _address.text = c.address;
    _pin.text = c.pincode;
    _landmark.text = c.landmark;
    _notes.text = c.notes;
    _lat = c.lat;
    _lng = c.lng;
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _alt, _email, _address, _pin, _landmark, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required / தேவை' : null;

  Widget _label(String en, {bool required = false, String? hint}) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Row(children: [
          Expanded(child: Text('$en${required ? ' *' : ''}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          if (hint != null) Text(hint, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        ]),
      );

  void _next(AppState st) {
    if (!_form.currentState!.validate()) return;
    st.customer
      ..name = _name.text.trim()
      ..phone = _phone.text.trim()
      ..altPhone = _alt.text.trim()
      ..email = _email.text.trim()
      ..address = _address.text.trim()
      ..pincode = _pin.text.trim()
      ..landmark = _landmark.text.trim()
      ..notes = _notes.text.trim()
      ..lat = _lat
      ..lng = _lng;
    st.saveCustomer();
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewScreen()));
  }

  Future<void> _pickLocation() async {
    final r = await Navigator.push<LatLngResult>(
        context, MaterialPageRoute(builder: (_) => LocationPickerScreen(initialLat: _lat, initialLng: _lng)));
    if (r != null) setState(() { _lat = r.lat; _lng = r.lng; });
  }

  Widget _locationButton() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Map Location / வரைபட இருப்பிடம்', hint: 'Optional'),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          onPressed: _pickLocation,
          icon: Icon(_lat != null ? Icons.check_circle : Icons.my_location, color: AppColors.green),
          label: Text(_lat != null ? 'Location selected — tap to change' : 'Pick delivery location on map'),
        ),
        if (_lat != null)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: () => setState(() { _lat = null; _lng = null; }), child: const Text('Remove pin')),
          ),
      ]);

  Widget _page(Widget body) => Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.bg,
          title: const Text('Delivery Details', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: body,
      );

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    if (st.cart.isEmpty) {
      return _page(Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.chat_outlined, size: 64, color: AppColors.muted),
          const SizedBox(height: 12),
          const BiText('Add items first', 'முதலில் பொருட்களை சேர்க்கவும்', align: CrossAxisAlignment.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: () { Navigator.pop(context); st.openCatalogue(); }, child: const Text('Browse Catalogue')),
        ]),
      ));
    }
    final pin = _pin.text.trim();
    final match = st.shop!.pincodes.where((p) => p.pincode == pin && p.active);
    final pinNum = int.tryParse(pin) ?? 0;
    final inTamilNadu = pin.length == 6 && pinNum >= 600001 && pinNum <= 643999;
    final areaLabel = match.isNotEmpty ? match.first.area : (inTamilNadu ? 'Tamil Nadu' : null);
    return _page(Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        const StepHeader(2),
        if (_bannerOpen && st.customerLoadedFromSaved)
          SectionCard(
            color: AppColors.mint,
            child: Row(children: [
              const Icon(Icons.history, color: AppColors.green),
              const SizedBox(width: 10),
              const Expanded(
                  child: Text('Previous details auto-filled. Tap any field to modify.\nமுந்தைய விவரங்கள் நிரப்பப்பட்டுள்ளன',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
              IconButton(onPressed: () => setState(() => _bannerOpen = false), icon: const Icon(Icons.close, size: 18)),
            ]),
          ),
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const BiText('Customer Contact Information', 'வாடிக்கையாளர் விவரங்கள்', size: 16),
            _label('Full Name / முழு பெயர்', required: true),
            TextFormField(controller: _name, validator: _req, textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.person_outline))),
            _label('WhatsApp No. / வாட்ஸ்அப் எண்', required: true),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 10 ? 'Enter a valid number' : null,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.phone_android), hintText: '+91 98401 23456'),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Bill & produce availability will be shared to this number.', style: TextStyle(fontSize: 11, color: AppColors.muted)),
            ),
            _label('Alternate Phone / மாற்று எண்', hint: 'Optional'),
            TextFormField(controller: _alt, keyboardType: TextInputType.phone,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.call_outlined))),
            _label('Email / மின்னஞ்சல்', hint: 'Optional'),
            TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.mail_outline))),
          ]),
        ),
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const BiText('Delivery Address', 'டெலிவரி இருப்பிடம்', size: 16),
            _label('Door No, Flat, Street / கதவு எண், தெரு', required: true),
            TextFormField(controller: _address, validator: _req, maxLines: 2,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.place_outlined))),
            _label('Pincode / அஞ்சல் குறியீடு', required: true),
            TextFormField(
              controller: _pin,
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (_) => setState(() {}),
              validator: (v) => (v ?? '').length != 6 ? '6 digit pincode' : null,
              decoration: InputDecoration(
                counterText: '',
                prefixIcon: const Icon(Icons.local_shipping_outlined),
                suffixIcon: areaLabel != null
                    ? Padding(padding: const EdgeInsets.all(10), child: Pill('✓ $areaLabel'))
                    : null,
              ),
            ),
            if (pin.length == 6 && areaLabel == null)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('We may not deliver to this pincode — we will confirm on WhatsApp.',
                    style: TextStyle(fontSize: 11, color: Colors.deepOrange)),
              ),
            _label('Landmark / அடையாளம்', required: true),
            TextFormField(controller: _landmark, validator: _req,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.explore_outlined))),
            _locationButton(),
            _label('Delivery Notes / Time', hint: 'Optional'),
            Wrap(spacing: 8, children: [
              for (final s in ['Morning', 'Noon', 'Evening'])
                ActionChip(label: Text(s), onPressed: () => setState(() => _notes.text = '${_notes.text} $s delivery preferred.'.trim())),
            ]),
            const SizedBox(height: 8),
            TextFormField(controller: _notes, maxLines: 3,
                decoration: const InputDecoration(hintText: 'Please call 10 minutes before arriving.')),
          ]),
        ),
        SectionCard(
          child: Column(children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: st.rememberDetails,
              activeThumbColor: AppColors.green,
              onChanged: (v) => setState(() => st.rememberDetails = v),
              title: const Text('Save details for next time', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Stored only on this device', style: TextStyle(fontSize: 11)),
            ),
          ]),
        ),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Cart'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: AppColors.green),
              onPressed: () => _next(st),
              icon: const Icon(Icons.arrow_forward),
              iconAlignment: IconAlignment.end,
              label: const Text('Review Enquiry', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ]),
    ));
  }
}
