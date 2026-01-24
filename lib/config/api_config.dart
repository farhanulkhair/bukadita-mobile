import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi API untuk aplikasi BukaDita
/// Semua endpoint dan base URL didefinisikan di sini
class ApiConfig {
  // Base URL dari environment variable
  static String get baseUrl => dotenv.env['API_URL'] ?? 'http://localhost:4000';

  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URl'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // Auth Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  // Timeout Duration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
