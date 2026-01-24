import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/theme.dart';
import '../../services/quiz_service.dart';

/// Quiz Questions Screen - Halaman soal-soal kuis
/// Tidak ada tombol kembali - user harus menyelesaikan kuis
class QuizQuestionScreen extends StatefulWidget {
  const QuizQuestionScreen({super.key});

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  final QuizService _quizService = QuizService();

  String _quizId = '';
  String _materialId = '';
  String _moduleId = '';
  int _currentQuestionIndex = 0;
  Map<int, String> _answers = {}; // index -> jawaban (A/B/C/D)
  Timer? _timer;
  int _secondsElapsed = 0;
  int _timeLimit = 0; // dalam detik

  String _quizTitle = '';
  String _poinTitle = '';
  List<Map<String, dynamic>> _questions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      _quizId = args['quizId'] ?? '';
      _materialId = args['materialId'] ?? '';
      _moduleId = args['moduleId'] ?? '';
      _quizTitle = args['quizTitle'] ?? 'Kuis';
      _poinTitle = args['poinTitle'] ?? '';
      _questions =
          (args['questions'] as List<dynamic>?)
              ?.map((q) => q as Map<String, dynamic>)
              .toList() ??
          [];
      final timeLimitMinutes = args['timeLimit'] ?? 15;
      _timeLimit = timeLimitMinutes * 60; // Convert to seconds

      // Start timer
      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });

        // Check if time's up
        if (_timeLimit > 0 && _secondsElapsed >= _timeLimit) {
          timer.cancel();
          _submitQuiz(timeUp: true);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  int _getAnsweredCount() {
    return _answers.length;
  }

  void _selectAnswer(String answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });
  }

  void _goToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _submitQuiz({bool timeUp = false}) {
    // Check if all questions answered
    if (_getAnsweredCount() < _questions.length && !timeUp) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Kuis Belum Lengkap'),
              content: Text(
                'Anda baru menjawab ${_getAnsweredCount()} dari ${_questions.length} soal. '
                'Apakah Anda yakin ingin menyelesaikan kuis?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _finishQuiz();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Ya, Selesai'),
                ),
              ],
            ),
      );
    } else {
      if (timeUp) {
        // Show time's up message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Waktu habis! Kuis akan disubmit otomatis.'),
            backgroundColor: AppColors.orange600,
          ),
        );
      }
      _finishQuiz();
    }
  }

  void _finishQuiz() async {
    _timer?.cancel();

    try {
      // Prepare answers for API
      List<Map<String, dynamic>> answersList = [];
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final userAnswer = _answers[i] ?? ''; // Empty if not answered

        // Convert A, B, C, D to index 0, 1, 2, 3
        int? optionIndex;
        if (userAnswer.isNotEmpty) {
          optionIndex = userAnswer.codeUnitAt(0) - 'A'.codeUnitAt(0);
        }

        answersList.add({
          'question_id': question['id'],
          'selected_option_index': optionIndex,
        });
      }

      // Submit quiz to API
      final submitResult = await _quizService.submitQuiz(
        quizId: _quizId,
        answers: answersList,
      );

      if (!submitResult['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(submitResult['message'] ?? 'Gagal submit kuis'),
              backgroundColor: AppColors.red600,
            ),
          );
        }
        return;
      }

      // Get result from API response
      final resultData = submitResult['data'];
      final score = (resultData['score'] as num?)?.toInt() ?? 0;
      final correctCount = (resultData['correct_count'] as num?)?.toInt() ?? 0;

      // Get correct answers from result if available
      final resultAnswers = resultData['answers'] as List? ?? [];
      final Map<String, dynamic> correctAnswersMap = {};

      for (var answer in resultAnswers) {
        final questionId = answer['question_id'];
        final correctIndex = answer['correct_answer_index'];
        if (correctIndex != null) {
          correctAnswersMap[questionId] = correctIndex;
        }
      }

      // Add correct answers to questions
      final questionsWithAnswers =
          _questions.map((q) {
            final correctIndex = correctAnswersMap[q['id']];
            return {...q, 'correct_answer_index': correctIndex};
          }).toList();

      // Navigate to result screen
      Navigator.pushReplacementNamed(
        context,
        '/quiz-result',
        arguments: {
          'score': score,
          'correctCount': correctCount,
          'totalQuestions': _questions.length,
          'timeSpent': _secondsElapsed,
          'questions': questionsWithAnswers,
          'userAnswers': _answers,
          'materialId': _materialId,
          'moduleId': _moduleId,
        },
      ).then((result) {
        // Return result to overview screen
        if (result != null && mounted) {
          Navigator.pop(context, result);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.red600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Tidak ada soal tersedia')),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final userAnswer = _answers[_currentQuestionIndex];

    // Calculate remaining time
    final remainingSeconds = _timeLimit > 0 ? _timeLimit - _secondsElapsed : 0;
    final isTimeRunningOut = remainingSeconds <= 60 && remainingSeconds > 0;

    return WillPopScope(
      // Prevent back button
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header Card dengan Timer dan Navigasi Soal
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gray400.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Timer - Lebih besar untuk keterbacaan
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isTimeRunningOut
                                ? AppColors.red50
                                : AppColors.blue50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isTimeRunningOut
                                  ? AppColors.red600
                                  : AppColors.blue600,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 32,
                            color:
                                isTimeRunningOut
                                    ? AppColors.red600
                                    : AppColors.blue600,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _timeLimit > 0
                                ? _formatTime(remainingSeconds)
                                : _formatTime(_secondsElapsed),
                            style: AppTextStyles.headingLarge.copyWith(
                              color:
                                  isTimeRunningOut
                                      ? AppColors.red600
                                      : AppColors.blue600,
                              fontWeight: FontWeight.bold,
                              fontSize: 40,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Navigasi Soal
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Navigasi Soal',
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.gray700,
                              ),
                            ),
                            Text(
                              '${_getAnsweredCount()} terjawab',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.green600,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_questions.length, (index) {
                            final isAnswered = _answers.containsKey(index);
                            final isCurrent = index == _currentQuestionIndex;

                            return InkWell(
                              onTap: () => _goToQuestion(index),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color:
                                      isCurrent
                                          ? AppColors.primary
                                          : isAnswered
                                          ? AppColors.green600
                                          : AppColors.gray200,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      isCurrent
                                          ? Border.all(
                                            color: AppColors.primary,
                                            width: 3,
                                          )
                                          : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${index + 1}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color:
                                        isCurrent || isAnswered
                                            ? AppColors.white
                                            : AppColors.gray700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Soal Header - Simple
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${_currentQuestionIndex + 1}',
                                style: AppTextStyles.headingSmall.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Soal ${_currentQuestionIndex + 1}',
                              style: AppTextStyles.headingSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Question Text
                      Container(
                        padding: const EdgeInsets.all(20),
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
                        child: Text(
                          currentQuestion['question_text'] ?? '',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                            color: AppColors.gray800,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Options
                      ...['A', 'B', 'C', 'D'].asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final isSelected = userAnswer == option;

                        // Get option text from array or old format
                        String optionText = '';
                        if (currentQuestion['options'] != null &&
                            currentQuestion['options'] is List) {
                          final options = currentQuestion['options'] as List;
                          if (index < options.length) {
                            optionText = options[index].toString();
                          }
                        } else {
                          optionText = currentQuestion['option$option'] ?? '';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _selectAnswer(option),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? AppColors.primary.withOpacity(0.1)
                                        : AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? AppColors.primary
                                          : AppColors.gray300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          isSelected
                                              ? AppColors.primary
                                              : AppColors.gray200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      option,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color:
                                            isSelected
                                                ? AppColors.white
                                                : AppColors.gray700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      optionText,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color:
                                            isSelected
                                                ? AppColors.primary
                                                : AppColors.gray800,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 32),

                      // Navigation Buttons
                      Row(
                        children: [
                          // Prev Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _currentQuestionIndex > 0
                                      ? _previousQuestion
                                      : null,
                              icon: const Icon(Icons.arrow_back, size: 20),
                              label: const Text('Sebelumnya'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                side: BorderSide(
                                  color:
                                      _currentQuestionIndex > 0
                                          ? AppColors.primary
                                          : AppColors.gray300,
                                ),
                                foregroundColor:
                                    _currentQuestionIndex > 0
                                        ? AppColors.primary
                                        : AppColors.gray400,
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Next Button
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _nextQuestion,
                              icon: Icon(
                                _currentQuestionIndex < _questions.length - 1
                                    ? Icons.arrow_forward
                                    : Icons.check_circle,
                                size: 20,
                              ),
                              label: Text(
                                _currentQuestionIndex < _questions.length - 1
                                    ? 'Selanjutnya'
                                    : 'Selesai',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
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
}
