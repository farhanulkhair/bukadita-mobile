import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../utils/error_helper.dart';
import './storage_service.dart';

/// Service untuk mengelola profil user
class ProfileService {
  final StorageService _storageService = StorageService();

  /// Get current user profile from API
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    try {
      // Get token
      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/users/me');
      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update user data di storage
        if (data['data'] != null) {
          final userData = UserModel.fromJson(data['data']);
          await _storageService.saveUserData(userData);

          return {
            'success': true,
            'message': 'Berhasil mendapatkan data user',
            'data': userData,
          };
        }

        return {'success': false, 'message': 'Data user tidak ditemukan'};
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal mendapatkan data user');
      }
    } catch (e) {
      throw Exception(friendlyErrorMessage(e));
    }
  }

  /// Upload foto profil
  /// [imageFile] - File gambar yang akan diupload
  /// Returns URL foto profil yang berhasil diupload
  Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile) async {
    try {
      // Get token
      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }

      // Prepare multipart request
      final uri = Uri.parse('${ApiConfig.baseUrl}/users/me/profile-photo');
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers.addAll({'Authorization': 'Bearer $token'});

      // Add file
      final String mimeType = _getMimeType(imageFile.path);
      final List<String> mimeTypeParts = mimeType.split('/');

      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          imageFile.path,
          contentType: MediaType(mimeTypeParts[0], mimeTypeParts[1]),
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update user data di storage
        final userData = await _storageService.getUserData();
        if (userData != null && data['data'] != null) {
          // API returns 'profil_url', but we store as 'avatar'
          final avatarUrl =
              data['data']['profil_url'] ?? data['data']['avatar'];
          final updatedUser = userData.copyWith(avatar: avatarUrl);
          await _storageService.saveUserData(updatedUser);
        }

        return {
          'success': true,
          'message': 'Foto profil berhasil diupload',
          'data': data['data'],
        };
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal upload foto profil');
      }
    } catch (e) {
      throw Exception(friendlyErrorMessage(e));
    }
  }

  /// Delete foto profil
  Future<Map<String, dynamic>> deleteProfilePhoto() async {
    try {
      // Get token
      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/users/me/profile-photo');
      final response = await http.delete(
        uri,
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update user data di storage
        final userData = await _storageService.getUserData();
        if (userData != null) {
          final updatedUser = userData.copyWith(avatar: null);
          await _storageService.saveUserData(updatedUser);
        }

        return {'success': true, 'message': 'Foto profil berhasil dihapus'};
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal hapus foto profil');
      }
    } catch (e) {
      throw Exception(friendlyErrorMessage(e));
    }
  }

  /// Update profile data
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? address,
    String? date_of_birth,
  }) async {
    try {
      // Get token
      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/users/me');
      final response = await http.put(
        uri,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({
          if (name != null) 'full_name': name,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
          if (date_of_birth != null) 'date_of_birth': date_of_birth,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update user data di storage
        final userData = await _storageService.getUserData();
        if (userData != null && data['data'] != null) {
          final updatedUser = userData.copyWith(
            name: data['data']['full_name'] ?? userData.name,
            phone: data['data']['phone'] ?? userData.phone,
            address: data['data']['address'] ?? userData.address,
            date_of_birth:
                data['data']['date_of_birth'] ?? userData.date_of_birth,
          );
          await _storageService.saveUserData(updatedUser);
        }

        return {
          'success': true,
          'message': 'Profil berhasil diupdate',
          'data': data['data'],
        };
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Gagal update profil');
      }
    } catch (e) {
      throw Exception(friendlyErrorMessage(e));
    }
  }

  /// Get mime type dari file path
  String _getMimeType(String path) {
    final extension = path.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Change password
  /// [oldPassword] - Password lama user
  /// [newPassword] - Password baru yang diinginkan
  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // Get token
      final token = await _storageService.getAccessToken();
      if (token == null) {
        throw Exception('Sesi Anda telah berakhir. Silakan login kembali.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/users/me/change-password');
      final response = await http.post(
        uri,
        headers: ApiConfig.authHeaders(token),
        body: json.encode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password berhasil diubah',
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal mengubah password',
        };
      }
    } catch (e) {
      return {'success': false, 'message': friendlyErrorMessage(e)};
    }
  }
}
