import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRequiredScreen extends StatelessWidget {
  final String message;
  final String? storeUrl;

  const UpdateRequiredScreen({
    super.key,
    this.message = 'هذه النسخة لم تعد مدعومة. يرجى تحديث التطبيق.',
    this.storeUrl,
  });

  Future<void> _launchStore() async {
    if (storeUrl != null && await canLaunchUrl(Uri.parse(storeUrl!))) {
      await launchUrl(
        Uri.parse(storeUrl!),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back button
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.system_security_update,
                  size: 100,
                  color: AppTheme.primaryGold,
                ),
                const SizedBox(height: 32),
                const Text(
                  'تحديث مطلوب',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 48),
                if (storeUrl != null)
                  ElevatedButton(
                    onPressed: _launchStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('تحديث الان'),
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text(
                    'إغلاق التطبيق',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
