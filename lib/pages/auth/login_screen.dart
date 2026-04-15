import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/error_alert.dart';
import '../../models/login_request.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../utils/error_helper.dart';

/// Halaman Login BukaDita
/// Halaman untuk login dengan email/phone & password
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Form Key
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  // Services
  final _authService = AuthService();

  // State Variables
  bool _isLoading = false;
  String? _generalError;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _authService.dispose();
    super.dispose();
  }

  /// Handle Login dengan Email/Phone dan Password
  Future<void> _handleLogin() async {
    // Clear error sebelumnya
    setState(() {
      _generalError = null;
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
      final request = LoginRequest(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      // Panggil API login
      final response = await _authService.login(request);

      // Handle response
      if (response.success && response.data != null) {
        // Login berhasil
        if (!mounted) return;

        // Check pendingProfile
        if (response.pendingProfile == true) {
          // Navigate ke pengaturan untuk melengkapi profil
          Navigator.pushReplacementNamed(
            context,
            '/user/pengaturan',
            arguments: {'complete': true},
          );
        } else {
          // Navigate ke beranda
          Navigator.pushReplacementNamed(context, '/user/beranda');
        }
      } else {
        // Login gagal
        setState(() {
          _generalError = response.error ??
              response.message ??
              'Login gagal, silakan coba lagi';
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
                              const SizedBox(height: 16),

                              // ===== FORGOT PASSWORD =====
                              _buildForgotPassword(),
                              const SizedBox(height: 28),

                              // ===== LOGIN BUTTON =====
                              GradientButton(
                                text: 'Masuk',
                                onPressed: _handleLogin,
                                isLoading: _isLoading,
                              ),
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
              Navigator.pushReplacementNamed(context, '/onboarding');
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
        // Logo Container dengan Gradient
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/icon/icon-72x72.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.book_rounded,
                    color: AppColors.white,
                    size: 48,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Judul
        Text(
          'Masuk ke Akun',
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
          'Selamat datang kembali di Bukadita',
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
          hint: 'Masukkan email atau nomor HP Anda',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          validator: Validators.validateIdentifier,
          onChanged: (_) {
            // Clear error saat user mengetik
            if (_generalError != null) {
              setState(() {
                _generalError = null;
              });
            }
          },
        ),
        const SizedBox(height: 20),

        // Password Field
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Masukkan password Anda',
          prefixIcon: LucideIcons.lock,
          isPassword: true,
          validator: Validators.validatePassword,
          onChanged: (_) {
            // Clear error saat user mengetik
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

  /// Build Forgot Password Link
  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/reset-password');
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Text(
            'Lupa password?',
            style: AppTextStyles.linkMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
