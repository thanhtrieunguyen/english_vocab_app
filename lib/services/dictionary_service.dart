import 'dart:convert';
import 'package:http/http.dart' as http;

class DictionaryService {
  static const String baseUrl = 'https://dictionary-api.eliaschen.dev/api/dictionary';
  
  // Lấy cách đọc từ Cambridge Dictionary API
  Future<String?> getPronunciation(String word) async {
    try {
      // Sử dụng English (US) làm mặc định
      final uri = Uri.parse('$baseUrl/en/$word');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'English Vocab App',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Lấy pronunciation đầu tiên từ mảng pronunciation
        if (data['pronunciation'] != null && 
            data['pronunciation'] is List &&
            data['pronunciation'].isNotEmpty) {
          
          // Ưu tiên pronunciation US, nếu không có thì lấy UK
          var usPronunciation = data['pronunciation'].firstWhere(
            (p) => p['lang'] == 'us',
            orElse: () => null,
          );
          
          if (usPronunciation != null && usPronunciation['pron'] != null) {
            String pronunciation = usPronunciation['pron'];
            // Loại bỏ dấu / ở đầu và cuối nếu có
            pronunciation = pronunciation.replaceAll(RegExp(r'^/|/$'), '');
            return pronunciation;
          }
          
          // Nếu không có US pronunciation, lấy UK
          var ukPronunciation = data['pronunciation'].firstWhere(
            (p) => p['lang'] == 'uk',
            orElse: () => null,
          );
          
          if (ukPronunciation != null && ukPronunciation['pron'] != null) {
            String pronunciation = ukPronunciation['pron'];
            pronunciation = pronunciation.replaceAll(RegExp(r'^/|/$'), '');
            return pronunciation;
          }
          
          // Nếu không có cả US và UK, lấy pronunciation đầu tiên
          var firstPronunciation = data['pronunciation'][0];
          if (firstPronunciation['pron'] != null) {
            String pronunciation = firstPronunciation['pron'];
            pronunciation = pronunciation.replaceAll(RegExp(r'^/|/$'), '');
            return pronunciation;
          }
        }
        
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
  
  // Lấy thông tin chi tiết từ (pronunciation + definition)
  Future<Map<String, dynamic>?> getWordDetails(String word) async {
    try {
      final uri = Uri.parse('$baseUrl/en/$word');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'English Vocab App',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        String? pronunciation;
        String? definition;
        List<Map<String, dynamic>> rawDefinitions = [];
        String? rawExample;
        
        // Lấy pronunciation
        if (data['pronunciation'] != null && 
            data['pronunciation'] is List &&
            data['pronunciation'].isNotEmpty) {
          
          var usPronunciation = data['pronunciation'].firstWhere(
            (p) => p['lang'] == 'us',
            orElse: () => data['pronunciation'][0],
          );
          
          if (usPronunciation['pron'] != null) {
            pronunciation = usPronunciation['pron'].replaceAll(RegExp(r'^/|/$'), '');
          }
        }
        
        // Lấy definition và parse raw data
        if (data['definition'] != null && 
            data['definition'] is List &&
            data['definition'].isNotEmpty) {
          
          List<String> definitions = [];
          String? firstExample;
          
          // Lấy 2 definition đầu tiên cho raw data
          for (int i = 0; i < data['definition'].length && i < 2; i++) {
            var def = data['definition'][i];
            
            // Lưu raw definition data với format phù hợp với UI
            if (def['text'] != null) {
              Map<String, dynamic> rawDef = {
                'definition': def['text'].toString().trim(),
                'partOfSpeech': def['pos'] ?? '',
                'example': null
              };
              
              // Lấy example đầu tiên cho definition này
              if (def['example'] != null && def['example'] is List && def['example'].isNotEmpty) {
                rawDef['example'] = def['example'][0]['text']?.toString().trim();
              }
              
              rawDefinitions.add(rawDef);
              
              // Xử lý cho formatted definition
              String defText = def['text'].toString().trim();
              if (defText.endsWith(':')) {
                defText = defText.substring(0, defText.length - 1).trim();
              }
              
              String pos = def['pos'] ?? '';
              if (pos.isNotEmpty) {
                defText = '($pos) $defText';
              }
              
              definitions.add(defText);
              
              // Lấy example đầu tiên từ definition đầu tiên
              if (i == 0 && firstExample == null && def['example'] != null && def['example'] is List && def['example'].isNotEmpty) {
                var firstExampleObj = def['example'][0];
                if (firstExampleObj['text'] != null) {
                  firstExample = firstExampleObj['text'].toString().trim();
                  rawExample = firstExample;
                }
              }
            }
          }
          
          // Kết hợp definitions
          if (definitions.isNotEmpty) {
            definition = definitions.join('\n\n');
          }
          
          // Nếu có example, thêm vào definition
          if (firstExample != null && firstExample.isNotEmpty) {
            definition = definition != null 
                ? '$definition\n\nExample: $firstExample'
                : 'Example: $firstExample';
          }
        }
        
        return {
          'pronunciation': pronunciation,
          'definition': definition,
          'word': data['word'],
          'rawDefinitions': rawDefinitions,
          'rawExample': rawExample,
        };
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
