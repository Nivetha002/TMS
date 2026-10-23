import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'login/login_screen.dart';
import 'dashboard/dashboard_screen.dart';

/// Decides which screen to show, based on AuthProvider state.
/// No Navigator needed: when the state changes, this widget rebuilds.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // 1. Still checking the saved session -> Splash
    if (auth.isRestoring) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // 2. Logged in -> Home
    if (auth.user != null) {
      return const DashboardScreen();
    }

    // 3. Not logged in -> Login
    return const LoginScreen();
  }
}