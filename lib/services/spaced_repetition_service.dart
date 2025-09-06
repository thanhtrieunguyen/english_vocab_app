import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocabulary.dart';
import 'vocabulary_service.dart';
import 'package:intl/intl.dart';

class SpacedRepetitionService {
  static const String _lastCheckDateKey = 'last_check_date';
  static const String _dailyReviewsKey = 'daily_reviews';
  
  final VocabularyService _vocabularyService = VocabularyService();

  // Public getter for vocabulary service
  VocabularyService get vocabularyService => _vocabularyService;

  // Canonical SM-2 algorithm (đơn giản, ổn định) – không can thiệp Leitner
  Map<String, dynamic> calculateNextReview({
    required int repetitionCount,
    required double easeFactor,
    required int intervalDays,
    required int quality, // 0-5, với 3+ là pass
    int streak = 0,
    double difficulty = 0.5,
    List<int> recentQualities = const [],
  }) {
    int newRepetitionCount = repetitionCount;
    double newEaseFactor = easeFactor;
    int newIntervalDays = intervalDays;
    final bool isCorrect = quality >= 3;

    if (isCorrect) {
      newRepetitionCount++;
      if (newRepetitionCount == 1) {
        newIntervalDays = 1;
      } else if (newRepetitionCount == 2) {
        newIntervalDays = 6;
      } else {
        newIntervalDays = (intervalDays * easeFactor).round();
      }
      newEaseFactor = easeFactor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    } else {
      newRepetitionCount = 0;
      newIntervalDays = 1; // reset
      newEaseFactor = easeFactor - 0.2; // penalty
    }

    // Boundaries
    newEaseFactor = max(1.3, min(3.0, newEaseFactor));
    newIntervalDays = max(1, min(365, newIntervalDays));
    final nextReviewDate = DateTime.now().add(Duration(days: newIntervalDays));

    return {
      'repetitionCount': newRepetitionCount,
      'easeFactor': newEaseFactor,
      'intervalDays': newIntervalDays,
      'nextReviewDate': nextReviewDate,
    };
  }

  // Cập nhật từ vựng sau một lần SR review (độc lập Leitner)
  Future<Vocabulary> updateVocabularyAfterReview({
    required Vocabulary vocabulary,
    required DateTime originalDate,
    required int vocabularyIndex,
    required int quality,
  }) async {
    final now = DateTime.now();
    final isCorrect = quality >= 3;
    
    // Update performance tracking
    final newTotalReviews = vocabulary.totalReviews + 1;
    final newTotalCorrect = vocabulary.totalCorrect + (isCorrect ? 1 : 0);
    final newStreak = isCorrect ? vocabulary.streak + 1 : 0;
    
    // Update recent qualities (keep last 5)
    final newRecentQualities = [...vocabulary.recentQualities, quality];
    if (newRecentQualities.length > 5) {
      newRecentQualities.removeAt(0);
    }
    
    // Calculate dynamic difficulty based on performance
    double newDifficulty = vocabulary.difficulty;
    if (quality <= 2) {
      newDifficulty = min(1.0, newDifficulty + 0.1); // Increase difficulty
    } else if (quality >= 4) {
      newDifficulty = max(0.0, newDifficulty - 0.05); // Decrease difficulty
    }

    final reviewData = calculateNextReview(
      repetitionCount: vocabulary.repetitionCount,
      easeFactor: vocabulary.easeFactor,
      intervalDays: vocabulary.intervalDays,
      quality: quality,
      streak: newStreak,
      difficulty: newDifficulty,
      recentQualities: newRecentQualities,
    );

    final updatedVocabulary = vocabulary.copyWith(
      repetitionCount: reviewData['repetitionCount'],
      easeFactor: reviewData['easeFactor'],
      intervalDays: reviewData['intervalDays'],
      nextReviewDate: reviewData['nextReviewDate'],
      lastQuality: quality,
      lastReviewDate: now,
      streak: newStreak,
      totalReviews: newTotalReviews,
      totalCorrect: newTotalCorrect,
      difficulty: newDifficulty,
      recentQualities: newRecentQualities,
    );

    // Cập nhật vào storage
    await _vocabularyService.updateVocabularyInDate(
      originalDate,
      vocabularyIndex,
      updatedVocabulary,
    );

    // Save enhanced review stats
    await _saveReviewStats(quality >= 3);
    
    return updatedVocabulary;
  }

  // Lấy tất cả từ vựng cần review hôm nay
  Future<List<VocabularyReviewItem>> getTodayReviews() async {
    final reviewItems = <VocabularyReviewItem>[];
    final dates = await _vocabularyService.getAllVocabularyDates();
    
    for (final date in dates) {
      final vocabularies = await _vocabularyService.getVocabularyForDate(date);
      
      for (int i = 0; i < vocabularies.length; i++) {
        final vocab = vocabularies[i];
        if (vocab.isDueForReview) {
          reviewItems.add(VocabularyReviewItem(
            vocabulary: vocab,
            originalDate: date,
            vocabularyIndex: i,
          ));
        }
      }
    }

    // Sắp xếp theo thứ tự ưu tiên (từ cũ nhất, repetition count thấp nhất)
    reviewItems.sort((a, b) {
      final aUrgency = _calculateUrgency(a.vocabulary);
      final bUrgency = _calculateUrgency(b.vocabulary);
      return bUrgency.compareTo(aUrgency);
    });

    return reviewItems;
  }

  // Tính độ ưu tiên review
  double _calculateUrgency(Vocabulary vocab) {
    if (vocab.nextReviewDate == null) return 100.0;
    
    final daysPast = DateTime.now().difference(vocab.nextReviewDate!).inDays;
    final repeatFactor = 1 / (vocab.repetitionCount + 1);
    
    return daysPast + (10 * repeatFactor);
  }

  // Tự động tính toán và cập nhật từ vựng cần review khi mở app
  Future<void> performDailyCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final lastCheckDate = prefs.getString(_lastCheckDateKey);

    // Chỉ chạy một lần mỗi ngày
    if (lastCheckDate == today) return;

    try {
      // Cập nhật ngày check cuối cùng
      await prefs.setString(_lastCheckDateKey, today);

      // Tìm và cập nhật các từ vựng mới (chưa có nextReviewDate)
      await _initializeNewVocabularies();

      // Thông báo số lượng từ cần review
      final reviewItems = await getTodayReviews();
      await _saveNotificationData(reviewItems.length);

    } catch (e) {
      print('Error in daily check: $e');
    }
  }

  // Khởi tạo spaced repetition cho từ vựng mới
  Future<void> _initializeNewVocabularies() async {
    final dates = await _vocabularyService.getAllVocabularyDates();
    
    for (final date in dates) {
      final vocabularies = await _vocabularyService.getVocabularyForDate(date);
      bool needsUpdate = false;
      
      for (int i = 0; i < vocabularies.length; i++) {
        final vocab = vocabularies[i];
        
        // Nếu từ vựng chưa có nextReviewDate, khởi tạo
        if (vocab.nextReviewDate == null) {
          final updatedVocab = vocab.copyWith(
            nextReviewDate: DateTime.now().add(const Duration(days: 1)),
            repetitionCount: 0,
            easeFactor: 2.5,
            intervalDays: 1,
            leitnerBox: 1,
            consecutiveCorrect: 0,
            lastLeitnerReview: DateTime.now().subtract(const Duration(days: 1)),
          );
          
          vocabularies[i] = updatedVocab;
          needsUpdate = true;
        }
      }
      
      if (needsUpdate) {
        await _vocabularyService.saveVocabularyForDate(date, vocabularies);
      }
    }
  }

  // Lưu thống kê review hàng ngày
  Future<void> _saveReviewStats(bool isCorrect) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final key = '${_dailyReviewsKey}_$today';
      
      final data = prefs.getString(key);
      Map<String, int> stats = {'correct': 0, 'total': 0};
      
      if (data != null) {
        final decoded = jsonDecode(data);
        stats = Map<String, int>.from(decoded);
      }
      
      stats['total'] = (stats['total'] ?? 0) + 1;
      if (isCorrect) {
        stats['correct'] = (stats['correct'] ?? 0) + 1;
      }
      
      await prefs.setString(key, jsonEncode(stats));
      print('Saved SR review stats for $today: $stats');
    } catch (e) {
      print('Error saving SR review stats: $e');
    }
  }

  // Lưu dữ liệu thông báo
  Future<void> _saveNotificationData(int reviewCount) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    await prefs.setInt('review_count_$today', reviewCount);
    await prefs.setString('last_notification_date', today);
  }

  // Lấy thống kê review hôm nay
  Future<Map<String, int>> getTodayReviewStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = '${_dailyReviewsKey}_$today';
    
    final data = prefs.getString(key);
    if (data == null) return {'correct': 0, 'total': 0};
    
    return Map<String, int>.from(jsonDecode(data));
  }

  // Lấy thống kê review 7 ngày gần nhất
  Future<List<Map<String, dynamic>>> getWeeklyReviewStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stats = <Map<String, dynamic>>[];
      
      print('Đang tải thống kê 7 ngày gần nhất...');
      
      for (int i = 6; i >= 0; i--) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final key = '${_dailyReviewsKey}_$dateKey';
        
        final data = prefs.getString(key);
        Map<String, int> dayStats = {'correct': 0, 'total': 0};
        
        if (data != null) {
          try {
            dayStats = Map<String, int>.from(jsonDecode(data));
          } catch (e) {
            print('Lỗi đọc dữ liệu ngày $dateKey: $e');
          }
        }
        
        final accuracy = dayStats['total']! > 0 
            ? ((dayStats['correct']! / dayStats['total']!) * 100).round()
            : 0;
        
        stats.add({
          'date': date,
          'dateString': dateKey,
          'correct': dayStats['correct'] ?? 0,
          'total': dayStats['total'] ?? 0,
          'accuracy': accuracy,
        });
        
        print('Ngày $dateKey: ${dayStats['correct']}/${dayStats['total']} ($accuracy%)');
      }
      
      return stats;
    } catch (e) {
      print('Lỗi khi tải thống kê tuần: $e');
      return [];
    }
  }

  // Lấy số lượng từ vựng theo level
  Future<Map<String, int>> getVocabularyLevels() async {
    try {
      final dates = await _vocabularyService.getAllVocabularyDates();
      final levels = <String, int>{
        'new': 0,      // repetitionCount == 0
        'learning': 0, // repetitionCount 1-2
        'reviewing': 0, // repetitionCount 3-5
        'mature': 0,   // repetitionCount >= 6
      };
      
      print('Đang tính toán cấp độ từ vựng cho ${dates.length} ngày');
      
      for (final date in dates) {
        final vocabularies = await _vocabularyService.getVocabularyForDate(date);
        print('Ngày ${date.toString().split(' ')[0]}: ${vocabularies.length} từ vựng');
        
        for (final vocab in vocabularies) {
          if (vocab.repetitionCount == 0) {
            levels['new'] = levels['new']! + 1;
          } else if (vocab.repetitionCount <= 2) {
            levels['learning'] = levels['learning']! + 1;
          } else if (vocab.repetitionCount <= 5) {
            levels['reviewing'] = levels['reviewing']! + 1;
          } else {
            levels['mature'] = levels['mature']! + 1;
          }
        }
      }
      
      print('Kết quả phân loại: $levels');
      return levels;
    } catch (e) {
      print('Lỗi khi tính toán cấp độ từ vựng: $e');
      return {'new': 0, 'learning': 0, 'reviewing': 0, 'mature': 0};
    }
  }

  // Reset tất cả spaced repetition data (cho testing)
  Future<void> resetAllSpacedRepetitionData() async {
    final dates = await _vocabularyService.getAllVocabularyDates();
    
    for (final date in dates) {
      final vocabularies = await _vocabularyService.getVocabularyForDate(date);
      final resetVocabs = vocabularies.map((vocab) => vocab.copyWith(
        repetitionCount: 0,
        easeFactor: 2.5,
        intervalDays: 1,
        nextReviewDate: null,
        lastQuality: null,
        leitnerBox: 1,
        consecutiveCorrect: 0,
        lastLeitnerReview: null,
      )).toList();
      
      await _vocabularyService.saveVocabularyForDate(date, resetVocabs);
    }

    // Xóa stats
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final keysToRemove = keys.where((key) => 
        key.startsWith(_dailyReviewsKey) || 
        key == _lastCheckDateKey ||
        key.startsWith('review_count_') ||
        key == 'last_notification_date'
    ).toList();
    
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  // Reset Spaced Repetition từ một ngày cụ thể
  Future<void> resetSpacedRepetitionFromDate(DateTime fromDate) async {
    final prefs = await SharedPreferences.getInstance();
    final fromDateString = DateFormat('yyyy-MM-dd').format(fromDate);
    
    print('Bắt đầu reset Spaced Repetition từ ngày: $fromDateString');
    
    // Lấy tất cả các ngày có từ vựng
    final allDates = await _vocabularyService.getAllVocabularyDates();
    print('Tìm thấy ${allDates.length} ngày có từ vựng');
    
    int totalReset = 0;
    
    for (final date in allDates) {
      final dateString = DateFormat('yyyy-MM-dd').format(date);
      final vocabularies = await _vocabularyService.getVocabularyForDate(date);
      print('Ngày $dateString: ${vocabularies.length} từ vựng');
      
      for (int i = 0; i < vocabularies.length; i++) {
        final vocab = vocabularies[i];
        
        // Tạo vocabulary mới với các thuộc tính Spaced Repetition được reset
        final resetVocab = Vocabulary(
          word: vocab.word,
          meaning: vocab.meaning,
          pronunciation: vocab.pronunciation,
          example: vocab.example,
          memoryTip: vocab.memoryTip,
          repetitionCount: 0,
          easeFactor: 2.5,
          intervalDays: 1,
          nextReviewDate: fromDate, // Đặt ngày review là ngày reset luôn
          createdAt: vocab.createdAt,
        );
        
        // Lưu vocabulary đã reset
        vocabularies[i] = resetVocab;
        totalReset++;
      }
      
      // Lưu tất cả vocabularies của ngày này cùng lúc
      await _vocabularyService.saveVocabularyForDate(date, vocabularies);
      
      // Xóa tất cả dữ liệu SR cũ của ngày này
      for (int i = 0; i < vocabularies.length; i++) {
        final key = '${dateString}_${i}_spaced_repetition';
        await prefs.remove(key);
        
        // Lưu dữ liệu mới cho Spaced Repetition
        final srData = {
          'repetitionCount': 0,
          'easeFactor': 2.5,
          'intervalDays': 1,
          'nextReviewDate': fromDateString,
          'lastReviewDate': null,
          'reviewStatus': 'new',
        };
        await prefs.setString(key, json.encode(srData));
      }
    }
    
    // Cập nhật ngày check cuối cùng
    await prefs.setString(_lastCheckDateKey, fromDateString);
    
    // Xóa toàn bộ daily reviews cũ và cache khác
    await prefs.remove(_dailyReviewsKey);
    
    // Xóa tất cả các key liên quan đến SR stats
    final allKeys = prefs.getKeys().where((key) => 
      key.contains('spaced_repetition') || 
      key.contains('review_stats') ||
      key.contains('daily_reviews')
    ).toList();
    
    for (final key in allKeys) {
      if (!key.contains('_spaced_repetition')) { // Giữ lại data vừa tạo
        await prefs.remove(key);
      }
    }
    
    print('Reset hoàn tất: $totalReset từ vựng từ ${allDates.length} ngày');
    print('Tất cả từ vựng sẽ được ôn từ ngày: $fromDateString');
  }
}

// Class để lưu trữ thông tin vocabulary cần review
class VocabularyReviewItem {
  final Vocabulary vocabulary;
  final DateTime originalDate;
  final int vocabularyIndex;

  VocabularyReviewItem({
    required this.vocabulary,
    required this.originalDate,
    required this.vocabularyIndex,
  });
}
