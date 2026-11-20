import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:invoiso/common/app_config.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/common/setting_key.dart';
import 'package:invoiso/database/company_registry_service.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/company_profile.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/providers/locale_provider.dart';
import 'package:invoiso/providers/purchase_bills_settings_provider.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/providers/theme_provider.dart';
import 'package:invoiso/screens/auth/forgot_password_screen.dart';
import 'package:invoiso/screens/auth/change_password_screen.dart';
import 'package:invoiso/screens/help/help_search_screen.dart';
import 'package:invoiso/screens/settings/company_management_screen.dart';
import 'package:invoiso/screens/test_gate_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:invoiso/providers/app_config_provider.dart';
import 'package:invoiso/utils/post_auth_navigation.dart';
import 'package:invoiso/utils/window_title.dart';
import 'package:invoiso/widgets/company_avatar.dart';

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
  List<CompanyProfile> _companies = [];
  String? _activeCompanyId;
  bool _rememberUsername = true;
  bool _capsLock = false;

  static const _brandNavy = Color(0xFF081634);
  static const _accent = Color(0xFF2563EB);
  // Device-level (shared_prefs, like the company registry) — the username
  // is kept per company since each company has its own users table.
  static const _rememberPrefsKey = 'login_remember_username';
  String get _usernamePrefsKey => loginUsernamePrefsKey(_activeCompanyId ?? '');

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _capsLock = _isCapsLockOn();
    _loadCompanies();
    _checkFirstTimeUser();
  }

  bool _isCapsLockOn() => HardwareKeyboard.instance.lockModesEnabled
      .contains(KeyboardLockMode.capsLock);

  bool _onKey(KeyEvent event) {
    final on = _isCapsLockOn();
    if (on != _capsLock && mounted) setState(() => _capsLock = on);
    return false;
  }

  Future<void> _loadCompanies() async {
    final companies = await BackendServices.companyRegistry.listCompanies();
    final activeId = await BackendServices.companyRegistry.getActiveCompanyId();
    if (!mounted) return;
    setState(() {
      _companies = companies;
      _activeCompanyId = activeId;
    });
    await _loadRememberedUsername();
  }

  Future<void> _loadRememberedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_rememberPrefsKey) ?? true;
    final saved = remember ? prefs.getString(_usernamePrefsKey) : null;
    if (!mounted) return;
    setState(() => _rememberUsername = remember);
    // The admin/admin first-run hint wins — it already filled both fields.
    if (saved != null && !_showDefaultCredsHint) {
      _usernameController.text = saved;
    }
  }

  Future<void> _saveRememberedUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberPrefsKey, _rememberUsername);
    if (_rememberUsername) {
      await prefs.setString(_usernamePrefsKey, username);
    } else {
      await prefs.remove(_usernamePrefsKey);
    }
  }

  /// Nothing has read per-company data yet at the Login screen (see
  /// `CompanyManagementScreen`'s doc comment for the full reasoning), so
  /// switching here is instant — repoint the DB, re-sync the two providers
  /// loaded before this screen even rendered, and start the credential
  /// fields fresh for whichever company is now selected.
  Future<void> _onCompanySelected(String? id) async {
    if (id == null || id == _activeCompanyId) return;
    await BackendServices.companyRegistry.switchToCompany(id);
    final themeKey = await ref.read(settingsRepositoryProvider).getThemeMode();
    final localeKey = await ref.read(settingsRepositoryProvider).getAppLocale();
    final purchaseBills = await ref
        .read(settingsRepositoryProvider)
        .getSetting(SettingKey.enablePurchaseBillsAndSuppliers);
    await refreshWindowTitle();
    if (!mounted) return;
    ref.read(themeModeProvider.notifier).state = themeModeFromKey(themeKey);
    applyAppLocale(ref, localeFromKey(localeKey));
    ref.read(enablePurchaseBillsAndSuppliersProvider.notifier).state =
        purchaseBills == 'true';
    _usernameController.clear();
    _passwordController.clear();
    setState(() {
      _activeCompanyId = id;
      _showDefaultCredsHint = false;
    });
    await _checkFirstTimeUser();
    await _loadRememberedUsername();
  }

  Future<void> _openCompanyManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CompanyManagementScreen()),
    );
    if (!mounted) return;
    _usernameController.clear();
    _passwordController.clear();
    setState(() => _showDefaultCredsHint = false);
    await _loadCompanies();
    await _checkFirstTimeUser();
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
    HardwareKeyboard.instance.removeHandler(_onKey);
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

    final User? user;
    try {
      user = await ref.read(authRepositoryProvider).getUser(username, password);
    } catch (e) {
      // e.g. cloud: signed in fine but not assigned to any company.
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
      return;
    }

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

    await _saveRememberedUsername(username);
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
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Phone/tablet portrait: form only. Desktop/landscape: split layout.
          final wide = constraints.maxWidth >= 900;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide) Expanded(flex: 11, child: _buildBrandPanel(cfg)),
              Expanded(flex: 9, child: _buildFormPanel(cfg, wide)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBrandPanel(AppEditionConfig cfg) {
    final headline = cfg.isCloud
        ? 'Your billing, on every device.'
        : 'Billing that lives on your computer.';
    final body = cfg.isCloud
        ? 'Invoices, purchases, stock and GST reports — synced across every device your team signs in from.'
        : 'Invoices, purchases, stock and GST reports — all stored on this device and available without an internet connection.';
    final bullets = cfg.isCloud
        ? const [
            (Icons.devices_outlined, 'Sign in from any device'),
            (Icons.description_outlined, 'GST invoices, returns and reports'),
            (Icons.group_outlined, 'Team members with their own logins'),
          ]
        : const [
            (Icons.wifi_off_outlined, 'Works fully offline'),
            (Icons.description_outlined, 'GST invoices, returns and reports'),
            (Icons.lock_outline, 'Your data never leaves this device'),
          ];
    return Container(
      color: _brandNavy,
      child: CustomPaint(
        painter: _GridPainter(),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset('assets/images/logo_dark.png', height: 100),
                      const SizedBox(height: 32),
                      const Spacer(),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              headline,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                  letterSpacing: -0.8),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              body,
                              style: const TextStyle(
                                  color: Color(0xFFB4C3E0),
                                  fontSize: 16,
                                  height: 1.6),
                            ),
                            const SizedBox(height: 28),
                            for (final (icon, label) in bullets)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: const Color(0x1F38BDF8),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(icon,
                                          size: 18,
                                          color: const Color(0xFF7DD3FC)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                            color: Color(0xFFDCE5F7),
                                            fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Decorative only — dropped on short windows.
                            if (constraints.maxHeight >= 820) ...[
                              const SizedBox(height: 16),
                              const _InvoicePreview(),
                            ],
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (!cfg.isCloud) ...[
                        const SizedBox(height: 32),
                        _buildCloudCard(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openCloudInfo() => launchUrl(
        Uri.parse('https://invoiso.co.in/customization.html'),
        mode: LaunchMode.externalApplication,
      );

  Widget _buildCloudCard() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _openCloudInfo,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0x0AFFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x14FFFFFF)),
          ),
          child: const Row(
            children: [
              Icon(Icons.cloud_outlined, color: Color(0xFF93B4F5), size: 22),
              SizedBox(width: 14),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Need multi-device access? ',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                          text: 'Invoiso Cloud Edition syncs across devices.'),
                    ],
                  ),
                  style: TextStyle(
                      color: Color(0xFFDCE5F7), fontSize: 14, height: 1.45),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Learn more →',
                style: TextStyle(
                    color: Color(0xFF7EA6FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormPanel(AppEditionConfig cfg, bool wide) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final muted = scheme.onSurfaceVariant;
    return SafeArea(
      child: Column(
        children: [
          if (!cfg.isCloud)
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 24, 0),
                child: OutlinedButton.icon(
                  onPressed: _openCompanyManagement,
                  icon: const Icon(Icons.domain_outlined, size: 18),
                  label: Text(
                      AppLocalizations.of(context)!.loginCompanyGearTooltip),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: muted,
                    minimumSize: const Size(0, 44),
                    side: BorderSide(color: scheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!wide) ...[
                        Image.asset(
                          // TODO: swap to a real dark-mode asset once available.
                          isDark
                              ? 'assets/images/logo_dark.png'
                              : 'assets/images/logo.png',
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        'Welcome back',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                            color: scheme.onSurface),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue to your workspace.',
                        style: TextStyle(fontSize: 15, color: muted),
                      ),
                      const SizedBox(height: 28),
                      if (!cfg.isCloud && _showDefaultCredsHint) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 18, color: muted),
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
                                  style: TextStyle(fontSize: 13, color: muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_companies.length > 1) ...[
                        _fieldLabel(AppLocalizations.of(context)!
                            .loginCompanySelectorLabel),
                        DropdownButtonFormField<String>(
                          value: _activeCompanyId,
                          isExpanded: true,
                          decoration: _inputDecoration(),
                          items: [
                            for (final company in _companies)
                              DropdownMenuItem(
                                value: company.id,
                                child: Row(
                                  children: [
                                    CompanyAvatar(
                                        id: company.id,
                                        name: company.name,
                                        size: 32),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        company.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                          onChanged: _onCompanySelected,
                        ),
                        const SizedBox(height: 20),
                      ],
                      _fieldLabel(cfg.isCloud ? 'Email' : 'Username'),
                      TextField(
                        controller: _usernameController,
                        decoration: _inputDecoration(
                          icon: Icons.person_outline,
                          hint: cfg.isCloud
                              ? 'Enter your email'
                              : 'Enter your username',
                        ),
                        keyboardType: cfg.isCloud
                            ? TextInputType.emailAddress
                            : TextInputType.text,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 20),
                      _fieldLabel('Password'),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _login(cfg),
                        decoration: _inputDecoration(
                          icon: Icons.lock_outline,
                          hint: 'Enter your password',
                          suffix: IconButton(
                            tooltip: _obscurePassword
                                ? 'Show password'
                                : 'Hide password',
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      if (_capsLock)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Caps Lock is on',
                            style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.orange.shade300
                                    : Colors.orange.shade800),
                          ),
                        ),
                      const SizedBox(height: 12),
                      // Wrap, not Row: drops "Forgot password?" to its own
                      // line instead of overflowing on narrow phones.
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(
                                () => _rememberUsername = !_rememberUsername),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value: _rememberUsername,
                                      activeColor: _accent,
                                      onChanged: (v) => setState(
                                          () => _rememberUsername = v ?? true),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text('Remember username',
                                      style: TextStyle(
                                          fontSize: 14, color: muted)),
                                ],
                              ),
                            ),
                          ),
                          if (!cfg.isCloud)
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgotPasswordScreen()),
                              ),
                              child: const Text('Forgot password?'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: _isLoading ? null : () => _login(cfg),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            disabledBackgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            textStyle: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
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
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Sign in'),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
                      ),
                      if (wide) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Press Enter to sign in',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: muted),
                        ),
                      ],
                      if (!wide && !cfg.isCloud) ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: _openCloudInfo,
                          icon: const Icon(Icons.cloud_outlined, size: 18),
                          label: const Text(
                              'Need multi-device access? Try Invoiso Cloud →'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 18,
              runSpacing: 8,
              children: [
                Text(AppConfig.version,
                    style: TextStyle(fontSize: 12, color: muted)),
                _footerLink(
                  Uri.parse(AppConfig.website).host,
                  () => launchUrl(Uri.parse(AppConfig.website),
                      mode: LaunchMode.externalApplication),
                ),
                _footerLink('Contact support',
                    () => showHelpSearchDialog(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );

  InputDecoration _inputDecoration(
      {IconData? icon, String? hint, Widget? suffix}) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: scheme.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(scheme.outlineVariant),
      enabledBorder: border(scheme.outlineVariant),
      focusedBorder: border(_accent, 1.6),
    );
  }

  Widget _footerLink(String text, VoidCallback onTap) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            text,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                decoration: TextDecoration.underline),
          ),
        ),
      );
}

/// Faint 40px grid behind the login brand panel.
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0BFFFFFF)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Decorative skeleton invoice on the login brand panel — no real data.
class _InvoicePreview extends StatelessWidget {
  const _InvoicePreview();

  Widget _bar(double width, double height, Color color) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(4)),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 380,
      height: 150,
      child: Stack(
        children: [
          Positioned(
            left: 36,
            top: 0,
            child: Transform.rotate(
              angle: -0.05,
              child: Container(
                width: 340,
                height: 132,
                decoration: BoxDecoration(
                  color: const Color(0x0DFFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x14FFFFFF)),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 14,
            child: Container(
              width: 360,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2350),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x3893B4F5)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x59000000),
                      blurRadius: 48,
                      offset: Offset(0, 24)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Tax invoice',
                          style: TextStyle(
                              color: Color(0xFFDCE5F7),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6EE7A8),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Text('Paid',
                            style: TextStyle(
                                color: Color(0xFF052E1A),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _bar(224, 8, const Color(0x24FFFFFF)),
                  const SizedBox(height: 12),
                  _bar(166, 8, const Color(0x1AFFFFFF)),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0x24FFFFFF)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _bar(96, 8, const Color(0x1AFFFFFF)),
                      const Spacer(),
                      _bar(84, 12, const Color(0xFF4C82FF)),
                    ],
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
