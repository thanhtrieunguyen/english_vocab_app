import 'package:flutter/material.dart';
import '../models/vocabulary.dart';
import '../services/leitner_service.dart';

class LeitnerSystemScreen extends StatefulWidget {
  const LeitnerSystemScreen({super.key});

  @override
  State<LeitnerSystemScreen> createState() => _LeitnerSystemScreenState();
}

class _LeitnerSystemScreenState extends State<LeitnerSystemScreen>
    with TickerProviderStateMixin {
  final LeitnerService _leitnerService = LeitnerService();
  
  List<LeitnerReviewItem> _reviewItems = [];
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
    
    // Đảm bảo khởi tạo dữ liệu Leitner
    _leitnerService.initializeLeitnerForNewVocabularies();
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
      await _leitnerService.initializeLeitnerForNewVocabularies();
      final items = await _leitnerService.getLeitnerReviews();
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

  Future<void> _submitAnswer(bool isCorrect) async {
    if (_currentIndex >= _reviewItems.length) return;

    final currentItem = _reviewItems[_currentIndex];
    
    try {
      await _leitnerService.updateVocabularyAfterLeitnerReview(
        vocabulary: currentItem.vocabulary,
        originalDate: currentItem.originalDate,
        vocabularyIndex: currentItem.vocabularyIndex,
        isCorrect: isCorrect,
      );

      // Chuyển sang câu tiếp theo
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
          'Leitner System',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.view_module),
            onPressed: _showBoxesOverview,
            tooltip: 'Xem các hộp',
          ),
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
        // Progress bar với thông tin hộp
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(vocabulary.leitnerBoxColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      vocabulary.leitnerBoxName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Color(vocabulary.leitnerBoxColor)),
                  );
                },
              ),
            ],
          ),
        ),

        // Vocabulary card đơn giản không có animation
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Card(
              elevation: 8,
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
                    colors: [
                      Color(vocabulary.leitnerBoxColor).withOpacity(0.7),
                      Color(vocabulary.leitnerBoxColor).withOpacity(0.9),
                    ],
                  ),
                ),
                child: _showAnswer
                    ? _buildAnswerSide(vocabulary)
                    : _buildQuestionSide(vocabulary),
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
          size: 40,
          color: Colors.white,
        ),
        const SizedBox(height: 24),
        Text(
          vocabulary.word,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if (vocabulary.pronunciation.isNotEmpty)
          Text(
            vocabulary.pronunciation,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Bạn có nhớ nghĩa của từ này không?',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Liên tiếp: ${vocabulary.consecutiveCorrect}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (vocabulary.lastLeitnerReview != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Ôn lần cuối: ${DateTime.now().difference(vocabulary.lastLeitnerReview!).inDays} ngày trước',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerSide(Vocabulary vocabulary) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lightbulb,
          size: 32,
          color: Colors.white,
        ),
        const SizedBox(height: 16),
        Text(
          'Đáp án:',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          vocabulary.meaning,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        if (vocabulary.example.isNotEmpty) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'Ví dụ:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  vocabulary.example,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
          'Xem đáp án',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAnswerButtons() {
    return Column(
      children: [
        const Text(
          'Bạn có nhớ được không?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _submitAnswer(false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.close, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Không nhớ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '→ Hộp 1',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _submitAnswer(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check, size: 24),
                    const SizedBox(height: 4),
                    const Text(
                      'Nhớ được',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _getPromotionText(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getPromotionText() {
    if (_currentIndex >= _reviewItems.length) return '';
    
    final vocab = _reviewItems[_currentIndex].vocabulary;
    if (vocab.consecutiveCorrect + 1 >= 2 && vocab.leitnerBox < 5) {
      return '→ Hộp ${vocab.leitnerBox + 1}';
    } else if (vocab.leitnerBox >= 5) {
      return '→ Hoàn thiện';
    } else {
      return '→ Tiến bộ (${vocab.consecutiveCorrect + 1}/2)';
    }
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
            'Hoàn thành Leitner!',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _reviewItems.isEmpty 
                ? 'Không có từ vựng nào cần ôn theo Leitner hôm nay!'
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

  void _showBoxesOverview() async {
    final boxDistribution = await _leitnerService.getBoxDistribution();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Các hộp Leitner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final box = index + 1;
              final count = boxDistribution[box] ?? 0;
              final intervals = [1, 3, 7, 14, 30];
              
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(Vocabulary(
                      word: '', meaning: '', pronunciation: '', 
                      memoryTip: '', example: '', createdAt: DateTime.now(),
                      leitnerBox: box,
                    ).leitnerBoxColor),
                    child: Text(
                      '$box',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('Hộp $box'),
                  subtitle: Text('Ôn lại mỗi ${intervals[index]} ngày'),
                  trailing: Text(
                    '$count từ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }),
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

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Leitner System'),
        content: const Text(
          'Điều này sẽ đặt lại tất cả từ vựng về Hộp 1 và xóa toàn bộ dữ liệu Leitner. Bạn có chắc chắn?',
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

              await _leitnerService.resetAllLeitnerData();
              
              if (mounted) {
                Navigator.of(context).pop(); // Close loading
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã reset Leitner System thành công!'),
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
          'Hướng dẫn Leitner System',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leitner System là phương pháp học sử dụng thẻ học được phân loại vào 5 hộp dựa trên mức độ hiểu biết.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Cách hoạt động:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Hộp 1 (Đỏ): Từ mới hoặc khó - ôn mỗi ngày'),
              Text('• Hộp 2 (Cam): Đang học - ôn mỗi 3 ngày'),
              Text('• Hộp 3 (Vàng): Quen thuộc - ôn mỗi tuần'),
              Text('• Hộp 4 (Xanh nhạt): Thành thạo - ôn mỗi 2 tuần'),
              Text('• Hộp 5 (Xanh): Hoàn thiện - ôn mỗi tháng'),
              SizedBox(height: 16),
              Text(
                'Quy tắc:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('✅ Đúng 2 lần liên tiếp → Lên hộp cao hơn'),
              Text('❌ Sai 1 lần → Về hộp 1'),
              Text('🔄 Ôn tập theo lịch trình của từng hộp'),
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
