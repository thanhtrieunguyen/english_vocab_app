import 'package:flutter/material.dart';
import '../services/spaced_repetition_service.dart';
import '../screens/spaced_repetition_screen.dart';
import '../screens/spaced_repetition_test_screen.dart';

class SpacedRepetitionInfoWidget extends StatefulWidget {
  const SpacedRepetitionInfoWidget({super.key});

  @override
  State<SpacedRepetitionInfoWidget> createState() => _SpacedRepetitionInfoWidgetState();
}

class _SpacedRepetitionInfoWidgetState extends State<SpacedRepetitionInfoWidget> {
  final SpacedRepetitionService _spacedRepetitionService = SpacedRepetitionService();
  
  bool _isLoading = true;
  int _reviewsToday = 0;
  int _todayCorrect = 0;
  int _todayTotal = 0;
  double _todayAccuracy = 0;
  
  int _newCount = 0;
  int _learningCount = 0;
  int _reviewingCount = 0;
  int _matureCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load review data
      final reviewItems = await _spacedRepetitionService.getTodayReviews();
      final stats = await _spacedRepetitionService.getTodayReviewStats();
      final levels = await _spacedRepetitionService.getVocabularyLevels();
      
      setState(() {
        _reviewsToday = reviewItems.length;
        _todayCorrect = stats['correct'] ?? 0;
        _todayTotal = stats['total'] ?? 0;
        _todayAccuracy = _todayTotal > 0 ? (_todayCorrect / _todayTotal) * 100 : 0;
        
        _newCount = levels['new'] ?? 0;
        _learningCount = levels['learning'] ?? 0;
        _reviewingCount = levels['reviewing'] ?? 0;
        _matureCount = levels['mature'] ?? 0;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading spaced repetition data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.purple.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Spaced Repetition',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Status ngày hôm nay
                  if (_reviewsToday == 0)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Hoàn thành hôm nay!',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.orange, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Còn $_reviewsToday từ cần ôn',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Stats hôm nay
                  Text(
                    'Hôm nay',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: _buildMiniStat('Đã làm', '$_todayTotal', Colors.blue)),
                      const SizedBox(width: 4),
                      Expanded(child: _buildMiniStat('Đúng', '$_todayCorrect', Colors.green)),
                      const SizedBox(width: 4),
                      Expanded(child: _buildMiniStat('Tỉ lệ', '${_todayAccuracy.toInt()}%', Colors.purple)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Cấp độ từ vựng
                  Text(
                    'Cấp độ từ vựng',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      children: [
                        _buildLevelCard('Mới', _newCount, Colors.blue),
                        _buildLevelCard('Học', _learningCount, Colors.orange),
                        _buildLevelCard('Ôn', _reviewingCount, Colors.purple),
                        _buildLevelCard('Thạo', _matureCount, Colors.green),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Action buttons
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          onPressed: _reviewsToday > 0 ? _navigateToSpacedRepetition : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Ôn tập',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: OutlinedButton(
                          onPressed: _navigateToSpacedRepetitionTest,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple.shade600,
                            side: BorderSide(color: Colors.purple.shade600),
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Kiểm tra',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSpacedRepetition() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SpacedRepetitionScreen(),
      ),
    ).then((_) {
      _loadData(); // Refresh data when returning
    });
  }

  void _navigateToSpacedRepetitionTest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SpacedRepetitionTestScreen(),
      ),
    ).then((_) {
      _loadData(); // Refresh data when returning
    });
  }
}