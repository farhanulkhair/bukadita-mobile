/// Constants untuk aplikasi BukaDita
/// Storage keys, route names, dan konstanta lainnya
class AppConstants {
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String rememberMeKey = 'remember_me';

  // Route Names
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String resetPasswordRoute = '/reset-password';
  static const String homeRoute = '/user/beranda';
  static const String profilRoute = '/user/profil';

  // API Response Messages
  static const String successMessage = 'Login berhasil';
  static const String errorMessage = 'Terjadi kesalahan';
  static const String networkErrorMessage = 'Tidak ada koneksi internet';
  static const String timeoutErrorMessage =
      'Request timeout, silakan coba lagi';

  // Validation Messages
  static const String requiredFieldMessage = 'Field ini wajib diisi';
  static const String invalidEmailMessage = 'Format email tidak valid';
  static const String invalidPhoneMessage = 'Format nomor HP tidak valid';
  static const String invalidPasswordMessage = 'Password minimal 6 karakter';
}
