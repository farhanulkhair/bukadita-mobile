import 'package:email_validator/email_validator.dart';

/// Validators untuk form input
class Validators {
  /// Validate identifier (email atau nomor HP)
  static String? validateIdentifier(String? value) {
    // Trim whitespace
    final trimmedValue = value?.trim() ?? '';

    // Check if empty
    if (trimmedValue.isEmpty) {
      return 'Email atau Nomor HP wajib diisi';
    }

    // Check email format
    final isValidEmail = EmailValidator.validate(trimmedValue);

    // Check phone format (Indonesia)
    // Format: 08xxxxxxxx, 62xxxxxxxx, atau +62xxxxxxxx
    final phoneRegex = RegExp(r'^(08|62|\+62)[0-9]{8,12}$');
    final isValidPhone = phoneRegex.hasMatch(trimmedValue);

    // Harus valid sebagai email ATAU phone
    if (!isValidEmail && !isValidPhone) {
      return 'Format email atau nomor HP tidak valid';
    }

    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    // Check if empty
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }

    // Check minimum length
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }

    return null;
  }

  /// Validate email only
  static String? validateEmail(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Email wajib diisi';
    }

    if (!EmailValidator.validate(trimmedValue)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  /// Validate phone only
  static String? validatePhone(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Nomor HP wajib diisi';
    }

    final phoneRegex = RegExp(r'^(08|62|\+62)[0-9]{8,12}$');
    if (!phoneRegex.hasMatch(trimmedValue)) {
      return 'Format nomor HP tidak valid';
    }

    return null;
  }

  /// Validate nama
  static String? validateName(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return 'Nama wajib diisi';
    }

    if (trimmedValue.length < 3) {
      return 'Nama minimal 3 karakter';
    }

    return null;
  }
}
