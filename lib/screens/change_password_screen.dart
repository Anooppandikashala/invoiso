import 'package:flutter/material.dart';
import 'package:invoiso/constants.dart';
import '../database/user_service.dart';
import '../models/user.dart';
import '../utils/password_utils.dart';
import 'dashboard_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final User user;
  final bool forced;

  const ChangePasswordScreen({
    super.key,
    required this.user,
    this.forced = false,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _errorMessage = null;
    });

    // Validate new password length
    if (newPassword.length < 8) {
      setState(() => _errorMessage = 'New password must be at least 8 characters.');
      return;
    }

    // Validate new password not same as username
    if (newPassword.toLowerCase() == widget.user.username.toLowerCase()) {
      setState(() => _errorMessage = 'Password cannot be the same as your username.');
      return;
    }

    // Validate confirmation matches
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    // If not forced, verify current password
    if (!widget.forced) {
      final currentPassword = _currentPasswordController.text;
      final valid = PasswordUtils.verify(
        currentPassword,
        widget.user.password,
        widget.user.salt,
      );
      if (!valid) {
        setState(() => _errorMessage = 'Current password is incorrect.');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      await UserService.updatePassword(widget.user.id, newPassword);
      await UserService.markPasswordChanged(widget.user.id);

      if (!mounted) return;

      // Get fresh user object
      final updatedUser = await UserService.getUserById(widget.user.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(updatedUser ?? widget.user),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to change password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forced,
      child: Scaffold(
        backgroundColor: Colors.blue[50],
        body: Center(
          child: Card(
            elevation: 8,
            color: Colors.white,
            child: Container(
              width: MediaQuery.sizeOf(context).width * 0.3,
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_reset,
                        color: Theme.of(context).primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.forced ? 'Change Password Required' : 'Change Password',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.forced)
                              Text(
                                'You must set a new password before continuing.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.orange[700],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  AppSpacing.hXlarge,

                  if (!widget.forced) ...[
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: Icon(Icons.lock_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    AppSpacing.hMedium,
                  ],

                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password (min 8 characters)',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  AppSpacing.hMedium,

                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    AppSpacing.hMedium,
                    Container(
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
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  AppSpacing.hXlarge,

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _changePassword,
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
                          : const Text('Change Password'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
