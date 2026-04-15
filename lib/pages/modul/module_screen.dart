import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/theme.dart';
import '../../layouts/app_layout.dart';
import '../../services/module_service.dart';
import '../../services/progress_service.dart';
import '../../services/cache_service.dart';
import '../../services/notification_service.dart';
import '../../components/modul/module_card.dart';

/// Modul Screen - Halaman daftar modul pembelajaran
class ModulScreen extends StatefulWidget {
  const ModulScreen({super.key});

  @override
  State<ModulScreen> createState() => _ModulScreenState();
}

class _ModulScreenState extends State<ModulScreen> {
  final ModuleService _moduleService = ModuleService();
  final ProgressService _progressService = ProgressService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allModules = [];
  List<Map<String, dynamic>> _filteredModules = [];
  List<String> _categories = ['Semua Kategori'];
  String _selectedCategory = 'Semua Kategori';
  String?
  _selectedStatus; // null = semua, 'completed', 'in-progress', 'not-started'
  bool _isLoading = true;
  String _greeting = '';

  // Stats
  int _completedCount = 0;
  int _inProgressCount = 0;
  int _notStartedCount = 0;

  @override
  void initState() {
    super.initState();
    _setGreeting();
    _loadModules();
    _backgroundRefreshIfStale();
  }

  Future<void> _onRefresh() async {
    await _loadModules(forceRefresh: true);
  }

  Future<void> _backgroundRefreshIfStale() async {
    final cache = CacheService();
    final freshness = await cache.freshness('modules_list_p1_l100');
    if (freshness == CacheFreshness.stale ||
        freshness == CacheFreshness.expired) {
      _loadModules(forceRefresh: true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      _greeting = 'Selamat pagi';
    } else if (hour < 15) {
      _greeting = 'Selamat siang';
    } else if (hour < 18) {
      _greeting = 'Selamat sore';
    } else {
      _greeting = 'Selamat malam';
    }
  }

  Future<void> _loadModules({bool forceRefresh = false}) async {
    if (_allModules.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final modulesResult = await _moduleService.getAllModules(
        limit: 100,
        forceRefresh: forceRefresh,
      );
      final progressResult = await _progressService.getModulesProgress(
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

        // Process modules and get material counts
        List<Map<String, dynamic>> processedModules = [];

        for (var module in items) {
          final moduleId = module['id'].toString();
          final progress = progressMap[moduleId];
          final progressPercent =
              progress != null
                  ? (progress['progress_percentage'] as num?)?.toDouble() ?? 0.0
                  : 0.0;

          // Determine status based on progress
          String status = 'not-started';
          if (progressPercent >= 100) {
            status = 'completed';
          } else if (progressPercent > 0) {
            status = 'in-progress';
          }

          // Get actual materials count from API
          int lessonsCount = 0;
          try {
            final materialsResult = await _moduleService.getMaterialsByModule(
              moduleId,
              limit: 1000,
            );

            if (materialsResult['success']) {
              final materialsData = materialsResult['data'];
              if (materialsData is Map && materialsData.containsKey('items')) {
                lessonsCount = (materialsData['items'] as List).length;
              } else if (materialsData is List) {
                lessonsCount = materialsData.length;
              }
            }
          } catch (e) {
            // Fallback: try to get from module data
            if (module['sub_materi_count'] != null) {
              lessonsCount =
                  module['sub_materi_count'] is int
                      ? module['sub_materi_count']
                      : int.tryParse(module['sub_materi_count'].toString()) ??
                          0;
            } else if (module['total_sub_materis'] != null) {
              lessonsCount =
                  module['total_sub_materis'] is int
                      ? module['total_sub_materis']
                      : int.tryParse(module['total_sub_materis'].toString()) ??
                          0;
            }
          }

          // Duration dari API, atau hitung dari jumlah sub materi
          String duration =
              module['duration_label'] ?? module['duration'] ?? '';

          // Jika duration kosong, estimasi dari jumlah sub materi
          // Asumsi: setiap sub materi = 1-2 minggu
          if (duration.isEmpty && lessonsCount > 0) {
            final weeks = lessonsCount * 2; // 2 minggu per sub materi
            duration = '$weeks minggu';
          }

          processedModules.add({
            'id': module['id'],
            'title': module['title'],
            'slug': module['slug'],
            'category': module['category'] ?? 'Umum',
            'lessons': lessonsCount,
            'duration': duration.isNotEmpty ? duration : '4-6 minggu',
            'progress': progressPercent,
            'status': status,
          });
        }

        setState(() {
          _allModules = processedModules;
          _filteredModules = List.from(_allModules);
          _calculateStats();
          _extractCategories();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats() {
    _completedCount =
        _allModules.where((m) => m['status'] == 'completed').length;
    _inProgressCount =
        _allModules.where((m) => m['status'] == 'in-progress').length;
    _notStartedCount =
        _allModules.where((m) => m['status'] == 'not-started').length;
  }

  void _extractCategories() {
    // Extract unique categories from modules
    final uniqueCategories = <String>{};
    for (var module in _allModules) {
      final category = module['category']?.toString().trim() ?? '';
      if (category.isNotEmpty) {
        uniqueCategories.add(category);
      }
    }

    setState(() {
      _categories = ['Semua Kategori', ...uniqueCategories.toList()..sort()];
    });
  }

  void _filterModules(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  void _filterByStatus(String? status) {
    setState(() {
      // Toggle: jika klik yang sama, reset ke null (tampilkan semua)
      if (_selectedStatus == status) {
        _selectedStatus = null;
      } else {
        _selectedStatus = status;
      }
      _applyFilters();
    });
  }

  void _applyFilters() {
    // Start dengan semua modules
    List<Map<String, dynamic>> filtered = List.from(_allModules);

    // Filter by category
    if (_selectedCategory != 'Semua Kategori') {
      filtered =
          filtered
              .where(
                (m) =>
                    m['category']?.toString().toLowerCase() ==
                    _selectedCategory.toLowerCase(),
              )
              .toList();
    }

    // Filter by status
    if (_selectedStatus != null) {
      filtered = filtered.where((m) => m['status'] == _selectedStatus).toList();
    }

    setState(() {
      _filteredModules = filtered;
      _applySearch();
    });
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _filteredModules =
          _filteredModules
              .where((m) => m['title'].toString().toLowerCase().contains(query))
              .toList();
    });
  }

  Color _getProgressColor(double progress) {
    if (progress >= 100) {
      return AppColors.green600; // Hijau untuk complete
    } else if (progress >= 50) {
      return AppColors.blue600; // Biru untuk setengah
    } else {
      return AppColors.red600; // Merah untuk baru mulai
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dateString =
        '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]} ${now.year}';

    return AppLayout(
      currentIndex: 1, // Modul
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
              valueListenable: NotificationService().unreadCount,
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
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
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
                    NotificationService().refreshCount();
                  },
                );
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
            // Date and Time Card
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.white.withOpacity(0.3),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              color: AppColors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _greeting,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.white.withOpacity(0.9),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  dateString,
                                  style: AppTextStyles.headingSmall.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Decorative circles
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.08),
                            AppColors.secondary.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.school_rounded,
                              color: AppColors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Semua Modul',
                                  style: AppTextStyles.heading.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total ${_allModules.length} modul pembelajaran',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.gray600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Stats Cards
                    Row(
                      children: [
                        _buildStatCard(
                          '$_completedCount',
                          'Modul\nSelesai',
                          AppColors.green600,
                          'completed',
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          '$_inProgressCount',
                          'Sedang\nBelajar',
                          AppColors.blue600,
                          'in-progress',
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          '$_notStartedCount',
                          'Belum\nDimulai',
                          AppColors.red600,
                          'not-started',
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.gray200,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => _applySearch(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gray800,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Cari modul pembelajaran...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.gray400,
                            fontSize: 14,
                          ),
                          prefixIcon: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          suffixIcon:
                              _searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: AppColors.gray400,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                      _applySearch();
                                    },
                                  )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children:
                            _categories.map((category) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _buildFilterChip(category),
                              );
                            }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Modules List
                    if (_isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (_filteredModules.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: AppColors.gray400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tidak ada modul ditemukan',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredModules.length,
                        itemBuilder: (context, index) {
                          final module = _filteredModules[index];
                          final progress = module['progress'] as double;
                          return ModuleCard(
                            id: module['id'],
                            title: module['title'],
                            category: module['category'],
                            lessonsCount: module['lessons'],
                            duration: module['duration'],
                            progressPercent: progress,
                            status: module['status'],
                            primaryColor: _getProgressColor(progress),
                            onTap: () async {
                              // Load module detail dan navigasi ke materi pertama
                              final result = await _moduleService
                                  .getModuleDetail(module['id']);

                              if (result['success'] && mounted) {
                                final data = result['data'];
                                final subMateris =
                                    (data['subMateris'] as List? ?? [])
                                        .map((m) => m as Map<String, dynamic>)
                                        .toList();

                                if (subMateris.isNotEmpty) {
                                  // Navigate ke materials list
                                  Navigator.pushNamed(
                                    context,
                                    '/modul-materials',
                                    arguments: {
                                      'moduleId': module['id'],
                                      'moduleTitle': module['title'],
                                    },
                                  ).then((_) => _loadModules());
                                } else {
                                  // Tidak ada materi
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Modul ini belum memiliki materi',
                                      ),
                                      backgroundColor: AppColors.orange600,
                                    ),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['message'] ?? 'Gagal memuat modul',
                                    ),
                                    backgroundColor: AppColors.red600,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    Color color,
    String status,
  ) {
    final isSelected = _selectedStatus == status;
    return Expanded(
      child: GestureDetector(
        onTap: () => _filterByStatus(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isSelected
                      ? [color.withOpacity(0.25), color.withOpacity(0.15)]
                      : [color.withOpacity(0.12), color.withOpacity(0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.25),
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isSelected ? 0.25 : 0.15),
                blurRadius: isSelected ? 12 : 8,
                offset: Offset(0, isSelected ? 4 : 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(isSelected ? 0.25 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  value,
                  style: AppTextStyles.headingLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
              if (isSelected) ...[
                const SizedBox(height: 4),
                Icon(Icons.check_circle, size: 14, color: color),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => _filterModules(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  )
                  : null,
          color: isSelected ? null : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.gray300,
            width: 1.5,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.white : AppColors.gray700,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
