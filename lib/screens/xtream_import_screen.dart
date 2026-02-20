import 'package:flutter/material.dart';
import '../models/xtream_config.dart';
import '../models/category_model.dart';
import '../services/xtream_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class XtreamImportScreen extends StatefulWidget {
  final XtreamConfig config;

  const XtreamImportScreen({super.key, required this.config});

  @override
  State<XtreamImportScreen> createState() => _XtreamImportScreenState();
}

class _XtreamImportScreenState extends State<XtreamImportScreen> {
  final XtreamService _xtreamService = XtreamService();
  final FirebaseService _firebaseService = FirebaseService();

  List<CategoryModel> _categories = [];
  Set<String> _selectedCategoryIds = {};
  bool _isLoading = true;
  String? _error;

  // Stats for the import process
  int _importingIndex = 0;
  int _totalToImport = 0;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final categories = await _xtreamService.getCategories(widget.config);
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'حدث خطأ أثناء جلب الأقسام: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedCategoryIds = _categories.map((c) => c.id).toSet();
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedCategoryIds.clear();
    });
  }

  Future<void> _startImport() async {
    if (_selectedCategoryIds.isEmpty) return;

    setState(() {
      _isImporting = true;
      _importingIndex = 0;
      _totalToImport = _selectedCategoryIds.length;
    });

    try {
      final selectedCategories = _categories
          .where((c) => _selectedCategoryIds.contains(c.id))
          .toList();

      for (var cat in selectedCategories) {
        if (!mounted) break;

        setState(() => _importingIndex++);

        // 1. Add Category to Firebase
        await _firebaseService.addOrUpdateCategory(cat);

        // 2. Fetch Channels for this category
        final channels = await _xtreamService.getChannels(
          widget.config,
          cat.id.replaceFirst('xtream_', ''),
        );

        // 3. Add Channels in batch
        if (channels.isNotEmpty) {
          await _firebaseService.addChannelsBatch(channels);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم استيراد المحتوى بنجاح')),
        );
        Navigator.pop(context); // Go back after success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الاستيراد: $e')));
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('استيراد من Xtream'),
        actions: [
          if (!_isLoading && _categories.isNotEmpty) ...[
            TextButton(
              onPressed: _selectAll,
              child: const Text(
                'تحديد الكل',
                style: TextStyle(color: AppTheme.primaryGold),
              ),
            ),
            TextButton(
              onPressed: _deselectAll,
              child: const Text(
                'إلغاء الكل',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGold,
                        ),
                      )
                    : _categories.isEmpty
                    ? const Center(child: Text('لا توجد أقسام متوفرة'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategoryIds.contains(
                            cat.id,
                          );
                          return InkWell(
                            onTap: () => _toggleSelection(cat.id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryGold
                                      : Colors.white10,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: cat.imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              cat.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.category,
                                                    color: AppTheme.primaryGold,
                                                  ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.category,
                                            color: AppTheme.primaryGold,
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Checkbox(
                                    value: isSelected,
                                    activeColor: AppTheme.primaryGold,
                                    checkColor: Colors.black,
                                    onChanged: (_) => _toggleSelection(cat.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              if (!_isLoading && _categories.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _selectedCategoryIds.isEmpty
                          ? null
                          : _startImport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'استيراد المحدد (${_selectedCategoryIds.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (_isImporting)
            Container(
              color: Colors.black87,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppTheme.primaryGold,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'جاري استيراد الأقسام والقنوات...\n($_importingIndex / $_totalToImport)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'يرجى عدم إغلاق هذه الصفحة حتى انتهاء العملية',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
