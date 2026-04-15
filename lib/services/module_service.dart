import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../utils/error_helper.dart';
import 'storage_service.dart';
import 'cache_service.dart';

class ModuleService {
  final StorageService _storageService = StorageService();
  final CacheService _cache = CacheService();

  // Cache keys
  static String _modulesKey({int page = 1, int limit = 100}) =>
      'modules_list_p${page}_l$limit';
  static String _moduleDetailKey(String id) => 'module_detail_$id';
  static String _materialsKey(String moduleId) => 'materials_$moduleId';
  static String _materialDetailKey(String id) => 'material_detail_$id';
  static String _materialPointsKey(String id) => 'material_points_$id';

  /// Get all published modules (cache-first)
  Future<Map<String, dynamic>> getAllModules({
    int page = 1,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    final key = _modulesKey(page: page, limit: limit);

    if (!forceRefresh) {
      final cached = await _cache.get(key);
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/modules?page=$page&limit=$limit',
      );
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
        await _cache.set(key, result);
        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memuat daftar modul',
          'data': null,
        };
      }
    } catch (e) {
      // On network error, try returning stale cache
      final stale = await _cache.get(key);
      if (stale != null) return stale;
      return {'success': false, 'message': friendlyErrorMessage(e), 'data': null};
    }
  }

  /// Get module detail by ID (cache-first)
  Future<Map<String, dynamic>> getModuleDetail(
    String moduleId, {
    bool forceRefresh = false,
  }) async {
    final key = _moduleDetailKey(moduleId);

    if (!forceRefresh) {
      final cached = await _cache.get(key);
      if (cached != null) return cached;
    }

    try {
      final token = await _storageService.getAccessToken();
      final url = Uri.parse('${ApiConfig.baseUrl}/modules/$moduleId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
        await _cache.set(key, result);
        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memuat detail modul',
          'data': null,
        };
      }
    } catch (e) {
      final stale = await _cache.get(key);
      if (stale != null) return stale;
      return {'success': false, 'message': friendlyErrorMessage(e), 'data': null};
    }
  }

  /// Get materials by module ID (cache-first)
  Future<Map<String, dynamic>> getMaterialsByModule(
    String moduleId, {
    int page = 1,
    int limit = 100,
    bool forceRefresh = false,
  }) async {
    final key = _materialsKey(moduleId);

    if (!forceRefresh) {
      final cached = await _cache.get(key);
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/materials/public?module_id=$moduleId&page=$page&limit=$limit',
      );
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
        await _cache.set(key, result);
        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memuat daftar materi',
          'data': null,
        };
      }
    } catch (e) {
      final stale = await _cache.get(key);
      if (stale != null) return stale;
      return {'success': false, 'message': friendlyErrorMessage(e), 'data': null};
    }
  }

  /// Get material detail with poin pembelajaran (cache-first)
  Future<Map<String, dynamic>> getMaterialDetail(
    String materialId, {
    bool forceRefresh = false,
  }) async {
    final key = _materialDetailKey(materialId);

    if (!forceRefresh) {
      final cached = await _cache.get(key);
      if (cached != null) return cached;
    }

    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/materials/$materialId/public',
      );
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
        await _cache.set(key, result);
        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memuat detail materi',
          'data': null,
        };
      }
    } catch (e) {
      final stale = await _cache.get(key);
      if (stale != null) return stale;
      return {'success': false, 'message': friendlyErrorMessage(e), 'data': null};
    }
  }

  /// Get material points by material ID (cache-first)
  Future<Map<String, dynamic>> getMaterialPoints(
    String materialId, {
    bool forceRefresh = false,
  }) async {
    final key = _materialPointsKey(materialId);

    if (!forceRefresh) {
      final cached = await _cache.get(key);
      if (cached != null) return cached;
    }

    try {
      final token = await _storageService.getAccessToken();
      final url = Uri.parse(
        '${ApiConfig.baseUrl}/materials/$materialId/points',
      );
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final result = {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
        await _cache.set(key, result);
        return result;
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memuat poin materi',
          'data': null,
        };
      }
    } catch (e) {
      final stale = await _cache.get(key);
      if (stale != null) return stale;
      return {'success': false, 'message': friendlyErrorMessage(e), 'data': null};
    }
  }

  /// Invalidate material-related caches (call after quiz/progress changes)
  Future<void> invalidateMaterialCache(String materialId) async {
    await _cache.remove(_materialDetailKey(materialId));
    await _cache.remove(_materialPointsKey(materialId));
  }

  /// Invalidate module caches
  Future<void> invalidateModuleCache() async {
    await _cache.removeByPrefix('modules_list');
  }
}
