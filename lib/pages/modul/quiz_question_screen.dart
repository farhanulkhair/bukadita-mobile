import 'package:flutter/material.dart';
import 'dart:async';
import '../../theme/theme.dart';
import '../../services/quiz_service.dart';
import '../../utils/error_helper.dart';

/// Quiz Questions Screen - Halaman soal-soal kuis
/// Tidak ada tombol kembali - user harus menyelesaikan kuis
class QuizQuestionScreen extends StatefulWidget {
  const QuizQuestionScreen({super.key});

  @override
  State<QuizQuestionScreen> createState() => _QuizQuestionScreenState();
}

class _QuizQuestionScreenState extends State<QuizQuestionScreen> {
  final QuizService _quizService = QuizService();
  final ScrollController _scrollController = ScrollController();

  String _quizId = '';
  String _materialId = '';
  String _moduleId = '';
  int _currentQuestionIndex = 0;
  Map<int, String> _answers = {};
  Timer? _timer;
  int _secondsElapsed = 0;
  int _timeLimit = 0;

  String _quizTitle = '';
  String _poinTitle = '';
  List<Map<String, dynamic>> _questions = [];

  bool _isNavExpanded = false;

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
      _timeLimit = timeLimitMinutes * 60;

      _startTimer();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });

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
    _scrollController.dispose();
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

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _goToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
      _isNavExpanded = false;
    });
    _scrollToTop();
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _scrollToTop();
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _scrollToTop();
    } else {
      _submitQuiz();
    }
  }

  void _submitQuiz({bool timeUp = false}) {
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
      List<Map<String, dynamic>> answersList = [];
      for (int i = 0; i < _questions.length; i++) {
        final question = _questions[i];
        final userAnswer = _answers[i] ?? '';

        int? optionIndex;
        if (userAnswer.isNotEmpty) {
          optionIndex = userAnswer.codeUnitAt(0) - 'A'.codeUnitAt(0);
        }

        answersList.add({
          'question_id': question['id'],
          'selected_option_index': optionIndex,
        });
      }

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

      final resultData = submitResult['data'];
      final score = (resultData['score'] as num?)?.toInt() ?? 0;
      final correctCount = (resultData['correct_count'] as num?)?.toInt() ?? 0;

      final resultAnswers = resultData['answers'] as List? ?? [];
      final Map<String, dynamic> correctAnswersMap = {};

      for (var answer in resultAnswers) {
        final questionId = answer['question_id'];
        final correctIndex = answer['correct_answer_index'];
        if (correctIndex != null) {
          correctAnswersMap[questionId] = correctIndex;
        }
      }

      final questionsWithAnswers =
          _questions.map((q) {
            final correctIndex = correctAnswersMap[q['id']];
            return {...q, 'correct_answer_index': correctIndex};
          }).toList();

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
        if (result != null && mounted) {
          Navigator.pop(context, result);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyErrorMessage(e)),
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

    final remainingSeconds = _timeLimit > 0 ? _timeLimit - _secondsElapsed : 0;
    final isTimeRunningOut = remainingSeconds <= 60 && remainingSeconds > 0;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Compact header: timer + progress + nav toggle
              _buildCompactHeader(remainingSeconds, isTimeRunningOut),

              // Collapsible question navigation
              _buildCollapsibleNav(),

              // Question content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // Question header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${_currentQuestionIndex + 1}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Soal ${_currentQuestionIndex + 1} dari ${_questions.length}',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Question text
                      Container(
                        padding: const EdgeInsets.all(18),
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

                      const SizedBox(height: 16),

                      // Options
                      ...['A', 'B', 'C', 'D'].asMap().entries.map((entry) {
                        final index = entry.key;
                        final option = entry.value;
                        final isSelected = userAnswer == option;

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
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () => _selectAnswer(option),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
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
                                    width: 34,
                                    height: 34,
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
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
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
                      }),

                      const SizedBox(height: 24),

                      // Navigation Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _currentQuestionIndex > 0
                                      ? _previousQuestion
                                      : null,
                              icon: const Icon(Icons.arrow_back, size: 18),
                              label: const Text('Sebelumnya'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
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

                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _nextQuestion,
                              icon: Icon(
                                _currentQuestionIndex < _questions.length - 1
                                    ? Icons.arrow_forward
                                    : Icons.check_circle,
                                size: 18,
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
                                  vertical: 14,
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

  Widget _buildCompactHeader(int remainingSeconds, bool isTimeRunningOut) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.gray400.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Timer chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isTimeRunningOut ? AppColors.red50 : AppColors.blue50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isTimeRunningOut ? AppColors.red600 : AppColors.blue600,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color:
                      isTimeRunningOut ? AppColors.red600 : AppColors.blue600,
                ),
                const SizedBox(width: 6),
                Text(
                  _timeLimit > 0
                      ? _formatTime(remainingSeconds)
                      : _formatTime(_secondsElapsed),
                  style: AppTextStyles.labelMedium.copyWith(
                    color:
                        isTimeRunningOut
                            ? AppColors.red600
                            : AppColors.blue600,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Progress indicator
          Text(
            '${_getAnsweredCount()}/${_questions.length}',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.green600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'terjawab',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.gray500,
            ),
          ),

          const SizedBox(width: 12),

          // Nav toggle button
          InkWell(
            onTap: () {
              setState(() {
                _isNavExpanded = !_isNavExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color:
                    _isNavExpanded
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.gray100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _isNavExpanded ? AppColors.primary : AppColors.gray300,
                ),
              ),
              child: Icon(
                _isNavExpanded
                    ? Icons.grid_view_rounded
                    : Icons.grid_view_outlined,
                size: 20,
                color:
                    _isNavExpanded ? AppColors.primary : AppColors.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleNav() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child:
          _isNavExpanded
              ? Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.gray200,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Navigasi Soal',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray600,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isNavExpanded = false;
                            });
                          },
                          child: Icon(
                            Icons.keyboard_arrow_up,
                            size: 20,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(_questions.length, (index) {
                        final isAnswered = _answers.containsKey(index);
                        final isCurrent = index == _currentQuestionIndex;

                        return InkWell(
                          onTap: () => _goToQuestion(index),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color:
                                  isCurrent
                                      ? AppColors.primary
                                      : isAnswered
                                      ? AppColors.green600
                                      : AppColors.gray200,
                              borderRadius: BorderRadius.circular(6),
                              border:
                                  isCurrent
                                      ? Border.all(
                                        color: AppColors.primary,
                                        width: 2,
                                      )
                                      : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color:
                                    isCurrent || isAnswered
                                        ? AppColors.white
                                        : AppColors.gray700,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              )
              : const SizedBox.shrink(),
    );
  }
}
