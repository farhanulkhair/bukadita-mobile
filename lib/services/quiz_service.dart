import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/error_helper.dart';
import 'storage_service.dart';
import 'cache_service.dart';

/// Service untuk mengelola operasi terkait kuis
class QuizService {
  final StorageService _storageService = StorageService();
  final CacheService _cache = CacheService();

  static const _maxRetries = 2;

  Future<http.Response> _getWithRetry(
    Uri url,
    Map<String, String> headers,
  ) async {
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await http.get(url, headers: headers);
      } on SocketException {
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt + 1));
      } on http.ClientException {
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    throw const SocketException('Gagal terhubung setelah retry');
  }

  String _friendlyError(Object e) => friendlyErrorMessage(e);

  /// Get quizzes by material ID (cache-first)
  /// Get quizzes for a material — always fetch from API, cache as offline fallback
  Future<Map<String, dynamic>> getMaterialQuizzes(String materialId) async {
    final cacheKey = 'material_quizzes_$materialId';

    final token = await _storageService.getAccessToken();

    // List of endpoints to try in order
    final endpoints = [
      '${ApiConfig.baseUrl}/materials/$materialId/quiz', // Public singular
      '${ApiConfig.baseUrl}/materials/$materialId/quizzes', // Authenticated plural
    ];

    for (var i = 0; i < endpoints.length; i++) {
      try {
        final url = Uri.parse(endpoints[i]);

        final response = await http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Handle different response structures
          var quizData = data['data'];

          // If data is null or not found, try next endpoint
          if (quizData == null) {
            continue;
          }

          // Normalize to array format
          List quizList;
          if (quizData is Map && quizData.containsKey('quiz')) {
            // Response format: {data: {quiz: {...}}}
            quizList = [quizData['quiz']];
          } else if (quizData is List) {
            // Response format: {data: [{...}]}
            quizList = quizData;
          } else if (quizData is Map) {
            // Response format: {data: {...}}
            quizList = [quizData];
          } else {
            quizList = [];
          }

          final result = {
            'success': true,
            'data': quizList,
            'message': data['message'] ?? 'Kuis berhasil dimuat',
          };
          await _cache.set(cacheKey, result);
          return result;
        } else if (response.statusCode == 404 && i < endpoints.length - 1) {
          // Try next endpoint on 404
          continue;
        } else {
          final data = json.decode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Gagal memuat kuis',
            'data': null,
          };
        }
      } catch (e) {
        if (i == endpoints.length - 1) {
          final stale = await _cache.get(cacheKey);
          if (stale != null) return stale;
          return {'success': false, 'message': friendlyErrorMessage(e), 'data': null};
        }
        continue;
      }
    }

    // All endpoints failed
    return {
      'success': false,
      'message': 'Tidak ada kuis untuk materi ini',
      'data': [],
    };
  }

  /// Get quiz detail by ID — always fetch from API, cache as offline fallback
  Future<Map<String, dynamic>> getQuizDetail(String quizId) async {
    final cacheKey = 'quiz_detail_$quizId';

    try {
      final token = await _storageService.getAccessToken();
      final url = Uri.parse('${ApiConfig.baseUrl}/quizzes/$quizId');

      final response = await _getWithRetry(url, {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
        await _cache.set(cacheKey, result);
        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memuat detail kuis',
          'data': null,
        };
      }
    } catch (e) {
      final stale = await _cache.get(cacheKey);
      if (stale != null) return stale;
      return {'success': false, 'message': _friendlyError(e), 'data': null};
    }
  }

  /// Start quiz attempt
  Future<Map<String, dynamic>> startQuizAttempt(String quizId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Sesi Anda telah berakhir. Silakan login kembali.'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/quizzes/start');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'quiz_id': quizId}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memulai kuis',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': _friendlyError(e), 'data': null};
    }
  }

  /// Submit quiz answers
  Future<Map<String, dynamic>> submitQuiz({
    required String quizId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Sesi Anda telah berakhir. Silakan login kembali.'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/quizzes/submit');

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'quiz_id': quizId,
          'answers': answers,
          'submitted_at': DateTime.now().toIso8601String(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengirim jawaban kuis',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': _friendlyError(e), 'data': null};
    }
  }

  /// Get quiz results/history
  Future<Map<String, dynamic>> getQuizResults(String quizId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Sesi Anda telah berakhir. Silakan login kembali.'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/quizzes/$quizId/results');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memuat hasil kuis',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': _friendlyError(e), 'data': null};
    }
  }

  /// Get my quiz attempts with optional module filter (cache-first)
  /// Get quiz attempts — always fetch from API, cache as offline fallback
  Future<Map<String, dynamic>> getMyQuizAttempts({
    String? status,
    String? moduleId,
    int page = 1,
    int limit = 10,
  }) async {
    final cacheKey = 'quiz_attempts_${moduleId ?? 'all'}_p${page}_l$limit';

    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Sesi Anda telah berakhir. Silakan login kembali.'};
      }

      var url =
          '${ApiConfig.baseUrl}/quizzes/attempts/my?page=$page&limit=$limit';
      if (status != null) {
        url += '&status=$status';
      }
      if (moduleId != null) {
        url += '&module_id=$moduleId';
      }

      final response = await _getWithRetry(Uri.parse(url), {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      final data = json.decode(response.body);

      if (response.statusCode == 404) {
        final result = {
          'success': true,
          'data': {'attempts': [], 'total': 0},
          'message': 'Belum ada riwayat kuis',
        };
        await _cache.set(cacheKey, result);
        return result;
      }

      if (response.statusCode == 200) {
        final result = {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
        await _cache.set(cacheKey, result);
        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memuat riwayat kuis',
          'data': null,
        };
      }
    } catch (e) {
      final stale = await _cache.get(cacheKey);
      if (stale != null) return stale;
      return {'success': false, 'message': _friendlyError(e), 'data': null};
    }
  }
}
