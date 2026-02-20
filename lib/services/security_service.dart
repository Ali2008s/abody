import 'dart:async';
import 'package:flutter/material.dart';
import 'package:check_vpn_connection/check_vpn_connection.dart';

import '../main.dart';
import '../screens/security_block_screen.dart';

class SecurityService with WidgetsBindingObserver {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  bool _isBlocked = false;
  Timer? _vpnCheckTimer;

  Future<void> initialize() async {
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Start VPN Monitoring
    await _startVpnMonitoring();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check VPN when app comes to foreground
      _checkVpn();
    }
  }

  Future<void> _startVpnMonitoring() async {
    // Check immediately
    await _checkVpn();

    // Check every 5 seconds as a heartbeat
    _vpnCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkVpn();
    });
  }

  Future<void> _checkVpn() async {
    if (_isBlocked) return;

    try {
      if (await CheckVpnConnection.isVpnActive()) {
        _handleThreat("تم اكتشاف VPN", "يرجى تعطيل VPN لاستخدام هذا التطبيق.");
      }
    } catch (e) {
      debugPrint("VPN check failed: $e");
    }
  }

  void _handleThreat(String title, String message) {
    if (_isBlocked) return;
    _isBlocked = true;

    // Use the navigator key to push the block screen
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SecurityBlockScreen(title: title, message: message),
      ),
      (route) => false,
    );
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _vpnCheckTimer?.cancel();
  }
}
