import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/error_alert.dart';
import '../../models/forgot_password_request.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../utils/error_helper.dart';

/// Halaman Reset/Lupa Password BukaDita
/// User memasukkan email/phone dan password baru untuk reset password
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Form Key
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _identifierController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Services
  final _authService = AuthService();

  // State Variables
  bool _isLoading = false;
  String? _generalError;
  String? _successMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _authService.dispose();
    super.dispose();
  }

  /// Validasi confirm password
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != _newPasswordController.text) {
      return 'Password tidak sama';
    }
    return null;
  }

  /// Handle Reset Password
  Future<void> _handleResetPassword() async {
    // Clear messages
    setState(() {
      _generalError = null;
      _successMessage = null;
      _isLoading = true;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      // Buat request
      final request = ForgotPasswordRequest(
        identifier: _identifierController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      // Panggil API reset password
      final response = await _authService.resetPassword(request);

      if (!mounted) return;

      // Handle response
      if (response['success'] == true) {
        // Reset berhasil
        setState(() {
          _successMessage =
              response['message'] ??
              'Password berhasil diubah! Silakan login dengan password baru';
        });

        // Tunggu 2 detik lalu kembali ke login
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;

        Navigator.pop(context);
      } else {
        // Reset gagal
        setState(() {
          _generalError =
              response['error'] ??
              'Reset password gagal. Pastikan email/nomor HP terdaftar';
        });
      }
    } catch (e) {
      setState(() {
        _generalError = friendlyErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 24.0 : 40.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // ===== HEADER SECTION =====
                        _buildHeader(),
                        const SizedBox(height: 40),

                        // ===== FORM CARD =====
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gray500.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            children: [
                              // ===== SUCCESS MESSAGE (Conditional) =====
                              if (_successMessage != null) ...[
                                _buildSuccessAlert(),
                                const SizedBox(height: 20),
                              ],

                              // ===== ERROR ALERT (Conditional) =====
                              if (_generalError != null) ...[
                                ErrorAlert(
                                  message: _generalError!,
                                  onDismiss: () {
                                    setState(() {
                                      _generalError = null;
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                              ],

                              // ===== FORM FIELDS =====
                              _buildForm(),
                              const SizedBox(height: 28),

                              // ===== RESET PASSWORD BUTTON =====
                              GradientButton(
                                text: 'Ubah Password',
                                onPressed: _handleResetPassword,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 16),

                              // ===== BACK TO LOGIN =====
                              _buildBackToLogin(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ===== BACK BUTTON =====
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  /// Build Back Button
  Widget _buildBackButton() {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray500.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(
                LucideIcons.arrowLeft,
                color: AppColors.gray800,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build Header Section
  Widget _buildHeader() {
    return Column(
      children: [
        // Icon Container
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.blue50,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            LucideIcons.lockKeyhole,
            color: AppColors.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),

        // Judul
        Text(
          'Lupa Password',
          style: AppTextStyles.heading.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.gray800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Masukkan email/nomor HP dan password baru Anda',
          style: AppTextStyles.subheading.copyWith(
            fontSize: 15,
            color: AppColors.gray500,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build Form Fields
  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email atau Nomor HP Field
        CustomTextField(
          controller: _identifierController,
          label: 'Email atau Nomor HP',
          hint: 'Masukkan email atau nomor HP terdaftar',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateIdentifier,
          onChanged: (_) {
            if (_generalError != null) {
              setState(() {
                _generalError = null;
              });
            }
          },
        ),
        const SizedBox(height: 20),

        // Password Baru Field
        CustomTextField(
          controller: _newPasswordController,
          label: 'Password Baru',
          hint: 'Masukkan password baru',
          prefixIcon: LucideIcons.lock,
          isPassword: true,
          validator: Validators.validatePassword,
          onChanged: (_) {
            if (_generalError != null) {
              setState(() {
                _generalError = null;
              });
            }
          },
        ),
        const SizedBox(height: 20),

        // Konfirmasi Password Field
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Konfirmasi Password Baru',
          hint: 'Masukkan ulang password baru',
          prefixIcon: LucideIcons.lockKeyhole,
          isPassword: true,
          validator: _validateConfirmPassword,
          onChanged: (_) {
            if (_generalError != null) {
              setState(() {
                _generalError = null;
              });
            }
          },
        ),
      ],
    );
  }

  /// Build Success Alert
  Widget _buildSuccessAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.green500, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.green600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _successMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.green700,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build Back to Login Link
  Widget _buildBackToLogin() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sudah ingat password? ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gray600,
            fontSize: 14,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Text(
              'Masuk',
              style: AppTextStyles.linkMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
