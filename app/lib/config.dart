class AppConfig {
  /// Root of the site that hosts /content/*.json and /images/uploads/*.
  /// Override at build time:
  ///   flutter run --dart-define=CMS_BASE_URL=https://your-site.netlify.app
  /// Default targets the local CMS (`npm run dev`) from the Android emulator.
  static const baseUrl =
      String.fromEnvironment('CMS_BASE_URL', defaultValue: 'http://10.0.2.2:8080');

  static String resolveImage(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
  }
}
