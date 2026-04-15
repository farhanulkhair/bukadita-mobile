import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../utils/error_helper.dart';
import 'storage_service.dart';
import 'cache_service.dart';

class ProgressService {
  final StorageService _storageService = StorageService();
  final CacheService _cache = CacheService();

  // Cache keys
  static const String _modulesProgressKey = 'progress_modules';
  static String _moduleProgressKey(String id) => 'progress_module_$id';
  static String _materialProgressKey(String id) => 'progress_material_$id';
  static String _completedPoinsKey(String id) => 'completed_poins_$id';

  /// Get all modules progress (cache-first)
  Future<Map<String, dynamic>> getModulesProgress({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.get(_modulesProgressKey);
      if (cached != null) return cached;
    }

    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Sesi Anda telah berakhir. Silakan login kembali.'};
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
        final result = {'success': true, 'data': data['data']};
        await _cache.set(_modulesProgressKey, result);
        return result;
      } else {
        final stale = await _cache.get(_modulesProgressKey);
        if (stale != null) return stale;
        return {'success': false, 'error': 'Gagal mengambil progress modul'};
      }
    } catch (e) {
      final stale = await _cache.get(_modulesProgressKey);
      if (stale != null) return stale;
      return {'success': false, 'error': friendlyErrorMessage(e)};
    }
  }

  /// Get module progress with detail (cache-first)
  Future<Map<String, dynamic>> getModuleProgress(
    String moduleId, {
    bool forceRefresh = false,
  }) async {
    final key = _moduleProgressKey(moduleId);

    if (!forceRefresh) {
      final cached = await _cache.get(key);
      if (cached != null) return cached;
    }

    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Sesi Anda telah berakhir. Silakan login kembali.'};
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
        final result = {'success': true, 'data': data['data']};
        await _cache.set(key, result);
        return result;
      } else {
        final stale = await _cache.get(key);
        if (stale != null) return stale;
        return {'success': false, 'error': 'Gagal mengambil progress modul'};
      }
    } catch (e) {
      final stale = await _cache.get(key);
      if (stale != null) return stale;
      return {'success': false, 'error': friendlyErrorMessage(e)};
    }
  }

  /// Get material progress (cache-first)
  Future<Map<String, dynamic>> getMaterialProgress(
    String materialId, {
    bool forceRefresh = false,
  }) async {
    final key = _materialProgressKey(materialId);

    if (!forceRefresh) {
      final cached = await _cache.get(key);
      if (cached != null) return cached;
    }

    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Sesi Anda telah berakhir. Silakan login kembali.'};
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
        final result = {'success': true, 'data': data['data']};
        await _cache.set(key, result);
        return result;
      } else {
        final stale = await _cache.get(key);
        if (stale != null) return stale;
        return {'success': false, 'error': 'Gagal mengambil progress'};
      }
    } catch (e) {
      final stale = await _cache.get(key);
      if (stale != null) return stale;
      return {'success': false, 'error': friendlyErrorMessage(e)};
    }
  }

  /// Mark poin as completed — invalidates relevant caches
  Future<Map<String, dynamic>> markPoinCompleted(String poinId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Sesi Anda telah berakhir. Silakan login kembali.'};
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
        // Invalidate progress caches since data changed
        await _cache.removeByPrefix('progress_');
        await _cache.removeByPrefix('completed_poins_');
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': 'Gagal menandai poin selesai'};
      }
    } catch (e) {
      return {'success': false, 'error': friendlyErrorMessage(e)};
    }
  }

  /// Get completed poins for a material (cache-first, short TTL)
  Future<Map<String, dynamic>> getCompletedPoins(
    String materialId, {
    bool forceRefresh = false,
  }) async {
    final key = _completedPoinsKey(materialId);

    if (!forceRefresh) {
      final cached = await _cache.get(key);
      if (cached != null) return cached;
    }

    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Sesi Anda telah berakhir. Silakan login kembali.'};
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
        final result = {'success': true, 'data': data['data']};
        await _cache.set(key, result);
        return result;
      } else {
        final stale = await _cache.get(key);
        if (stale != null) return stale;
        return {'success': false, 'error': 'Gagal mengambil progress poin'};
      }
    } catch (e) {
      final stale = await _cache.get(key);
      if (stale != null) return stale;
      return {'success': false, 'error': friendlyErrorMessage(e)};
    }
  }

  /// Mark material as completed — invalidates caches
  Future<Map<String, dynamic>> markMaterialCompleted(String materialId) async {
    try {
      final token = await _storageService.getAccessToken();
      if (token == null) {
        return {'success': false, 'error': 'Sesi Anda telah berakhir. Silakan login kembali.'};
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
        await _cache.removeByPrefix('progress_');
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': 'Gagal menandai materi selesai'};
      }
    } catch (e) {
      return {'success': false, 'error': friendlyErrorMessage(e)};
    }
  }

  /// Save last accessed poin locally
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

  /// Clear last accessed poin
  Future<bool> clearLastAccessedPoin(String materialId) async {
    try {
      await _storageService.removeLocalData('last_accessed_poin_$materialId');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Invalidate all progress caches
  Future<void> invalidateAllProgress() async {
    await _cache.removeByPrefix('progress_');
    await _cache.removeByPrefix('completed_poins_');
  }

  /// Save poin as read locally for offline/fast tracking
  Future<void> savePoinReadLocally(String materialId, String poinId) async {
    try {
      final key = 'read_poins_$materialId';
      final data = await _storageService.getLocalData(key);
      Set<String> readPoins = {};
      if (data != null) {
        readPoins = (json.decode(data) as List).cast<String>().toSet();
      }
      readPoins.add(poinId);
      await _storageService.saveLocalData(key, json.encode(readPoins.toList()));
    } catch (_) {}
  }

  /// Get locally read poin IDs for a material
  Future<Set<String>> getLocallyReadPoins(String materialId) async {
    try {
      final key = 'read_poins_$materialId';
      final data = await _storageService.getLocalData(key);
      if (data != null) {
        return (json.decode(data) as List).cast<String>().toSet();
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}
