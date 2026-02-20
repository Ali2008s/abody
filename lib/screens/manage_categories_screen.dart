import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';
import 'manage_channels_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManageCategoriesScreen extends StatefulWidget {
  final bool selectingForChannels;
  const ManageCategoriesScreen({super.key, this.selectingForChannels = false});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  void _showCategoryDialog(BuildContext context, {CategoryModel? category}) {
    final nameController = TextEditingController(text: category?.name);
    final imageController = TextEditingController(text: category?.imageUrl);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(category == null ? 'إضافة قسم' : 'تعديل قسم'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم القسم'),
                ),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: 'رابط الصورة'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.isEmpty) return;
                      setState(() => isLoading = true);
                      try {
                        if (category == null) {
                          await FirebaseService().addCategory(
                            nameController.text,
                            imageController.text,
                          );
                        } else {
                          await FirebaseService().updateCategory(
                            category.id,
                            nameController.text,
                            imageController.text,
                          );
                        }
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                        }
                      } finally {
                        if (context.mounted) setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'بحث عن قسم...',
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : Text(
                widget.selectingForChannels
                    ? 'اختر قسم لإدارة قنواته'
                    : 'إدارة الأقسام',
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      floatingActionButton: widget.selectingForChannels
          ? null
          : FloatingActionButton(
              onPressed: () => _showCategoryDialog(context),
              backgroundColor: AppTheme.primaryGold,
              child: const Icon(Icons.add, color: Colors.black),
            ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: FirebaseService().getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد أقسام حالياً'));
          }

          var categories = snapshot.data!;
          if (_searchQuery.isNotEmpty) {
            categories = categories
                .where(
                  (cat) => cat.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList();
          }

          if (categories.isEmpty && _searchQuery.isNotEmpty) {
            return const Center(child: Text('لا توجد نتائج للبحث'));
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 80, top: 10),
            itemCount: categories.length,
            // Disable reorder when searching because filtered indices don't match source list
            onReorder: _isSearching
                ? (oldIndex, newIndex) {}
                : (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = categories.removeAt(oldIndex);
                    categories.insert(newIndex, item);
                    FirebaseService().reorderCategories(categories);
                  },
            itemBuilder: (context, index) {
              final cat = categories[index];
              return Card(
                key: ValueKey(cat.id),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: AppTheme.cardBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  title: Text(
                    cat.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: cat.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.white10),
                      errorWidget: (context, url, error) =>
                          Image.asset('assets/logo.png', fit: BoxFit.cover),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!widget.selectingForChannels) ...[
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 20,
                          ),
                          onPressed: () =>
                              _showCategoryDialog(context, category: cat),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('حذف القسم'),
                                content: const Text(
                                  'هل أنت متأكد من حذف هذا القسم؟ سيتم حذف جميع القنوات بداخلة أيضاً.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('إلغاء'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('حذف'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              FirebaseService().deleteCategory(cat.id);
                            }
                          },
                        ),
                      ],
                      if (!_isSearching)
                        const Icon(Icons.drag_handle, color: Colors.grey),
                    ],
                  ),
                  onTap: widget.selectingForChannels
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ManageChannelsScreen(category: cat),
                          ),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
