import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/screens/change_password_screen.dart';
import 'package:invoiso/services/analytics/cloudflare_analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/app_config_provider.dart';
import 'dashboard_screen.dart';

// Login Screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login(AppEditionConfig cfg) async {

    // for cloud the username will be email
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    final usernameText = cfg.isCloud ? "Email" : "Username";

    if (username.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter $usernameText and password')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = await ref.read(authRepositoryProvider).getUser(username, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if(user == null)
    {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
      return;
    }

    if(cfg.isCloud)
    {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen(user)),
      );
    }
    else if (!user.passwordChanged && !cfg.isCloud) {
      // Force password change
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChangePasswordScreen(user: user, forced: true),
        ),
      );
    }
    else{
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen(user)),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(appEditionConfigProvider);
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if(!cfg.isCloud)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse('https://invoiso.co.in/customization.html'),
                  mode: LaunchMode.externalApplication,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_outlined, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Text(
                            'Need multi-device access? ',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                          const Text(
                            '"Invoiso Cloud Edition"',
                            style: TextStyle(color: Colors.yellow, fontSize: 13),
                          ),
                          const Text(
                            ' is available.',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Learn more →',
                        style: TextStyle(
                          color: Colors.blue[100],
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Card(
          elevation: 8,
          color: Colors.white,
          child: Container(
            width: MediaQuery.sizeOf(context).width * 0.25,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 230,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                AppSpacing.hXlarge,
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText:  cfg.isCloud ? 'Email' : 'Username',
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: cfg.isCloud ? TextInputType.emailAddress : TextInputType.text,
                ),
                AppSpacing.hMedium,
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onSubmitted: (_) => _login(cfg),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                AppSpacing.hXlarge,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _login(cfg),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Login'),
                  ),
                ),
                AppSpacing.hLarge,
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => launchUrl(Uri.parse(AppConfig.website), mode: LaunchMode.externalApplication),
                    child: Text(
                      AppConfig.website,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConfig.version,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}
