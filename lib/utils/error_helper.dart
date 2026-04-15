/// Translates common English API messages to user-friendly Indonesian.
/// Falls back to the original message if no translation is found.
String translateApiMessage(String message) {
  final msg = message.toLowerCase().trim();

  // Auth / credentials
  if (msg.contains('invalid credential') ||
      msg.contains('invalid email or password') ||
      msg.contains('wrong password') ||
      msg.contains('incorrect password')) {
    return 'Email/No. HP atau password salah. Silakan coba lagi.';
  }
  if (msg.contains('user not found') ||
      msg.contains('account not found') ||
      msg.contains('email not found')) {
    return 'Akun tidak ditemukan. Periksa email atau nomor HP Anda.';
  }
  if (msg.contains('account locked') || msg.contains('account disabled')) {
    return 'Akun Anda dinonaktifkan. Hubungi admin untuk bantuan.';
  }
  if (msg.contains('too many attempts') ||
      msg.contains('too many requests') ||
      msg.contains('rate limit')) {
    return 'Terlalu banyak percobaan. Silakan tunggu beberapa saat.';
  }
  if (msg.contains('token expired') || msg.contains('token invalid')) {
    return 'Sesi Anda telah berakhir. Silakan login kembali.';
  }
  if (msg.contains('unauthorized') || msg.contains('not authenticated')) {
    return 'Sesi Anda telah berakhir. Silakan login kembali.';
  }

  // Validation
  if (msg.contains('required') && msg.contains('field')) {
    return 'Harap lengkapi semua data yang diperlukan.';
  }
  if (msg.contains('already exists') || msg.contains('duplicate')) {
    return 'Data sudah ada. Silakan gunakan data lain.';
  }
  if (msg.contains('email already') || msg.contains('phone already')) {
    return 'Email atau nomor HP sudah terdaftar.';
  }
  if (msg.contains('password') && msg.contains('short')) {
    return 'Password terlalu pendek. Minimal 6 karakter.';
  }
  if (msg.contains('invalid email')) {
    return 'Format email tidak valid.';
  }

  // Not found
  if (msg.contains('not found')) {
    return 'Data tidak ditemukan.';
  }

  // Server
  if (msg.contains('internal server error')) {
    return 'Terjadi kesalahan pada server. Silakan coba lagi nanti.';
  }
  if (msg.contains('service unavailable') || msg.contains('maintenance')) {
    return 'Server sedang dalam pemeliharaan. Silakan coba lagi nanti.';
  }

  // If already in Indonesian or no match, return as-is
  return message;
}

/// Converts raw exceptions into user-friendly Indonesian error messages.
String friendlyErrorMessage(Object e) {
  final raw = e.toString();
  final msg = raw.toLowerCase();

  // Network / connectivity
  if (msg.contains('host lookup') ||
      msg.contains('socketexception') ||
      msg.contains('no address associated') ||
      msg.contains('network is unreachable') ||
      msg.contains('connection refused') ||
      msg.contains('clientexception')) {
    return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
  }

  // Timeout
  if (msg.contains('timeout') || msg.contains('timed out')) {
    return 'Server tidak merespon. Silakan coba lagi nanti.';
  }

  // SSL / certificate
  if (msg.contains('certificate') ||
      msg.contains('handshake') ||
      msg.contains('ssl')) {
    return 'Koneksi tidak aman. Periksa tanggal & waktu perangkat Anda.';
  }

  // Format / parsing (truly technical)
  if (msg.contains('formatexception') ||
      msg.contains('type \'') ||
      msg.contains('is not a subtype')) {
    return 'Terjadi kesalahan saat memproses data. Silakan coba lagi.';
  }

  // Strip Dart exception prefixes
  final cleaned = raw
      .replaceFirst(RegExp(r'^(Exception|ApiException):\s*'), '')
      .trim();

  // If we have a clean message, try translating it
  if (cleaned.isNotEmpty) {
    return translateApiMessage(cleaned);
  }

  // Generic fallback
  return 'Terjadi kesalahan. Silakan coba lagi nanti.';
}
