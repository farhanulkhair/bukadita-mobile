/// Model untuk request forgot/reset password
class ForgotPasswordRequest {
  final String identifier; // Email atau nomor HP
  final String newPassword;

  ForgotPasswordRequest({required this.identifier, required this.newPassword});

  /// Convert to JSON untuk dikirim ke API
  Map<String, dynamic> toJson() {
    return {'identifier': identifier, 'new_password': newPassword};
  }
}
