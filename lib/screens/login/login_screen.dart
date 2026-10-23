import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/primary_button.dart';
import '../dashboard/dashboard_screen.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLoginPressed() async {
    // 1. Check the fields
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus(); // close keyboard

     await context.read<AuthProvider>().login(
          username: _usernameController.text,
          password: _passwordController.text,
        );


    // 2. Ask the provider to log in
    final success = await context.read<AuthProvider>().login(
          username: _usernameController.text,
          password: _passwordController.text,
        );

    // 3. If the screen was closed while waiting, stop
    if (!mounted) return;

    // 4. Success -> go to Home (replace, so Back does not return to login)
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
    // Failure: nothing to do here. The provider already set errorMessage,
    // and the banner shows automatically.
  }

  @override
  Widget build(BuildContext context) {
    // watch = rebuild this screen whenever the provider calls notifyListeners()
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildCard(auth),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            if (auth.errorMessage != null) ...[
              ErrorBanner(message: auth.errorMessage!),
              const SizedBox(height: 16),
            ],
            AppTextField(
              controller: _usernameController,
              label: 'Username',
              hint: 'Enter your username',
              prefixIcon: Icons.person_outline,
              enabled: !auth.isLoading,
              validator: Validators.username,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Enter your password',
              prefixIcon: Icons.lock_outline,
              isPassword: true,
              enabled: !auth.isLoading,
              textInputAction: TextInputAction.done,
              validator: Validators.password,
              onSubmitted: (_) => _onLoginPressed(),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Sign In',
              isLoading: auth.isLoading,
              onPressed: _onLoginPressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo placeholder. Later: Image.asset('assets/images/JKFenner.jpeg')
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.precision_manufacturing_outlined,
            size: 38,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tool Monitoring',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Sign in to continue',
          style: TextStyle(fontSize: 14, color: AppColors.textLight),
        ),
      ],
    );
  }
}