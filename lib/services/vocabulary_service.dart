import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocabulary.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class VocabularyService {
  static const String _storageKey = 'vocabulary_data';

  // Lưu từ vựng cho một ngày cụ thể
  Future<void> saveVocabularyForDate(DateTime date, List<Vocabulary> vocabularies) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    
    final vocabularyData = vocabularies.map((v) => v.toJson()).toList();
    await prefs.setString('${_storageKey}_$dateKey', jsonEncode(vocabularyData));
  }

  // Lấy từ vựng cho một ngày cụ thể
  Future<List<Vocabulary>> getVocabularyForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    
    final data = prefs.getString('${_storageKey}_$dateKey');
    if (data == null) return [];

    final List<dynamic> decodedData = jsonDecode(data);
    return decodedData.map((item) => Vocabulary.fromJson(item)).toList();
  }

  // Cập nhật một từ vựng cụ thể trong ngày
  Future<void> updateVocabularyInDate(DateTime date, int index, Vocabulary updatedVocabulary) async {
    final vocabularies = await getVocabularyForDate(date);
    if (index >= 0 && index < vocabularies.length) {
      vocabularies[index] = updatedVocabulary;
      await saveVocabularyForDate(date, vocabularies);
    }
  }

  // Xóa một từ vựng cụ thể trong ngày
  Future<void> deleteVocabularyInDate(DateTime date, int index) async {
    final vocabularies = await getVocabularyForDate(date);
    if (index >= 0 && index < vocabularies.length) {
      vocabularies.removeAt(index);
      await saveVocabularyForDate(date, vocabularies);
    }
  }

  // Thêm một từ vựng vào ngày
  Future<void> addVocabularyToDate(DateTime date, Vocabulary vocabulary) async {
    final vocabularies = await getVocabularyForDate(date);
    vocabularies.add(vocabulary);
    await saveVocabularyForDate(date, vocabularies);
  }

  // Tìm kiếm từ vựng trong một ngày
  Future<List<Vocabulary>> searchVocabularyInDate(DateTime date, String query) async {
    final vocabularies = await getVocabularyForDate(date);
    if (query.isEmpty) return vocabularies;
    
    final lowercaseQuery = query.toLowerCase();
    return vocabularies.where((vocab) => 
      vocab.word.toLowerCase().contains(lowercaseQuery) ||
      vocab.meaning.toLowerCase().contains(lowercaseQuery) ||
      vocab.memoryTip.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Tìm kiếm từ vựng trong tất cả các ngày
  Future<Map<DateTime, List<Vocabulary>>> searchVocabularyGlobal(String query) async {
    final result = <DateTime, List<Vocabulary>>{};
    final dates = await getAllVocabularyDates();
    
    for (final date in dates) {
      final searchResults = await searchVocabularyInDate(date, query);
      if (searchResults.isNotEmpty) {
        result[date] = searchResults;
      }
    }
    
    return result;
  }

  // Lấy tất cả ngày có từ vựng
  Future<List<DateTime>> getAllVocabularyDates() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    final vocabularyKeys = keys.where((key) => key.startsWith(_storageKey)).toList();
    final dates = <DateTime>[];
    
    for (final key in vocabularyKeys) {
      final dateString = key.replaceFirst('${_storageKey}_', '');
      try {
        final date = DateFormat('yyyy-MM-dd').parse(dateString);
        dates.add(date);
      } catch (e) {
        // Ignore invalid date formats
      }
    }
    
    dates.sort((a, b) => b.compareTo(a)); // Sort descending (newest first)
    return dates;
  }

  // Lấy số lượng từ vựng cho một ngày
  Future<int> getVocabularyCountForDate(DateTime date) async {
    final vocabularies = await getVocabularyForDate(date);
    return vocabularies.length;
  }

  // Xóa từ vựng cho một ngày cụ thể
  Future<void> deleteVocabularyForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    await prefs.remove('${_storageKey}_$dateKey');
  }

  // Cập nhật từ vựng cho một ngày cụ thể
  Future<void> updateVocabularyForDate(DateTime date, List<Vocabulary> vocabularies) async {
    await saveVocabularyForDate(date, vocabularies);
  }

  // Export tất cả data ra JSON
  Future<String?> exportAllDataToJson() async {
    try {
      final allData = <String, dynamic>{};
      final dates = await getAllVocabularyDates();
      
      for (final date in dates) {
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final vocabularies = await getVocabularyForDate(date);
        allData[dateKey] = vocabularies.map((v) => v.toJson()).toList();
      }
      
      final exportData = {
        'app_name': 'English Vocab App',
        'export_date': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'data': allData,
      };
      
      // Lưu file
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'vocabulary_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(jsonEncode(exportData));
      return file.path;
    } catch (e) {
      return null;
    }
  }

  // Import data từ JSON file
  Future<bool> importDataFromJson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final data = jsonDecode(content);
        
        if (data['data'] != null) {
          final vocabularyData = data['data'] as Map<String, dynamic>;
          
          for (final entry in vocabularyData.entries) {
            try {
              final date = DateFormat('yyyy-MM-dd').parse(entry.key);
              final vocabList = (entry.value as List)
                  .map((item) => Vocabulary.fromJson(item))
                  .toList();
              
              await saveVocabularyForDate(date, vocabList);
            } catch (e) {
              // Skip invalid entries
              continue;
            }
          }
          
          return true;
        }
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  // Lấy thống kê tổng quan
  Future<Map<String, int>> getStatistics() async {
    final dates = await getAllVocabularyDates();
    int totalWords = 0;
    int totalDays = dates.length;
    
    for (final date in dates) {
      final count = await getVocabularyCountForDate(date);
      totalWords += count;
    }
    
    return {
      'totalWords': totalWords,
      'totalDays': totalDays,
      'averagePerDay': totalDays > 0 ? (totalWords / totalDays).round() : 0,
    };
  }

  // Xóa một từ vựng tại vị trí index trong ngày cụ thể
  Future<void> deleteVocabulary(DateTime date, int index) async {
    final vocabularies = await getVocabularyForDate(date);
    
    if (index < 0 || index >= vocabularies.length) {
      throw Exception('Index không hợp lệ');
    }
    
    // Xóa từ vựng tại index
    vocabularies.removeAt(index);
    
    // Lưu lại danh sách đã cập nhật
    await saveVocabularyForDate(date, vocabularies);
  }

  // Xóa tất cả từ vựng của một ngày
  Future<void> deleteAllVocabularyForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    await prefs.remove('${_storageKey}_$dateKey');
  }
}
