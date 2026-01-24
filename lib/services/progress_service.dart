import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import 'storage_service.dart';

/// Service untuk mengelola progress pembelajaran pengguna
class ProgressService {
  final StorageService _storageService = StorageService();

  /// Get all modules progress
  Future<Map<String, dynamic>> getModulesProgress() async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Token tidak ditemukan'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/progress/modules');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': 'Gagal mengambil progress modul'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get module progress with detail
  Future<Map<String, dynamic>> getModuleProgress(String moduleId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Token tidak ditemukan'};
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/progress/modules/$moduleId');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': 'Gagal mengambil progress modul'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get material progress including last accessed poin
  Future<Map<String, dynamic>> getMaterialProgress(String materialId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Token tidak ditemukan'};
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/progress/materials/$materialId',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': 'Gagal mengambil progress'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mark poin as completed (dibaca)
  Future<Map<String, dynamic>> markPoinCompleted(String poinId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Token tidak ditemukan'};
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/progress/poins/$poinId/complete',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'poin_id': poinId,
          'completed_at': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': 'Gagal menandai poin selesai'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get completed poins for a material
  Future<Map<String, dynamic>> getCompletedPoins(String materialId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Token tidak ditemukan'};
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/progress/materials/$materialId/poins',
      );

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': 'Gagal mengambil progress poin'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mark material as completed
  Future<Map<String, dynamic>> markMaterialCompleted(String materialId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Token tidak ditemukan'};
      }

      final url = Uri.parse(
        '${ApiConfig.baseUrl}/progress/materials/$materialId/complete',
      );

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': 'Gagal menandai materi selesai'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Save last accessed poin locally (using SharedPreferences)
  /// Enhanced dengan informasi quiz status
  Future<bool> saveLastAccessedPoin({
    required String materialId,
    required int poinIndex,
    required String poinId,
    bool isQuizCompleted = false,
    bool shouldShowQuiz = false,
  }) async {
    try {
      await _storageService.saveLocalData(
        'last_accessed_poin_$materialId',
        json.encode({
          'poinIndex': poinIndex,
          'poinId': poinId,
          'isQuizCompleted': isQuizCompleted,
          'shouldShowQuiz': shouldShowQuiz,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get last accessed poin locally
  Future<Map<String, dynamic>?> getLastAccessedPoin(String materialId) async {
    try {
      final data = await _storageService.getLocalData(
        'last_accessed_poin_$materialId',
      );
      if (data != null) {
        return json.decode(data) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear last accessed poin untuk material tertentu
  Future<bool> clearLastAccessedPoin(String materialId) async {
    try {
      await _storageService.removeLocalData('last_accessed_poin_$materialId');
      return true;
    } catch (e) {
      return false;
    }
  }
}
