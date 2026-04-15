import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/message_model.dart';
import '../utils/error_helper.dart';
import './storage_service.dart';

class MessageService {
  final StorageService _storageService = StorageService();

  Future<String> _getToken() async {
    final token = await _storageService.getAccessToken();
    if (token == null) {
      throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
    }
    return token;
  }

  Future<Map<String, dynamic>> getMyMessages({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/messages/my?page=$page&limit=$limit',
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rawItems = data['data']['items'] as List? ?? [];
        final items =
            rawItems.map((e) => MessageModel.fromJson(e)).toList();

        return {
          'success': true,
          'data': items,
          'unread_count': data['data']['unread_count'] ?? 0,
          'pagination': data['data']['pagination'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal memuat notifikasi',
        };
      }
    } catch (e) {
      return {'success': false, 'message': friendlyErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/messages/unread-count');

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'count': data['data']['count'] ?? 0,
        };
      } else {
        return {'success': false, 'count': 0};
      }
    } catch (e) {
      return {'success': false, 'count': 0};
    }
  }

  Future<Map<String, dynamic>> markAsRead(String messageId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/messages/$messageId/read');

      final response = await http.patch(
        uri,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal menandai pesan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': friendlyErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/messages/read-all');

      final response = await http.patch(
        uri,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal menandai semua pesan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': friendlyErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/messages/my/$messageId');

      final response = await http.delete(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal menghapus notifikasi',
        };
      }
    } catch (e) {
      return {'success': false, 'message': friendlyErrorMessage(e)};
    }
  }
}
