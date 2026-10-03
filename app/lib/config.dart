import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  /// Build-time default. Set per environment:
  ///   flutter run --dart-define-from-file=env/local.json
  ///   flutter build apk --release --dart-define-from-file=env/prod.json
  /// Falls back to the local CMS (`npm run dev`) as seen from the Android emulator.
  static const defaultBaseUrl =
      String.fromEnvironment('CMS_BASE_URL', defaultValue: 'http://10.0.2.2:8080');

  static const _prefKey = 'base_url_override';

  /// Host saved on the device from the hidden server settings (long-press the
  /// shop name on the Contact tab). Wins over the build-time default.
  static String? _override;

  static String get baseUrl => _override ?? defaultBaseUrl;
  static bool get isOverridden => _override != null;

  /// Call once before runApp.
  static Future<void> init() async {
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

  static String resolveImage(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
  }
}
