import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  /// Build-time default. Set per environment:
  ///   flutter run --dart-define-from-file=env/local.json   (emulator + `npm run dev`)
  ///   flutter build apk --release --dart-define-from-file=env/prod.json
  /// With no define, the app uses the live site. (10.0.2.2 only works inside the
  /// Android emulator, so it must never be the default for a phone build.)
  static const defaultBaseUrl =
      String.fromEnvironment('CMS_BASE_URL', defaultValue: 'https://am-veg.vercel.app');

  /// The hidden server switcher is on in debug runs and off in release builds.
  /// Force it on for a QA build with --dart-define=ALLOW_HOST_SWITCH=true.
  static const allowHostSwitch =
      bool.fromEnvironment('ALLOW_HOST_SWITCH', defaultValue: kDebugMode);

  static const _prefKey = 'base_url_override';

  /// Host saved on the device from the hidden server settings (long-press the
  /// shop name on the Contact tab). Wins over the build-time default.
  static String? _override;

  static String get baseUrl => _override ?? defaultBaseUrl;
  static bool get isOverridden => _override != null;

  /// Call once before runApp.
  static Future<void> init() async {
    if (!allowHostSwitch) return; // release: always use the build default
    final prefs = await SharedPreferences.getInstance();
    _override = prefs.getString(_prefKey);
  }

  /// Saves a new host, or clears the override when [url] is null/empty.
  static Future<void> setOverride(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    final clean = url?.trim().replaceAll(RegExp(r'/+$'), '');
    if (clean == null || clean.isEmpty) {
      _override = null;
      await prefs.remove(_prefKey);
    } else {
      _override = clean;
      await prefs.setString(_prefKey, clean);
    }
  }

  /// [width] only applies to Cloudinary photos: they are served resized (and as
  /// WebP/AVIF where supported) so phones download small files.
  static String resolveImage(String path, {int width = 500}) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) {
      const marker = '/image/upload/';
      if (path.contains('res.cloudinary.com') && path.contains(marker) && !path.contains('/upload/f_auto')) {
        return path.replaceFirst(marker, '${marker}f_auto,q_auto,c_limit,w_$width/');
      }
      return path;
    }
    return '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
  }
}
