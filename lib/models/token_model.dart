/// Model untuk Token yang diterima dari API
class TokenModel {
  final String accessToken;
  final String refreshToken;
  final dynamic expiresAt; // bisa int, string, atau null

  TokenModel({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  /// Convert dari JSON response ke TokenModel object
  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      // Support both camelCase and snake_case
      accessToken: json['accessToken'] ?? json['access_token'] ?? '',
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
      expiresAt: json['expiresAt'] ?? json['expires_at'],
    );
  }

  /// Convert dari TokenModel object ke JSON
  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt,
    };
  }
}
