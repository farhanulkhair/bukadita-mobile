import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/note_model.dart';
import '../utils/error_helper.dart';
import './storage_service.dart';

class NoteService {
  final StorageService _storageService = StorageService();

  Future<String> _getToken() async {
    final token = await _storageService.getAccessToken();
    if (token == null) throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
    return token;
  }

  /// Get all notes with optional pagination, category filter, and search
  Future<Map<String, dynamic>> getNotes({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
  }) async {
    try {
      final token = await _getToken();

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/notes')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = (data['data']['items'] as List?)
                ?.map((e) => NoteModel.fromJson(e))
                .toList() ??
            [];

        return {
          'success': true,
          'data': items,
          'pagination': data['data']['pagination'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal memuat catatan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': friendlyErrorMessage(e)};
    }
  }

  /// Get a single note by ID
  Future<Map<String, dynamic>> getNoteById(String noteId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/notes/$noteId');

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': NoteModel.fromJson(data['data']),
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal memuat catatan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': friendlyErrorMessage(e)};
    }
  }

  /// Create a new note
  Future<Map<String, dynamic>> createNote({
    required String title,
    required String content,
    String? category,
    bool isPinned = false,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/notes');

      final body = <String, dynamic>{
        'title': title,
        'content': content,
        'is_pinned': isPinned,
      };
      if (category != null && category.isNotEmpty) {
        body['category'] = category;
      }

      final response = await http.post(
        uri,
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': NoteModel.fromJson(data['data']),
          'message': 'Catatan berhasil dibuat',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal membuat catatan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': friendlyErrorMessage(e)};
    }
  }

  /// Update an existing note
  Future<Map<String, dynamic>> updateNote({
    required String noteId,
    required String title,
    required String content,
    String? category,
    bool? isPinned,
  }) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/notes/$noteId');

      final body = <String, dynamic>{
        'title': title,
        'content': content,
      };
      if (category != null) body['category'] = category;
      if (isPinned != null) body['is_pinned'] = isPinned;

      final response = await http.put(
        uri,
        headers: ApiConfig.authHeaders(token),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': NoteModel.fromJson(data['data']),
          'message': 'Catatan berhasil diperbarui',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal memperbarui catatan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': friendlyErrorMessage(e)};
    }
  }

  /// Delete a note
  Future<Map<String, dynamic>> deleteNote(String noteId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/notes/$noteId');

      final response = await http.delete(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Catatan berhasil dihapus',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal menghapus catatan',
        };
      }
    } catch (e) {
      return {'success': false, 'message': friendlyErrorMessage(e)};
    }
  }

  /// Toggle pin status of a note
  Future<Map<String, dynamic>> togglePin(String noteId) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/notes/$noteId/pin');

      final response = await http.patch(
        uri,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': NoteModel.fromJson(data['data']),
          'message': 'Status pin catatan berhasil diubah',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal mengubah status pin',
        };
      }
    } catch (e) {
      return {'success': false, 'message': friendlyErrorMessage(e)};
    }
  }

  /// Get all user note categories
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/notes/categories');

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final categories =
            (data['data'] as List?)?.map((e) => e.toString()).toList() ?? [];
        return {
          'success': true,
          'data': categories,
        };
      } else {
        return {'success': false, 'data': <String>[]};
      }
    } catch (e) {
      return {'success': false, 'data': <String>[]};
    }
  }
}
