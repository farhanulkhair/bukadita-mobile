import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../services/quiz_service.dart';

/// Quiz Overview Screen - Halaman overview kuis sebelum memulai
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final QuizService _quizService = QuizService();

  bool _isLoading = true;
  String _quizId = '';
  String _materialId = '';
  String _moduleId = '';
  String _quizTitle = '';
  String _poinTitle = '';
  int _totalQuestions = 0;
  int _timeLimit = 0; // dalam menit
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _quizHistory = []; // Riwayat kuis

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _isLoading) {
      _quizId = args['quizId'] ?? '';
      _materialId = args['materialId'] ?? '';
      _moduleId = args['moduleId'] ?? '';
      _poinTitle = args['poinTitle'] ?? '';
      _loadQuizData();
    }
  }

  Future<void> _loadQuizData() async {
    setState(() => _isLoading = true);

    try {
      // Load quiz detail dengan soal-soal
      final quizResult = await _quizService.getQuizDetail(_quizId);

      if (quizResult['success'] && mounted) {
        final quiz = quizResult['data'];
        final questions =
            (quiz['questions'] as List?)
                ?.map((q) => q as Map<String, dynamic>)
                .toList() ??
            [];

        // Load quiz history/results by module (sesuai web app)
        final moduleId = _moduleId;
        final historyResult = await _quizService.getMyQuizAttempts(
          limit: 100,
          moduleId: moduleId, // Pass module_id untuk filter
        );
        List<Map<String, dynamic>> history = [];

        if (historyResult['success']) {
          final responseData = historyResult['data'];

          List results = [];

          // Handle API response structure: {data: {attempts: [...]}}
          if (responseData is Map && responseData.containsKey('attempts')) {
            results = responseData['attempts'] as List? ?? [];
          } else if (responseData is Map && responseData.containsKey('items')) {
            results = responseData['items'] as List? ?? [];
          } else if (responseData is List) {
            results = responseData;
          }

          // Debug: Print untuk cek data
          debugPrint(
            '📊 [QUIZ_HISTORY] Total attempts fetched: ${results.length}',
          );
          debugPrint('📊 [QUIZ_HISTORY] Current material ID: $_materialId');

          // Filter berdasarkan sub_materi_id dari nested quiz object (sesuai web app)
          results =
              results.where((r) {
                if (r is! Map) return false;

                // Get nested quiz object
                final quiz = r['quiz'];
                if (quiz == null || quiz is! Map) {
                  debugPrint(
                    '⚠️ [QUIZ_HISTORY] Attempt tanpa quiz object: ${r['id']}',
                  );
                  return false;
                }

                // Check sub_materi_id (snake_case!)
                final attemptSubMateriId =
                    quiz['sub_materi_id']?.toString() ?? '';
                final currentMaterialId = _materialId.toString();
                final matches = attemptSubMateriId == currentMaterialId;

                debugPrint(
                  '📊 [QUIZ_HISTORY] Comparing sub_materi_id: "$attemptSubMateriId" == "$currentMaterialId" = $matches',
                );
                return matches;
              }).toList();

          debugPrint(
            '✅ [QUIZ_HISTORY] Filtered attempts for this material: ${results.length}',
          );

          try {
            history =
                results.map((r) {
                  try {
                    final score = _safeInt(r['score']);
                    final passed =
                        r['passed'] ??
                        (score >= 70); // Use passed flag or calculate

                    // Calculate time spent from timestamps if time_taken_seconds not available
                    int timeSpent = 0;
                    if (r.containsKey('time_taken_seconds')) {
                      timeSpent = _safeInt(r['time_taken_seconds']);
                    } else if (r['started_at'] != null &&
                        r['completed_at'] != null) {
                      try {
                        final start = DateTime.parse(r['started_at']);
                        final end = DateTime.parse(r['completed_at']);
                        timeSpent = end.difference(start).inSeconds;
                      } catch (e) {
                        debugPrint('⚠️ [QUIZ_HISTORY] Error parsing dates: $e');
                      }
                    }

                    final historyItem = {
                      'attemptDate': _formatDate(
                        r['completed_at'] ??
                            r['submitted_at'] ??
                            r['created_at'],
                      ),
                      'score': score,
                      'correctCount': _safeInt(
                        r['correct_answers'] ?? r['correct_count'],
                      ),
                      'totalQuestions': _safeInt(
                        r['total_questions'],
                        defaultValue: questions.length,
                      ),
                      'timeSpent': _formatTime(timeSpent),
                      'status': passed ? 'passed' : 'failed',
                    };

                    debugPrint('📋 [QUIZ_HISTORY] History item: $historyItem');
                    return historyItem;
                  } catch (e) {
                    debugPrint('⚠️ [QUIZ_HISTORY] Error mapping item: $e');
                    // Return a placeholder or rethrow
                    rethrow;
                  }
                }).toList();

            debugPrint(
              '📋 [QUIZ_HISTORY] Total history items created: ${history.length}',
            );
          } catch (e) {
            debugPrint('❌ [QUIZ_HISTORY] Error during mapping: $e');
            history = []; // Fallback to empty list
          }
        } else {
          // History API failed
        }

        setState(() {
          _quizTitle = quiz['title'] ?? 'Kuis';
          _questions = questions;
          _totalQuestions = questions.length;
          // Convert seconds to minutes
          final timeLimitSeconds =
              (quiz['time_limit_seconds'] as num?)?.toInt() ?? 900;
          _timeLimit = (timeLimitSeconds / 60).ceil(); // Convert to minutes
          _quizHistory = history;
          _isLoading = false;

          debugPrint(
            '🎯 [QUIZ_HISTORY] setState completed. _quizHistory.length = ${_quizHistory.length}',
          );
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(quizResult['message'] ?? 'Gagal memuat kuis'),
              backgroundColor: AppColors.red600,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [QUIZ_HISTORY] Error loading quiz data: $e');
      debugPrint('❌ [QUIZ_HISTORY] Stack trace: $stackTrace');
      setState(() => _isLoading = false);
    }
  }

  // Helper: Safe int conversion dari dynamic (bisa string atau number)
  int _safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    if (value is num) return value.toInt();
    return defaultValue;
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _startQuiz() {
    Navigator.pushNamed(
      context,
      '/quiz-questions',
      arguments: {
        'quizId': _quizId,
        'materialId': _materialId,
        'moduleId': _moduleId,
        'quizTitle': _quizTitle,
        'poinTitle': _poinTitle,
        'questions': _questions,
        'timeLimit': _timeLimit,
      },
    ).then((result) {
      // Ketika kembali dari quiz questions dengan hasil
      if (result != null && result is Map<String, dynamic>) {
        // Reload quiz data to refresh history
        _loadQuizData();

        // Pass result kembali ke material_poin_detail_screen
        // Sehingga material bisa di-mark as completed
        Navigator.pop(context, result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
              const SizedBox(width: 4),
              Text(
                'Kembali',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        leadingWidth: 100,
        title: Text(
          'Overview Kuis',
          style: AppTextStyles.headingSmall.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiz Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.quiz,
                          color: AppColors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _quizTitle,
                              style: AppTextStyles.headingMedium.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _poinTitle,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: AppColors.white.withOpacity(0.3)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(Icons.assignment, '$_totalQuestions Soal'),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.white.withOpacity(0.3),
                      ),
                      _buildInfoItem(Icons.access_time, '$_timeLimit Menit'),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.white.withOpacity(0.3),
                      ),
                      _buildInfoItem(Icons.check_circle, 'Nilai Min: 70'),
                    ],
                  ),
                ],
              ),
            ),

            // Aturan Kuis
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gray400.withOpacity(0.1),
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
                      Icon(Icons.rule, color: AppColors.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Aturan Kuis',
                        style: AppTextStyles.headingSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRuleItem(
                    '1',
                    'Kuis terdiri dari $_totalQuestions soal pilihan ganda',
                  ),
                  _buildRuleItem('2', 'Waktu pengerjaan: $_timeLimit menit'),
                  _buildRuleItem('3', 'Nilai minimal kelulusan: 70'),
                  _buildRuleItem(
                    '4',
                    'Tidak dapat keluar setelah kuis dimulai - harus diselesaikan',
                  ),
                  _buildRuleItem(
                    '5',
                    'Jawaban tidak dapat diubah setelah submit',
                  ),
                  _buildRuleItem('6', 'Kuis dapat diulang jika nilai < 70'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Riwayat Kuis
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.history, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Riwayat Kuis',
                    style: AppTextStyles.headingSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            if (_quizHistory.isEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 48,
                        color: AppColors.gray400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada riwayat kuis',
                        style: AppTextStyles.bodyMedium.copyWith(
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _quizHistory.length,
                itemBuilder: (context, index) {
                  final history = _quizHistory[index];
                  final isPassed = history['status'] == 'passed';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isPassed
                                ? AppColors.green600.withOpacity(0.3)
                                : AppColors.red600.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gray400.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isPassed
                                        ? AppColors.green600
                                        : AppColors.red600)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isPassed ? Icons.check_circle : Icons.cancel,
                                color:
                                    isPassed
                                        ? AppColors.green600
                                        : AppColors.red600,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    history['attemptDate'],
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.gray600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isPassed ? 'LULUS' : 'TIDAK LULUS',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color:
                                          isPassed
                                              ? AppColors.green600
                                              : AppColors.red600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${history['score']}',
                                  style: AppTextStyles.headingLarge.copyWith(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isPassed
                                            ? AppColors.green600
                                            : AppColors.red600,
                                  ),
                                ),
                                Text(
                                  'Nilai',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(color: AppColors.gray200),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '${history['correctCount']}/${history['totalQuestions']}',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Benar',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: Container(
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
          child: ElevatedButton.icon(
            onPressed: _startQuiz,
            icon: const Icon(Icons.play_arrow, color: AppColors.white),
            label: Text(
              'Mulai Kuis',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppColors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          text,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRuleItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.gray700,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
