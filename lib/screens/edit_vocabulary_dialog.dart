import 'package:flutter/material.dart';
import '../models/vocabulary.dart';
import '../services/vocabulary_service.dart';
import '../services/dictionary_service.dart';
import '../services/translation_service.dart';

class EditVocabularyDialog extends StatefulWidget {
  final Vocabulary vocabulary;
  final DateTime date;
  final int index;
  final VoidCallback onUpdated;

  const EditVocabularyDialog({
    super.key,
    required this.vocabulary,
    required this.date,
    required this.index,
    required this.onUpdated,
  });

  @override
  State<EditVocabularyDialog> createState() => _EditVocabularyDialogState();
}

class _EditVocabularyDialogState extends State<EditVocabularyDialog> {
  final _formKey = GlobalKey<FormState>();
  final VocabularyService _vocabularyService = VocabularyService();
  final DictionaryService _dictionaryService = DictionaryService();
  final TranslationService _translationService = TranslationService();
  
  late final TextEditingController _wordController;
  late final TextEditingController _meaningController;
  late final TextEditingController _pronunciationController;
  late final TextEditingController _exampleController;
  
  bool _isLoading = false;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _wordController = TextEditingController(text: widget.vocabulary.word);
    _meaningController = TextEditingController(text: widget.vocabulary.meaning);
    _pronunciationController = TextEditingController(text: widget.vocabulary.pronunciation);
    _exampleController = TextEditingController(text: widget.vocabulary.example);
    
    // Listen for changes
    _wordController.addListener(_onTextChanged);
    _meaningController.addListener(_onTextChanged);
    _pronunciationController.addListener(_onTextChanged);
    _exampleController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _wordController.dispose();
    _meaningController.dispose();
    _pronunciationController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _lookupDictionary() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _dictionaryService.getWordDetails(word);
      if (result != null && mounted) {
        setState(() {
          if (_pronunciationController.text.isEmpty && result['pronunciation'] != null) {
            _pronunciationController.text = result['pronunciation'];
          }
          if (_meaningController.text.isEmpty && result['definition'] != null) {
            _meaningController.text = result['definition'];
          }
          if (_exampleController.text.isEmpty && result['rawExample'] != null) {
            _exampleController.text = result['rawExample'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tra cứu từ điển: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _translateText() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final translation = await _translationService.translateText(word);
      if (translation != null && mounted) {
        setState(() {
          if (_meaningController.text.isEmpty) {
            _meaningController.text = translation;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi dịch: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedVocabulary = Vocabulary(
        word: _wordController.text.trim(),
        meaning: _meaningController.text.trim(),
        pronunciation: _pronunciationController.text.trim(),
        example: _exampleController.text.trim(),
        memoryTip: '', // Set empty string since we removed memory tip
        createdAt: widget.vocabulary.createdAt, // Keep original creation time
        apiDefinitions: widget.vocabulary.apiDefinitions, // Keep original API data
      );

      await _vocabularyService.updateVocabularyInDate(
        widget.date,
        widget.index,
        updatedVocabulary,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật từ vựng thành công'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onUpdated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteVocabulary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa từ "${widget.vocabulary.word}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _vocabularyService.deleteVocabularyInDate(widget.date, widget.index);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa từ vựng thành công'),
            backgroundColor: Colors.green,
          ),
        );
        
        widget.onUpdated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thay đổi chưa được lưu'),
        content: const Text('Bạn có muốn lưu thay đổi trước khi thoát?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Thoát không lưu'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lưu trước'),
          ),
        ],
      ),
    );

    if (shouldPop == true) {
      await _saveChanges();
      return false; // Don't pop, let save handle it
    }

    return shouldPop == false;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = true,
    int maxLines = 1,
    List<Widget>? suffixActions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00BCD4), width: 2),
            ),
            suffixIcon: suffixActions != null 
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: suffixActions,
                  )
                : null,
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập $label';
                  }
                  return null;
                }
              : null,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 700, maxWidth: 500),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Chỉnh sửa từ vựng',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_hasUnsavedChanges)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Chưa lưu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _wordController,
                          label: 'Từ vựng',
                          hint: 'Nhập từ tiếng Anh',
                          suffixActions: [
                            IconButton(
                              onPressed: _isLoading ? null : _lookupDictionary,
                              icon: const Icon(Icons.search),
                              tooltip: 'Tra từ điển',
                            ),
                            IconButton(
                              onPressed: _isLoading ? null : _translateText,
                              icon: const Icon(Icons.translate),
                              tooltip: 'Dịch tự động',
                            ),
                          ],
                        ),
                        
                        _buildTextField(
                          controller: _meaningController,
                          label: 'Nghĩa tiếng Việt',
                          hint: 'Nhập nghĩa tiếng Việt',
                        ),
                        
                        _buildTextField(
                          controller: _pronunciationController,
                          label: 'Phiên âm',
                          hint: 'Nhập phiên âm (tùy chọn)',
                          required: false,
                        ),
                        
                        _buildTextField(
                          controller: _exampleController,
                          label: 'Ví dụ',
                          hint: 'Nhập câu ví dụ (tùy chọn)',
                          required: false,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _deleteVocabulary,
                          icon: const Icon(Icons.delete),
                          label: const Text('Xóa'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _saveChanges,
                          icon: const Icon(Icons.save),
                          label: const Text('Lưu thay đổi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BCD4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
