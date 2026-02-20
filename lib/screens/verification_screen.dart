import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'main_screen.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال اسم المستخدم وكلمة المرور')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firebaseService = FirebaseService();
      await firebaseService.loginOrRegister(username, password);

      if (!mounted) return;

      // Update app provider state
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      await appProvider.setVerified(true);

      // Check if admin
      final isAdmin = await firebaseService.isAdmin();
      await appProvider.setAdmin(isAdmin);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ في تسجيل الدخول';
      if (e.code == 'user-not-found') {
        message = 'المستخدم غير موجود';
      } else if (e.code == 'wrong-password') {
        message = 'كلمة المرور غير صحيحة';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صحيح';
      } else if (e.code == 'user-disabled') {
        message = 'هذا الحساب معطل';
      } else if (e.code == 'invalid-credential') {
        message = 'بيانات الاعتماد غير صحيحة';
      } else if (e.code == 'email-already-in-use') {
        message = 'البريد الإلكتروني مستخدم بالفعل';
      } else {
        message = e.message ?? message;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, textAlign: TextAlign.right),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}', textAlign: TextAlign.right),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGuest() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.setVerified(true);
    await appProvider.setAdmin(false);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryGold),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.png', height: 120),
              const SizedBox(height: 30),
              const Text(
                'تسجيل الدخول',
                style: TextStyle(
                  color: AppTheme.primaryGold,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'أدخل معلومات حسابك للاستمرار',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 40),
              // Username
              TextField(
                controller: _usernameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Colors.white),
                decoration: AppTheme.inputDecoration(
                  hint: 'اسم المستخدم',
                  icon: Icons.person_outline,
                ),
              ),
              const SizedBox(height: 20),
              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleLogin(),
                style: const TextStyle(color: Colors.white),
                decoration:
                    AppTheme.inputDecoration(
                      hint: 'كلمة المرور',
                      icon: Icons.lock_outline,
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
              ),
              const SizedBox(height: 40),
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          'دخول / إنشاء حساب',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Guest Button
              TextButton(
                onPressed: _handleGuest,
                child: const Text(
                  'الدخول كضيف',
                  style: TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
