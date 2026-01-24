import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/theme.dart';
import '../../services/module_service.dart';
import '../../services/progress_service.dart';
import '../../services/quiz_service.dart';
import 'material_poin_detail_screen.dart';

/// Module Materials List Screen - Design Modern seperti gambar referensi
class ModuleMaterialsListScreen extends StatefulWidget {
  const ModuleMaterialsListScreen({super.key});

  @override
  State<ModuleMaterialsListScreen> createState() =>
      _ModuleMaterialsListScreenState();
}

class _ModuleMaterialsListScreenState extends State<ModuleMaterialsListScreen> {
  final ModuleService _moduleService = ModuleService();
  final ProgressService _progressService = ProgressService();
  final QuizService _quizService = QuizService();

  bool _isLoading = true;
  List<Map<String, dynamic>> _materials = [];
  Map<String, bool> _expandedMaterials = {};
  Map<String, dynamic> _progressData = {};
  String _moduleTitle = '';
  String _moduleId = '';
  int _completedCount = 0;
  int _totalCount = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _moduleId = args['moduleId'] ?? '';
      _moduleTitle = args['moduleTitle'] ?? 'Daftar Modul';
      _loadMaterials();
    }
  }

  Future<void> _loadMaterials() async {
    setState(() => _isLoading = true);

    try {
      // Clear material detail cache to ensure fresh progress data
      MaterialPoinDetailScreen.clearAllCache();

      // Load materials dan progress
      final result = await _moduleService.getMaterialsByModule(
        _moduleId,
        limit: 1000,
      );
      final progressResult = await _progressService.getModuleProgress(
        _moduleId,
      );

      if (result['success'] && mounted) {
        final responseData = result['data'];
        List materialsList = [];

        if (responseData is Map && responseData.containsKey('items')) {
          materialsList = responseData['items'] as List;
        } else if (responseData is List) {
          materialsList = responseData;
        }

        // Parse progress data
        _progressData.clear();
        if (progressResult['success']) {
          // API returns 'sub_materis' not 'materials'
          final progressMaterials =
              progressResult['data']['sub_materis'] as List? ?? [];
          for (var pm in progressMaterials) {
            // Use 'id' not 'material_id' based on API response
            final matId = (pm['id'] ?? pm['material_id']).toString();
            _progressData[matId] = pm;
          }
        }

        final materials =
            materialsList.map((m) => m as Map<String, dynamic>).toList();

        // Load poin details and quiz for each material
        _completedCount = 0;
        for (var material in materials) {
          final materialId = material['id']?.toString();
          if (materialId != null) {
            // Load poin details
            final detailResult = await _moduleService.getMaterialDetail(
              materialId,
            );
            if (detailResult['success']) {
              final poinDetails =
                  detailResult['data']['poinDetails'] ??
                  detailResult['data']['poin_details'] ??
                  [];
              material['poin_details'] = poinDetails;
            }

            // Load quiz data
            final quizResult = await _quizService.getMaterialQuizzes(
              materialId,
            );
            if (quizResult['success'] && quizResult['data'] != null) {
              final quizzes = quizResult['data'] as List;
              material['quizzes'] = quizzes;
            } else {
              material['quizzes'] = [];
            }

            // Check completion from progress data
            final progressMat = _progressData[materialId];
            if (progressMat != null) {
              final completed = progressMat['is_completed'] ?? false;
              material['is_completed'] = completed;
              if (completed) _completedCount++;
            } else {
              material['is_completed'] = false;
            }
          }
        }

        _totalCount = materials.length;

        setState(() {
          _materials = materials;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        _totalCount > 0 ? (_completedCount / _totalCount * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _moduleTitle,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.x, color: AppColors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              LucideIcons.bookOpen,
                              color: AppColors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Daftar Materi',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Progress bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress Belajar',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: AppColors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '$progress%',
                                    style: AppTextStyles.headingSmall.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (progress == 100) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.white,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: progress / 100,
                              backgroundColor: AppColors.white.withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_completedCount dari $_totalCount materi selesai',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.white.withOpacity(0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Materials list
          Expanded(
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                    : _materials.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.inbox,
                            size: 64,
                            color: AppColors.gray400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada materi tersedia',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      itemCount: _materials.length,
                      itemBuilder: (context, index) {
                        final material = _materials[index];
                        return _buildMaterialCard(material, index);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material, int index) {
    final materialId = material['id']?.toString() ?? '';
    final isExpanded = _expandedMaterials[materialId] ?? false;
    final poinDetails = material['poin_details'] as List? ?? [];
    final isCompleted = material['is_completed'] ?? false;
    final isLocked =
        index > 0 && !(_materials[index - 1]['is_completed'] ?? false);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isCompleted
                  ? AppColors.green600.withOpacity(0.3)
                  : isLocked
                  ? AppColors.gray300.withOpacity(0.5)
                  : AppColors.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                isCompleted
                    ? AppColors.green600.withOpacity(0.08)
                    : AppColors.gray500.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap:
                isLocked
                    ? null
                    : () {
                      setState(() {
                        _expandedMaterials[materialId] = !isExpanded;
                      });
                    },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Status Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          isLocked
                              ? AppColors.gray200
                              : isCompleted
                              ? AppColors.green600
                              : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isLocked
                                ? AppColors.gray300
                                : isCompleted
                                ? AppColors.green600
                                : AppColors.primary.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      isLocked
                          ? LucideIcons.lock
                          : isCompleted
                          ? Icons.check_circle
                          : LucideIcons.circle,
                      color:
                          isLocked
                              ? AppColors.gray500
                              : isCompleted
                              ? AppColors.white
                              : AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material['title'] ?? '',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color:
                                isLocked
                                    ? AppColors.gray500
                                    : AppColors.gray800,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (poinDetails.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.fileText,
                                  size: 14,
                                  color:
                                      isLocked
                                          ? AppColors.gray400
                                          : AppColors.gray500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${poinDetails.length} poin materi',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color:
                                        isLocked
                                            ? AppColors.gray400
                                            : AppColors.gray600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Expand icon
                  if (!isLocked)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color:
                            isExpanded
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        color:
                            isExpanded
                                ? AppColors.primary
                                : AppColors.gray600,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Expanded poin list
          if (isExpanded && !isLocked)
            Container(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                children: [
                  // Poin items
                  ...poinDetails.asMap().entries.map((entry) {
                    return _buildPoinItem(entry.value, materialId, false);
                  }).toList(),
                  // Quiz item
                  _buildQuizItem(material, materialId),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPoinItem(
    Map<String, dynamic> poin,
    String materialId,
    bool isLast,
  ) {
    final poinId = poin['id']?.toString() ?? '';

    // Logic sederhana: Jika material sudah completed, maka semua poinnya juga completed
    final materialProgressData = _progressData[materialId];
    bool isCompleted = false;

    if (materialProgressData != null) {
      // Jika material is_completed = true, berarti semua poinnya sudah selesai
      final materialCompleted = materialProgressData['is_completed'] ?? false;
      final progressPercent = materialProgressData['progress_percent'] ?? 0;

      // Material completed = semua poin completed
      if (materialCompleted && progressPercent == 100) {
        isCompleted = true;
      }
    }

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/material-poin-detail',
          arguments: {
            'materialId': materialId,
            'materialTitle': poin['title'],
            'moduleTitle': _moduleTitle,
            'moduleId': _moduleId,
          },
        ).then((_) => _loadMaterials()); // Reload after returning
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: EdgeInsets.only(top: 8, bottom: isLast ? 0 : 0),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isCompleted
                    ? AppColors.green600.withOpacity(0.3)
                    : AppColors.gray300.withOpacity(0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray400.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    isCompleted
                        ? AppColors.green600.withOpacity(0.1)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle
                    : LucideIcons.circle,
                color:
                    isCompleted
                        ? AppColors.green600
                        : AppColors.gray400,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                poin['title'] ?? '',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray800,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizItem(Map<String, dynamic> material, String materialId) {
    final quizzes = material['quizzes'] as List? ?? [];
    final isCompleted = material['is_completed'] ?? false;

    if (quizzes.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        if (quizzes.isNotEmpty) {
          final quiz = quizzes[0];
          final quizId = quiz['id']?.toString() ?? '';
          Navigator.pushNamed(
            context,
            '/quiz',
            arguments: {
              'quizId': quizId,
              'materialId': materialId,
              'moduleId': _moduleId,
              'poinTitle': material['title'] ?? '',
            },
          ).then((_) => _loadMaterials());
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(top: 8),
        decoration: BoxDecoration(
          gradient:
              isCompleted
                  ? LinearGradient(
                    colors: [
                      AppColors.green600.withOpacity(0.08),
                      AppColors.green600.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                  : LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.08),
                      AppColors.secondary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isCompleted
                    ? AppColors.green600.withOpacity(0.3)
                    : AppColors.primary.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isCompleted
                      ? AppColors.green600.withOpacity(0.08)
                      : AppColors.primary.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    isCompleted
                        ? AppColors.green600
                        : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.help_outline,
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
                    'Kuis',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gray800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isCompleted)
                    Text(
                      'Selamat, Anda telah lulus!',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.green600,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (isCompleted)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.green600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Lulus',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
