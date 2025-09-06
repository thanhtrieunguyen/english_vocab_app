import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocabulary.dart';
import 'vocabulary_service.dart';
import 'package:intl/intl.dart';

class LeitnerService {
  static const String _leitnerStatsKey = 'leitner_stats';
  static const String _dailyLeitnerReviewsKey = 'daily_leitner_reviews';
  
  final VocabularyService _vocabularyService = VocabularyService();

  // Lấy từ vựng cần ôn theo Leitner System
  Future<List<LeitnerReviewItem>> getLeitnerReviews() async {
    final reviewItems = <LeitnerReviewItem>[];
    final dates = await _vocabularyService.getAllVocabularyDates();
    
    for (final date in dates) {
      final vocabularies = await _vocabularyService.getVocabularyForDate(date);
      
      for (int i = 0; i < vocabularies.length; i++) {
        final vocab = vocabularies[i];
        if (vocab.isDueForLeitnerReview) {
          reviewItems.add(LeitnerReviewItem(
            vocabulary: vocab,
            originalDate: date,
            vocabularyIndex: i,
          ));
        }
      }
    }

    // Sắp xếp theo hộp và thời gian cần ôn
    reviewItems.sort((a, b) {
      // Ưu tiên hộp thấp hơn (khó hơn)
      if (a.vocabulary.leitnerBox != b.vocabulary.leitnerBox) {
        return a.vocabulary.leitnerBox.compareTo(b.vocabulary.leitnerBox);
      }
      
      // Trong cùng hộp, ưu tiên từ cũ hơn
      final aDays = a.vocabulary.lastLeitnerReview != null
          ? DateTime.now().difference(a.vocabulary.lastLeitnerReview!).inDays
          : 999;
      final bDays = b.vocabulary.lastLeitnerReview != null
          ? DateTime.now().difference(b.vocabulary.lastLeitnerReview!).inDays
          : 999;
      
      return bDays.compareTo(aDays);
    });

    return reviewItems;
  }

  // Cập nhật từ vựng sau khi ôn Leitner
  Future<Vocabulary> updateVocabularyAfterLeitnerReview({
    required Vocabulary vocabulary,
    required DateTime originalDate,
    required int vocabularyIndex,
    required bool isCorrect,
  }) async {
    int newBox = vocabulary.leitnerBox;
    int newConsecutiveCorrect = vocabulary.consecutiveCorrect;
    
    if (isCorrect) {
      newConsecutiveCorrect++;
      
      // Quy tắc thăng hộp: cần 2 lần đúng liên tiếp để lên hộp cao hơn
      if (newConsecutiveCorrect >= 2 && newBox < 5) {
        newBox++;
        newConsecutiveCorrect = 0; // Reset streak khi lên hộp mới
      }
    } else {
      // Sai => về hộp 1 và reset streak
      newBox = 1;
      newConsecutiveCorrect = 0;
    }

    final updatedVocabulary = vocabulary.copyWith(
      leitnerBox: newBox,
      consecutiveCorrect: newConsecutiveCorrect,
      lastLeitnerReview: DateTime.now(),
    );

    // Cập nhật vào storage
    await _vocabularyService.updateVocabularyInDate(
      originalDate,
      vocabularyIndex,
      updatedVocabulary,
    );

    // Lưu thống kê
    await _saveLeitnerReviewStats(isCorrect, vocabulary.leitnerBox, newBox);

    return updatedVocabulary;
  }

  // Lấy từ vựng theo hộp Leitner cụ thể
  Future<List<LeitnerReviewItem>> getVocabulariesInBox(int boxNumber) async {
    final items = <LeitnerReviewItem>[];
    final dates = await _vocabularyService.getAllVocabularyDates();
    
    for (final date in dates) {
      final vocabularies = await _vocabularyService.getVocabularyForDate(date);
      
      for (int i = 0; i < vocabularies.length; i++) {
        final vocab = vocabularies[i];
        if (vocab.leitnerBox == boxNumber) {
          items.add(LeitnerReviewItem(
            vocabulary: vocab,
            originalDate: date,
            vocabularyIndex: i,
          ));
        }
      }
    }

    return items;
  }

  // Thống kê phân bố từ vựng theo hộp
  Future<Map<int, int>> getBoxDistribution() async {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final dates = await _vocabularyService.getAllVocabularyDates();
    
    for (final date in dates) {
      final vocabularies = await _vocabularyService.getVocabularyForDate(date);
      
      for (final vocab in vocabularies) {
        distribution[vocab.leitnerBox] = (distribution[vocab.leitnerBox] ?? 0) + 1;
      }
    }

    return distribution;
  }

  // Lưu thống kê Leitner review
  Future<void> _saveLeitnerReviewStats(bool isCorrect, int fromBox, int toBox) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = '${_dailyLeitnerReviewsKey}_$today';
    
    final data = prefs.getString(key);
    Map<String, dynamic> stats = {
      'correct': 0,
      'total': 0,
      'boxPromotions': 0,
      'boxDemotions': 0,
    };
    
    if (data != null) {
      stats = Map<String, dynamic>.from(jsonDecode(data));
    }
    
    stats['total'] = (stats['total'] ?? 0) + 1;
    if (isCorrect) {
      stats['correct'] = (stats['correct'] ?? 0) + 1;
    }
    
    if (toBox > fromBox) {
      stats['boxPromotions'] = (stats['boxPromotions'] ?? 0) + 1;
    } else if (toBox < fromBox) {
      stats['boxDemotions'] = (stats['boxDemotions'] ?? 0) + 1;
    }
    
    await prefs.setString(key, jsonEncode(stats));
  }

  // Lấy thống kê Leitner hôm nay
  Future<Map<String, int>> getTodayLeitnerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = '${_dailyLeitnerReviewsKey}_$today';
    
    final data = prefs.getString(key);
    if (data == null) {
      return {'correct': 0, 'total': 0, 'boxPromotions': 0, 'boxDemotions': 0};
    }
    
    return Map<String, int>.from(jsonDecode(data));
  }

  // Lấy thống kê Leitner 7 ngày gần nhất
  Future<List<Map<String, dynamic>>> getWeeklyLeitnerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final stats = <Map<String, dynamic>>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final key = '${_dailyLeitnerReviewsKey}_$dateKey';
      
      final data = prefs.getString(key);
      Map<String, int> dayStats = {
        'correct': 0,
        'total': 0,
        'boxPromotions': 0,
        'boxDemotions': 0,
      };
      
      if (data != null) {
        dayStats = Map<String, int>.from(jsonDecode(data));
      }
      
      stats.add({
        'date': date,
        'dateString': dateKey,
        'correct': dayStats['correct'] ?? 0,
        'total': dayStats['total'] ?? 0,
        'boxPromotions': dayStats['boxPromotions'] ?? 0,
        'boxDemotions': dayStats['boxDemotions'] ?? 0,
        'accuracy': dayStats['total']! > 0 
            ? ((dayStats['correct']! / dayStats['total']!) * 100).round()
            : 0,
      });
    }
    
    return stats;
  }

  // Khởi tạo Leitner cho từ vựng mới
  Future<void> initializeLeitnerForNewVocabularies() async {
    final dates = await _vocabularyService.getAllVocabularyDates();
    
    for (final date in dates) {
      final vocabularies = await _vocabularyService.getVocabularyForDate(date);
      bool needsUpdate = false;
      
      for (int i = 0; i < vocabularies.length; i++) {
        final vocab = vocabularies[i];
        
        // Nếu từ vựng chưa có thông tin Leitner, khởi tạo
        if (vocab.lastLeitnerReview == null && vocab.leitnerBox == 1) {
          final updatedVocab = vocab.copyWith(
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

  // Reset toàn bộ Leitner data
  Future<void> resetAllLeitnerData() async {
    final dates = await _vocabularyService.getAllVocabularyDates();
    
    for (final date in dates) {
      final vocabularies = await _vocabularyService.getVocabularyForDate(date);
      final resetVocabs = vocabularies.map((vocab) => vocab.copyWith(
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
        key.startsWith(_dailyLeitnerReviewsKey) || 
        key.startsWith(_leitnerStatsKey)
    ).toList();
    
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  // Lấy gợi ý ôn tập Leitner
  Future<Map<String, dynamic>> getLeitnerSuggestions() async {
    final distribution = await getBoxDistribution();
    final reviewItems = await getLeitnerReviews();
    final todayStats = await getTodayLeitnerStats();
    
    final suggestions = <String>[];
    final totalWords = distribution.values.fold(0, (sum, count) => sum + count);
    
    // Gợi ý dựa trên phân bố
    if (distribution[1]! > totalWords * 0.4) {
      suggestions.add('Bạn có nhiều từ ở Hộp 1. Hãy tập trung ôn tập để chuyển chúng lên hộp cao hơn!');
    }
    
    if (distribution[5]! > totalWords * 0.3) {
      suggestions.add('Tuyệt vời! Bạn đã thành thạo nhiều từ vựng ở Hộp 5.');
    }
    
    if (reviewItems.length > 50) {
      suggestions.add('Bạn có ${reviewItems.length} từ cần ôn. Hãy chia nhỏ thành các phiên học 10-15 từ.');
    }
    
    if (todayStats['total']! > 0 && todayStats['correct']! / todayStats['total']! > 0.8) {
      suggestions.add('Tỷ lệ chính xác hôm nay rất cao! Tiếp tục phát huy!');
    }

    return {
      'suggestions': suggestions,
      'totalReviews': reviewItems.length,
      'distribution': distribution,
      'todayAccuracy': todayStats['total']! > 0 
          ? (todayStats['correct']! / todayStats['total']! * 100).round()
          : 0,
    };
  }
}

// Class để lưu trữ thông tin vocabulary cần review theo Leitner
class LeitnerReviewItem {
  final Vocabulary vocabulary;
  final DateTime originalDate;
  final int vocabularyIndex;

  LeitnerReviewItem({
    required this.vocabulary,
    required this.originalDate,
    required this.vocabularyIndex,
  });
}
