import 'package:flutter/material.dart';
import '../services/leitner_service.dart';
import '../screens/leitner_system_screen.dart';

class EnhancedLeitnerWidget extends StatefulWidget {
  const EnhancedLeitnerWidget({super.key});

  @override
  State<EnhancedLeitnerWidget> createState() => _EnhancedLeitnerWidgetState();
}

class _EnhancedLeitnerWidgetState extends State<EnhancedLeitnerWidget> {
  final LeitnerService _leitnerService = LeitnerService();
  int _totalReviews = 0;
  bool _isLoading = true;
  Map<int,int> _boxDistribution = {1:0,2:0,3:0,4:0,5:0};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final reviews = await _leitnerService.getLeitnerReviews();
    final distribution = await _leitnerService.getBoxDistribution();
      if (mounted) {
        setState(() {
          _totalReviews = reviews.length;
          _isLoading = false;
      _boxDistribution = distribution;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LeitnerSystemScreen(),
        ),
      ).then((_) => _loadData()),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF7C2D12), const Color(0xFFEA580C)]
                : [const Color(0xFFEA580C), const Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.orange.shade900 : Colors.orange.shade200).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inbox,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Leitner System',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Review count + small boxes summary
              if (_isLoading) ...[
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_totalReviews',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _totalReviews > 0 ? 'Từ cần ôn' : 'Đã xong hôm nay',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _buildBoxesMiniBar(),
                    ),
                  ],
                ),
              ],
              
              const Spacer(),
              
              // Action button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  _totalReviews > 0 ? 'Bắt đầu ôn tập' : 'Xem chi tiết',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBoxesMiniBar() {
    // Create a bar showing proportions of boxes 1-5
    final total = _boxDistribution.values.fold<int>(0, (s, v) => s + v);
    if (total == 0) {
      return Text(
        '0 0 0 0 0',
        style: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 11,
        ),
        textAlign: TextAlign.right,
      );
    }

    final colors = <Color>[
      const Color(0xFFDC2626), // box1
      const Color(0xFFF97316), // box2
      const Color(0xFFFBBF24), // box3
      const Color(0xFF4ADE80), // box4
      const Color(0xFF10B981), // box5
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: List.generate(5, (i) {
            final count = _boxDistribution[i + 1] ?? 0;
            final fraction = count / total;
            return Expanded(
              flex: (fraction * 1000).round().clamp(1, 1000),
              child: Container(
                height: 10,
                margin: EdgeInsets.only(left: i == 0 ? 0 : 2),
                decoration: BoxDecoration(
                  color: colors[i].withOpacity(0.85),
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(i == 0 ? 4 : 0),
                    right: Radius.circular(i == 4 ? 4 : 0),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: List.generate(5, (i) {
              final count = _boxDistribution[i + 1] ?? 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'B${i + 1}:$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
