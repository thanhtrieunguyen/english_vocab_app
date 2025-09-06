import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/vocabulary.dart';

class QuizScreen extends StatefulWidget {
  final List<Vocabulary> vocabularies;
  final DateTime selectedDate;

  const QuizScreen({
    Key? key,
    required this.vocabularies,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int? selectedAnswerIndex;
  bool showAnswer = false;
  bool quizCompleted = false;
  late List<QuizQuestion> questions;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateQuestions();
  }

  void _generateQuestions() {
    questions = widget.vocabularies.map((vocab) {
      return _generateQuestionForVocabulary(vocab);
    }).toList();
    questions.shuffle(_random);
  }

  QuizQuestion _generateQuestionForVocabulary(Vocabulary correctVocab) {
    List<String> options = [correctVocab.meaning];
    
    // Tạo 3 đáp án sai từ các từ vựng khác
    List<Vocabulary> otherVocabs = widget.vocabularies
        .where((v) => v.word != correctVocab.word)
        .toList();
    
    while (options.length < 4 && otherVocabs.isNotEmpty) {
      int randomIndex = _random.nextInt(otherVocabs.length);
      String wrongAnswer = otherVocabs[randomIndex].meaning;
      
      if (!options.contains(wrongAnswer)) {
        options.add(wrongAnswer);
      }
      otherVocabs.removeAt(randomIndex);
    }
    
    // Nếu không đủ từ vựng khác, tạo đáp án giả
    while (options.length < 4) {
      options.add("Đáp án ${options.length}");
    }
    
    options.shuffle(_random);
    int correctIndex = options.indexOf(correctVocab.meaning);
    
    return QuizQuestion(
      vocabulary: correctVocab,
      options: options,
      correctIndex: correctIndex,
    );
  }

  void _selectAnswer(int index) {
    if (showAnswer) return;
    
    setState(() {
      selectedAnswerIndex = index;
      showAnswer = true;
      
      if (index == questions[currentQuestionIndex].correctIndex) {
        correctAnswers++;
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedAnswerIndex = null;
        showAnswer = false;
      });
    } else {
      setState(() {
        quizCompleted = true;
      });
    }
  }

  void _restartQuiz() {
    setState(() {
      currentQuestionIndex = 0;
      correctAnswers = 0;
      selectedAnswerIndex = null;
      showAnswer = false;
      quizCompleted = false;
      _generateQuestions();
    });
  }

  String _getPerformanceMessage() {
    double percentage = (correctAnswers / questions.length) * 100;
    if (percentage >= 90) return "Xuất sắc! 🎉";
    if (percentage >= 70) return "Tốt lắm! 👏";
    if (percentage >= 50) return "Khá ổn! 👍";
    return "Cần cải thiện! 💪";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (quizCompleted) {
      return _buildResultScreen(colorScheme);
    }

    final currentQuestion = questions[currentQuestionIndex];
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz - Câu ${currentQuestionIndex + 1}/${questions.length}'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            onPressed: () => _showExitDialog(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (currentQuestionIndex + 1) / questions.length,
                backgroundColor: colorScheme.outline.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ).animate().slideX(duration: 300.ms),
              
              const SizedBox(height: 24),
              
              // Question card
              Expanded(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Vocabulary word
                        Text(
                          currentQuestion.vocabulary.word,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(duration: 500.ms).scale(),
                        
                        const SizedBox(height: 8),
                        
                        // Pronunciation
                        Text(
                          '/${currentQuestion.vocabulary.pronunciation}/',
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),
                        
                        const SizedBox(height: 32),
                        
                        Text(
                          'Chọn nghĩa đúng:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ).animate().fadeIn(delay: 400.ms),
                        
                        const SizedBox(height: 24),
                        
                        // Answer options
                        ...currentQuestion.options.asMap().entries.map((entry) {
                          int index = entry.key;
                          String option = entry.value;
                          
                          Color? backgroundColor;
                          Color? textColor;
                          IconData? icon;
                          
                          if (showAnswer) {
                            if (index == currentQuestion.correctIndex) {
                              backgroundColor = Colors.green.withOpacity(0.2);
                              textColor = Colors.green.shade700;
                              icon = Icons.check_circle;
                            } else if (index == selectedAnswerIndex) {
                              backgroundColor = Colors.red.withOpacity(0.2);
                              textColor = Colors.red.shade700;
                              icon = Icons.cancel;
                            }
                          } else if (selectedAnswerIndex == index) {
                            backgroundColor = colorScheme.primary.withOpacity(0.2);
                            textColor = colorScheme.primary;
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _selectAnswer(index),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: backgroundColor ?? colorScheme.surface,
                                  foregroundColor: textColor ?? colorScheme.onSurface,
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: backgroundColor != null 
                                          ? (textColor ?? colorScheme.outline)
                                          : colorScheme.outline,
                                      width: 1,
                                    ),
                                  ),
                                  elevation: backgroundColor != null ? 4 : 1,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                    if (icon != null) ...[
                                      const SizedBox(width: 8),
                                      Icon(icon, size: 20),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ).animate().slideX(
                            delay: Duration(milliseconds: 600 + (index * 100)),
                            duration: 300.ms,
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Next button
              if (showAnswer)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _nextQuestion,
                    icon: Icon(currentQuestionIndex < questions.length - 1 
                        ? Icons.arrow_forward 
                        : Icons.flag),
                    label: Text(currentQuestionIndex < questions.length - 1 
                        ? 'Câu tiếp theo' 
                        : 'Hoàn thành'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ).animate().slideY(duration: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen(ColorScheme colorScheme) {
    double percentage = (correctAnswers / questions.length) * 100;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả Quiz'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.surface,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Score circle
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.1),
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 4,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${correctAnswers}/${questions.length}',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 600.ms),
              
              const SizedBox(height: 32),
              
              // Performance message
              Text(
                _getPerformanceMessage(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              
              const SizedBox(height: 16),
              
              Text(
                'Bạn đã trả lời đúng $correctAnswers/${questions.length} câu hỏi',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 500.ms),
              
              const SizedBox(height: 48),
              
              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _restartQuiz,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Làm lại Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ).animate().slideX(delay: 700.ms),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.home),
                      label: const Text('Về trang chính'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: colorScheme.primary),
                      ),
                    ),
                  ).animate().slideX(delay: 800.ms),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát Quiz'),
        content: const Text('Bạn có chắc chắn muốn thoát? Tiến độ sẽ bị mất.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close quiz screen
            },
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }
}

class QuizQuestion {
  final Vocabulary vocabulary;
  final List<String> options;
  final int correctIndex;

  QuizQuestion({
    required this.vocabulary,
    required this.options,
    required this.correctIndex,
  });
}
