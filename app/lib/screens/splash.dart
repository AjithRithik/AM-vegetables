import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state.dart';
import 'shell.dart';
import '../widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
  late final AnimationController _ring =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  late final Animation<double> _scale = CurvedAnimation(parent: _c, curve: Curves.elasticOut);
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: const Interval(0.3, 1, curve: Curves.easeIn));

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final st = context.read<AppState>();
    // Load CMS data while the animation plays; keep splash at least 2.2s.
    await Future.wait([st.load(), Future.delayed(const Duration(milliseconds: 2200))]);
    if (!mounted) return;
    if (st.error != null && st.shop == null) {
      setState(() {}); // show retry
      return;
    }
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => const Shell(),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  void dispose() {
    _c.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    final failed = !st.loading && st.error != null && st.shop == null;
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.green, AppColors.greenDark]),
        ),
        child: SafeArea(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(alignment: Alignment.center, children: [
                for (final phase in [0.0, 0.5])
                  AnimatedBuilder(
                    animation: _ring,
                    builder: (_, __) {
                      final t = (_ring.value + phase) % 1;
                      return Container(
                        width: 120 + 100 * t,
                        height: 120 + 100 * t,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.5 * (1 - t)), width: 2),
                        ),
                      );
                    },
                  ),
                ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(14),
                    child: const AppLogo(size: 92),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _fade,
              child: Column(children: [
                const Text('AM Vegetables',
                    style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text('ஏ எம் காய்கறி அங்காடி', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 18),
                Text(st.shop?.splashEn ?? 'Farm fresh, every morning',
                    style: const TextStyle(color: AppColors.mint, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 48),
            if (failed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(st.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.green),
                onPressed: _boot,
                child: const Text('Retry'),
              ),
            ] else
              const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}

