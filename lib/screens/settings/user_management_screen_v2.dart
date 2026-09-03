import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/providers/repositories.dart';
import 'package:invoiso/common/constants.dart';
import 'package:invoiso/l10n/app_localizations.dart';
import 'package:invoiso/models/user.dart';
import 'package:invoiso/utils/password_utils.dart';

class UserManagementScreenV2 extends ConsumerStatefulWidget {
  final User currentUser;
  const UserManagementScreenV2({super.key, required this.currentUser});

  @override
  ConsumerState<UserManagementScreenV2> createState() => _UserManagementScreenV2State();
}

class _UserManagementScreenV2State extends ConsumerState<UserManagementScreenV2>
    with SingleTickerProviderStateMixin {
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userTypeController = TextEditingController();
  final _searchController = TextEditingController();
  String? _editingUserId;
  bool _obscurePassword = true;

  late AnimationController _animationController;

  // ── V2 state ──────────────────────────────────────────────────────────
  bool _showAddPanelV2 = false;
  String _roleFilterV2 = 'all'; // 'all' | 'admin' | 'user'
  int _currentPageV2 = 0;
  final int _pageSizeV2 = 10;
  final Set<String> _selectedIdsV2 = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadUsers();
    _searchController.addListener(_filterUsers);
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      if (widget.currentUser.isAdmin()) {
        final users = await ref.read(authRepositoryProvider).getAllUsers();
        setState(() {
          _users = users;
          _filteredUsers = users;
          _isLoading = false;
        });
      } else {
        final fresh = await ref.read(authRepositoryProvider).getUserById(widget.currentUser.id);
        final user = fresh ?? widget.currentUser;
        setState(() {
          _users = [user];
          _filteredUsers = [user];
          _editingUserId = user.id;
          _isLoading = false;
        });
      }
      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showSnackBar(AppLocalizations.of(context)!.userMgmtLoadErrorMessage(e.toString()), Colors.red);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = List.from(_users);
      } else {
        _filteredUsers = _users
            .where((user) =>
        user.username.toLowerCase().contains(query) ||
            user.userType.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final l10n = AppLocalizations.of(context)!;

      // Role changes that can lock someone out of user management:
      //  - nobody may change their own role
      //  - the only remaining admin may not be demoted
      if (_editingUserId != null) {
        final original = _users.firstWhere(
          (u) => u.id == _editingUserId,
          orElse: () => widget.currentUser,
        );
        final roleChanged = _userTypeController.text != original.userType;
        if (roleChanged && _editingUserId == widget.currentUser.id) {
          _showSnackBar(l10n.userMgmtCantChangeOwnRoleMessage, Colors.red);
          return;
        }
        if (roleChanged &&
            original.userType == 'admin' &&
            _userTypeController.text != 'admin' &&
            _adminCountV2 <= 1) {
          _showSnackBar(l10n.userMgmtCantDemoteLastAdminMessage, Colors.red);
          return;
        }
      }

      // Reject a username already taken by another user before hitting the
      // DB's UNIQUE constraint (which would surface as a raw sqlite error).
      final trimmedName = _usernameController.text.trim();
      final existing =
          await ref.read(authRepositoryProvider).getUserByUsername(trimmedName);
      if (existing != null && existing.id != _editingUserId) {
        if (!mounted) return;
        _showSnackBar(l10n.userMgmtUsernameTakenMessage, Colors.red);
        return;
      }

      setState(() => _isLoading = true);

      try {
        final user = User(
          id: _editingUserId ?? UniqueKey().toString(),
          username: trimmedName,
          password: _passwordController.text,
          userType: _userTypeController.text,
        );

        if (_editingUserId == null) {
          await ref.read(authRepositoryProvider).insertUser(user);
          if (!mounted) return;
          _showSnackBar(l10n.userMgmtAddedMessage, Colors.green);
        } else {
          await ref.read(authRepositoryProvider).updateUser(user);
          if (!mounted) return;
          _showSnackBar(l10n.userMgmtUpdatedMessage, Theme.of(context).primaryColor);
        }

        _resetForm();
        await _loadUsers();
      } catch (e) {
        setState(() => _isLoading = false);
        final msg = e.toString().toLowerCase().contains('unique')
            ? l10n.userMgmtUsernameTakenMessage
            : l10n.userMgmtSaveErrorMessage(e.toString());
        _showSnackBar(msg, Colors.red);
      }
    }
  }

  void _resetForm() {
    _usernameController.clear();
    _passwordController.clear();
    _userTypeController.clear();
    if (widget.currentUser.isAdmin()) {
      setState(() {
        _editingUserId = null;
        _obscurePassword = true;
      });
    } else {
      setState(() {
        _editingUserId = widget.currentUser.id;
        _obscurePassword = true;
      });
    }
  }

  Future<void> _showChangePasswordDialog(String userId, String username) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureOldPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    final l10n = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_outline,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.userMgmtChangePasswordTitle,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ],
                ),
              ),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                l10n.userMgmtUserColonLabel(username),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: oldPasswordController,
                          obscureText: obscureOldPassword,
                          decoration: InputDecoration(
                            labelText: l10n.userMgmtCurrentPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureOldPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureOldPassword = !obscureOldPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.userMgmtCurrentPasswordRequiredMessage;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: l10n.userMgmtNewPasswordLabel,
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureNewPassword = !obscureNewPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.userMgmtNewPasswordRequiredMessage;
                            }
                            if (value.length < 6) {
                              return l10n.userMgmtPasswordMinLengthMessage;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: l10n.userMgmtConfirmNewPasswordLabel,
                            prefixIcon: const Icon(Icons.lock_clock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureConfirmPassword =
                                  !obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.userMgmtConfirmPasswordRequiredMessage;
                            }
                            if (value != newPasswordController.text) {
                              return l10n.userMgmtPasswordsDoNotMatchMessage;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: Text(l10n.actionCancel, style: const TextStyle(fontSize: 15)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(l10n.userMgmtChangePasswordTitle,
                      style: const TextStyle(fontSize: 15)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final user = _users.firstWhere((u) => u.id == userId);
                      if (user.password == PasswordUtils.hash(oldPasswordController.text)) {
                        await ref.read(authRepositoryProvider).updatePassword(
                            userId, newPasswordController.text);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        _showSnackBar(
                            l10n.userMgmtPasswordChangedMessage, Colors.green);
                        _loadUsers();
                      } else {
                        if (!context.mounted) return;
                        _showSnackBar(
                            l10n.userMgmtCurrentPasswordIncorrectMessage, Colors.red);
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteUser(User user) async {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.warning,
                      color: Theme.of(context).colorScheme.onError, size: 24),
                ),
                const SizedBox(width: 12),
                Text(l10n.userMgmtDeleteUserTitle,
                    style: TextStyle(
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.onErrorContainer)),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.userMgmtDeleteUserConfirmLabel,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.userMgmtActionCannotBeUndoneMessage,
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(l10n.actionCancel, style: const TextStyle(fontSize: 15)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                ),
              ),
              icon: const Icon(Icons.delete_forever),
              label: Text(l10n.actionDelete, style: const TextStyle(fontSize: 15)),
              onPressed: () async {
                await ref.read(authRepositoryProvider).deleteUserSafely(user.id);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                _showSnackBar(l10n.userMgmtDeletedMessage, Colors.orange);
                _loadUsers();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green
                  ? Icons.check_circle
                  : color == Colors.red
                  ? Icons.error
                  : Icons.info,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildUserTypeChip(String userType) {
    final isAdmin = userType == 'admin';
    final color = isAdmin ? Colors.purple : Colors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person,
            color: color,
            size: 13,
          ),
          const SizedBox(width: 4),
          Text(
            isAdmin
                ? AppLocalizations.of(context)!.dashboardRoleAdmin
                : AppLocalizations.of(context)!.dashboardRoleUser,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _userTypeController.dispose();
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildV2(context);

  // ============================================================
  // V2 — flat / modern layout. Reuses all v1 state, controllers,
  // validation and repository calls (_saveUser, _resetForm,
  // _confirmDeleteUser, _showChangePasswordDialog, _buildUserTypeChip,
  // _buildActionButton are all untouched). New pieces: stat cards,
  // role filter, a flat table with optional bulk-select, and a
  // slide-out Add/Edit User panel.
  //
  // Honest scope note: the User model here only has id/username/
  // password/userType (admin|user) — no full name, email, active/
  // inactive status, or last-login timestamp. Rather than fabricate
  // those, this UI only shows what's real.
  // ============================================================

  int get _adminCountV2 => _users.where((u) => u.userType == 'admin').length;
  int get _regularCountV2 => _users.where((u) => u.userType != 'admin').length;

  List<User> get _roleFilteredUsersV2 {
    if (_roleFilterV2 == 'all') return _filteredUsers;
    return _filteredUsers.where((u) => u.userType == _roleFilterV2).toList();
  }

  void _openAddPanelV2() {
    _resetForm();
    setState(() {
      _editingUserId = null;
      _showAddPanelV2 = true;
    });
  }

  void _editUserV2(User user) {
    _usernameController.text = user.username;
    _passwordController.text = user.password;
    _userTypeController.text = user.userType;
    setState(() {
      _editingUserId = user.id;
      _showAddPanelV2 = true;
    });
  }

  Future<void> _saveUserV2() async {
    await _saveUser();
    // _saveUser only clears _isLoading/_editingUserId on failure (it
    // rethrows into the catch and leaves the form populated); on success
    // it calls _resetForm() + _loadUsers(). Use the username field being
    // cleared as the signal that it actually succeeded, same approach
    // used on the other v2 screens.
    if (_usernameController.text.isEmpty && !_isLoading) {
      if (!mounted) return;
      setState(() => _showAddPanelV2 = false);
    }
  }

  Future<void> _deleteUserV2(User user) async {
    if (user.id == widget.currentUser.id) {
      _showSnackBar(
          AppLocalizations.of(context)!.userMgmtCantDeleteOwnAccountMessage,
          Colors.red);
      return;
    }
    await _confirmDeleteUser(user);
  }

  void _showViewUserDialogV2(User user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: (user.userType == 'admin' ? Colors.purple : Colors.blue)
                  .withValues(alpha: 0.12),
              child: Text(
                user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                style: TextStyle(
                    color: user.userType == 'admin' ? Colors.purple : Colors.blue,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(user.username,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserTypeChip(user.userType),
            if (user.id == widget.currentUser.id) ...[
              const SizedBox(height: 10),
              Text(AppLocalizations.of(context)!.userMgmtThisIsYourAccountMessage,
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.actionClose),
          ),
        ],
      ),
    );
  }

  Future<void> _bulkDeleteSelectedV2() async {
    final l10n = AppLocalizations.of(context)!;
    final includesSelf = _selectedIdsV2.contains(widget.currentUser.id);
    final ids = _selectedIdsV2.where((id) => id != widget.currentUser.id).toList();
    if (ids.isEmpty) {
      if (includesSelf) {
        _showSnackBar(l10n.userMgmtCantDeleteOwnAccountMessage, Colors.red);
      }
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.userMgmtDeleteSelectedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.userMgmtBulkDeleteBody(ids.length)),
            if (includesSelf) ...[
              const SizedBox(height: 8),
              Text(l10n.userMgmtOwnAccountSkippedMessage,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.actionCancel)),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _isLoading = true);
    try {
      for (final id in ids) {
        await ref.read(authRepositoryProvider).deleteUserSafely(id);
      }
      _showSnackBar(l10n.userMgmtBulkDeletedMessage(ids.length), Colors.orange);
      _selectedIdsV2.clear();
      await _loadUsers();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(l10n.userMgmtBulkDeleteErrorMessage(e.toString()), Colors.red);
    }
  }

  BoxDecoration _flatCardDecorationV2(BuildContext context) => BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      );

  Widget _menuButtonLookV2(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        border:
            Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13.5, color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(width: 4),
          Icon(Icons.arrow_drop_down,
              size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _statCardV2({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _flatCardDecorationV2(context),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  Text(value,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCardsRowV2() {
    return Row(
      children: [
        _statCardV2(
          label: 'Total Users',
          value: '${_users.length}',
          subtitle: 'All users',
          icon: Icons.groups_outlined,
          accent: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 12),
        _statCardV2(
          label: 'Admin Users',
          value: '$_adminCountV2',
          subtitle: 'Full access',
          icon: Icons.admin_panel_settings_outlined,
          accent: Colors.purple,
        ),
        const SizedBox(width: 12),
        _statCardV2(
          label: 'Regular Users',
          value: '$_regularCountV2',
          subtitle: 'Standard access',
          icon: Icons.person_outline,
          accent: Colors.blue,
        ),
      ],
    );
  }

  Widget _headerBarV2() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.userMgmtTitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 2),
              Text(l10n.userMgmtSubtitle,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        Flexible(
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              IconButton(
                onPressed: _isLoading ? null : _loadUsers,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.refresh),
                tooltip: l10n.actionRefresh,
              ),
              if (widget.currentUser.isAdmin())
                FilledButton.icon(
                  onPressed: _openAddPanelV2,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.userMgmtAddUserButton),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchFilterRowV2() {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.userMgmtSearchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: _searchController.clear,
                    )
                  : null,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                  borderSide:
                      BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        PopupMenuButton<String>(
          tooltip: l10n.userMgmtFilterByRoleTooltip,
          onSelected: (value) {
            if (!mounted) return;
            setState(() {
              _roleFilterV2 = value;
              _currentPageV2 = 0;
            });
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(value: 'all', child: Text(l10n.userMgmtAllRolesLabel)),
            PopupMenuItem(value: 'admin', child: Text(l10n.dashboardRoleAdmin)),
            PopupMenuItem(value: 'user', child: Text(l10n.dashboardRoleUser)),
          ],
          child: _menuButtonLookV2(
              Icons.filter_list,
              l10n.userMgmtRoleColonLabel(_roleFilterV2 == 'all'
                  ? l10n.userMgmtAllLabel
                  : (_roleFilterV2 == 'admin' ? l10n.dashboardRoleAdmin : l10n.dashboardRoleUser))),
        ),
      ],
    );
  }

  Widget _tableHeaderRowV2() {
    TextStyle style = TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
        color: Theme.of(context).colorScheme.onSurfaceVariant);
    final pageItems = _pagedUsersV2();
    final allSelected = pageItems.isNotEmpty &&
        pageItems.every((u) => _selectedIdsV2.contains(u.id));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 1.4),
        ),
      ),
      child: Row(
        children: [
          if (widget.currentUser.isAdmin())
            SizedBox(
              width: 36,
              child: Checkbox(
                value: allSelected,
                onChanged: (v) {
                  if (!mounted) return;
                  setState(() {
                    if (v == true) {
                      _selectedIdsV2.addAll(pageItems.map((u) => u.id));
                    } else {
                      _selectedIdsV2.removeAll(pageItems.map((u) => u.id));
                    }
                  });
                },
              ),
            ),
          Expanded(flex: 3, child: Text(AppLocalizations.of(context)!.userMgmtColUser, style: style)),
          Expanded(flex: 2, child: Text(AppLocalizations.of(context)!.userMgmtColRole, style: style)),
          SizedBox(
              width: 164,
              child: Text(AppLocalizations.of(context)!.customerMgmtColActions, style: style)),
        ],
      ),
    );
  }

  Widget _tableRowV2(User user) {
    final isAdmin = user.userType == 'admin';
    final avatarColor = isAdmin ? Colors.purple : Colors.blue;
    final isYou = user.id == widget.currentUser.id;
    final selected = _selectedIdsV2.contains(user.id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          if (widget.currentUser.isAdmin())
            SizedBox(
              width: 36,
              child: Checkbox(
                value: selected,
                onChanged: (v) {
                  if (!mounted) return;
                  setState(() {
                    if (v == true) {
                      _selectedIdsV2.add(user.id);
                    } else {
                      _selectedIdsV2.remove(user.id);
                    }
                  });
                },
              ),
            ),
          Expanded(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: avatarColor.withValues(alpha: 0.12),
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.username,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (isYou)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(AppLocalizations.of(context)!.userMgmtYouBadgeLabel,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).primaryColor)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _buildUserTypeChip(user.userType),
            ),
          ),
          SizedBox(
            width: 164,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.visibility_outlined,
                  color: Colors.green,
                  tooltip: AppLocalizations.of(context)!.actionView,
                  onPressed: () => _showViewUserDialogV2(user),
                ),
                const SizedBox(width: 6),
                _buildActionButton(
                  icon: Icons.edit_outlined,
                  color: Colors.blue,
                  tooltip: AppLocalizations.of(context)!.actionEdit,
                  onPressed: () => _editUserV2(user),
                ),
                const SizedBox(width: 6),
                _buildActionButton(
                  icon: Icons.lock_reset,
                  color: Colors.orange,
                  tooltip: AppLocalizations.of(context)!.userMgmtChangePasswordTitle,
                  onPressed: () =>
                      _showChangePasswordDialog(user.id, user.username),
                ),
                if (widget.currentUser.isAdmin() && !isYou) ...[
                  const SizedBox(width: 6),
                  _buildActionButton(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    tooltip: AppLocalizations.of(context)!.actionDelete,
                    onPressed: () => _deleteUserV2(user),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<User> _pagedUsersV2() {
    final list = _roleFilteredUsersV2;
    final start = (_currentPageV2 * _pageSizeV2).clamp(0, list.length);
    final end = (start + _pageSizeV2).clamp(0, list.length);
    return start < end ? list.sublist(start, end) : <User>[];
  }

  Widget _paginationV2() {
    final l10n = AppLocalizations.of(context)!;
    final total = _roleFilteredUsersV2.length;
    final totalPages = total == 0 ? 1 : ((total - 1) ~/ _pageSizeV2) + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          Row(
            children: [
              if (widget.currentUser.isAdmin())
                PopupMenuButton<String>(
                  enabled: _selectedIdsV2.isNotEmpty,
                  tooltip: l10n.userMgmtBulkActionsTooltip,
                  onSelected: (value) {
                    if (value == 'delete') _bulkDeleteSelectedV2();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'delete',
                      enabled: _selectedIdsV2.isNotEmpty,
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(l10n.userMgmtDeleteSelectedMenuLabel,
                              style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: _menuButtonLookV2(
                      Icons.checklist,
                      '${l10n.userMgmtBulkActionsLabel}'
                      '${_selectedIdsV2.isNotEmpty ? ' (${_selectedIdsV2.length})' : ''}'),
                ),
              const SizedBox(width: 12),
              Text(
                  l10n.userMgmtShowingRangeLabel(
                      total == 0 ? 0 : _currentPageV2 * _pageSizeV2 + 1,
                      (_currentPageV2 * _pageSizeV2 + _pageSizeV2).clamp(0, total),
                      total),
                  style: TextStyle(
                      fontSize: 12.5, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(width: 24),
          Row(
            children: [
              IconButton(
                onPressed: _currentPageV2 > 0
                    ? () => setState(() => _currentPageV2--)
                    : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${_currentPageV2 + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              Text(l10n.customerMgmtOfTotalPagesLabel(totalPages),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              IconButton(
                onPressed: _currentPageV2 < totalPages - 1
                    ? () => setState(() => _currentPageV2++)
                    : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          ],
        ),
      ),
    );
  }

  // Sizes itself naturally instead of relying on `Expanded` to fill
  // whatever space a bounded ancestor gives it — the page itself is a
  // CustomScrollView (see _buildV2), so the list here is shrink-wrapped
  // (its own scrolling disabled) and the page just scrolls further if the
  // natural content (header + rows + pagination) doesn't fit the viewport.
  Widget _tableSectionV2() {
    final pageItems = _pagedUsersV2();
    return Container(
      decoration: _flatCardDecorationV2(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _tableHeaderRowV2(),
          _isLoading && _users.isEmpty
              ? const SizedBox(
                  height: 240, child: Center(child: CircularProgressIndicator()))
              : pageItems.isEmpty
                  ? SizedBox(
                      height: 240,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_search_outlined,
                                size: 48,
                                color: Theme.of(context).colorScheme.outlineVariant),
                            const SizedBox(height: 12),
                            Text(AppLocalizations.of(context)!.userMgmtNoUsersFoundMessage,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pageItems.length,
                      itemBuilder: (context, index) => _tableRowV2(pageItems[index]),
                    ),
          _paginationV2(),
        ],
      ),
    );
  }

  // ── Slide-out Add/Edit User panel ──────────────────────────────────
  // Only real fields: username, password (add only), role. No
  // full name / email / status — the User model doesn't have them.

  Widget _addPanelV2() {
    final l10n = AppLocalizations.of(context)!;
    final isAdding = _editingUserId == null;
    final primaryColor = Theme.of(context).primaryColor;
    // Width is controlled by the Positioned wrapper in _buildV2 (scales with
    // the window, capped between 520-680px, full width on narrow screens).
    return Container(
      decoration: _flatCardDecorationV2(context),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 10, 16),
            child: Row(
              children: [
                Text(isAdding ? l10n.userMgmtAddNewUserTitle : l10n.userMgmtEditUserTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _resetForm();
                    setState(() => _showAddPanelV2 = false);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: l10n.userMgmtUsernameRequiredLabel,
                        hintText: l10n.userMgmtEnterUsernameHint,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.userMgmtUsernameRequiredMessage;
                        }
                        if (value.trim().length < 3) {
                          return l10n.userMgmtUsernameMinLengthMessage;
                        }
                        return null;
                      },
                    ),
                    if (isAdding) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: l10n.userMgmtPasswordRequiredLabel,
                          hintText: l10n.userMgmtEnterPasswordHint,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.userMgmtPasswordRequiredMessage;
                          }
                          if (value.length < 6) return l10n.userMgmtMinimum6CharsMessage;
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    Builder(builder: (context) {
                      final editingSelf =
                          !isAdding && _editingUserId == widget.currentUser.id;
                      final lockLastAdmin = !isAdding &&
                          _userTypeController.text == 'admin' &&
                          _adminCountV2 <= 1;
                      final roleLocked = editingSelf || lockLastAdmin;
                      return DropdownButtonFormField<String>(
                        value: _userTypeController.text.isNotEmpty
                            ? _userTypeController.text
                            : null,
                        decoration: InputDecoration(
                          labelText: l10n.userMgmtRoleRequiredLabel,
                          helperText: editingSelf
                              ? l10n.userMgmtCantChangeOwnRoleMessage
                              : lockLastAdmin
                                  ? l10n.userMgmtCantDemoteLastAdminMessage
                                  : null,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                        ),
                        items: [
                          DropdownMenuItem(value: 'admin', child: Text(l10n.dashboardRoleAdmin)),
                          DropdownMenuItem(value: 'user', child: Text(l10n.dashboardRoleUser)),
                        ],
                        onChanged: roleLocked
                            ? null
                            : (value) => _userTypeController.text = value!,
                        validator: (value) =>
                            value == null ? l10n.userMgmtRoleRequiredMessage : null,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _resetForm();
                      setState(() => _showAddPanelV2 = false);
                    },
                    child: Text(l10n.actionCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _isLoading ? null : _saveUserV2,
                    style: FilledButton.styleFrom(backgroundColor: primaryColor),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Icon(isAdding ? Icons.add : Icons.check, size: 18),
                    label: Text(isAdding ? l10n.userMgmtSaveUserButton : l10n.productMgmtSaveChangesButton),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Non-admin users only ever see their own account (matches v1's
  // _loadUsers behaviour) — a full management table doesn't make sense
  // for them, so this is a simple "my account" panel instead.
  Widget _selfAccountViewV2() {
    final l10n = AppLocalizations.of(context)!;
    final user = _users.isNotEmpty ? _users.first : widget.currentUser;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: _flatCardDecorationV2(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.withValues(alpha: 0.12),
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.username,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        _buildUserTypeChip(user.userType),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: l10n.userMgmtUsernameRequiredLabel,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppBorderRadius.xsmall)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.userMgmtUsernameRequiredMessage;
                    }
                    if (value.trim().length < 3) {
                      return l10n.userMgmtUsernameMinLengthMessage;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showChangePasswordDialog(user.id, user.username),
                      icon: const Icon(Icons.lock_reset, size: 18),
                      label: Text(l10n.userMgmtChangePasswordTitle),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isLoading ? null : _saveUser,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 18),
                      label: Text(l10n.actionSave),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildV2(BuildContext context) {
    if (!widget.currentUser.isAdmin()) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _selfAccountViewV2(),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Add/Edit panel width: floats as an overlay instead of sitting
            // in a Row next to the main content, so it never steals width
            // from the table. Scales with the window on large screens
            // (capped so it doesn't get unwieldy), full width on narrow ones.
            final panelWidth = constraints.maxWidth < 750
                ? constraints.maxWidth - 32
                : (constraints.maxWidth * 0.42).clamp(520.0, 680.0);

            return Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _headerBarV2(),
                            const SizedBox(height: 12),
                            _statCardsRowV2(),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: _flatCardDecorationV2(context),
                              child: _searchFilterRowV2(),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: _tableSectionV2(),
                      ),
                    ),
                  ],
                ),
                if (_showAddPanelV2) ...[
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () => setState(() => _showAddPanelV2 = false),
                      child: Container(color: Colors.black.withValues(alpha: 0.3)),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    bottom: 16,
                    width: panelWidth,
                    child: _addPanelV2(),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

