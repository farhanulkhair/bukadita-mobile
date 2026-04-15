import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../services/storage_service.dart';

/// Onboarding Screen - Halaman pengenalan aplikasi untuk user pertama kali
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final StorageService _storageService = StorageService();
  int _currentPage = 0;

  // Data onboarding slides
  final List<OnboardingData> _pages = [
    OnboardingData(
      icon: Icons.school_rounded,
      title: 'Belajar Kesehatan\nPosyandu',
      description:
          'Platform edukasi digital untuk meningkatkan pengetahuan kader dan masyarakat tentang kesehatan ibu dan anak',
      color: AppColors.blue600,
    ),
    OnboardingData(
      icon: Icons.menu_book_rounded,
      title: 'Modul Pembelajaran\nTerstruktur',
      description:
          'Akses berbagai modul pembelajaran lengkap dengan materi, video, dan kuis interaktif untuk pemahaman optimal',
      color: AppColors.green600,
    ),
    // OnboardingData(
    //   icon: Icons.workspace_premium_rounded,
    //   title: 'Raih Sertifikat\nKompetensi',
    //   description:
    //       'Selesaikan pembelajaran dan ujian untuk mendapatkan sertifikat kompetensi yang diakui',
    //   color: AppColors.orange600,
    // ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navigasi ke halaman berikutnya
  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  /// Lewati onboarding dan langsung ke login
  void _skipOnboarding() {
    _completeOnboarding();
  }

  /// Selesai onboarding, simpan status dan ke login
  Future<void> _completeOnboarding() async {
    // Simpan status bahwa user sudah melihat onboarding
    await _storageService.setOnboardingCompleted(true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            _buildSkipButton(),

            // Page view dengan slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_pages[index]);
                },
              ),
            ),

            // Page indicator
            _buildPageIndicator(),

            const SizedBox(height: 24),

            // Navigation buttons
            _buildNavigationButtons(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Build skip button di pojok kanan atas
  Widget _buildSkipButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 20, top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _skipOnboarding,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              backgroundColor: AppColors.gray100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'Lewati',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.gray600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build single onboarding page
  Widget _buildOnboardingPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon dengan gradient background
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  data.color.withOpacity(0.15),
                  data.color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: data.color.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: data.color.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.color.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 24,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: data.color.withOpacity(0.15),
                    ),
                  ),
                ),
                // Main icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [data.color, data.color.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: data.color.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(data.icon, size: 48, color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 36),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headingLarge.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 22,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.gray600,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Build page indicator (dots)
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient:
                _currentPage == index
                    ? LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    )
                    : null,
            color: _currentPage == index ? null : AppColors.gray300,
            borderRadius: BorderRadius.circular(4),
            boxShadow:
                _currentPage == index
                    ? [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
        ),
      ),
    );
  }

  /// Build navigation buttons (Selanjutnya/Mulai)
  Widget _buildNavigationButtons() {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          // Tombol Kembali (hanya muncul jika bukan halaman pertama)
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _pageController.animateToPage(
                    _currentPage - 1,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kembali',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),

          // Tombol Selanjutnya/Mulai
          Expanded(
            flex: _currentPage > 0 ? 1 : 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? 'Mulai Belajar' : 'Selanjutnya',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isLastPage
                          ? Icons.rocket_launch_rounded
                          : Icons.arrow_forward_rounded,
                      size: 20,
                      color: AppColors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Model untuk data onboarding
class OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
