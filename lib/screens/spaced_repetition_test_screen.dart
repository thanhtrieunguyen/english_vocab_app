import 'package:flutter/material.dart';
import '../models/vocabulary.dart';
import '../services/spaced_repetition_service.dart';
import 'dart:math';

class SpacedRepetitionTestScreen extends StatefulWidget {
  const SpacedRepetitionTestScreen({super.key});

  @override
  State<SpacedRepetitionTestScreen> createState() => _SpacedRepetitionTestScreenState();
}

class _SpacedRepetitionTestScreenState extends State<SpacedRepetitionTestScreen>
    with TickerProviderStateMixin {
  final SpacedRepetitionService _spacedRepetitionService = SpacedRepetitionService();
  
  List<QuizQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  bool _isCompleted = false;
  bool _hasAnswered = false;
  String? _selectedAnswer;
  
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  Map<String, int> _results = {'correct': 0, 'total': 0};

  @override
  void initState() {
    super.initState();
    
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeOut,
    ));

    _loadReviewItems();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadReviewItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final items = await _spacedRepetitionService.getTodayReviews();
      
      if (items.isEmpty) {
        setState(() {
          _isLoading = false;
          _isCompleted = true;
        });
        return;
      }

      // Tạo câu hỏi từ vocabulary items
      final questions = await _generateQuestions(items);
      
      setState(() {
        _questions = questions;
        _isLoading = false;
        _isCompleted = questions.isEmpty;
      });
      
      if (questions.isNotEmpty) {
        _progressAnimationController.forward();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<QuizQuestion>> _generateQuestions(List<VocabularyReviewItem> items) async {
    final questions = <QuizQuestion>[];
    final random = Random();
    
    // Lấy tất cả từ vựng để tạo câu trả lời sai
    final allVocabularies = <Vocabulary>[];
    final dates = await _spacedRepetitionService.vocabularyService.getAllVocabularyDates();
    for (final date in dates) {
      final vocabs = await _spacedRepetitionService.vocabularyService.getVocabularyForDate(date);
      allVocabularies.addAll(vocabs);
    }

    for (final item in items) {
      final vocab = item.vocabulary;
      
      // Tạo câu hỏi nghĩa từ tiếng Anh
      final wrongAnswers = allVocabularies
          .where((v) => v.word != vocab.word && v.meaning.isNotEmpty)
          .map((v) => v.meaning)
          .toSet()
          .toList();
      
      if (wrongAnswers.length >= 3) {
        wrongAnswers.shuffle(random);
        final options = [vocab.meaning, ...wrongAnswers.take(3)];
        options.shuffle(random);
        
        questions.add(QuizQuestion(
          reviewItem: item,
          question: 'Nghĩa của từ "${vocab.word}" là gì?',
          options: options,
          correctAnswer: vocab.meaning,
          type: QuestionType.meaningFromWord,
        ));
      }
      
      // Tạo câu hỏi từ vựng từ nghĩa
      final wrongWords = allVocabularies
          .where((v) => v.word != vocab.word && v.word.isNotEmpty)
          .map((v) => v.word)
          .toSet()
          .toList();
      
      if (wrongWords.length >= 3) {
        wrongWords.shuffle(random);
        final options = [vocab.word, ...wrongWords.take(3)];
        options.shuffle(random);
        
        questions.add(QuizQuestion(
          reviewItem: item,
          question: 'Từ nào có nghĩa là "${vocab.meaning}"?',
          options: options,
          correctAnswer: vocab.word,
          type: QuestionType.wordFromMeaning,
        ));
      }
    }
    
    questions.shuffle(random);
    return questions.take(20).toList(); // Giới hạn 20 câu
  }

  void _selectAnswer(String answer) {
    if (_hasAnswered) return;
    
    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });
  }

  Future<void> _nextQuestion() async {
    if (!_hasAnswered) return;

    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = _selectedAnswer == currentQuestion.correctAnswer;
    
    // Cập nhật kết quả
    setState(() {
      _results['total'] = _results['total']! + 1;
      if (isCorrect) {
        _results['correct'] = _results['correct']! + 1;
      }
    });

    // Cập nhật spaced repetition data
    final quality = isCorrect ? 5 : 1; // 5 cho đúng, 1 cho sai
    try {
      await _spacedRepetitionService.updateVocabularyAfterReview(
        vocabulary: currentQuestion.reviewItem.vocabulary,
        originalDate: currentQuestion.reviewItem.originalDate,
        vocabularyIndex: currentQuestion.reviewItem.vocabularyIndex,
        quality: quality,
      );
    } catch (e) {
      print('Error updating vocabulary: $e');
    }

    // Chuyển câu tiếp theo
    await Future.delayed(const Duration(milliseconds: 1500));
    
    setState(() {
      _currentQuestionIndex++;
      _hasAnswered = false;
      _selectedAnswer = null;
      
      if (_currentQuestionIndex >= _questions.length) {
        _isCompleted = true;
      }
    });
    
    if (!_isCompleted) {
      _progressAnimationController.reset();
      _progressAnimationController.forward();
    }
  }

  double get _progress {
    if (_questions.isEmpty) return 0.0;
    return _currentQuestionIndex / _questions.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Kiểm tra Spaced Repetition',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : _isCompleted
              ? _buildCompletedView()
              : _buildQuizView(),
    );
  }

  Widget _buildQuizView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentQuestion = _questions[_currentQuestionIndex];

    return Column(
      children: [
        // Progress bar
        Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu ${_currentQuestionIndex + 1} / ${_questions.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Đúng: ${_results['correct']}/${_results['total']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AnimatedBuilder(
                animation: _progressAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progress * _progressAnimation.value,
                    backgroundColor: colorScheme.surfaceContainer,
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  );
                },
              ),
            ],
          ),
        ),

        // Question
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Question card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primaryContainer, colorScheme.secondaryContainer],
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          currentQuestion.type == QuestionType.meaningFromWord
                              ? Icons.translate
                              : Icons.quiz,
                          size: 48,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          currentQuestion.question,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Options
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.options.length,
                    itemBuilder: (context, index) {
                      final option = currentQuestion.options[index];
                      final isSelected = _selectedAnswer == option;
                      final isCorrect = option == currentQuestion.correctAnswer;
                      
                      Color? backgroundColor;
                      Color? textColor;
                      
                      if (_hasAnswered) {
                        if (isCorrect) {
                          backgroundColor = Colors.green;
                          textColor = Colors.white;
                        } else if (isSelected && !isCorrect) {
                          backgroundColor = Colors.red;
                          textColor = Colors.white;
                        }
                      } else if (isSelected) {
                        backgroundColor = colorScheme.primary;
                        textColor = colorScheme.onPrimary;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: backgroundColor ?? colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: () => _selectAnswer(option),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected 
                                      ? colorScheme.primary 
                                      : colorScheme.outline,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: textColor ?? colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Next button
        if (_hasAnswered)
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _currentQuestionIndex + 1 >= _questions.length ? 'Hoàn thành' : 'Câu tiếp theo',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompletedView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accuracy = _results['total']! > 0 
        ? ((_results['correct']! / _results['total']!) * 100).round()
        : 0;

    String getMessage() {
      if (accuracy >= 90) return 'Xuất sắc! 🎉';
      if (accuracy >= 80) return 'Rất tốt! 👏';
      if (accuracy >= 70) return 'Tốt! 👍';
      if (accuracy >= 60) return 'Khá! 😊';
      return 'Cần cố gắng thêm! 💪';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              accuracy >= 80 ? Icons.celebration : Icons.quiz,
              size: 80,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Hoàn thành kiểm tra!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            getMessage(),
            style: TextStyle(
              fontSize: 20,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Kết quả',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultItem(
                      'Tổng số câu',
                      '${_results['total']}',
                      Icons.quiz,
                      colorScheme.primary,
                    ),
                    _buildResultItem(
                      'Đúng',
                      '${_results['correct']}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildResultItem(
                      'Độ chính xác',
                      '$accuracy%',
                      Icons.analytics,
                      accuracy >= 80 ? Colors.green : 
                      accuracy >= 60 ? Colors.orange : Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentQuestionIndex = 0;
                    _hasAnswered = false;
                    _selectedAnswer = null;
                    _isCompleted = false;
                    _results = {'correct': 0, 'total': 0};
                  });
                  _loadReviewItems();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.secondary,
                  foregroundColor: colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Làm lại',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Quay lại',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Quiz question model
class QuizQuestion {
  final VocabularyReviewItem reviewItem;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final QuestionType type;

  QuizQuestion({
    required this.reviewItem,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.type,
  });
}

enum QuestionType {
  meaningFromWord,
  wordFromMeaning,
}
