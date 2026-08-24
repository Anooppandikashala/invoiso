import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/services/backend_services.dart';
import 'package:invoiso/utils/reset_code_verifier.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _responseCodeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _installationId;
  String? _verifiedUserId;
  bool _codeJustVerified = false;
  String? _verifiedUsername;
  bool _isVerifying = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInstallationId();
  }

  Future<void> _loadInstallationId() async {
    final id = await BackendServices.installation.getOrCreateInstallationId();
    if (!mounted) return;
    setState(() => _installationId = id);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _responseCodeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _copyInstallationId() async {
    if (_installationId == null) return;
    await Clipboard.setData(ClipboardData(text: _installationId!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Installation ID copied to clipboard.')),
    );
  }

  Future<void> _verifyCode() async {
    final username = _usernameController.text.trim();
    final responseCode = _responseCodeController.text.trim();

    setState(() => _errorMessage = null);

    if (username.isEmpty || responseCode.isEmpty) {
      setState(() => _errorMessage = 'Please enter username and response code.');
      return;
    }
    if (_installationId == null) {
      setState(() => _errorMessage = 'Please wait, still loading installation info.');
      return;
    }

    setState(() => _isVerifying = true);

    final user = await ref.read(authRepositoryProvider).getUserByUsername(username);
    final valid = await ResetCodeVerifier.verifyResetCode(
      installationId: _installationId!,
      responseCode: responseCode,
    );

    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (user == null || !valid) {
      setState(() => _errorMessage = 'Invalid or expired code.');
      return;
    }

    setState(() => _codeJustVerified = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      _verifiedUserId = user.id;
      _verifiedUsername = user.username;
    });
  }

  Future<void> _submitNewPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() => _errorMessage = null);

    if (newPassword.length < 8) {
      setState(() => _errorMessage = 'New password must be at least 8 characters.');
      return;
    }
    if (newPassword.toLowerCase() == _verifiedUsername?.toLowerCase()) {
      setState(() => _errorMessage = 'Password cannot be the same as your username.');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref.read(authRepositoryProvider).updatePassword(_verifiedUserId!, newPassword);
      await ref.read(authRepositoryProvider).markPasswordChanged(_verifiedUserId!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. Please log in.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Failed to reset password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Same phone/tablet fix as login_screen.dart: fill the width (minus
    // side padding) on phones instead of the old `width * 0.3`, which
    // shrank to an unusably narrow card on tablet/phone widths.
    final isPhone = screenWidth < 600;
    final cardWidth = isPhone ? screenWidth - 48 : 460.0;
    final cardPadding = isPhone ? 20.0 : 32.0;
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? null
          : Colors.blue[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Card(
          elevation: 8,
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Container(
            width: cardWidth,
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.password_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Reset Password',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),

                if (_verifiedUserId == null) ...[
                  const Text(
                    'Share the Installation ID below with support to get a response code.',
                    style: TextStyle(fontSize: 13),
                  ),

                  AppSpacing.hMedium,

                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _installationId ?? 'Loading...',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          tooltip: 'Copy Installation ID',
                          onPressed: _installationId == null ? null : _copyInstallationId,
                        ),
                      ],
                    ),
                  ),

                  AppSpacing.hXlarge,

                  if (_codeJustVerified)
                    _buildSuccessBox(
                      'Successfully verified. Enter your new password.',
                    )
                  else ...[
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.hMedium,
                    TextField(
                      controller: _responseCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Response Code',
                        prefixIcon: Icon(Icons.vpn_key_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      AppSpacing.hMedium,
                      _buildErrorBox(_errorMessage!),
                    ],
                    AppSpacing.hXlarge,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Verify'),
                      ),
                    ),
                  ],
                ] else ...[
                  _buildSuccessBox(
                    'Successfully verified. Enter your new password.',
                  ),
                  AppSpacing.hMedium,
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password (min 8 characters)',
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
                  AppSpacing.hMedium,
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    AppSpacing.hMedium,
                    _buildErrorBox(_errorMessage!),
                  ],
                  AppSpacing.hXlarge,
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitNewPassword,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Set New Password'),
                    ),
                  ),
                ],

                AppSpacing.hMedium,
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Login'),
                  ),
                ),
              ],
            ),
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.green, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
