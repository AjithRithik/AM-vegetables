import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'screens/shell.dart';
import 'screens/splash.dart';
import 'state.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  runApp(ChangeNotifierProvider(create: (_) => AppState(), child: const AmApp()));
}

class AmApp extends StatelessWidget {
  const AmApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Plus Jakarta Sans for Latin; Noto Sans Tamil as fallback for Tamil glyphs.
    final base = GoogleFonts.plusJakartaSansTextTheme();
    final tamil = GoogleFonts.notoSansTamil().fontFamily!;
    return MaterialApp(
      title: 'AM Vegetables',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green, primary: AppColors.green),
        scaffoldBackgroundColor: AppColors.bg,
        textTheme: base.apply(fontFamilyFallback: [tamil]),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.bg,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      home: const SplashScreen(),
      routes: {'/home': (_) => const Shell()},
    );
  }
}
