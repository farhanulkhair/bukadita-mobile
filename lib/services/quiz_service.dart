import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

/// Service untuk mengelola operasi terkait kuis
class QuizService {
  final StorageService _storageService = StorageService();

  /// Get quizzes by material ID
  /// Tries multiple endpoints with fallback mechanism
  Future<Map<String, dynamic>> getMaterialQuizzes(String materialId) async {
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

          return {
            'success': true,
            'data': quizList,
            'message': data['message'] ?? 'Quiz fetched successfully',
          };
        } else if (response.statusCode == 404 && i < endpoints.length - 1) {
          // Try next endpoint on 404
          continue;
        } else {
          final data = json.decode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch quiz',
            'data': null,
          };
        }
      } catch (e) {
        if (i == endpoints.length - 1) {
          // Last endpoint failed
          return {'success': false, 'message': 'Error: $e', 'data': null};
        }
        // Try next endpoint
        continue;
      }
    }

    // All endpoints failed
    return {
      'success': false,
      'message': 'No quiz available for this material',
      'data': [],
    };
  }

  /// Get quiz detail by ID including questions
  Future<Map<String, dynamic>> getQuizDetail(String quizId) async {
    try {
      final token = await _storageService.getAccessToken();
      final url = Uri.parse('${ApiConfig.baseUrl}/quizzes/$quizId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
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
          'message': data['message'] ?? 'Failed to fetch quiz detail',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  /// Start quiz attempt
  Future<Map<String, dynamic>> startQuizAttempt(String quizId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
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
          'message': data['message'] ?? 'Failed to start quiz',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': null};
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
        return {'success': false, 'message': 'Token tidak ditemukan'};
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
          'message': data['message'] ?? 'Failed to submit quiz',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  /// Get quiz results/history
  Future<Map<String, dynamic>> getQuizResults(String quizId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
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
          'message': data['message'] ?? 'Failed to fetch results',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  /// Get my quiz attempts with optional module filter (sesuai web app)
  Future<Map<String, dynamic>> getMyQuizAttempts({
    String? status,
    String? moduleId, // Add module_id filter
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'message': 'Token tidak ditemukan'};
      }

      var url =
          '${ApiConfig.baseUrl}/quizzes/attempts/my?page=$page&limit=$limit';
      if (status != null) {
        url += '&status=$status';
      }
      if (moduleId != null) {
        url += '&module_id=$moduleId'; // Add module_id to query params
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final data = json.decode(response.body);

      // Handle 404 sebagai normal (user belum pernah quiz)
      if (response.statusCode == 404) {
        return {
          'success': true, // Treat as success with empty data
          'data': {'attempts': [], 'total': 0},
          'message': 'No quiz history found',
        };
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch attempts',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }
}
