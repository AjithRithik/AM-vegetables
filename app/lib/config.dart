class AppConfig {
  /// Supabase project. The publishable (anon) key is meant to be public: row level security in
  /// the database only lets the app READ the catalogue. NEVER put the secret key in the app.
  /// Override per environment with: flutter run --dart-define-from-file=env/local.json
  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: 'https://zuucgnnnygtyvwmshwpe.supabase.co');
  static const supabaseKey = String.fromEnvironment('SUPABASE_KEY',
      defaultValue: 'sb_publishable_koyTn0cjI12NIV-5Xs-Cug_l_YBvhca');

  /// Headers for the Supabase REST API (PostgREST).
  static Map<String, String> get headers => {
        'apikey': supabaseKey,
        // Legacy JWT-style anon keys also go in Authorization; new sb_publishable_ keys must not.
        if (supabaseKey.startsWith('eyJ')) 'Authorization': 'Bearer $supabaseKey',
        'Accept': 'application/json',
      };

  static Uri rest(String path, [Map<String, String>? query]) =>
      Uri.parse('$supabaseUrl/rest/v1/$path').replace(queryParameters: query);

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
    return path;
  }
}
