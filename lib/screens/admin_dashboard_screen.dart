import 'dart:async';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/xtream_config.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'manage_categories_screen.dart';
import 'xtream_import_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  int _activeUsers = 0;
  int _totalDownloads = 0;
  int _categoryCount = 0;
  int _channelCount = 0;
  int _codeEntries = 0;
  bool _isStatsLoading = true;
  StreamSubscription? _activeUsersSubscription;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Listen to active users
    _activeUsersSubscription = _firebaseService.getActiveUsersCount().listen((
      count,
    ) {
      if (mounted) setState(() => _activeUsers = count);
    });
  }

  @override
  void dispose() {
    _activeUsersSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadStats() async {
    setState(() => _isStatsLoading = true);
    try {
      final results = await Future.wait([
        _firebaseService.getTotalDownloads(),
        _firebaseService.getCategoriesCount(),
        _firebaseService.getChannelsCount(),
        _firebaseService.getCodeEntriesCount(),
      ]).timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() {
          _totalDownloads = results[0];
          _categoryCount = results[1];
          _channelCount = results[2];
          _codeEntries = results[3];
          _isStatsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isStatsLoading = false);
    }
  }

  void _showDeleteXtreamDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف بيانات Xtream'),
        content: const Text(
          'هل أنت متأكد من حذف جميع قنوات وأقسام Xtream فقط؟\nلن يتم حذف الأقسام والقنوات اليدوية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isStatsLoading = true);
              await _firebaseService.deleteXtreamData();
              await _loadStats();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف بيانات Xtream بنجاح')),
                );
              }
            },
            child: const Text(
              'حذف الآن',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
      ),
      body: _isStatsLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            )
          : RefreshIndicator(
              onRefresh: _loadStats,
              color: AppTheme.primaryGold,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats Grid
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                    children: [
                      _StatItem(
                        title: 'المستخدمين النشطين',
                        value: _activeUsers,
                      ),
                      _StatItem(
                        title: 'إجمالي التنزيلات',
                        value: _totalDownloads,
                      ),
                      _StatItem(title: 'عدد الأقسام', value: _categoryCount),
                      _StatItem(title: 'عدد القنوات', value: _channelCount),
                      _StatItem(title: 'مستخدمي التطبيق', value: _codeEntries),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'الإدارة العامة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AdminButton(
                    title: 'إدارة الأقسام',
                    icon: Icons.category,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageCategoriesScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AdminButton(
                    title: 'إدارة القنوات',
                    icon: Icons.tv,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageCategoriesScreen(
                          selectingForChannels: true,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AdminButton(
                    title: 'إدارة حسابات Xtream',
                    icon: Icons.account_box,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageXtreamScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AdminButton(
                    title: 'حذف بيانات Xtream فقط',
                    icon: Icons.delete_sweep,
                    color: Colors.redAccent,
                    onTap: () => _showDeleteXtreamDialog(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

class ManageXtreamScreen extends StatefulWidget {
  const ManageXtreamScreen({super.key});

  @override
  State<ManageXtreamScreen> createState() => _ManageXtreamScreenState();
}

class _ManageXtreamScreenState extends State<ManageXtreamScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  void _showAddDialog({Map<String, dynamic>? config, String? id}) {
    final serverController = TextEditingController(text: config?['serverUrl']);
    final userController = TextEditingController(text: config?['username']);
    final passController = TextEditingController(text: config?['password']);
    final imageController = TextEditingController(text: config?['imageUrl']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? 'إضافة حساب Xtream' : 'تعديل حساب'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: serverController,
                decoration: const InputDecoration(labelText: 'سيرفر (URL)'),
              ),
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: 'اسم المستخدم'),
              ),
              TextField(
                controller: passController,
                decoration: const InputDecoration(labelText: 'كلمة المرور'),
              ),
              TextField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: 'رابط الشعار / الصورة (اختياري)',
                ),
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
            onPressed: () async {
              final newConfig = {
                'serverUrl': serverController.text,
                'username': userController.text,
                'password': passController.text,
                'imageUrl': imageController.text,
              };
              if (id == null) {
                await _firebaseService.addXtreamAccount(newConfig);
              } else {
                await _firebaseService.updateXtreamAccount(id, newConfig);
              }
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _syncAccount(Map<String, dynamic> config) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            XtreamImportScreen(config: XtreamConfig.fromMap(config)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابات Xtream IPTV')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: AppTheme.primaryGold,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: _firebaseService.getXtreamAccountsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('لا توجد حسابات حالياً'));
              }
              final docs = snapshot.data!.docs;
              return ListView.separated(
                itemCount: docs.length,
                padding: const EdgeInsets.all(12),
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final imageUrl = data['imageUrl'] as String?;

                  return ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: (imageUrl != null && imageUrl.startsWith('http'))
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.tv,
                                      color: AppTheme.primaryGold,
                                    ),
                              ),
                            )
                          : const Icon(Icons.tv, color: AppTheme.primaryGold),
                    ),
                    title: Text(data['serverUrl'] ?? ''),
                    subtitle: Text('User: ${data['username'] ?? ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.sync, color: Colors.green),
                          onPressed: () => _syncAccount(data),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () =>
                              _showAddDialog(config: data, id: doc.id),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _firebaseService.deleteXtreamAccount(doc.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGold),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final int value;
  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryGold, width: 1),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _AdminButton({
    required this.title,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color?.withOpacity(0.3) ?? Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color ?? AppTheme.primaryGold),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: color?.withOpacity(0.5) ?? Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
