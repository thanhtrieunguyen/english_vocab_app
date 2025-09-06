import 'package:flutter/material.dart';
import '../services/vocabulary_service.dart';
import '../services/spaced_repetition_service.dart';
import '../services/leitner_service.dart';

class EnhancedLearningProgressWidget extends StatefulWidget {
  const EnhancedLearningProgressWidget({super.key});

  @override
  State<EnhancedLearningProgressWidget> createState() => _EnhancedLearningProgressWidgetState();
}

class _EnhancedLearningProgressWidgetState extends State<EnhancedLearningProgressWidget>
    with TickerProviderStateMixin {
  final VocabularyService _vocabularyService = VocabularyService();
  final SpacedRepetitionService _srService = SpacedRepetitionService();
  final LeitnerService _leitnerService = LeitnerService();
  
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  int _totalWords = 0;
  Map<String, int> _srLevels = {'new': 0, 'learning': 0, 'reviewing': 0, 'mature': 0};
  Map<int, int> _leitnerBoxes = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
  double _overallProgress = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadData();
  }

  void _setupAnimation() {
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load vocabulary data
      final dates = await _vocabularyService.getAllVocabularyDates();
      int totalWords = 0;
      for (final date in dates) {
        final vocabs = await _vocabularyService.getVocabularyForDate(date);
        totalWords += vocabs.length;
      }

      // Load SR and Leitner data
      final srLevels = await _srService.getVocabularyLevels();
      final leitnerBoxes = await _leitnerService.getBoxDistribution();
      
      // Calculate overall progress
      final mature = srLevels['mature'] ?? 0;
      final leitnerHigh = (leitnerBoxes[4] ?? 0) + (leitnerBoxes[5] ?? 0);
      final overallProgress = totalWords > 0 ? 
          ((mature + leitnerHigh) / (totalWords * 2)).clamp(0.0, 1.0) : 0.0;
      
      if (mounted) {
        setState(() {
          _totalWords = totalWords;
          _srLevels = srLevels;
          _leitnerBoxes = leitnerBoxes;
          _overallProgress = overallProgress;
          _isLoading = false;
        });
        _progressController.forward();
      }
    } catch (e) {
      print('Error loading progress data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.surfaceVariant,
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                if (_isLoading) 
                  _buildLoadingIndicator()
                else ...[
                  _buildProgressCircle(),
                  const SizedBox(height: 20),
                  _buildProgressDetails(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.trending_up,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tiến độ học tập',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Theo dõi sự tiến bộ của bạn',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildProgressCircle() {
    return Center(
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, child) {
          return Container(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    backgroundColor: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                ),
                // Progress circle
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: _overallProgress * _progressAnimation.value,
                    strokeWidth: 12,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(_overallProgress),
                    ),
                  ),
                ),
                // Center content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(_overallProgress * _progressAnimation.value * 100).round()}%',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(_overallProgress),
                      ),
                    ),
                    Text(
                      'Hoàn thành',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_totalWords từ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressDetails() {
    return Column(
      children: [
        _buildSystemComparison(),
        const SizedBox(height: 16),
        _buildAchievements(),
      ],
    );
  }

  Widget _buildSystemComparison() {
    final srMastered = _srLevels['mature'] ?? 0;
    final leitnerMastered = (_leitnerBoxes[4] ?? 0) + (_leitnerBoxes[5] ?? 0);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'So sánh hệ thống',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildSystemRow(
            'Spaced Repetition',
            srMastered,
            _totalWords,
            Icons.psychology,
            Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          _buildSystemRow(
            'Leitner System',
            leitnerMastered,
            _totalWords,
            Icons.inbox,
            Theme.of(context).colorScheme.tertiary,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemRow(String name, int mastered, int total, IconData icon, Color color) {
    final percentage = total > 0 ? mastered / total : 0.0;
    
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$mastered/$total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements() {
    final achievements = _getAchievements();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Thành tích',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (achievements.isEmpty)
            Text(
              'Hãy bắt đầu học để mở khóa thành tích!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: achievements.map((achievement) => _buildAchievementChip(achievement)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementChip(Map<String, dynamic> achievement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: achievement['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: achievement['color'].withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            achievement['icon'],
            color: achievement['color'],
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            achievement['title'],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: achievement['color'],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getAchievements() {
    final achievements = <Map<String, dynamic>>[];
    
    // Vocabulary milestones
    if (_totalWords >= 10) {
      achievements.add({
        'title': 'Người mới bắt đầu',
        'icon': Icons.start,
        'color': Colors.green,
      });
    }
    if (_totalWords >= 50) {
      achievements.add({
        'title': 'Người học tích cực',
        'icon': Icons.school,
        'color': Colors.blue,
      });
    }
    if (_totalWords >= 100) {
      achievements.add({
        'title': 'Bậc thầy từ vựng',
        'icon': Icons.psychology,
        'color': Colors.purple,
      });
    }
    
    // Progress milestones
    if (_overallProgress >= 0.3) {
      achievements.add({
        'title': 'Tiến bộ vững chắc',
        'icon': Icons.trending_up,
        'color': Colors.orange,
      });
    }
    if (_overallProgress >= 0.7) {
      achievements.add({
        'title': 'Gần hoàn thành',
        'icon': Icons.star_half,
        'color': Colors.amber,
      });
    }
    
    // Leitner achievements
    final leitnerHigh = (_leitnerBoxes[4] ?? 0) + (_leitnerBoxes[5] ?? 0);
    if (leitnerHigh >= 20) {
      achievements.add({
        'title': 'Chuyên gia Leitner',
        'icon': Icons.inbox,
        'color': Colors.teal,
      });
    }
    
    return achievements;
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.5) return Colors.orange;
    if (progress < 0.7) return Colors.blue;
    return Colors.green;
  }
}
