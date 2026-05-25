import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  const AppEnv._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? '';
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  static void validate() {
    final missingKeys = <String>[];

    if (supabaseUrl.isEmpty) missingKeys.add('SUPABASE_URL');
    if (supabaseAnonKey.isEmpty) missingKeys.add('SUPABASE_ANON_KEY');
    if (apiBaseUrl.isEmpty) missingKeys.add('API_BASE_URL');
    if (googleWebClientId.isEmpty) missingKeys.add('GOOGLE_WEB_CLIENT_ID');

    if (missingKeys.isNotEmpty) {
      throw Exception('Missing env keys: ${missingKeys.join(', ')}');
    }
  }
}
