import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

import 'xtream_channels_screen.dart';
import 'webview_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'update_required_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Wait for provider to initialize (loading SharedPreferences)
    final provider = context.read<AppProvider>();

    // Check every 100ms if provider is initialized
    while (!provider.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 2. Pre-load data from Firebase
    try {
      final firebaseService = FirebaseService();

      // --- VERSION CHECK ---
      final versionData = await firebaseService.checkAppVersion();
      final blockedVersions = List<String>.from(
        versionData['blocked_versions'] ?? [],
      );
      final allowedVersions = List<String>.from(
        versionData['allowed_versions'] ?? [],
      );
      final storeUrl = versionData['store_url'] as String?;
      final message =
          versionData['force_update_message'] as String? ??
          'هذه النسخة لم تعد مدعومة. يرجى تحديث التطبيق.';

      // Get current version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;
      // String buildNumber = packageInfo.buildNumber;

      bool isBlocked = false;

      // 1. Check Blocked List
      if (blockedVersions.contains(currentVersion)) {
        isBlocked = true;
      }

      // 2. Check Allowed List (if configured, strict mode)
      if (allowedVersions.isNotEmpty &&
          !allowedVersions.contains(currentVersion)) {
        isBlocked = true;
      }

      if (isBlocked) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  UpdateRequiredScreen(message: message, storeUrl: storeUrl),
            ),
          );
        }
        return; // Stop initialization
      }
      // ---------------------

      // Update presence and stats
      // Only update presence if verified/logged in might be better, but let's leave it compatible
      // or check inside the service. For now, we run it.
      if (provider.isVerified) {
        firebaseService.updatePresence();
      }
      firebaseService.incrementTotalDownloads();

      // Fetch categories to warm up cache
      final categories = await firebaseService.getCategories().first;

      // Pre-cache Category Images safely
      if (mounted) {
        for (var category in categories) {
          if (category.imageUrl.isNotEmpty &&
              category.imageUrl.startsWith('http')) {
            try {
              precacheImage(
                NetworkImage(category.imageUrl),
                context,
              ).catchError((e) {
                debugPrint('Failed to precache image: ${category.imageUrl}');
              });
            } catch (e) {
              // Ignore precache errors to avoid hanging
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Preloading data failed: $e');
    }

    // 3. Ensure splash screen stays for at least 2.5 seconds for branding
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      // Navigate to the appropriate screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryGold.withOpacity(0.1),
                    AppTheme.darkBg,
                  ],
                  center: Alignment.center,
                  radius: 1.0,
                ),
              ),
            ),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryGold,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                        image: const DecorationImage(
                          image: AssetImage('assets/logo.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'العبودي TV',
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGold,
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Branding
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    'By Arix',
                    style: TextStyle(
                      color: AppTheme.primaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
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
