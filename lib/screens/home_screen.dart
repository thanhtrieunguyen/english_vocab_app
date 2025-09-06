import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/vocabulary_service.dart';
import '../services/spaced_repetition_service.dart';
import '../models/vocabulary.dart';
import '../constants/theme_provider.dart';
import 'add_vocabulary_screen.dart';
import 'learning_screen.dart';
import 'edit_vocabulary_dialog.dart';
import 'spaced_repetition_screen.dart';
import 'spaced_repetition_test_screen.dart';
import 'leitner_system_screen.dart';
import '../widgets/spaced_repetition_info_widget.dart';
import '../widgets/leitner_info_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final VocabularyService _vocabularyService = VocabularyService();
  final SpacedRepetitionService _spacedRepetitionService = SpacedRepetitionService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Map<DateTime, int> _vocabularyCounts = {};
  DateTime _currentMonth = DateTime.now();
  bool _isLoading = true;
  GlobalKey _spacedRepetitionKey = GlobalKey(); // Key để refresh SR widget

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    _initializeWeek();
    _loadVocabularyCounts();
    _performDailyCheck();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeWeek() {
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  // Thực hiện daily check cho Spaced Repetition
  Future<void> _performDailyCheck() async {
    try {
      await _spacedRepetitionService.performDailyCheck();
    } catch (e) {
      print('Daily check error: $e');
    }
  }

  Future<void> _loadVocabularyCounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final counts = <DateTime, int>{};
      
      // Load data cho cả tháng
      final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) {
        final date = DateTime(_currentMonth.year, _currentMonth.month, i);
        final count = await _vocabularyService.getVocabularyCountForDate(date);
        counts[date] = count;
      }
      
      setState(() {
        _vocabularyCounts = counts;
        _isLoading = false;
      });
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

  void _previousWeek() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
    _loadVocabularyCounts();
  }

  void _nextWeek() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
    _loadVocabularyCounts();
  }

  void _goToToday() {
    _initializeWeek();
    _loadVocabularyCounts();
  }

  Future<void> _openDayDetail(DateTime date) async {
    final vocabularies = await _vocabularyService.getVocabularyForDate(date);
    
    if (!mounted) return;

    if (vocabularies.isEmpty) {
      // Mở màn hình thêm từ vựng
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddVocabularyScreen(selectedDate: date),
        ),
      );
      
      if (result == true) {
        _loadVocabularyCounts(); // Reload data
      }
    } else {
      // Hiển thị dialog chọn hành động
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Ngày ${date.day}/${date.month}/${date.year}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text('Có ${vocabularies.length} từ vựng. Bạn muốn làm gì?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LearningScreen(
                      vocabularies: vocabularies,
                      date: date,
                    ),
                  ),
                );
              },
              child: Text(
                'Học từ vựng',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddVocabularyScreen(selectedDate: date),
                  ),
                );
                
                if (result == true) {
                  _loadVocabularyCounts();
                }
              },
              child: Text(
                'Thêm từ vựng',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'English Vocabulary App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: () => themeProvider.toggleTheme(),
                tooltip: themeProvider.isDarkMode ? 'Chế độ sáng' : 'Chế độ tối',
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) async {
              switch (value) {
                case 'search':
                  _showGlobalSearch();
                  break;
                case 'export':
                  await _exportData();
                  break;
                case 'import':
                  await _importData();
                  break;
                case 'statistics':
                  _showStatistics();
                  break;
                case 'spaced_repetition':
                  _navigateToSpacedRepetition();
                  break;
                case 'leitner_system':
                  _navigateToLeitnerSystem();
                  break;
                case 'spaced_repetition_test':
                  _navigateToSpacedRepetitionTest();
                  break;
                case 'reset_spaced_repetition':
                  _showResetSpacedRepetitionDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Tìm kiếm toàn bộ'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'spaced_repetition',
                child: Row(
                  children: [
                    Icon(Icons.psychology),
                    SizedBox(width: 8),
                    Text('Spaced Repetition'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leitner_system',
                child: Row(
                  children: [
                    Icon(Icons.layers),
                    SizedBox(width: 8),
                    Text('Leitner System'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'spaced_repetition_test',
                child: Row(
                  children: [
                    Icon(Icons.quiz),
                    SizedBox(width: 8),
                    Text('Kiểm tra SR'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_spaced_repetition',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reset SR từ hôm nay', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Thống kê'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Xuất dữ liệu'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload),
                    SizedBox(width: 8),
                    Text('Nhập dữ liệu'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : Column(
                      children: [
                        // Main content - 3 columns layout
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Column 1: Calendar (2/3 width)
                                Expanded(
                                  flex: 4,
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.shadow.withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // Header với navigation tuần
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: colorScheme.primary,
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_month,
                                                color: colorScheme.onPrimary,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Lịch học',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorScheme.onPrimary,
                                                ),
                                              ),
                                              const Spacer(),
                                              IconButton(
                                                onPressed: _previousWeek,
                                                icon: Icon(Icons.arrow_back_ios, 
                                                  color: colorScheme.onPrimary, size: 16),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(
                                                  minWidth: 24,
                                                  minHeight: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: _goToToday,
                                                child: Text(
                                                  _getMonthYearText(_currentMonth),
                                                  style: TextStyle(
                                                    color: colorScheme.onPrimary,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                onPressed: _nextWeek,
                                                icon: Icon(Icons.arrow_forward_ios, 
                                                  color: colorScheme.onPrimary, size: 16),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(
                                                  minWidth: 24,
                                                  minHeight: 24,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Calendar grid
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              children: [
                                                // Days of week header
                                                Row(
                                                  children: [
                                                    'T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'
                                                  ].map((day) => Expanded(
                                                    child: Text(
                                                      day,
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: colorScheme.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  )).toList(),
                                                ),
                                                const SizedBox(height: 8),
                                                // Calendar days
                                                Expanded(
                                                  child: _buildMonthCalendar(colorScheme),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Column 2: Spaced Repetition (1/6 width) - Split vertically
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 4, right: 4),
                                    child: Column(
                                      children: [
                                        // SR Upper half
                                        Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 4),
                                            child: SpacedRepetitionInfoWidget(key: _spacedRepetitionKey),
                                          ),
                                        ),
                                        // SR Lower half (could be stats or other info)
                                        Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.only(top: 4),
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
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.purple.shade400,
                                                    borderRadius: const BorderRadius.only(
                                                      topLeft: Radius.circular(12),
                                                      topRight: Radius.circular(12),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.analytics, color: Colors.white, size: 14),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          'SR Stats',
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
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8),
                                                    child: Center(
                                                      child: Text(
                                                        'Thống kê\nSR chi tiết',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: colorScheme.onSurface.withOpacity(0.7),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                // Column 3: Leitner System (1/6 width) - Split vertically
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 4),
                                    child: Column(
                                      children: [
                                        // Leitner Upper half
                                        Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 4),
                                            child: const LeitnerInfoWidget(),
                                          ),
                                        ),
                                        // Leitner Lower half (could be stats or other info)
                                        Expanded(
                                          child: Container(
                                            margin: const EdgeInsets.only(top: 4),
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
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal.shade400,
                                                    borderRadius: const BorderRadius.only(
                                                      topLeft: Radius.circular(12),
                                                      topRight: Radius.circular(12),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.trending_up, color: Colors.white, size: 14),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          'LS Progress',
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
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8),
                                                    child: Center(
                                                      child: Text(
                                                        'Tiến độ\nLeitner System',
                                                        textAlign: TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: colorScheme.onSurface.withOpacity(0.7),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
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
                          ),
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthCalendar(ColorScheme colorScheme) {
    // Tính toán ngày đầu tiên của tháng và ngày cuối cùng
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday;
    
    // Tính toán số ngày cần hiển thị (bao gồm cả ngày của tháng trước)
    final startDate = firstDayOfMonth.subtract(Duration(days: firstWeekdayOfMonth - 1));
    final totalDays = ((lastDayOfMonth.day + firstWeekdayOfMonth - 1) / 7).ceil() * 7;
    
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.0, // Tăng từ 1.2 lên 1.0 để item vuông vắn hơn
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: totalDays,
      itemBuilder: (context, index) {
        final date = startDate.add(Duration(days: index));
        final count = _vocabularyCounts[date] ?? 0;
        final isToday = _isSameDay(date, DateTime.now());
        final isCurrentMonth = date.month == _currentMonth.month;
        
        return GestureDetector(
          onTap: () => _openDayDetail(date),
          child: Container(
            decoration: BoxDecoration(
              color: isToday 
                  ? colorScheme.secondary
                  : count > 0 
                      ? Colors.green.shade400
                      : isCurrentMonth
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isToday 
                    ? colorScheme.secondary
                    : colorScheme.outline.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 18, // Tăng font size từ 16 lên 18
                    fontWeight: FontWeight.bold,
                    color: isCurrentMonth
                        ? (isToday || count > 0 
                            ? Colors.white 
                            : colorScheme.onSurface)
                        : colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                if (count > 0 && isCurrentMonth) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 11, // Tăng font size từ 12 lên 13
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] else if (isCurrentMonth && count == 0) ...[
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.add,
                      size: 12, // Tăng size từ 10 lên 12
                      color: colorScheme.outline.withOpacity(0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthYearText(DateTime date) {
    const months = [
      'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
      'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // Tìm kiếm toàn bộ từ vựng
  void _showGlobalSearch() {
    showDialog(
      context: context,
      builder: (context) => const GlobalSearchDialog(),
    );
  }

  // Export dữ liệu
  Future<void> _exportData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final filePath = await _vocabularyService.exportAllDataToJson();
    
    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xuất dữ liệu thành công: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi khi xuất dữ liệu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Import dữ liệu
  Future<void> _importData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận nhập dữ liệu'),
        content: const Text(
          'Việc nhập dữ liệu sẽ ghi đè lên dữ liệu hiện tại. Bạn có chắc chắn muốn tiếp tục?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tiếp tục'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await _vocabularyService.importDataFromJson();
    
    if (!mounted) return;
    Navigator.of(context).pop(); // Close loading dialog

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã nhập dữ liệu thành công'),
          backgroundColor: Colors.green,
        ),
      );
      _loadVocabularyCounts(); // Reload data
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lỗi khi nhập dữ liệu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hiển thị thống kê
  void _showStatistics() async {
    final stats = await _vocabularyService.getStatistics();
    
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Thống kê học tập',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Tổng số từ vựng:', '${stats['totalWords']} từ'),
            const SizedBox(height: 8),
            _buildStatRow('Số ngày đã học:', '${stats['totalDays']} ngày'),
            const SizedBox(height: 8),
            _buildStatRow('Trung bình mỗi ngày:', '${stats['averagePerDay']} từ'),
          ],
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

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Navigation methods for Spaced Repetition
  void _navigateToSpacedRepetition() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SpacedRepetitionScreen(),
      ),
    ).then((_) {
      // Refresh data when returning
      _performDailyCheck();
    });
  }

  void _navigateToSpacedRepetitionTest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SpacedRepetitionTestScreen(),
      ),
    ).then((_) {
      // Refresh data when returning
      _performDailyCheck();
    });
  }

  void _navigateToLeitnerSystem() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LeitnerSystemScreen(),
      ),
    ).then((_) {
      // Refresh data when returning
      _performDailyCheck();
    });
  }

  // Method để reset Spaced Repetition từ ngày hiện tại
  void _showResetSpacedRepetitionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Reset Spaced Repetition'),
          ],
        ),
        content: const Text(
          'Điều này sẽ reset toàn bộ tiến trình Spaced Repetition và đặt lại tất cả từ vựng để ôn từ hôm nay. Bạn có chắc chắn muốn thực hiện?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _resetSpacedRepetitionFromToday();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Method thực hiện reset Spaced Repetition từ hôm nay
  Future<void> _resetSpacedRepetitionFromToday() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final today = DateTime.now();
      await _spacedRepetitionService.resetSpacedRepetitionFromDate(today);
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        
        // Tạo key mới để force refresh SpacedRepetitionInfoWidget
        setState(() {
          _spacedRepetitionKey = GlobalKey();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã reset Spaced Repetition từ ngày ${today.day}/${today.month}/${today.year}!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadVocabularyCounts(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Global Search Dialog
class GlobalSearchDialog extends StatefulWidget {
  const GlobalSearchDialog({super.key});

  @override
  State<GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<GlobalSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final VocabularyService _vocabularyService = VocabularyService();
  Map<DateTime, List<Vocabulary>> _searchResults = {};
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = {};
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _vocabularyService.searchVocabularyGlobal(query);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tìm kiếm: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text(
                  'Tìm kiếm từ vựng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Nhập từ khóa để tìm kiếm...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _performSearch,
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
              const Center(
                child: Text(
                  'Không tìm thấy kết quả nào',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else if (_searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final date = _searchResults.keys.elementAt(index);
                    final vocabularies = _searchResults[date]!;
                    
                    return ExpansionTile(
                      title: Text(
                        '${date.day}/${date.month}/${date.year} (${vocabularies.length} từ)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: vocabularies.asMap().entries.map((entry) {
                        final index = entry.key;
                        final vocab = entry.value;
                        return ListTile(
                          title: Text(vocab.word),
                          subtitle: Text(vocab.meaning),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              Navigator.of(context).pop(); // Close search dialog first
                              showDialog(
                                context: context,
                                builder: (context) => EditVocabularyDialog(
                                  vocabulary: vocab,
                                  date: date,
                                  index: index,
                                  onUpdated: () {
                                    // Refresh search results if needed
                                    if (_searchController.text.isNotEmpty) {
                                      _performSearch(_searchController.text);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
