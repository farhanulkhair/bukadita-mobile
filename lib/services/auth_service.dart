import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/forgot_password_request.dart';
import '../models/user_model.dart';
import '../config/api_config.dart';
import '../utils/error_helper.dart';
import 'api_client.dart';
import 'storage_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service untuk handle authentication (login, register, logout)
class AuthService {
  final ApiClient _apiClient = ApiClient();
  final StorageService _storageService = StorageService();

  /// Login dengan email/phone dan password
  /// Returns LoginResponse yang berisi user data dan token
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      // Panggil API login
      final response = await _apiClient.post(
        ApiConfig.loginEndpoint,
        body: request.toJson(),
      );

      // Parse response
      final loginResponse = LoginResponse.fromJson(response);

      // Jika login berhasil, simpan token dan user data
      if (loginResponse.success && loginResponse.data != null) {
        await _storageService.saveAccessToken(
          loginResponse.data!.token.accessToken,
        );
        await _storageService.saveRefreshToken(
          loginResponse.data!.token.refreshToken,
        );
        await _storageService.saveUserData(loginResponse.data!.user);
        await _storageService.saveRememberMe(request.rememberMe);

        // Refresh user profile dari API untuk mendapatkan data lengkap
        try {
          await _refreshUserProfile();
        } catch (e) {
          // Tidak throw error, karena login sudah berhasil
        }
      }

      return loginResponse;
    } on ApiException catch (e) {
      return LoginResponse(success: false, error: e.message);
    } catch (e) {
      return LoginResponse(success: false, error: friendlyErrorMessage(e));
    }
  }

  /// Logout
  Future<void> logout() async {
    try {
      // Clear local storage
      await _storageService.clearAll();
    } catch (e) {
      // Tetap clear local storage meskipun logout gagal
      await _storageService.clearAll();
    }
  }

  /// Check apakah user sudah login
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  /// Reset/Forgot Password
  /// User memasukkan email/phone dan password baru
  Future<Map<String, dynamic>> resetPassword(
    ForgotPasswordRequest request,
  ) async {
    try {
      // Panggil API reset password
      final response = await _apiClient.post(
        ApiConfig.resetPasswordEndpoint,
        body: request.toJson(),
      );

      return {
        'success': true,
        'message': response['message'] ?? 'Password berhasil diubah',
      };
    } on ApiException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': friendlyErrorMessage(e)};
    }
  }

  /// Refresh user profile dari API untuk mendapatkan data lengkap
  Future<void> _refreshUserProfile() async {
    final token = await _storageService.getAccessToken();
    if (token == null) return;

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/me');
      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final userData = UserModel.fromJson(data['data']);
          await _storageService.saveUserData(userData);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _apiClient.dispose();
  }
}
