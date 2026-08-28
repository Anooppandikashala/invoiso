import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:invoiso/common/app_config.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/screens/auth/forgot_password_screen.dart';
import 'package:invoiso/screens/auth/change_password_screen.dart';
import 'package:invoiso/screens/test_gate_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/utils/post_auth_navigation.dart';

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
  bool _showDefaultCredsHint = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTimeUser();
  }

  // Show the hint only while admin/admin actually still works as a login.
  // Cloud edition has no seeded default account — skip the check entirely.
  Future<void> _checkFirstTimeUser() async {
    if (ref.read(appEditionConfigProvider).isCloud) return;
    final user =
        await ref.read(authRepositoryProvider).getUser('admin', 'admin');
    if (!mounted || user == null) return;
    _usernameController.text = 'admin';
    _passwordController.text = 'admin';
    setState(() => _showDefaultCredsHint = true);
  }

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

    _afterLoginNavigate(cfg, user);
  }

  Future<void> _afterLoginNavigate(AppEditionConfig cfg, User user) async {
    if (TestBuildConfig.isTestBuild && !await _testGatePasses(cfg, user)) return;

    if(cfg.isCloud)
    {
      if (!mounted) return;
      await navigateAfterAuth(context, ref, user);
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
      await navigateAfterAuth(context, ref, user);
    }

  }

  // Uses the existing analytics heartbeat endpoint's response Date header as a
  // trusted clock — local device time is spoofable and would defeat this gate.
  Future<bool> _testGatePasses(AppEditionConfig cfg, User user) async {
    DateTime serverTime;
    try {
      final resp = await http
          .head(Uri.parse(AnalyticsConfig.heartbeatUrl))
          .timeout(const Duration(seconds: 5));
      final dateHeader = resp.headers['date'];
      if (dateHeader == null) throw const HttpException('missing Date header');
      serverTime = HttpDate.parse(dateHeader);
    } catch (_) {
      if (!mounted) return false;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TestGateScreen(
            reason: TestGateReason.noInternet,
            onRetry: () => _afterLoginNavigate(cfg, user),
          ),
        ),
      );
      return false;
    }

    final expiry = DateTime.fromMillisecondsSinceEpoch(TestBuildConfig.buildEpochSeconds * 1000)
        .add(const Duration(days: TestBuildConfig.testExpiryDays));
    if (serverTime.isAfter(expiry)) {
      if (!mounted) return false;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TestGateScreen(reason: TestGateReason.expired)),
      );
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(appEditionConfigProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Phone: card fills the width (minus side padding) since there's no
    // room to spare. Tablet/desktop: a fixed comfortable width instead of
    // the old `width * 0.25`, which shrank to an unusably narrow card on
    // tablet portrait widths (e.g. ~190px at 768px wide).
    final isPhone = screenWidth < 600;
    final cardWidth = isPhone ? screenWidth - 48 : 420.0;
    final cardPadding = isPhone ? 20.0 : 32.0;
    final logoWidth = (cardWidth * 0.65).clamp(140.0, 230.0);
    return Scaffold(
      backgroundColor: isDark ? null : Colors.blue[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!cfg.isCloud)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardWidth),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse('https://invoiso.co.in/customization.html'),
                          mode: LaunchMode.externalApplication,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const Icon(Icons.cloud_outlined,
                                  color: Colors.white, size: 24),
                              Wrap(
                                children: [
                                  const Text(
                                    'Need multi-device access? ',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 13),
                                  ),
                                  const Text(
                                    '"Invoiso Cloud Edition"',
                                    style: TextStyle(
                                        color: Colors.yellow, fontSize: 13),
                                  ),
                                  const Text(
                                    ' is available.',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 13),
                                  ),
                                ],
                              ),
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
                  ),
                Card(
                  elevation: 8,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Container(
                    width: cardWidth,
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          // TODO: swap to a real dark-mode asset once available.
                          isDark
                              ? 'assets/images/logo_dark.png'
                              : 'assets/images/logo.png',
                          width: logoWidth,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        AppSpacing.hSmall,
                        if (!cfg.isCloud && _showDefaultCredsHint) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 18,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        const TextSpan(
                                            text:
                                                'First time here? Log in with username '),
                                        TextSpan(
                                            text: 'admin',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade700)),
                                        const TextSpan(text: ' and password '),
                                        TextSpan(
                                            text: 'admin',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade700)),
                                        const TextSpan(
                                            text:
                                                ', then set your own password when prompted.'),
                                      ],
                                    ),
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppSpacing.hLarge,
                        ],
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: cfg.isCloud ? 'Email' : 'Username',
                            prefixIcon: const Icon(Icons.person),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: cfg.isCloud
                              ? TextInputType.emailAddress
                              : TextInputType.text,
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
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
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
                        AppSpacing.hSmall,
                        if (!cfg.isCloud)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen()),
                              ),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        AppSpacing.hLarge,
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => launchUrl(Uri.parse(AppConfig.website),
                                mode: LaunchMode.externalApplication),
                            child: Text(
                              AppConfig.website,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppConfig.version,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        ),
                        const SizedBox(height: 8),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => launchUrl(
                                Uri.parse(AppConfig.supportForm),
                                mode: LaunchMode.externalApplication),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.support_agent_outlined,
                                    size: 14,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    'Need help? Contact Support',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                        decoration: TextDecoration.underline),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
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
