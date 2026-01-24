import 'user_model.dart';
import 'token_model.dart';

/// Model untuk Login Response dari API
class LoginResponse {
  final bool success;
  final String? message;
  final LoginData? data;
  final String? error;
  final int? statusCode;
  final bool? pendingProfile;

  LoginResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
    this.statusCode,
    this.pendingProfile,
  });

  /// Convert dari JSON response ke LoginResponse object
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // API menggunakan "error": false untuk sukses, convert ke success: true
    final bool isSuccess = json['error'] == false || json['success'] == true;

    return LoginResponse(
      success: isSuccess,
      message: json['message'],
      data: json['data'] != null ? LoginData.fromJson(json['data']) : null,
      error: json['error'] is String ? json['error'] : null,
      statusCode: json['statusCode'],
      pendingProfile: json['pendingProfile'],
    );
  }

  /// Convert dari LoginResponse object ke JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
      'error': error,
      'statusCode': statusCode,
      'pendingProfile': pendingProfile,
    };
  }
}

/// Model untuk Data dalam Login Response
class LoginData {
  final UserModel user;
  final TokenModel token;

  LoginData({required this.user, required this.token});

  /// Convert dari JSON ke LoginData object
  factory LoginData.fromJson(Map<String, dynamic> json) {
    // Token bisa langsung di data atau dalam object token
    final tokenData =
        json['token'] != null
            ? json['token']
            : {
              'accessToken': json['access_token'],
              'refreshToken': json['refresh_token'],
              'expiresAt': json['expires_at'],
            };

    return LoginData(
      user: UserModel.fromJson(json['user']),
      token: TokenModel.fromJson(tokenData),
    );
  }

  /// Convert dari LoginData object ke JSON
  Map<String, dynamic> toJson() {
    return {'user': user.toJson(), 'token': token.toJson()};
  }
}
