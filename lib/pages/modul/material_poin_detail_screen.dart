import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../../theme/theme.dart';
import '../../services/module_service.dart';
import '../../services/progress_service.dart';
import '../../services/quiz_service.dart';

/// Material Poin Detail Screen dengan fitur:
/// - Langsung tampil konten (bukan list poin)
/// - Auto navigate ke last accessed poin
/// - Scroll detection untuk mark as complete
/// - Tombol "Daftar Isi" untuk lihat semua poin
class MaterialPoinDetailScreen extends StatefulWidget {
  const MaterialPoinDetailScreen({super.key});

  // Simple cache (static at widget level for access from other files)
  static final Map<String, Map<String, dynamic>> _materialCache = {};

  // Static method to clear cache for a specific material (call after quiz completion)
  static void clearCache(String materialId) {
    _materialCache.remove(materialId);
  }

  // Clear all cache
  static void clearAllCache() {
    _materialCache.clear();
  }

  @override
  State<MaterialPoinDetailScreen> createState() =>
      _MaterialPoinDetailScreenState();
}

class _MaterialPoinDetailScreenState extends State<MaterialPoinDetailScreen> {
  final ModuleService _moduleService = ModuleService();
  final ProgressService _progressService = ProgressService();
  final QuizService _quizService = QuizService();
  final ScrollController _scrollController = ScrollController();
  late PageController _pageController;

  bool _isLoading = true;
  bool _hasScrolledToBottom = false;
  bool _canProceed = false; // Auto-enable after timer or scroll
  bool _hasInitialized = false; // Prevent double initialization
  Map<String, dynamic>? _materialData;
  List<Map<String, dynamic>> _poinDetails = [];
  String _materialTitle = '';
  String _materialId = '';
  String _moduleTitle = '';
  String _moduleId = '';
  int _currentPoinIndex = 0;
  int _initialPoinIndex = 0;
  Set<int> _completedPoins = {}; // Local completed poins
  Set<String> _completedPoinIds = {}; // Completed poin IDs from API
  bool _shouldShowQuizDirectly = false; // Flag untuk langsung tampilkan quiz

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Prevent double initialization
    if (_hasInitialized) {
      return;
    }

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _materialId = args['materialId'] ?? '';
      _materialTitle = args['materialTitle'] ?? 'Detail Materi';
      _moduleTitle = args['moduleTitle'] ?? '';
      _moduleId = args['moduleId'] ?? '';

      _hasInitialized = true; // Mark as initialized

      debugPrint('🆕 [MATERIAL] Loading new material: $_materialId');
      _loadMaterialDetail();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Auto-enable button after 5 seconds (for short content)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_canProceed) {
        setState(() {
          _canProceed = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Enable button if scrolled significantly (not necessarily to bottom)
    if (_scrollController.position.pixels >= 100) {
      if (!_canProceed) {
        setState(() {
          _canProceed = true;
        });
      }
    }

    // Check if scrolled to bottom
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    } else {
      if (_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = false;
        });
      }
    }
  }

  Future<void> _loadMaterialDetail() async {
    setState(() => _isLoading = true);

    try {
      // Load completed poins from API first
      await _loadCompletedPoins();

      // Check cache first
      if (MaterialPoinDetailScreen._materialCache.containsKey(_materialId)) {
        final cachedData =
            MaterialPoinDetailScreen._materialCache[_materialId]!;
        final poinList = cachedData['poin_details'] as List;

        // Determine start position based on last accessed and completed status
        final startPosition = await _determineStartPosition(poinList);

        setState(() {
          _materialData = cachedData;
          _poinDetails = poinList.cast<Map<String, dynamic>>();
          _currentPoinIndex = startPosition['poinIndex'] as int;
          _initialPoinIndex = startPosition['poinIndex'] as int;
          _shouldShowQuizDirectly = startPosition['shouldShowQuiz'] as bool;
          _isLoading = false;
        });

        // Initialize PageController with correct initial page
        _pageController = PageController(
          initialPage: startPosition['poinIndex'] as int,
        );

        // Jika harus langsung tampilkan quiz
        if (_shouldShowQuizDirectly) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showQuiz();
            }
          });
        }

        return;
      }

      // Fetch from API
      final result = await _moduleService.getMaterialDetail(_materialId);

      if (result['success'] && mounted) {
        final data = result['data'];
        final poinList =
            (data['poin_details'] as List? ?? [])
                .map((p) => p as Map<String, dynamic>)
                .toList();

        // Cache the data
        MaterialPoinDetailScreen._materialCache[_materialId] = {
          ...data,
          'poin_details': poinList,
        };

        // Determine start position based on last accessed and completed status
        final startPosition = await _determineStartPosition(poinList);

        setState(() {
          _materialData = data;
          _poinDetails = poinList;
          _currentPoinIndex = startPosition['poinIndex'] as int;
          _initialPoinIndex = startPosition['poinIndex'] as int;
          _shouldShowQuizDirectly = startPosition['shouldShowQuiz'] as bool;
          _isLoading = false;
        });

        // Initialize PageController with correct initial page
        _pageController = PageController(
          initialPage: startPosition['poinIndex'] as int,
        );

        // Jika harus langsung tampilkan quiz
        if (_shouldShowQuizDirectly) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _showQuiz();
            }
          });
        }
      } else {
        setState(() => _isLoading = false);
        _pageController = PageController();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _pageController = PageController();
    }
  }

  /// Load completed poins from API
  Future<void> _loadCompletedPoins() async {
    try {
      final result = await _progressService.getCompletedPoins(_materialId);
      if (result['success']) {
        final completedPoins = result['data'] as List? ?? [];
        setState(() {
          _completedPoinIds =
              completedPoins
                  .map((p) => p['poin_id']?.toString() ?? '')
                  .where((id) => id.isNotEmpty)
                  .toSet();
        });

        debugPrint(
          '✅ [MATERIAL] Loaded ${_completedPoinIds.length} completed poins',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [MATERIAL] Failed to load completed poins: $e');
    }
  }

  /// Determine start position berdasarkan last accessed dan completed status
  /// Returns: {poinIndex: int, shouldShowQuiz: bool}
  Future<Map<String, dynamic>> _determineStartPosition(List poinList) async {
    // Default start from beginning
    int startIndex = 0;
    bool shouldShowQuiz = false;

    try {
      // Get last accessed info
      final lastAccessed = await _progressService.getLastAccessedPoin(
        _materialId,
      );

      if (lastAccessed != null) {
        final savedPoinIndex = lastAccessed['poinIndex'] as int? ?? 0;
        final savedShouldShowQuiz =
            lastAccessed['shouldShowQuiz'] as bool? ?? false;
        final isQuizCompleted =
            lastAccessed['isQuizCompleted'] as bool? ?? false;

        debugPrint(
          '📍 [MATERIAL] Last accessed: poinIndex=$savedPoinIndex, showQuiz=$savedShouldShowQuiz, quizDone=$isQuizCompleted',
        );

        // Jika quiz sudah completed, mulai dari poin berikutnya (atau poin terakhir jika tidak ada)
        if (isQuizCompleted) {
          startIndex = (savedPoinIndex + 1).clamp(0, poinList.length - 1);
          shouldShowQuiz = false;
          debugPrint(
            '✅ [MATERIAL] Quiz completed, start from next poin: $startIndex',
          );
        }
        // Jika harus tampilkan quiz (sudah baca semua poin tapi belum quiz)
        else if (savedShouldShowQuiz) {
          startIndex = savedPoinIndex;
          shouldShowQuiz = true;
          debugPrint('📝 [MATERIAL] Should show quiz at poin: $startIndex');
        }
        // Normal case: lanjutkan dari poin terakhir
        else {
          startIndex = savedPoinIndex;
          shouldShowQuiz = false;
          debugPrint('📖 [MATERIAL] Continue from poin: $startIndex');
        }

        // Validate index
        if (startIndex >= poinList.length) {
          startIndex = poinList.length - 1;
        }
      } else {
        debugPrint('🆕 [MATERIAL] No last accessed, start from beginning');
      }
    } catch (e) {
      debugPrint('⚠️ [MATERIAL] Error determining start position: $e');
    }

    return {'poinIndex': startIndex, 'shouldShowQuiz': shouldShowQuiz};
  }

  Future<void> _markCurrentPoinCompleted() async {
    if (_currentPoinIndex >= _poinDetails.length) return;

    final currentPoin = _poinDetails[_currentPoinIndex];
    final poinId = currentPoin['id']?.toString() ?? '';

    // Mark locally
    setState(() {
      _completedPoins.add(_currentPoinIndex);
      if (poinId.isNotEmpty) {
        _completedPoinIds.add(poinId);
      }
    });

    // Call API untuk mark as completed
    if (poinId.isNotEmpty) {
      final result = await _progressService.markPoinCompleted(poinId);
      if (result['success']) {
        debugPrint('✅ [MATERIAL] Poin $poinId marked as completed');
      } else {
        debugPrint(
          '⚠️ [MATERIAL] Failed to mark poin as completed: ${result['error']}',
        );
      }
    }

    // Determine if should show quiz next
    final isLastPoin = _currentPoinIndex >= _poinDetails.length - 1;

    // Save last accessed with updated info
    await _progressService.saveLastAccessedPoin(
      materialId: _materialId,
      poinIndex: _currentPoinIndex,
      poinId: poinId,
      shouldShowQuiz: isLastPoin, // Jika poin terakhir, next action adalah quiz
      isQuizCompleted: false,
    );

    debugPrint(
      '💾 [MATERIAL] Saved last accessed: poinIndex=$_currentPoinIndex, shouldShowQuiz=$isLastPoin',
    );
  }

  Future<void> _goToNextPoin() async {
    if (!_canProceed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _hasScrolledToBottom
                ? 'Silakan baca materi terlebih dahulu'
                : 'Scroll atau tunggu beberapa saat untuk melanjutkan',
          ),
          backgroundColor: AppColors.orange600,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Mark current poin as completed
    await _markCurrentPoinCompleted();

    // Cek apakah masih ada poin berikutnya
    if (_currentPoinIndex < _poinDetails.length - 1) {
      // Masih ada poin berikutnya, navigasi ke poin berikutnya
      _pageController.animateToPage(
        _currentPoinIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _canProceed = false; // Reset for next page
      });

      // Auto-enable after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && !_canProceed) {
          setState(() {
            _canProceed = true;
          });
        }
      });
    } else {
      // Sudah poin terakhir, tampilkan kuis
      await _showQuiz();
    }
  }

  Future<void> _goToPreviousPoin() async {
    if (_currentPoinIndex > 0) {
      _pageController.animateToPage(
        _currentPoinIndex - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _showQuiz() async {
    try {
      // Load quiz untuk material ini
      final quizzesResult = await _quizService.getMaterialQuizzes(_materialId);

      if (!quizzesResult['success'] || quizzesResult['data'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                quizzesResult['message'] ?? 'Tidak ada kuis tersedia',
              ),
              backgroundColor: AppColors.orange600,
            ),
          );
        }
        _goToNextPoinAfterQuiz(null);
        return;
      }

      final quizzes = quizzesResult['data'] as List;
      if (quizzes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada kuis untuk materi ini'),
              backgroundColor: AppColors.orange600,
            ),
          );
        }
        _goToNextPoinAfterQuiz(null);
        return;
      }

      // Ambil quiz pertama
      final quiz = quizzes[0];
      final quizId = quiz['id'].toString();

      final currentPoin = _poinDetails[_currentPoinIndex];

      // Mark current poin as completed sebelum buka quiz
      // Karena user sudah baca materi sampai klik "Mulai Kuis"
      await _markCurrentPoinCompleted();

      // Navigate ke quiz screen
      final result = await Navigator.pushNamed(
        context,
        '/quiz',
        arguments: {
          'quizId': quizId,
          'materialId': _materialId,
          'moduleId': _moduleId,
          'poinTitle': currentPoin['title'],
        },
      );

      // Hanya process jika ada result (user selesai quiz)
      // Jika user hanya back dari quiz overview, result akan null dan tidak perlu process
      if (result != null) {
        _goToNextPoinAfterQuiz(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: e'),
            backgroundColor: AppColors.red600,
          ),
        );
      }
      _goToNextPoinAfterQuiz(null);
    }
  }

  void _goToNextPoinAfterQuiz(dynamic result) {
    // Clear cache to force reload of progress data
    MaterialPoinDetailScreen.clearCache(_materialId);

    // Check if user wants to go to next material
    final shouldGoToNext = result is Map && result['goToNext'] == true;

    // Hanya save quiz completion jika user BENAR-BENAR selesai quiz (result tidak null)
    // Jika result null = user hanya back dari quiz overview tanpa mengerjakan
    if (result != null) {
      final currentPoin =
          _poinDetails.length > _currentPoinIndex
              ? _poinDetails[_currentPoinIndex]
              : null;

      if (currentPoin != null) {
        final poinId = currentPoin['id']?.toString() ?? '';
        _progressService.saveLastAccessedPoin(
          materialId: _materialId,
          poinIndex: _currentPoinIndex,
          poinId: poinId,
          isQuizCompleted: true, // Mark quiz as completed
          shouldShowQuiz: false,
        );

        debugPrint('✅ [MATERIAL] Quiz completed for poin $poinId');
      }
    } else {
      debugPrint(
        '⏭️ [MATERIAL] User back from quiz overview without completing',
      );
    }

    // If user wants to go to next material/poin
    if (shouldGoToNext) {
      // Cek apakah masih ada poin berikutnya di material ini
      if (_currentPoinIndex < _poinDetails.length - 1) {
        // Masih ada poin berikutnya, navigate ke poin berikutnya
        debugPrint('📍 [MATERIAL] Navigating to next poin after quiz');
        _pageController.animateToPage(
          _currentPoinIndex + 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() {
          _hasScrolledToBottom = false;
          _canProceed = false;
        });

        // Auto-enable after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && !_canProceed) {
            setState(() {
              _canProceed = true;
            });
          }
        });
        return;
      } else {
        // Sudah poin terakhir, kembali ke materials list
        debugPrint(
          '📍 [MATERIAL] Last poin completed, going back to materials list',
        );
        Navigator.popUntil(context, (route) {
          return route.settings.name == '/modul-materials' || route.isFirst;
        });
        return;
      }
    }

    // Navigate ke poin berikutnya (jika tidak ada flag goToNext)
    if (_currentPoinIndex < _poinDetails.length - 1) {
      _pageController.animateToPage(
        _currentPoinIndex + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _hasScrolledToBottom = false;
        _canProceed = false;
      });

      // Auto-enable after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && !_canProceed) {
          setState(() {
            _canProceed = true;
          });
        }
      });
    } else {
      // Last poin - selesai, kembali ke daftar materi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Selamat! Anda telah menyelesaikan semua materi!'),
            backgroundColor: AppColors.green600,
            duration: Duration(seconds: 3),
          ),
        );

        // Kembali ke daftar materi
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.popUntil(context, (route) {
              return route.settings.name == '/modul-materials' || route.isFirst;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, color: AppColors.white, size: 20),
              const SizedBox(width: 4),
              Text(
                'Kembali',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          onPressed: () {
            // Kembali langsung ke module screen, skip materials list
            Navigator.popUntil(context, (route) {
              return route.settings.name == '/modul' || route.isFirst;
            });
          },
        ),
        leadingWidth: 100,
        title: const Text(''),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/modul-materials',
                arguments: {
                  'moduleId': _materialData?['module_id'] ?? '',
                  'moduleTitle': _moduleTitle,
                  'currentMaterialId': _materialId,
                },
              );
            },
            icon: const Icon(Icons.list_alt, color: AppColors.white, size: 20),
            label: Text(
              'Daftar Materi',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(foregroundColor: AppColors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : _poinDetails.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 64,
                      color: AppColors.gray400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada poin pembelajaran',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  // Info Card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gray400.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.menu_book,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _moduleTitle,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.gray600,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _materialTitle,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 16,
                              color: AppColors.gray600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Poin ${_currentPoinIndex + 1} dari ${_poinDetails.length}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.gray600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_currentPoinIndex + 1}/${_poinDetails.length}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Content
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) async {
                        setState(() {
                          _currentPoinIndex = index;
                          _hasScrolledToBottom = false;
                          _canProceed = false; // Reset for new page
                        });

                        // Auto-enable after 5 seconds
                        Future.delayed(const Duration(seconds: 5), () {
                          if (mounted &&
                              !_canProceed &&
                              _currentPoinIndex == index) {
                            setState(() {
                              _canProceed = true;
                            });
                          }
                        });

                        // Save last accessed
                        if (index < _poinDetails.length) {
                          final poin = _poinDetails[index];
                          await _progressService.saveLastAccessedPoin(
                            materialId: _materialId,
                            poinIndex: index,
                            poinId: poin['id'],
                          );
                        }

                        // Reset scroll position
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(0);
                        }
                      },
                      itemCount: _poinDetails.length,
                      itemBuilder: (context, index) {
                        return _buildPoinContent(_poinDetails[index], index);
                      },
                    ),
                  ),

                  // Bottom bar with next button
                  _buildBottomBar(),
                ],
              ),
    );
  }

  Widget _buildProgressIndicator() {
    if (_poinDetails.isEmpty) return const SizedBox.shrink();

    final progress = (_currentPoinIndex + 1) / _poinDetails.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray400.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Poin ${_currentPoinIndex + 1} dari ${_poinDetails.length}',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.gray600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoinContent(Map<String, dynamic> poin, int index) {
    final htmlContent = poin['content_html'] ?? poin['content'] ?? '';

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poin title
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        poin['title'] ?? 'Poin ${index + 1}',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (poin['duration_label'] != null)
                        Text(
                          poin['duration_label'],
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withOpacity(0.9),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Content
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gray400.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                htmlContent.isNotEmpty
                    ? HtmlWidget(
                      htmlContent,
                      textStyle: AppTextStyles.bodyMedium.copyWith(
                        height: 1.6,
                        color: AppColors.gray700,
                      ),
                    )
                    : Text(
                      'Konten pembelajaran akan ditampilkan di sini.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
          ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLastPoin = _currentPoinIndex >= _poinDetails.length - 1;
    final isFirstPoin = _currentPoinIndex == 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray400.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Previous button
            if (!isFirstPoin)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _goToPreviousPoin,
                  icon: Icon(Icons.arrow_back, color: AppColors.primary),
                  label: Text(
                    'Sebelumnya',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (!isFirstPoin) const SizedBox(width: 12),

            // Scroll indicator or Next button
            if (!_canProceed)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.orange600),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.hourglass_bottom,
                        size: 16,
                        color: AppColors.orange600,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Baca materi atau tunggu...',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.orange600,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _goToNextPoin,
                  icon: Icon(
                    isLastPoin ? Icons.quiz : Icons.arrow_forward,
                    color: AppColors.white,
                  ),
                  label: Text(
                    isLastPoin ? 'Mulai Kuis' : 'Selanjutnya',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
