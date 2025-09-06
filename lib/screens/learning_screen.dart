import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';
import 'edit_vocabulary_dialog.dart';
import 'quiz_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LearningScreen extends StatefulWidget {
  final List<Vocabulary> vocabularies;
  final DateTime date;

  const LearningScreen({
    super.key,
    required this.vocabularies,
    required this.date,
  });

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final VocabularyService _vocabularyService = VocabularyService();
  List<Vocabulary> _vocabularies = [];

  @override
  void initState() {
    super.initState();
    
    _vocabularies = List.from(widget.vocabularies); // Create a mutable copy
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_vocabularies.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Học từ vựng'),
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
        ),
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Text(
            'Không có từ vựng nào để học',
            style: TextStyle(fontSize: 18, color: colorScheme.onSurface.withOpacity(0.6)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Học từ vựng - ${widget.date.day}/${widget.date.month}/${widget.date.year}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _startQuiz(),
            icon: const Icon(Icons.quiz),
            tooltip: 'Làm bài Quiz',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_vocabularies.length} từ',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.9,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: _vocabularies.length,
                itemBuilder: (context, index) {
                  final vocab = _vocabularies[index];
                  return Card(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header với số thứ tự và từ vựng
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          vocab.word,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '/${vocab.pronunciation}/',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: colorScheme.onSurface.withOpacity(0.6),
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _editVocabulary(index),
                                    tooltip: 'Chỉnh sửa từ vựng',
                                    icon: Icon(
                                      Icons.edit,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteVocabulary(index),
                                    tooltip: 'Xóa từ vựng',
                                    icon: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Nghĩa
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.primary.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nghĩa:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      vocab.meaning,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // API Information & Examples
                              _buildApiInfoDisplay(vocab),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: index * 100))
                      .fadeIn()
                      .slideY(begin: 0.3);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApiInfoDisplay(Vocabulary vocab) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // First try to use the new apiDefinitions field
    if (vocab.apiDefinitions != null && vocab.apiDefinitions!.isNotEmpty) {
      try {
        final List<dynamic> definitions = jsonDecode(vocab.apiDefinitions!);
        if (definitions.isNotEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.tertiary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: colorScheme.tertiary,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Cambridge Dictionary',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Display up to 2 definitions
                ...definitions.take(2).map((definition) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.5), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Part of speech
                      if (definition['partOfSpeech'] != null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                definition['partOfSpeech'],
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      
                      // Definition
                      if (definition['definition'] != null)
                        Text(
                          definition['definition'],
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      // Example
                      if (definition['example'] != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: colorScheme.secondary.withOpacity(0.3), width: 0.5),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.format_quote,
                                color: colorScheme.secondary,
                                size: 10,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  definition['example'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: colorScheme.onSurface,
                                    fontStyle: FontStyle.italic,
                                    height: 1.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                )).toList(),
              ],
            ),
          );
        }
      } catch (e) {
        // Fall through to legacy parsing if JSON parsing fails
      }
    }
    
    // Legacy parsing for old format in example field
    String exampleText = vocab.example;
    bool isApiFormat = exampleText.contains('\n\n') && 
                      (exampleText.contains('(verb)') || 
                       exampleText.contains('(noun)') ||
                       exampleText.contains('(adjective)') ||
                       exampleText.contains('Example:'));
    
    if (!isApiFormat) {
      // Hiển thị đơn giản nếu không phải format API
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.tertiary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.tertiary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.format_quote,
                  color: colorScheme.tertiary,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Ví dụ:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              exampleText,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface,
                fontStyle: FontStyle.italic,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    
    // Parse API format from legacy example field
    List<String> sections = exampleText.split('\n\n');
    List<Map<String, dynamic>> definitions = [];
    String? mainExample;
    
    for (String section in sections) {
      if (section.startsWith('(') && section.contains(')')) {
        // Đây là definition
        int endParen = section.indexOf(')');
        String pos = section.substring(1, endParen);
        String text = section.substring(endParen + 1).trim();
        definitions.add({
          'pos': pos,
          'text': text,
        });
      } else if (section.startsWith('Example:')) {
        // Đây là example
        mainExample = section.substring(8).trim();
      }
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.tertiary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: colorScheme.tertiary,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                'Cambridge Dictionary',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Definitions
          ...definitions.map((def) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colorScheme.outline.withOpacity(0.5), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        def['pos'],
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  def['text'],
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )).toList(),
          
          // Main Example
          if (mainExample != null && mainExample.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colorScheme.secondary.withOpacity(0.3), width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.format_quote,
                    color: colorScheme.secondary,
                    size: 10,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      mainExample,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface,
                        fontStyle: FontStyle.italic,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editVocabulary(int index) {
    if (index >= 0 && index < _vocabularies.length) {
      showDialog(
        context: context,
        builder: (context) => EditVocabularyDialog(
          vocabulary: _vocabularies[index],
          date: widget.date,
          index: index,
          onUpdated: () async {
            // Reload the vocabulary list
            final updatedVocabularies = await _vocabularyService.getVocabularyForDate(widget.date);
            setState(() {
              _vocabularies = updatedVocabularies;
            });
          },
        ),
      );
    }
  }

  void _startQuiz() {
    if (_vocabularies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có từ vựng nào để làm quiz!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizScreen(
          vocabularies: _vocabularies,
          selectedDate: widget.date,
        ),
      ),
    );
  }

  // Method để xóa từ vựng
  void _deleteVocabulary(int index) {
    if (index < 0 || index >= _vocabularies.length) return;
    
    final vocab = _vocabularies[index];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Xác nhận xóa'),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa từ vựng "${vocab.word}"?\nHành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDelete(index);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Method thực hiện xóa từ vựng
  Future<void> _performDelete(int index) async {
    try {
      // Hiển thị loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Xóa từ vocabulary service
      await _vocabularyService.deleteVocabulary(widget.date, index);
      
      // Cập nhật danh sách local
      setState(() {
        _vocabularies.removeAt(index);
      });

      if (mounted) {
        Navigator.of(context).pop(); // Đóng loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa từ vựng thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Đóng loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi xóa từ vựng: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
