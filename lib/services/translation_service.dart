import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  // Sử dụng Google Translate API miễn phí thông qua proxy
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';
  
  Future<String?> translateText(String text, {String fromLang = 'en', String toLang = 'vi'}) async {
    try {
      final uri = Uri.parse('$_baseUrl?q=${Uri.encodeComponent(text)}&langpair=$fromLang|$toLang');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'English Vocab App',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['responseStatus'] == 200 && data['responseData'] != null) {
          String translation = data['responseData']['translatedText'];
          
          // Làm sạch kết quả dịch
          translation = translation.trim();
          
          // Loại bỏ các ký tự không mong muốn
          translation = translation.replaceAll(RegExp(r'["""]'), '"');
          translation = translation.replaceAll(RegExp(r"[''']"), "'");
          
          return translation;
        }
      }
      return null;
    } catch (e) {
      print('Translation error: $e');
      return null;
    }
  }
  
  // Alternative API nếu MyMemory không hoạt động
  Future<String?> translateTextAlternative(String text) async {
    try {
      // Sử dụng LibreTranslate API miễn phí
      final uri = Uri.parse('https://libretranslate.com/translate');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'q': text,
          'source': 'en',
          'target': 'vi',
          'format': 'text',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedText']?.toString().trim();
      }
      return null;
    } catch (e) {
      print('Alternative translation error: $e');
      return null;
    }
  }
}
