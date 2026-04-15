import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/theme.dart';
import '../../layouts/app_layout.dart';
import '../../services/storage_service.dart';
import '../../services/module_service.dart';
import '../../services/progress_service.dart';
import '../../services/cache_service.dart';
import '../../services/notification_service.dart';

/// Home Screen dengan Resizable Navbar
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final PageController _carouselController = PageController();
  final PageController _sponsorCarouselController = PageController();
  final NotificationService _notifService = NotificationService();
  String _userName = 'Pengguna';
  int _currentCarouselPage = 0;
  int _currentSponsorPage = 0;
  List<Map<String, dynamic>> _featuredModules = [];
  bool _isLoadingModules = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFeaturedModules();
    _startSponsorAutoScroll();
    _backgroundRefreshIfStale();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await _notifService.init();
    _notifService.onNotificationTapped = () {
      if (mounted) Navigator.pushNamed(context, '/notifications');
    };
    _notifService.startPolling();
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      _loadUserData(),
      _loadFeaturedModules(forceRefresh: true),
    ]);
  }

  Future<void> _backgroundRefreshIfStale() async {
    final cache = CacheService();
    final freshness = await cache.freshness('modules_list_p1_l5');
    if (freshness == CacheFreshness.stale ||
        freshness == CacheFreshness.expired) {
      _loadFeaturedModules(forceRefresh: true);
    }
  }

  void _startSponsorAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;

      final totalPages = 2; // 6 logos / 3 per page = 2 pages
      if (_currentSponsorPage < totalPages - 1) {
        _sponsorCarouselController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _sponsorCarouselController.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }

      _startSponsorAutoScroll();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final storageService = StorageService();
      final userData = await storageService.getUserData();
      if (mounted && userData != null) {
        setState(() {
          _userName = userData.name ?? 'Pengguna';
        });
      }
    } catch (e) {
      // Silently fail
    }
  }

  Future<void> _loadFeaturedModules({bool forceRefresh = false}) async {
    try {
      final moduleService = ModuleService();
      final progressService = ProgressService();

      final modulesResult = await moduleService.getAllModules(
        limit: 5,
        page: 1,
        forceRefresh: forceRefresh,
      );
      final progressResult = await progressService.getModulesProgress(
        forceRefresh: forceRefresh,
      );

      if (modulesResult['success'] && mounted) {
        final items = modulesResult['data']['items'] as List;

        // Create map untuk cepat lookup progress by module ID
        Map<String, Map<String, dynamic>> progressMap = {};
        if (progressResult['success']) {
          final progressModules =
              progressResult['data']['modules'] as List? ?? [];
          for (var prog in progressModules) {
            progressMap[prog['module_id'].toString()] = prog;
          }
        }

        // Map icon based on module category or title
        final iconMap = {
          'Kesehatan Anak': Icons.child_care_outlined,
          'Kesehatan Ibu': Icons.pregnant_woman_outlined,
          'Nutrisi': Icons.restaurant_outlined,
          'Imunisasi': Icons.vaccines_outlined,
          'Kesehatan Lansia': Icons.elderly_outlined,
          'Posyandu': Icons.school_outlined,
        };

        final colorMap = [
          AppColors.primary,
          AppColors.secondary,
          AppColors.green600,
        ];

        setState(() {
          _featuredModules =
              items.asMap().entries.map((entry) {
                final index = entry.key;
                final module = entry.value;
                final category = module['category'] ?? '';
                final moduleId = module['id'].toString();

                // Get progress dari progressMap
                final progress = progressMap[moduleId];
                final progressPercent =
                    progress != null
                        ? (progress['progress_percentage'] as num?)
                                ?.toDouble() ??
                            0.0
                        : 0.0;

                // Find icon based on category or use default
                IconData icon = Icons.school_outlined;
                for (var key in iconMap.keys) {
                  if (category.contains(key)) {
                    icon = iconMap[key]!;
                    break;
                  }
                }

                return {
                  'id': module['id'],
                  'title': module['title'],
                  'icon': icon,
                  'color': colorMap[index % colorMap.length],
                  'slug': module['slug'],
                  'category': category,
                  'progress':
                      progressPercent, // Progress percentage 0-100 from API
                };
              }).toList();
          _isLoadingModules = false;
        });
      } else {
        // Fallback to empty if API fails
        if (mounted) {
          setState(() {
            _isLoadingModules = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingModules = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _carouselController.dispose();
    _sponsorCarouselController.dispose();
    _notifService.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 0, // Home
      child: Scaffold(
        backgroundColor: AppColors.background,
        // App Bar Sederhana di Top
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
          title: Row(
            children: [
              SvgPicture.asset(
                'assets/logo/logo_bukadita.svg',
                height: 32,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                'Bukadita',
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            ValueListenableBuilder<int>(
              valueListenable: _notifService.unreadCount,
              builder: (context, count, _) {
                return IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                      ),
                      if (count > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.white, width: 1.5),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () async {
                    await Navigator.pushNamed(context, '/notifications');
                    _notifService.refreshCount();
                  },
                );
              },
            ),
          ],
        ),
        // Main Content
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeroSection()),
              SliverToBoxAdapter(child: _buildFeaturedModules()),
              SliverToBoxAdapter(child: _buildContentSections()),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Stack(
        children: [
          // Background card with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('👋', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        'Selamat Datang',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // User Name
                Text(
                  _userName,
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Description
                Container(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    'Platform pembelajaran digital untuk meningkatkan kompetensi Anda. Mari bersama membangun Indonesia yang lebih sehat!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withOpacity(0.95),
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // CTA Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/modul');
                    },
                    icon: Icon(Icons.menu_book_rounded, size: 18),
                    label: const Text('Jelajahi Modul Pembelajaran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.primary,
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: AppTextStyles.button.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Decorative circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 40,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedModules() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Icon with gradient background
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.library_books_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modul Pembelajaran',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pilih modul untuk memulai belajar',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.gray500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _isLoadingModules
              ? Container(
                height: 200,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Memuat modul...',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                ),
              )
              : _featuredModules.isEmpty
              ? Container(
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gray200, width: 1.5),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.gray200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.library_books_outlined,
                          size: 48,
                          color: AppColors.gray400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada modul tersedia',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Modul akan segera ditambahkan',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _featuredModules.length,
                  itemBuilder: (context, index) {
                    final module = _featuredModules[index];
                    return _buildModuleCard(
                      title: module['title'],
                      icon: module['icon'],
                      color: module['color'],
                      progress: (module['progress'] as num?)?.toDouble() ?? 0.0,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/modul-materials',
                          arguments: {
                            'moduleId': module['id'],
                            'moduleTitle': module['title'],
                          },
                        );
                      },
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required IconData icon,
    required Color color,
    required double progress,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container with gradient
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),

            // Title
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.3,
                    color: AppColors.gray800,
                  ),
                ),
              ),
            ),

            // Progress section
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.gray500,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${progress.toInt()}%',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress Bar
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSections() {
    return Column(
      children: [
        // ILP Posyandu Section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Section Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.08),
                      AppColors.secondary.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.local_hospital_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Integrasi Layanan Primer',
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Transformasi kesehatan menyeluruh',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.gray600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildILPCard(
                title: 'Apa itu ILP?',
                description:
                    'Integrasi Layanan Primer (ILP) adalah penataan dan penguatan pelayanan kesehatan primer secara terpadu dengan pendekatan siklus hidup.\n\n'
                    'ILP mencakup layanan promotif, preventif, kuratif, dan rehabilitatif di fasilitas kesehatan tingkat pertama, dengan tujuan agar layanan kesehatan lebih:\n'
                    '• Terjangkau\n'
                    '• Komprehensif\n'
                    '• Terkoordinasi\n'
                    '• Berkesinambungan',
                tags: ['REFERENSI: KMK No. HK.01.07/MENKES/2015/2023'],
                icon: Icons.info_outline_rounded,
                cardColor: AppColors.white,
                borderColor: AppColors.primary.withOpacity(0.15),
              ),
              const SizedBox(height: 16),
              _buildILPCard(
                title: 'ILP Posyandu',
                description:
                    'ILP Posyandu adalah transformasi posyandu dari yang sebelumnya hanya fokus pada ibu dan balita menjadi layanan kesehatan untuk seluruh siklus hidup.\n\n'
                    'Dengan ILP, posyandu kini melayani semua kelompok usia untuk menciptakan masyarakat yang lebih sehat.',
                tags: [
                  'Ibu Hamil & Menyusui',
                  'Bayi & Balita',
                  'Anak Sekolah',
                  'Remaja',
                  'Usia Produktif',
                  'Lansia',
                ],
                cardColor: AppColors.white,
                borderColor: AppColors.secondary.withOpacity(0.15),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        // 25 Kompetensi Dasar Section
        _buildKompetensiCard(),

        const SizedBox(height: 40),
        // Galeri Posyandu Section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gallery Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.green600.withOpacity(0.08),
                      AppColors.blue600.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.green600.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.green600, AppColors.blue600],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green600.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.photo_library_rounded,
                        color: AppColors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Galeri Posyandu',
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Seulanga Indah',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.green600,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildPhotoCarousel(),
              const SizedBox(height: 32),
              _buildSponsorMarquee(),
            ],
          ),
        ),
      ],
    );
  }

  // Reusable ILP Card Component
  Widget _buildILPCard({
    required String title,
    required String description,
    List<String>? tags,
    IconData? icon,
    Color? cardColor,
    Color? borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor ?? AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            borderColor != null
                ? Border.all(color: borderColor, width: 1.5)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.12),
                      AppColors.secondary.withOpacity(0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon ?? Icons.groups_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Description/Content
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.gray600,
              height: 1.7,
              fontSize: 14,
            ),
          ),
          // Tags (optional)
          if (tags != null && tags.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children:
                  tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.1),
                            AppColors.secondary.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // 25 Kompetensi Dasar Card
  Widget _buildKompetensiCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text('🎓', style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '25 Kompetensi Dasar\nKader Posyandu',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Kemenkes menetapkan 25 kompetensi dasar kader posyandu dan melaksanakan pelatihan nasional untuk memperkuat kemampuan kader dalam mendukung upaya promotif dan preventif, sehingga derajat kesehatan masyarakat dapat meningkat.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.white.withOpacity(0.95),
                    height: 1.7,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          'https://ayosehat.kemkes.go.id/integrasi-layanan-primer-melalui-posyandu';
                        },
                        icon: Icon(Icons.open_in_new, size: 18),
                        label: const Text('Selengkapnya di AyoSehat'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: BorderSide(color: AppColors.white, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Show reference document
                  },
                  icon: Icon(Icons.article_outlined, size: 18),
                  label: const Text('Referensi Kementerian Kesehatan RI'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: BorderSide(
                      color: AppColors.white.withOpacity(0.6),
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Photo Carousel for Galeri Posyandu
  Widget _buildPhotoCarousel() {
    // TODO: Replace with actual photo paths from assets folder
    // Example: 'assets/gallery/posyandu_1.jpg', 'assets/gallery/posyandu_2.jpg', etc.
    final photos = [
      'assets/gallery/foto-1.jpg',
      'assets/gallery/foto-2.jpg',
      'assets/gallery/foto-3.jpg',
      'assets/gallery/foto-4.jpg',
      'assets/gallery/foto-5.jpg',
      'assets/gallery/foto-6.jpg',
    ];

    return Column(
      children: [
        Container(
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PageView.builder(
            controller: _carouselController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselPage = index;
              });
            },
            physics: const BouncingScrollPhysics(),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.15),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image with error handling
                      Image.asset(
                        photos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback when image fails to load
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.green600.withOpacity(0.12),
                                  AppColors.blue600.withOpacity(0.12),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.green600.withOpacity(
                                          0.2,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.camera_alt_rounded,
                                    size: 48,
                                    color: AppColors.green600,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'Foto ${index + 1}',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.green600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Gradient overlay for better caption readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.4),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Carousel Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            photos.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentCarouselPage == index ? 32 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient:
                    _currentCarouselPage == index
                        ? LinearGradient(
                          colors: [AppColors.green600, AppColors.blue600],
                        )
                        : null,
                color: _currentCarouselPage != index ? AppColors.gray300 : null,
                borderRadius: BorderRadius.circular(4),
                boxShadow:
                    _currentCarouselPage == index
                        ? [
                          BoxShadow(
                            color: AppColors.green600.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Sponsor Carousel - Show 3 logos at a time
  Widget _buildSponsorMarquee() {
    final sponsorLogos = [
      'assets/logo/logo_banda_aceh.png',
      'assets/logo/logo_diktisaintek_berdampak.png',
      'assets/logo/logo_kemenkes.png',
      'assets/logo/logo_lppm_usk.png',
      'assets/logo/logo_pk3kkn_usk.jpg',
      'assets/logo/logo_usk.png',
    ];

    // Group logos into pages of 3
    final List<List<String>> logoPages = [];
    for (var i = 0; i < sponsorLogos.length; i += 3) {
      logoPages.add(
        sponsorLogos.sublist(
          i,
          i + 3 > sponsorLogos.length ? sponsorLogos.length : i + 3,
        ),
      );
    }

    return Column(
      children: [
        // Sponsor header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.gray50,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gray200, width: 1),
          ),
          child: Text(
            'DIDUKUNG OLEH',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.gray600,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 130,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray200, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PageView.builder(
            controller: _sponsorCarouselController,
            onPageChanged: (index) {
              setState(() {
                _currentSponsorPage = index;
              });
            },
            physics: const BouncingScrollPhysics(),
            itemCount: logoPages.length,
            itemBuilder: (context, pageIndex) {
              final logosInPage = logoPages[pageIndex];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children:
                      logosInPage.map((logoPath) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.gray50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.gray200,
                                width: 1,
                              ),
                            ),
                            child: Image.asset(
                              logoPath,
                              height: 50,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.business_rounded,
                                  size: 40,
                                  color: AppColors.gray400,
                                );
                              },
                            ),
                          ),
                        );
                      }).toList(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Carousel Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            logoPages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentSponsorPage == index ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                gradient:
                    _currentSponsorPage == index
                        ? LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        )
                        : null,
                color: _currentSponsorPage != index ? AppColors.gray300 : null,
                borderRadius: BorderRadius.circular(4),
                boxShadow:
                    _currentSponsorPage == index
                        ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
