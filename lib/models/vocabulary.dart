class Vocabulary {
  final String word;
  final String meaning;
  final String pronunciation;
  final String memoryTip;
  final String example;
  final DateTime createdAt;
  final String? apiDefinitions; // JSON string chứa definitions từ API
  
  // Spaced Repetition fields
  final int repetitionCount;
  final double easeFactor;
  final int intervalDays;
  final DateTime? nextReviewDate;
  final int? lastQuality; // 0-5, chất lượng học tập lần cuối
  
  // Leitner System fields
  final int leitnerBox; // Hộp Leitner (1-5), hộp càng cao = hiểu biết càng tốt
  final int consecutiveCorrect; // Số lần trả lời đúng liên tiếp trong hộp hiện tại
  final DateTime? lastLeitnerReview; // Lần ôn Leitner cuối cùng

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
    this.leitnerBox = 1,
    this.consecutiveCorrect = 0,
    this.lastLeitnerReview,
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
      leitnerBox: json['leitnerBox'] as int? ?? 1,
      consecutiveCorrect: json['consecutiveCorrect'] as int? ?? 0,
      lastLeitnerReview: json['lastLeitnerReview'] != null 
          ? DateTime.parse(json['lastLeitnerReview'] as String)
          : null,
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
      'leitnerBox': leitnerBox,
      'consecutiveCorrect': consecutiveCorrect,
      'lastLeitnerReview': lastLeitnerReview?.toIso8601String(),
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

  // Copy with method for updating spaced repetition data
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
    int? leitnerBox,
    int? consecutiveCorrect,
    DateTime? lastLeitnerReview,
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
      leitnerBox: leitnerBox ?? this.leitnerBox,
      consecutiveCorrect: consecutiveCorrect ?? this.consecutiveCorrect,
      lastLeitnerReview: lastLeitnerReview ?? this.lastLeitnerReview,
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

  // Get status for display
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

  // Get Leitner box name
  String get leitnerBoxName {
    switch (leitnerBox) {
      case 1:
        return 'Hộp 1 (Mới)';
      case 2:
        return 'Hộp 2 (Đang học)';
      case 3:
        return 'Hộp 3 (Quen thuộc)';
      case 4:
        return 'Hộp 4 (Thành thạo)';
      case 5:
        return 'Hộp 5 (Hoàn thiện)';
      default:
        return 'Hộp $leitnerBox';
    }
  }

  // Get Leitner box color
  int get leitnerBoxColor {
    switch (leitnerBox) {
      case 1:
        return 0xFFE57373; // Red - New/Difficult
      case 2:
        return 0xFFFFB74D; // Orange - Learning
      case 3:
        return 0xFFFFD54F; // Yellow - Familiar
      case 4:
        return 0xFF81C784; // Light Green - Proficient
      case 5:
        return 0xFF4CAF50; // Green - Mastered
      default:
        return 0xFF9E9E9E; // Grey - Unknown
    }
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
