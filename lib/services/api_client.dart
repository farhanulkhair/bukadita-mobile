import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

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
      throw ApiException('Terjadi kesalahan: ${e.toString()}');
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
      throw ApiException('Terjadi kesalahan: ${e.toString()}');
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

      // Handle error response
      final errorMessage =
          jsonResponse['error'] ??
          jsonResponse['message'] ??
          'Terjadi kesalahan pada server';
      throw ApiException(errorMessage);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Gagal memproses response: ${e.toString()}');
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
