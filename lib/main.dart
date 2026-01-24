import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/api_config.dart';
import 'theme/theme.dart';
import 'pages/onboarding_screen.dart';
import 'pages/auth/login_screen.dart';
import 'pages/auth/forgot_password_screen.dart';
import 'pages/home/home_screen.dart';
import 'pages/home/notification_screen.dart';
import 'pages/modul/module_screen.dart';
import 'pages/modul/module_materials_list_screen.dart';
import 'pages/modul/material_poin_detail_screen.dart';
import 'pages/modul/quiz_screen.dart';
import 'pages/modul/quiz_question_screen.dart';
import 'pages/modul/quiz_result_screen.dart';
import 'pages/profile/profile_screen.dart';
import 'pages/profile/full_data_screen.dart';
import 'pages/profile/change_password_screen.dart';
import 'pages/profile/settings_screen.dart';
import 'services/storage_service.dart';

/// Main function - Entry point aplikasi
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase
  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bukadita Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.secondary,
          elevation: 0,
        ),
      ),
      // Initial route
      initialRoute: '/',
      // Routes
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/reset-password': (context) => const ForgotPasswordScreen(),
        '/user/beranda': (context) => const HomeScreen(),
        '/home': (context) => const HomeScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/user/profil': (context) => const ProfileScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/profile/full-data': (context) => const FullDataScreen(),
        '/profile/change-password': (context) => const ChangePasswordScreen(),
        '/profile/settings': (context) => const SettingsScreen(),
        '/modul': (context) => const ModulScreen(),
        '/modul-materials': (context) => const ModuleMaterialsListScreen(),
        '/material-poin-detail': (context) => const MaterialPoinDetailScreen(),
        '/quiz': (context) => const QuizScreen(),
        '/quiz-questions': (context) => const QuizQuestionScreen(),
        '/quiz-result': (context) => const QuizResultScreen(),
      },
    );
  }
}

/// Splash Screen - Check jika user sudah login
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// Check apakah user sudah login
  Future<void> _checkLoginStatus() async {
    // Tunggu sebentar untuk splash screen effect
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check login status
    final isLoggedIn = await _storageService.isLoggedIn();

    if (isLoggedIn) {
      // Sudah login, redirect ke home
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Belum login, check onboarding
      final hasSeenOnboarding = await _storageService.isOnboardingCompleted();

      if (hasSeenOnboarding) {
        // Sudah lihat onboarding, langsung ke login
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        // Belum lihat onboarding, tampilkan onboarding
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo/Icon Bukadita
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 16,
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
                        size: 50,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            Text(
              'Bukadita',
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),

            // Tagline
            Text(
              'Platform Belajar Digital',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 32),

            // Loading Indicator
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
