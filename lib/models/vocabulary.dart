class Vocabulary {
  final String word;
  final String meaning;
  final String pronunciation;
  final String memoryTip;
  final String example;
  final DateTime createdAt;
  final String? apiDefinitions; // JSON string chứa definitions từ API
  
  // Enhanced Spaced Repetition fields
  final int repetitionCount;
  final double easeFactor;
  final int intervalDays;
  final DateTime? nextReviewDate;
  final int? lastQuality; // 0-5, chất lượng học tập lần cuối
  final int streak; // Số lần đúng liên tiếp
  final int totalReviews; // Tổng số lần ôn tập
  final int totalCorrect; // Tổng số lần trả lời đúng
  final DateTime? lastReviewDate; // Lần ôn cuối cùng
  final double difficulty; // Độ khó của từ (0.0-1.0)
  final List<int> recentQualities; // 5 lần quality gần nhất
  
  // Enhanced Leitner System fields
  final int leitnerBox; // Hộp Leitner (1-5), hộp càng cao = hiểu biết càng tốt
  final int consecutiveCorrect; // Số lần trả lời đúng liên tiếp trong hộp hiện tại
  final DateTime? lastLeitnerReview; // Lần ôn Leitner cuối cùng
  final int leitnerStreak; // Streak trong Leitner system
  final int totalLeitnerReviews; // Tổng số lần ôn trong Leitner
  final int leitnerCorrectAnswers; // Tổng số câu đúng trong Leitner

  Vocabulary({
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.memoryTip,
    required this.example,
    required this.createdAt,
    this.apiDefinitions,
    this.repetitionCount = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.nextReviewDate,
    this.lastQuality,
    this.streak = 0,
    this.totalReviews = 0,
    this.totalCorrect = 0,
    this.lastReviewDate,
    this.difficulty = 0.5,
    this.recentQualities = const [],
    this.leitnerBox = 1,
    this.consecutiveCorrect = 0,
    this.lastLeitnerReview,
    this.leitnerStreak = 0,
    this.totalLeitnerReviews = 0,
    this.leitnerCorrectAnswers = 0,
  });

  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      pronunciation: json['pronunciation'] as String,
      memoryTip: json['memoryTip'] as String,
      example: json['example'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      apiDefinitions: json['apiDefinitions'] as String?,
      repetitionCount: json['repetitionCount'] as int? ?? 0,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: json['intervalDays'] as int? ?? 1,
      nextReviewDate: json['nextReviewDate'] != null 
          ? DateTime.parse(json['nextReviewDate'] as String)
          : null,
      lastQuality: json['lastQuality'] as int?,
      streak: json['streak'] as int? ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalCorrect: json['totalCorrect'] as int? ?? 0,
      lastReviewDate: json['lastReviewDate'] != null 
          ? DateTime.parse(json['lastReviewDate'] as String)
          : null,
      difficulty: (json['difficulty'] as num?)?.toDouble() ?? 0.5,
      recentQualities: (json['recentQualities'] as List<dynamic>?)?.cast<int>() ?? [],
      leitnerBox: json['leitnerBox'] as int? ?? 1,
      consecutiveCorrect: json['consecutiveCorrect'] as int? ?? 0,
      lastLeitnerReview: json['lastLeitnerReview'] != null 
          ? DateTime.parse(json['lastLeitnerReview'] as String)
          : null,
      leitnerStreak: json['leitnerStreak'] as int? ?? 0,
      totalLeitnerReviews: json['totalLeitnerReviews'] as int? ?? 0,
      leitnerCorrectAnswers: json['leitnerCorrectAnswers'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'meaning': meaning,
      'pronunciation': pronunciation,
      'memoryTip': memoryTip,
      'example': example,
      'createdAt': createdAt.toIso8601String(),
      'apiDefinitions': apiDefinitions,
      'repetitionCount': repetitionCount,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'nextReviewDate': nextReviewDate?.toIso8601String(),
      'lastQuality': lastQuality,
      'streak': streak,
      'totalReviews': totalReviews,
      'totalCorrect': totalCorrect,
      'lastReviewDate': lastReviewDate?.toIso8601String(),
      'difficulty': difficulty,
      'recentQualities': recentQualities,
      'leitnerBox': leitnerBox,
      'consecutiveCorrect': consecutiveCorrect,
      'lastLeitnerReview': lastLeitnerReview?.toIso8601String(),
      'leitnerStreak': leitnerStreak,
      'totalLeitnerReviews': totalLeitnerReviews,
      'leitnerCorrectAnswers': leitnerCorrectAnswers,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vocabulary &&
          runtimeType == other.runtimeType &&
          word == other.word &&
          meaning == other.meaning &&
          pronunciation == other.pronunciation &&
          memoryTip == other.memoryTip &&
          example == other.example &&
          apiDefinitions == other.apiDefinitions &&
          repetitionCount == other.repetitionCount &&
          easeFactor == other.easeFactor &&
          intervalDays == other.intervalDays &&
          nextReviewDate == other.nextReviewDate &&
          lastQuality == other.lastQuality &&
          leitnerBox == other.leitnerBox &&
          consecutiveCorrect == other.consecutiveCorrect &&
          lastLeitnerReview == other.lastLeitnerReview;

  @override
  int get hashCode =>
      word.hashCode ^
      meaning.hashCode ^
      pronunciation.hashCode ^
      memoryTip.hashCode ^
      example.hashCode ^
      apiDefinitions.hashCode ^
      repetitionCount.hashCode ^
      easeFactor.hashCode ^
      intervalDays.hashCode ^
      nextReviewDate.hashCode ^
      lastQuality.hashCode ^
      leitnerBox.hashCode ^
      consecutiveCorrect.hashCode ^
      lastLeitnerReview.hashCode;

  // Enhanced copyWith method with all new fields
  Vocabulary copyWith({
    String? word,
    String? meaning,
    String? pronunciation,
    String? memoryTip,
    String? example,
    DateTime? createdAt,
    String? apiDefinitions,
    int? repetitionCount,
    double? easeFactor,
    int? intervalDays,
    DateTime? nextReviewDate,
    int? lastQuality,
    int? streak,
    int? totalReviews,
    int? totalCorrect,
    DateTime? lastReviewDate,
    double? difficulty,
    List<int>? recentQualities,
    int? leitnerBox,
    int? consecutiveCorrect,
    DateTime? lastLeitnerReview,
    int? leitnerStreak,
    int? totalLeitnerReviews,
    int? leitnerCorrectAnswers,
  }) {
    return Vocabulary(
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      pronunciation: pronunciation ?? this.pronunciation,
      memoryTip: memoryTip ?? this.memoryTip,
      example: example ?? this.example,
      createdAt: createdAt ?? this.createdAt,
      apiDefinitions: apiDefinitions ?? this.apiDefinitions,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      lastQuality: lastQuality ?? this.lastQuality,
      streak: streak ?? this.streak,
      totalReviews: totalReviews ?? this.totalReviews,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
      difficulty: difficulty ?? this.difficulty,
      recentQualities: recentQualities ?? this.recentQualities,
      leitnerBox: leitnerBox ?? this.leitnerBox,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      lastLeitnerReview: lastLeitnerReview ?? this.lastLeitnerReview,
      leitnerStreak: leitnerStreak ?? this.leitnerStreak,
      totalLeitnerReviews: totalLeitnerReviews ?? this.totalLeitnerReviews,
      leitnerCorrectAnswers: leitnerCorrectAnswers ?? this.leitnerCorrectAnswers,
    );
  }

  // Check if this vocabulary is due for review
  bool get isDueForReview {
    if (nextReviewDate == null) return true;
    
    final today = DateTime.now();
    final reviewDate = nextReviewDate!;
    
    // So sánh theo ngày, tháng, năm (bỏ qua giờ, phút, giây)
    final todayDate = DateTime(today.year, today.month, today.day);
    final reviewDateOnly = DateTime(reviewDate.year, reviewDate.month, reviewDate.day);
    
    return todayDate.isAfter(reviewDateOnly) || todayDate.isAtSameMomentAs(reviewDateOnly);
  }

  // Enhanced status and display methods
  String get reviewStatus {
    if (repetitionCount == 0) return 'Mới';
    if (isDueForReview) return 'Cần ôn lại';
    if (nextReviewDate != null) {
      final days = nextReviewDate!.difference(DateTime.now()).inDays;
      if (days == 0) return 'Hôm nay';
      if (days == 1) return 'Ngày mai';
      return 'Còn $days ngày';
    }
    return 'Đã học';
  }

  // Enhanced Leitner box name with level descriptions
  String get leitnerBoxName {
    switch (leitnerBox) {
      case 1: return 'Mới học';
      case 2: return 'Đang nhớ';
      case 3: return 'Khá tốt';
      case 4: return 'Thành thạo';
      case 5: return 'Xuất sắc';
      default: return 'Hộp $leitnerBox';
    }
  }

  // Enhanced Leitner box color with better visual distinction
  int get leitnerBoxColor {
    switch (leitnerBox) {
      case 1: return 0xFFEF5350; // Red - cần học nhiều
      case 2: return 0xFFFF9800; // Orange - đang tiến bộ
      case 3: return 0xFFFFC107; // Amber - tạm ổn
      case 4: return 0xFF66BB6A; // Light Green - khá tốt
      case 5: return 0xFF4CAF50; // Green - thành thạo
      default: return 0xFF9E9E9E; // Grey
    }
  }

  // Icon cho Leitner box
  int get leitnerBoxIcon {
    switch (leitnerBox) {
      case 1: return 0xe80c; // school
      case 2: return 0xe8e6; // trending_up
      case 3: return 0xe8da; // psychology
      case 4: return 0xe839; // star_half
      case 5: return 0xe838; // star
      default: return 0xe887; // help
    }
  }

  // Tính tỷ lệ chính xác SR
  double get srAccuracyRate {
    if (totalReviews == 0) return 0.0;
    return totalCorrect / totalReviews;
  }

  // Tính tỷ lệ chính xác Leitner
  double get leitnerAccuracyRate {
    if (totalLeitnerReviews == 0) return 0.0;
    return leitnerCorrectAnswers / totalLeitnerReviews;
  }

  // Kiểm tra xem từ có đang "hot streak" không
  bool get isOnStreak => streak >= 3;

  // Kiểm tra từ khó
  bool get isDifficult => difficulty > 0.7 || (recentQualities.isNotEmpty && 
      recentQualities.where((q) => q <= 2).length >= 3);

  // Mức độ thành thạo tổng thể (0.0 - 1.0)
  double get masteryLevel {
    final srMastery = srAccuracyRate * 0.4;
    final leitnerMastery = (leitnerBox / 5.0) * 0.4;
    final streakBonus = (streak / 10.0).clamp(0.0, 0.2);
    return (srMastery + leitnerMastery + streakBonus).clamp(0.0, 1.0);
  }

  // Màu sắc cho mức độ thành thạo
  int get masteryColor {
    final level = masteryLevel;
    if (level < 0.3) return 0xFFEF5350; // Red
    if (level < 0.5) return 0xFFFF9800; // Orange
    if (level < 0.7) return 0xFFFBC02D; // Yellow
    if (level < 0.9) return 0xFF8BC34A; // Light Green
    return 0xFF4CAF50; // Green
  }

  // Check if this vocabulary needs Leitner review
  bool get isDueForLeitnerReview {
    if (lastLeitnerReview == null) return true;
    
    final today = DateTime.now();
    final daysSinceLastReview = today.difference(lastLeitnerReview!).inDays;
    
    // Khoảng thời gian ôn tập cho từng hộp (ngày)
    final reviewIntervals = [1, 3, 7, 14, 30]; // Box 1-5
    final interval = reviewIntervals[leitnerBox - 1];
    
    return daysSinceLastReview >= interval;
  }
}
