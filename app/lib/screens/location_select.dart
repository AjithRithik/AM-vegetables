import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../state.dart';
import '../widgets.dart';
import 'product_card.dart' show fadeRoute;
import 'shell.dart';

/// "Which shop is nearest to you?" Shown on first launch, and again from the header / Contact tab.
/// The catalogue, prices and WhatsApp number all depend on this choice.
class LocationSelectScreen extends StatefulWidget {
  /// true on first launch (replaces the splash); false when opened later to change location.
  final bool initial;
  const LocationSelectScreen({super.key, this.initial = true});

  @override
  State<LocationSelectScreen> createState() => _LocationSelectScreenState();
}

class _LocationSelectScreenState extends State<LocationSelectScreen> {
  String? _busyId;

  Future<void> _pick(ShopLocation l) async {
    final st = context.read<AppState>();
    if (!widget.initial && st.location?.id == l.id) {
      Navigator.pop(context);
      return;
    }
    setState(() => _busyId = l.id);
    final ok = await st.selectLocation(l);
    if (!mounted) return;
    setState(() => _busyId = null);
    if (!ok) {
      showSnack(context, st.error ?? 'Could not load this location.');
      return;
    }
    if (widget.initial) {
      Navigator.of(context).pushReplacement(fadeRoute(const Shell()));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final current = st.location?.id;
    return PopScope(
      canPop: !widget.initial,
      child: Scaffold(
        body: Column(children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 24, 24, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.greenDark, AppColors.green]),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: Column(children: [
              if (!widget.initial)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.white24),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                padding: const EdgeInsets.all(10),
                child: const AppLogo(size: 64),
              ),
              const SizedBox(height: 16),
              const Text('Choose your location',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('உங்கள் இடத்தைத் தேர்வு செய்யவும்', style: TextStyle(color: Colors.white70, fontSize: 15)),
              const SizedBox(height: 10),
              const Text('Products and prices depend on your nearest shop.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.mint, fontSize: 12.5)),
            ]),
          ),
          Expanded(child: _body(st, current)),
        ]),
      ),
    );
  }

  Widget _body(AppState st, String? current) {
    if (st.loading && st.locations.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppColors.green));
    }
    if (st.locations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(st.error ?? 'No locations are available right now.',
                textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.green),
              onPressed: st.load,
              child: const Text('Retry'),
            ),
          ]),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        for (final l in st.locations)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LocationTile(
              location: l,
              selected: l.id == current,
              busy: _busyId == l.id,
              disabled: _busyId != null && _busyId != l.id,
              onTap: () => _pick(l),
            ),
          ),
        if (!widget.initial)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Your cart is kept separately for each location.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12)),
          ),
      ],
    );
  }
}

class _LocationTile extends StatelessWidget {
  final ShopLocation location;
  final bool selected, busy, disabled;
  final VoidCallback onTap;
  const _LocationTile({required this.location, required this.selected, required this.busy, required this.disabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Pressable(
        onTap: disabled || busy ? () {} : onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: selected ? AppColors.green : Colors.transparent, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(color: AppColors.mint, shape: BoxShape.circle),
              child: const Icon(Icons.location_on, color: AppColors.green),
            ),
            const SizedBox(width: 14),
            Expanded(child: BiText(location.nameEn, location.nameTa, size: 18)),
            if (busy)
              const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.green))
            else if (selected)
              const Icon(Icons.check_circle, color: AppColors.green)
            else
              const Icon(Icons.chevron_right, color: AppColors.muted),
          ]),
        ),
      ),
    );
  }
}
