import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../../services/progress_service.dart';

/// Quiz Result Screen - Halaman hasil kuis dengan review jawaban
class QuizResultScreen extends StatefulWidget {
  const QuizResultScreen({super.key});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final ProgressService _progressService = ProgressService();

  int _score = 0;
  int _correctCount = 0;
  int _totalQuestions = 0;
  int _timeSpent = 0;
  bool _isPassed = false;
  String _materialId = '';
  String _moduleId = '';

  List<Map<String, dynamic>> _questions = [];
  Map<int, String> _userAnswers = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _score = args['score'] ?? 0;
      _correctCount = args['correctCount'] ?? 0;
      _totalQuestions = args['totalQuestions'] ?? 0;
      _timeSpent = args['timeSpent'] ?? 0;
      _materialId = args['materialId'] ?? '';
      _moduleId = args['moduleId'] ?? '';
      _questions =
          (args['questions'] as List<dynamic>?)
              ?.map((q) => q as Map<String, dynamic>)
              .toList() ??
          [];
      _userAnswers = (args['userAnswers'] as Map<int, String>?) ?? {};
      _isPassed = _score >= 70;
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _goBackToMaterial() async {
    // Return result to previous screen without showing alerts
    if (mounted) {
      Navigator.pop(context, {
        'completed': true,
        'passed': _isPassed,
        'score': _score,
        'correctCount': _correctCount,
        'totalQuestions': _totalQuestions,
        'timeSpent': _timeSpent,
      });
    }
  }

  Future<void> _goToNextMaterial() async {
    // Update progress silently di background
    if (_isPassed && _materialId.isNotEmpty && _moduleId.isNotEmpty) {
      try {
        await _progressService.markMaterialCompleted(_materialId);
      } catch (e) {
        debugPrint('Error marking material completed: $e');
      }
    }

    // Navigate back dengan flag untuk lanjut ke materi berikutnya
    if (mounted) {
      Navigator.pop(context, {
        'completed': true,
        'passed': _isPassed,
        'score': _score,
        'goToNext': true, // Flag untuk navigate ke materi berikutnya
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _goBackToMaterial();
        return false;
      },
      child: Scaffold(
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
            onPressed: _goBackToMaterial,
          ),
          leadingWidth: 100,
          title: Text(
            'Hasil Kuis',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Score Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        _isPassed
                            ? [AppColors.green600, AppColors.green700]
                            : [AppColors.red600, AppColors.red700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (_isPassed ? AppColors.green600 : AppColors.red600)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      _isPassed ? Icons.check_circle : Icons.cancel,
                      color: AppColors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isPassed ? 'SELAMAT!' : 'BELUM LULUS',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isPassed
                          ? 'Anda telah lulus kuis ini'
                          : 'Silakan pelajari kembali materi',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Score
                    Text(
                      'Nilai',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_score',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 72,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Divider(color: AppColors.white.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.check_circle_outline,
                          'Benar',
                          '$_correctCount',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.white.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          Icons.cancel_outlined,
                          'Salah',
                          '${_totalQuestions - _correctCount}',
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.white.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          Icons.access_time,
                          'Waktu',
                          _formatTime(_timeSpent),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Review Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.rate_review, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Review Jawaban',
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Questions Review
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  final userAnswer = _userAnswers[index];

                  // Get correct answer index from question data
                  var correctAnswerIndex = question['correct_answer_index'];
                  String? correctAnswer;

                  if (correctAnswerIndex != null && correctAnswerIndex is int) {
                    // Convert index (0,1,2,3) to letter (A,B,C,D)
                    correctAnswer = String.fromCharCode(
                      'A'.codeUnitAt(0) + correctAnswerIndex,
                    );
                  } else if (question['correctAnswer'] != null) {
                    var ca = question['correctAnswer'];
                    if (ca is int) {
                      correctAnswer = String.fromCharCode(
                        'A'.codeUnitAt(0) + ca,
                      );
                    } else {
                      correctAnswer = ca.toString();
                    }
                  }

                  final isCorrect = userAnswer == correctAnswer;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isCorrect
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (isCorrect
                                    ? AppColors.green600
                                    : AppColors.red600)
                                .withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      isCorrect
                                          ? AppColors.green600
                                          : AppColors.red600,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  isCorrect ? Icons.check : Icons.close,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Soal ${index + 1}',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isCorrect
                                            ? AppColors.green600
                                            : AppColors.red600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isCorrect
                                          ? AppColors.green600
                                          : AppColors.red600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isCorrect ? 'BENAR' : 'SALAH',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Question Text
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            question['question_text'] ??
                                question['question'] ??
                                '',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                          ),
                        ),

                        // Options
                        ...['A', 'B', 'C', 'D'].asMap().entries.map((entry) {
                          final index = entry.key;
                          final option = entry.value;

                          // Get option text from array or old format
                          String optionText = '';
                          if (question['options'] != null &&
                              question['options'] is List) {
                            final options = question['options'] as List;
                            if (index < options.length) {
                              optionText = options[index].toString();
                            }
                          } else {
                            optionText = question['option$option'] ?? '';
                          }

                          final isUserAnswer = userAnswer == option;
                          final isCorrectAnswer = correctAnswer == option;

                          Color? backgroundColor;
                          Color? borderColor;

                          if (isCorrectAnswer) {
                            backgroundColor = AppColors.green50;
                            borderColor = AppColors.green600;
                          } else if (isUserAnswer && !isCorrect) {
                            backgroundColor = AppColors.red50;
                            borderColor = AppColors.red600;
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: backgroundColor ?? Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  borderColor != null
                                      ? Border.all(
                                        color: borderColor,
                                        width: 1.5,
                                      )
                                      : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color:
                                        isCorrectAnswer
                                            ? AppColors.green600
                                            : isUserAnswer && !isCorrect
                                            ? AppColors.red600
                                            : AppColors.gray200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    option,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color:
                                          isCorrectAnswer ||
                                                  (isUserAnswer && !isCorrect)
                                              ? AppColors.white
                                              : AppColors.gray700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.gray800,
                                      fontWeight:
                                          isCorrectAnswer || isUserAnswer
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isCorrectAnswer)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.green600,
                                    size: 20,
                                  )
                                else if (isUserAnswer && !isCorrect)
                                  Icon(
                                    Icons.cancel,
                                    color: AppColors.red600,
                                    size: 20,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 12),
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
            child:
                _isPassed
                    ? ElevatedButton.icon(
                      onPressed: _goToNextMaterial,
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.white,
                      ),
                      label: Text(
                        'Lanjut ke Pelajaran Selanjutnya',
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
                    )
                    : ElevatedButton.icon(
                      onPressed: _goBackToMaterial,
                      icon: const Icon(Icons.refresh, color: AppColors.white),
                      label: Text(
                        'Ulangi Kuis',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppColors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.headingSmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}
