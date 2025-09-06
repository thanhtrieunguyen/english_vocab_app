import 'package:flutter/material.dart';
import '../services/leitner_service.dart';
import '../screens/leitner_system_screen.dart';

class LeitnerInfoWidget extends StatefulWidget {
  const LeitnerInfoWidget({super.key});

  @override
  State<LeitnerInfoWidget> createState() => _LeitnerInfoWidgetState();
}

class _LeitnerInfoWidgetState extends State<LeitnerInfoWidget> {
  final LeitnerService _leitnerService = LeitnerService();
  
  bool _isLoading = true;
  int _reviewsToday = 0;
  int _todayCorrect = 0;
  int _todayTotal = 0;
  int _boxPromotions = 0;
  
  Map<int, int> _boxDistribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Initialize new vocabularies for Leitner
      await _leitnerService.initializeLeitnerForNewVocabularies();
      
      // Load review data
      final reviewItems = await _leitnerService.getLeitnerReviews();
      final stats = await _leitnerService.getTodayLeitnerStats();
      final distribution = await _leitnerService.getBoxDistribution();
      
      setState(() {
        _reviewsToday = reviewItems.length;
        _todayCorrect = stats['correct'] ?? 0;
        _todayTotal = stats['total'] ?? 0;
        _boxPromotions = stats['boxPromotions'] ?? 0;
        _boxDistribution = distribution;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading Leitner data: $e');
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
              color: Colors.teal.shade600,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.layers,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Leitner System',
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
                              'Còn $_reviewsToday thẻ cần ôn',
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
                      Expanded(child: _buildMiniStat('Thăng', '$_boxPromotions', Colors.purple)),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Phân bố hộp Leitner
                  Text(
                    'Các hộp Leitner',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        final box = index + 1;
                        final count = _boxDistribution[box] ?? 0;
                        final colors = [
                          Colors.red,
                          Colors.orange,
                          Colors.yellow.shade700,
                          Colors.lightGreen,
                          Colors.green,
                        ];
                        final labels = ['Mới', 'Học', 'Quen', 'Thạo', 'Hoàn thiện'];
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          child: _buildBoxRow(
                            'Hộp $box: ${labels[index]}',
                            count,
                            colors[index],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Action button
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: ElevatedButton(
                      onPressed: _navigateToLeitnerSystem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.layers, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _reviewsToday > 0 ? 'Ôn tập thẻ' : 'Xem hộp',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildBoxRow(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToLeitnerSystem() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LeitnerSystemScreen(),
      ),
    ).then((_) {
      _loadData(); // Refresh data when returning
    });
  }
}
