import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';
import '../services/dictionary_service.dart';
import '../services/translation_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddVocabularyScreen extends StatefulWidget {
  final DateTime selectedDate;

  const AddVocabularyScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<AddVocabularyScreen> createState() => _AddVocabularyScreenState();
}

class _AddVocabularyScreenState extends State<AddVocabularyScreen>
    with TickerProviderStateMixin {
  final VocabularyService _vocabularyService = VocabularyService();
  final DictionaryService _dictionaryService = DictionaryService();
  final TranslationService _translationService = TranslationService();
  final List<Vocabulary> _vocabularies = [];
  
  final TextEditingController _wordController = TextEditingController();
  final TextEditingController _meaningController = TextEditingController();
  final TextEditingController _pronunciationController = TextEditingController();
  final TextEditingController _exampleController = TextEditingController();

  // FocusNodes cho toàn bộ form để điều khiển thứ tự Tab
  final FocusNode _wordFocus = FocusNode();
  final FocusNode _meaningFocus = FocusNode();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _isLoadingPronunciation = false;
  bool _isLoadingTranslation = false;
  
  // Dữ liệu từ API
  List<Map<String, dynamic>> _definitions = [];
  String? _apiExample;
  String? _translatedMeaning;
  
  // Biến để theo dõi từ vựng trước đó
  String _previousWord = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Thêm listener để tự động lấy API khi nhập nghĩa
    _meaningController.addListener(_onMeaningChanged);
    
    // Thêm listener để xóa dữ liệu API cũ khi từ vựng thay đổi
    _wordController.addListener(_onWordChanged);
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _animationController.forward();
    _loadExistingVocabularies();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _meaningController.removeListener(_onMeaningChanged);
    _wordController.removeListener(_onWordChanged);
    _wordController.dispose();
    _meaningController.dispose();
    _pronunciationController.dispose();
    _exampleController.dispose();
    
    // Dispose các FocusNodes
    _wordFocus.dispose();
    _meaningFocus.dispose();
    
    super.dispose();
  }

  Future<void> _loadExistingVocabularies() async {
    final vocabularies = await _vocabularyService.getVocabularyForDate(widget.selectedDate);
    setState(() {
      _vocabularies.clear();
      _vocabularies.addAll(vocabularies);
    });
  }

  void _addVocabulary() {
    if (_formKey.currentState!.validate()) {
      // Tạo cách nhớ từ các phần
      final memoryTip = _buildMemoryTip();
      
      // Convert API definitions to JSON string
      String? apiDefinitionsJson;
      if (_definitions.isNotEmpty) {
        apiDefinitionsJson = jsonEncode(_definitions);
      }
      
      final vocabulary = Vocabulary(
        word: _wordController.text.trim(),
        meaning: _meaningController.text.trim(),
        pronunciation: _pronunciationController.text.trim(),
        memoryTip: memoryTip,
        example: _exampleController.text.trim(),
        createdAt: DateTime.now(),
        apiDefinitions: apiDefinitionsJson,
      );

      setState(() {
        _vocabularies.add(vocabulary);
      });

      // Clear form
      _wordController.clear();
      _meaningController.clear();
      _pronunciationController.clear();
      _exampleController.clear();
      
      // Clear API data
      _definitions.clear();
      _apiExample = null;
      _translatedMeaning = null;
      _previousWord = ''; // Reset từ vựng trước đó

      // Show success animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm từ "${vocabulary.word}"'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            right: 20,
            left: MediaQuery.of(context).size.width - 280,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _buildMemoryTip() {
    return '';
  }

  Future<void> _saveAllVocabularies() async {
    if (_vocabularies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng thêm ít nhất một từ vựng'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            right: 20,
            left: MediaQuery.of(context).size.width - 350,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _vocabularyService.saveVocabularyForDate(widget.selectedDate, _vocabularies);
      
      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lưu ${_vocabularies.length} từ vựng thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              right: 20,
              left: MediaQuery.of(context).size.width - 380,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lỗi lưu dữ liệu'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              right: 20,
              left: MediaQuery.of(context).size.width - 250,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _removeVocabulary(int index) {
    setState(() {
      _vocabularies.removeAt(index);
    });
  }

  Future<void> _fetchPronunciation() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập từ vựng trước'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            right: 20,
            left: MediaQuery.of(context).size.width - 300,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingPronunciation = true;
    });

    try {
      final wordDetails = await _dictionaryService.getWordDetails(word);
      
      if (wordDetails != null) {
        setState(() {
          if (wordDetails['pronunciation'] != null) {
            _pronunciationController.text = wordDetails['pronunciation'];
          }
          
          // Parse definitions từ raw API data nếu có
          if (wordDetails['rawDefinitions'] != null) {
            _definitions = List<Map<String, dynamic>>.from(wordDetails['rawDefinitions']);
          }
          
          if (wordDetails['rawExample'] != null) {
            _apiExample = wordDetails['rawExample'];
            _exampleController.text = _apiExample!;
          } else if (wordDetails['definition'] != null) {
            _exampleController.text = wordDetails['definition'];
          }
          
          // Cập nhật từ vựng hiện tại để tránh xóa dữ liệu không cần thiết
          _previousWord = word;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đã lấy thông tin thành công'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 150,
                right: 20,
                left: MediaQuery.of(context).size.width - 300,
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Không tìm thấy thông tin cho từ này'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 150,
                right: 20,
                left: MediaQuery.of(context).size.width - 350,
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lỗi khi lấy thông tin từ API'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              right: 20,
              left: MediaQuery.of(context).size.width - 300,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPronunciation = false;
        });
      }
    }
  }

  // Tự động lấy API khi người dùng nhập nghĩa
  void _onMeaningChanged() {
    final meaning = _meaningController.text.trim();
    final word = _wordController.text.trim();
    
    // Chỉ tự động lấy API khi:
    // 1. Có từ vựng
    // 2. Có nghĩa 
    // 3. Chưa có thông tin API
    // 4. Không đang loading
    if (word.isNotEmpty && 
        meaning.isNotEmpty && 
        _definitions.isEmpty && 
        !_isLoadingPronunciation) {
      
      // Delay một chút để tránh gọi API quá nhiều lần khi đang gõ
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && 
            _meaningController.text.trim() == meaning && 
            _wordController.text.trim() == word &&
            _definitions.isEmpty) {
          _fetchPronunciation();
        }
      });
    }
  }

  // Xóa dữ liệu API cũ khi từ vựng thay đổi
  void _onWordChanged() {
    final currentWord = _wordController.text.trim();
    
    // Chỉ xóa dữ liệu khi từ vựng thực sự thay đổi (khác với từ trước đó)
    if (currentWord != _previousWord) {
      setState(() {
        // Xóa tất cả dữ liệu API cũ
        _pronunciationController.clear();
        _exampleController.clear();
        _definitions.clear();
        _apiExample = null;
        _translatedMeaning = null;
      });
      
      // Cập nhật từ vựng trước đó
      _previousWord = currentWord;
    }
  }

  // Lấy bản dịch từ API
  Future<void> _fetchTranslation() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập từ vựng trước'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height - 150,
            right: 20,
            left: MediaQuery.of(context).size.width - 300,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingTranslation = true;
    });

    try {
      String? translation = await _translationService.translateText(word);
      
      // Thử API thay thế nếu API chính không hoạt động
      if (translation == null || translation.isEmpty) {
        translation = await _translationService.translateTextAlternative(word);
      }
      
      if (translation != null && translation.isNotEmpty && mounted) {
        setState(() {
          _translatedMeaning = translation;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã dịch thành công'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              right: 20,
              left: MediaQuery.of(context).size.width - 250,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Không thể dịch từ này'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height - 150,
                right: 20,
                left: MediaQuery.of(context).size.width - 280,
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lỗi khi dịch từ API'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).size.height - 150,
              right: 20,
              left: MediaQuery.of(context).size.width - 250,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTranslation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Thêm từ vựng - ${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: [
          if (_vocabularies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_vocabularies.length} từ',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 50 * (1 - _slideAnimation.value)),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Row(
                children: [
                  // Form thêm từ vựng mới (bên trái)
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          height: double.infinity,
                          padding: const EdgeInsets.all(20.0),
                          child: SingleChildScrollView(
                            child: FocusTraversalGroup(
                              policy: OrderedTraversalPolicy(),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Thêm từ vựng mới',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Hướng dẫn Enter navigation
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: colorScheme.primary.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.keyboard_return,
                                          size: 16,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Nhấn Enter để chuyển từ ô Từ vựng sang ô Nghĩa',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _wordController,
                                    label: 'Từ vựng',
                                    hint: 'Ví dụ: Attend',
                                    icon: Icons.language,
                                    validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập từ vựng' : null,
                                    focusNode: _wordFocus,
                                    nextFocusNode: _meaningFocus,
                                    tabOrder: 1,
                                  ),
                                  const SizedBox(height: 16),
                                  // Phần nghĩa tiếng Việt với tùy chọn dịch
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: colorScheme.outline),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Nghĩa tiếng Việt',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                            const Spacer(),
                                            ElevatedButton.icon(
                                              onPressed: _isLoadingTranslation ? null : _fetchTranslation,
                                              focusNode: FocusNode(canRequestFocus: false),
                                              icon: _isLoadingTranslation 
                                                ? const SizedBox(
                                                    width: 16, 
                                                    height: 16, 
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : const Icon(Icons.translate, size: 16),
                                              label: Text(_isLoadingTranslation ? 'Đang dịch...' : 'Dịch từ API'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: colorScheme.primary,
                                                foregroundColor: colorScheme.onPrimary,
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                textStyle: const TextStyle(fontSize: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Hiển thị bản dịch từ API nếu có
                                        if (_translatedMeaning != null && _translatedMeaning!.isNotEmpty)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: colorScheme.primary.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Bản dịch từ API:',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _translatedMeaning!,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: colorScheme.onSurface,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _meaningController.text = _translatedMeaning!;
                                                    });
                                                  },
                                                  focusNode: FocusNode(canRequestFocus: false),
                                                  icon: const Icon(Icons.input, size: 14),
                                                  label: const Text('Sử dụng bản dịch này'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.green,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                    textStyle: const TextStyle(fontSize: 11),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        _buildTextField(
                                          controller: _meaningController,
                                          label: 'Nhập nghĩa',
                                          hint: 'Nhập nghĩa hoặc sử dụng dịch từ API ở trên',
                                          icon: Icons.translate,
                                          validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập nghĩa' : null,
                                          focusNode: _meaningFocus,
                                          nextFocusNode: null,
                                          tabOrder: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _pronunciationController,
                                          label: 'Cách đọc (tự động)',
                                          hint: 'Sẽ được tự động điền từ API',
                                          icon: Icons.record_voice_over,
                                          enabled: false,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                  
                  // API Information Box
                  _buildApiInfoBox(),                                  // Hidden example field for validation
                                  Visibility(
                                    visible: false,
                                    child: _buildTextField(
                                      controller: _exampleController,
                                      label: 'Example (hidden)',
                                      hint: '',
                                      icon: Icons.format_quote,
                                      validator: (value) => _definitions.isEmpty && (value?.isEmpty == true) 
                                          ? 'Vui lòng lấy thông tin từ API hoặc nhập thủ công' 
                                          : null,
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _addVocabulary,
                                      focusNode: FocusNode(canRequestFocus: false),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: colorScheme.primary,
                                        foregroundColor: colorScheme.onPrimary,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                      child: const Text(
                                        'Thêm từ vựng',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Danh sách từ vựng đã thêm (bên phải)
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16.0, right: 16.0, bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
                            child: Text(
                              _vocabularies.isEmpty 
                                  ? 'Chưa có từ vựng nào'
                                  : 'Danh sách từ vựng (${_vocabularies.length}):',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Card(
                              elevation: 8,
                              shadowColor: Colors.black.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16.0),
                                child: _vocabularies.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.school_outlined,
                                              size: 64,
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Thêm từ vựng đầu tiên!',
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: colorScheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _vocabularies.length,
                                        itemBuilder: (context, index) {
                                          final vocab = _vocabularies[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 12.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: colorScheme.surfaceContainer,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: colorScheme.secondary.withOpacity(0.2),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: colorScheme.shadow.withOpacity(0.05),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(16.0),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 28,
                                                          height: 28,
                                                          decoration: BoxDecoration(
                                                            color: colorScheme.secondary,
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              '${index + 1}',
                                                              style: TextStyle(
                                                                color: colorScheme.onSecondary,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                vocab.word,
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 16,
                                                                  color: colorScheme.onSurface,
                                                                ),
                                                              ),
                                                              Text(
                                                                '/${vocab.pronunciation}/',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: colorScheme.onSurfaceVariant,
                                                                  fontStyle: FontStyle.italic,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                          onPressed: () => _removeVocabulary(index),
                                                          focusNode: FocusNode(canRequestFocus: false),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      'Nghĩa: ${vocab.meaning}',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: colorScheme.onSurface,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ).animate().fadeIn(delay: Duration(milliseconds: index * 100)).slideY(begin: 0.3),
                                          );
                                        },
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
          );
        },
      ),
      floatingActionButton: _vocabularies.isNotEmpty
          ? Focus(
              canRequestFocus: false,
              child: FloatingActionButton.extended(
                onPressed: _isLoading ? null : _saveAllVocabularies,
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Đang lưu...' : 'Lưu tất cả'),
              ).animate().scale(delay: const Duration(milliseconds: 500)),
            )
          : null,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool enabled = true,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    int? tabOrder,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (tabOrder != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$tabOrder',
                      style: TextStyle(
                        color: colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          enabled: enabled,
          focusNode: focusNode,
          style: TextStyle(color: colorScheme.onSurface),
          onEditingComplete: () {
            // Khi nhấn Enter, chuyển sang field tiếp theo
            if (nextFocusNode != null) {
              nextFocusNode.requestFocus();
            } else {
              FocusScope.of(context).unfocus();
            }
          },
          textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
          decoration: InputDecoration(
            labelText: tabOrder == null ? label : null,
            hintText: hint,
            prefixIcon: Icon(icon, color: colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainer,
            labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
          ),
        ),
      ],
    );
  }

  Widget _buildApiInfoBox() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Thông tin từ Cambridge Dictionary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (_definitions.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tự động lấy definitions và examples khi bạn nhập nghĩa',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Hiển thị definitions
            for (int i = 0; i < _definitions.length; i++) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _definitions[i]['partOfSpeech']?.isNotEmpty == true 
                                ? _definitions[i]['partOfSpeech'] 
                                : 'Definition ${i + 1}',
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _definitions[i]['definition'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                    
                    // Hiển thị example cho definition này
                    if (_definitions[i]['example'] != null && 
                        _definitions[i]['example'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: colorScheme.outline),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.format_quote, color: colorScheme.onSurfaceVariant, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _definitions[i]['example'].toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

}
