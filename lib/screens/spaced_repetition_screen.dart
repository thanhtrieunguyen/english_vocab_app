import 'package:flutter/material.dart';
import '../models/vocabulary.dart';
import '../services/spaced_repetition_service.dart';

class SpacedRepetitionScreen extends StatefulWidget {
  const SpacedRepetitionScreen({super.key});

  @override
  State<SpacedRepetitionScreen> createState() => _SpacedRepetitionScreenState();
}

class _SpacedRepetitionScreenState extends State<SpacedRepetitionScreen>
    with TickerProviderStateMixin {
  final SpacedRepetitionService _spacedRepetitionService = SpacedRepetitionService();
  
  List<VocabularyReviewItem> _reviewItems = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _showAnswer = false;
  bool _isCompleted = false;
  
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

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
    
    // Đảm bảo khởi tạo dữ liệu Spaced Repetition
    _spacedRepetitionService.performDailyCheck();
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
      setState(() {
        _reviewItems = items;
        _isLoading = false;
        _isCompleted = items.isEmpty;
      });
      
      if (items.isNotEmpty) {
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

  void _toggleShowAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  Future<void> _submitAnswer(int quality) async {
    if (_currentIndex >= _reviewItems.length) return;

    final currentItem = _reviewItems[_currentIndex];
    
    try {
      await _spacedRepetitionService.updateVocabularyAfterReview(
        vocabulary: currentItem.vocabulary,
        originalDate: currentItem.originalDate,
        vocabularyIndex: currentItem.vocabularyIndex,
        quality: quality,
      );

      // Chuyển sang câu tiếp theo hoặc hoàn thành
      _nextQuestion();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu kết quả: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextQuestion() {
    setState(() {
      _showAnswer = false;
      _currentIndex++;
      
      if (_currentIndex >= _reviewItems.length) {
        _isCompleted = true;
      }
    });
    
    if (!_isCompleted) {
      _progressAnimationController.reset();
      _progressAnimationController.forward();
    }
  }

  double get _progress {
    if (_reviewItems.isEmpty) return 0.0;
    return _currentIndex / _reviewItems.length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Spaced Repetition',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'reset':
                  _showResetDialog();
                  break;
                case 'info':
                  _showInfoDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('Hướng dẫn'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Reset dữ liệu'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : _isCompleted
              ? _buildCompletedView()
              : _buildReviewView(),
    );
  }

  Widget _buildReviewView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentItem = _reviewItems[_currentIndex];
    final vocabulary = currentItem.vocabulary;

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
                    '${_currentIndex + 1} / ${_reviewItems.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
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

        // Vocabulary card
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
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
                    Expanded(child: _buildQuestionSide(vocabulary)),
                    if (_showAnswer) ...[
                      const SizedBox(height: 16),
                      const Divider(thickness: 1),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.secondary.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: _buildAnswerContent(vocabulary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),

        // Action buttons
        Container(
          padding: const EdgeInsets.all(16),
          child: _showAnswer ? _buildAnswerButtons() : _buildShowAnswerButton(),
        ),
      ],
    );
  }

  Widget _buildQuestionSide(Vocabulary vocabulary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.quiz,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          vocabulary.word,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (vocabulary.pronunciation.isNotEmpty)
          Text(
            vocabulary.pronunciation,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 20),
        Text(
          'Bạn có nhớ nghĩa của từ này không?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Text(
            'Lần ôn: ${vocabulary.repetitionCount + 1}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerContent(Vocabulary vocabulary) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb,
              size: 20,
              color: colorScheme.secondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Đáp án:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          vocabulary.meaning,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        if (vocabulary.example.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.format_quote,
                size: 16,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Ví dụ:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            vocabulary.example,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildShowAnswerButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _toggleShowAnswer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Hiển thị đáp án',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAnswerButtons() {
    return Column(
      children: [
        const Text(
          'Đánh giá mức độ ghi nhớ của bạn:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQualityButton(
                quality: 1,
                label: 'Khó',
                color: Colors.red,
                description: 'Hoàn toàn không nhớ',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQualityButton(
                quality: 3,
                label: 'Tốt',
                color: Colors.orange,
                description: 'Nhớ với một chút khó khăn',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQualityButton(
                quality: 5,
                label: 'Dễ',
                color: Colors.green,
                description: 'Nhớ ngay lập tức',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQualityButton({
    required int quality,
    required String label,
    required Color color,
    required String description,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _submitAnswer(quality),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCompletedView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              Icons.celebration,
              size: 80,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Hoàn thành!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _reviewItems.isEmpty 
                ? 'Không có từ vựng nào cần ôn lại hôm nay!'
                : 'Bạn đã hoàn thành ${_reviewItems.length} từ vựng!',
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Quay lại',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Spaced Repetition'),
        content: const Text(
          'Điều này sẽ xóa toàn bộ dữ liệu Spaced Repetition và đặt lại tất cả từ vựng về trạng thái ban đầu. Bạn có chắc chắn?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              await _spacedRepetitionService.resetAllSpacedRepetitionData();
              
              if (mounted) {
                Navigator.of(context).pop(); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã reset thành công!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadReviewItems();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Hướng dẫn Spaced Repetition',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spaced Repetition là phương pháp học tập dựa trên việc ôn lại kiến thức theo khoảng thời gian tăng dần.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Cách hoạt động:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Từ mới sẽ xuất hiện sau 1 ngày'),
              Text('• Nếu bạn nhớ tốt, khoảng cách sẽ tăng lên'),
              Text('• Nếu bạn quên, từ sẽ được reset về đầu'),
              Text('• Khoảng cách tối đa có thể lên đến vài tháng'),
              SizedBox(height: 16),
              Text(
                'Cách đánh giá:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('🔴 Khó: Hoàn toàn không nhớ'),
              Text('🟠 Tốt: Nhớ với một chút khó khăn'),
              Text('🟢 Dễ: Nhớ ngay lập tức'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

}
