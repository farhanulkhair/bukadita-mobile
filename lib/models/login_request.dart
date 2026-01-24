/// Model untuk Login Request
class LoginRequest {
  final String identifier; // Email atau nomor HP
  final String password;
  final bool rememberMe;

  LoginRequest({
    required this.identifier,
    required this.password,
    this.rememberMe = false,
  });

  /// Convert LoginRequest object ke JSON untuk dikirim ke API
  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'password': password,
      'rememberMe': rememberMe,
    };
  }
}

/// Model untuk Google Login Request
class GoogleLoginRequest {
  final String idToken;
  final String accessToken;

  GoogleLoginRequest({required this.idToken, required this.accessToken});

  /// Convert GoogleLoginRequest object ke JSON untuk dikirim ke API
  Map<String, dynamic> toJson() {
    return {'idToken': idToken, 'accessToken': accessToken};
  }
}
