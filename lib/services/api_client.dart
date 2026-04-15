import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/error_helper.dart';

/// API Client untuk handle semua HTTP requests
/// Menggunakan http package dengan error handling lengkap
class ApiClient {
  final http.Client _client = http.Client();

  /// POST request dengan error handling
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final response = await _client
          .post(
            url,
            headers: headers ?? ApiConfig.defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet');
    } on TimeoutException {
      throw ApiException('Request timeout, silakan coba lagi');
    } on FormatException {
      throw ApiException('Format response tidak valid');
    } on HttpException {
      throw ApiException('Server error, silakan coba lagi');
    } catch (e) {
      throw ApiException(friendlyErrorMessage(e));
    }
  }

  /// GET request dengan error handling
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

      final response = await _client
          .get(url, headers: headers ?? ApiConfig.defaultHeaders)
          .timeout(ApiConfig.connectionTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Tidak ada koneksi internet');
    } on TimeoutException {
      throw ApiException('Request timeout, silakan coba lagi');
    } on FormatException {
      throw ApiException('Format response tidak valid');
    } on HttpException {
      throw ApiException('Server error, silakan coba lagi');
    } catch (e) {
      throw ApiException(friendlyErrorMessage(e));
    }
  }

  /// Handle HTTP response
  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      // Cek jika response body kosong
      if (response.body.isEmpty) {
        throw ApiException('Response body kosong dari server');
      }

      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;

      // Check if response is successful (status code 2xx)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonResponse;
      }

      // Handle error response — 'error' field bisa boolean (true/false) atau string
      final errorField = jsonResponse['error'];
      final rawMessage = (errorField is String && errorField.isNotEmpty)
          ? errorField
          : jsonResponse['message']?.toString() ??
              'Terjadi kesalahan pada server';
      throw ApiException(translateApiMessage(rawMessage));
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(friendlyErrorMessage(e));
    }
  }

  /// Dispose client
  void dispose() {
    _client.close();
  }
}

/// Custom exception untuk API errors
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}
