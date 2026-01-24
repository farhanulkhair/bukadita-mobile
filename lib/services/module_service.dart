import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

/// Service untuk mengelola operasi terkait modul pembelajaran
class ModuleService {
  final StorageService _storageService = StorageService();

  /// Get all published modules
  Future<Map<String, dynamic>> getAllModules({
    int page = 1,
    int limit = 100,
  }) async {
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
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch modules',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  /// Get module detail by ID
  Future<Map<String, dynamic>> getModuleDetail(String moduleId) async {
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
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch module detail',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  /// Get materials by module ID
  Future<Map<String, dynamic>> getMaterialsByModule(
    String moduleId, {
    int page = 1,
    int limit = 100,
  }) async {
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
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch materials',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  /// Get material detail with poin pembelajaran
  Future<Map<String, dynamic>> getMaterialDetail(String materialId) async {
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
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch material detail',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }

  /// Get material points by material ID
  Future<Map<String, dynamic>> getMaterialPoints(String materialId) async {
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
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch material points',
          'data': null,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e', 'data': null};
    }
  }
}
