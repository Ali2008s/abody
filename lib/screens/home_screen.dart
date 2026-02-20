import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../models/category_model.dart';
import '../models/channel_model.dart';
import '../theme/app_theme.dart';
import '../widgets/category_card.dart';
import '../widgets/channel_card.dart';
import 'category_channels_screen.dart';
import 'admin_dashboard_screen.dart';
import 'video_player_screen.dart';
import 'verification_screen.dart';
import 'main_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _launchTelegram() async {
    final Uri url = Uri.parse('https://t.me/stlaet1');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح التليجرام')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<AppProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('العبودي TV'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.primaryGold),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ChannelSearchDelegate(_firebaseService),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppTheme.cardBg,
                border: Border(
                  bottom: BorderSide(color: AppTheme.primaryGold, width: 0.5),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/logo.png', height: 60),
                    const SizedBox(height: 10),
                    const Text(
                      'العبودي TV',
                      style: TextStyle(
                        color: AppTheme.primaryGold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: AppTheme.primaryGold,
              ),
              title: Text(isDark ? 'الوضع الفاتح' : 'الوضع الليلي'),
              onTap: () => themeProvider.toggleTheme(),
            ),
            ListTile(
              leading: const Icon(Icons.telegram, color: Colors.blue),
              title: const Text('قناة التلكرام'),
              onTap: () {
                Navigator.pop(context);
                _launchTelegram();
              },
            ),

            if (themeProvider.isAdmin)
              ListTile(
                leading: const Icon(
                  Icons.admin_panel_settings,
                  color: AppTheme.primaryGold,
                ),
                title: const Text('لوحة التحكم'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminDashboardScreen(),
                    ),
                  );
                },
              ),
            const Spacer(),
            if (themeProvider.isVerified)
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('تسجيل الخروج'),
                onTap: () {
                  themeProvider.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                    (route) => false,
                  );
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.login, color: AppTheme.primaryGold),
                title: const Text('تسجيل الدخول'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VerificationScreen(),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: _firebaseService.getCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد أقسام حالياً'));
          }

          final allCategories = snapshot.data!;
          final categories = allCategories
              .where((c) => !c.id.startsWith('xtream_'))
              .toList();

          if (categories.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد أقسام حالياً',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 3,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return CategoryCard(
                category: category,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryChannelsScreen(
                        key: ValueKey(category.id),
                        category: category,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChannelSearchDelegate extends SearchDelegate {
  final FirebaseService firebaseService;

  ChannelSearchDelegate(this.firebaseService);

  @override
  String get searchFieldLabel => 'بحث عن قناة...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTheme.darkBg,
        iconTheme: IconThemeData(color: AppTheme.primaryGold),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(titleLarge: TextStyle(color: Colors.white)),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear, color: AppTheme.primaryGold),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppTheme.primaryGold),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty)
      return const Center(child: Text('اكتب اسم القناة للبحث'));

    return FutureBuilder<List<ChannelModel>>(
      future: firebaseService.searchChannels(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGold),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('لا توجد قنوات بهذا الاسم'));
        }

        final channels = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 3,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: channels.length,
          itemBuilder: (context, index) {
            final channel = channels[index];
            return ChannelCard(
              channel: channel,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlayerScreen(channel: channel),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
