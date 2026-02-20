import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import '../services/firebase_service.dart';
import 'xtream_channels_screen.dart';
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    FirebaseService().updatePresence();
  }

  Future<void> _showExitConfirmDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        title: const Text(
          'خروج',
          style: TextStyle(color: AppTheme.primaryGold),
        ),
        content: const Text(
          'هل تريد الخروج من التطبيق؟',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const XtreamChannelsScreen();
      case 2:
        return const WebViewPage(
          key: ValueKey('entertainment'),
          url: 'https://m.filmcity12.com/',
          title: 'ترفيه',
        );
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return Scaffold(
      body: IndexedStack(
        index: appProvider.mainIndex,
        children: [_buildPage(0), _buildPage(1), _buildPage(2)],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: appProvider.mainIndex,
        onTap: (index) {
          if (index == 3) {
            _showExitConfirmDialog();
          } else {
            appProvider.setMainIndex(index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(
            icon: Icon(Icons.live_tv),
            label: 'قنوات IPTV',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'ترفيه'),
          BottomNavigationBarItem(icon: Icon(Icons.exit_to_app), label: 'خروج'),
        ],
      ),
    );
  }
}

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;
  const WebViewPage({super.key, required this.url, required this.title});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) => setState(() => _isLoading = true),
          onPageFinished: (String url) => setState(() => _isLoading = false),
          onWebResourceError: (WebResourceError error) {
            debugPrint('Web resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold),
            ),
        ],
      ),
    );
  }
}
