import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invoiso/database/user_service.dart';
import 'package:invoiso/providers/repositories.dart';
import '../constants.dart';
import '../models/user.dart';
import '../utils/password_utils.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  final User currentUser;
  const UserManagementScreen({super.key, required this.currentUser});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen>
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
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
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
      _showSnackBar('Error loading users: $e', Colors.red);
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
      setState(() => _isLoading = true);

      try {
        final user = User(
          id: _editingUserId ?? UniqueKey().toString(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          userType: _userTypeController.text,
        );

        if (_editingUserId == null) {
          await ref.read(authRepositoryProvider).insertUser(user);
          if (!mounted) return;
          _showSnackBar('User added successfully', Colors.green);
        } else {
          await ref.read(authRepositoryProvider).updateUser(user);
          if (!mounted) return;
          _showSnackBar(
              'User updated successfully', Theme.of(context).primaryColor);
        }

        _resetForm();
        await _loadUsers();
      } catch (e) {
        setState(() => _isLoading = false);
        _showSnackBar('Error saving user: $e', Colors.red);
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
                    const Expanded(
                      child: Text(
                        'Change Password',
                        style: TextStyle(fontSize: 20),
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
                                'User: $username',
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
                            labelText: 'Current Password',
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
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Current password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: 'New Password',
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
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'New password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
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
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != newPasswordController.text) {
                              return 'Passwords do not match';
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
                  child: const Text('Cancel', style: TextStyle(fontSize: 15)),
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
                  label: const Text('Change Password',
                      style: TextStyle(fontSize: 15)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final user = _users.firstWhere((u) => u.id == userId);
                      if (user.password == PasswordUtils.hash(oldPasswordController.text)) {
                        await ref.read(authRepositoryProvider).updatePassword(
                            userId, newPasswordController.text);
                        if (!context.mounted) return;
                        Navigator.of(context).pop();
                        _showSnackBar(
                            'Password changed successfully', Colors.green);
                        _loadUsers();
                      } else {
                        if (!context.mounted) return;
                        _showSnackBar(
                            'Current password is incorrect', Colors.red);
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
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                  const Icon(Icons.warning, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Delete User', style: TextStyle(fontSize: 20)),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Are you sure you want to delete user:',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
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
                'This action cannot be undone.',
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
              child: const Text('Cancel', style: TextStyle(fontSize: 15)),
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
              label: const Text('Delete', style: TextStyle(fontSize: 15)),
              onPressed: () async {
                await ref.read(authRepositoryProvider).deleteUserSafely(user.id);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                _showSnackBar('User deleted successfully', Colors.orange);
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
            isAdmin ? 'Admin' : 'User',
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

  Widget _buildUserForm() {
    final primaryColor = Theme.of(context).primaryColor;
    final isAdding = _editingUserId == null;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(
                  isAdding ? Icons.person_add_outlined : Icons.edit_outlined,
                  size: 18,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isAdding ? 'Add User' : 'Edit User',
                  style: TextStyle(
                    fontSize: AppFontSize.medium,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Divider(color: Colors.grey[200], height: 20),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        hintText: 'Enter username',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Username is required';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    if (isAdding) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password is required';
                          if (value.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _userTypeController.text.isNotEmpty
                          ? _userTypeController.text
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                      items: [
                        if (widget.currentUser.isAdmin())
                          const DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                        const DropdownMenuItem(
                          value: 'user',
                          child: Text('User'),
                        ),
                      ],
                      onChanged: (value) => _userTypeController.text = value!,
                      validator: (value) =>
                          value == null ? 'Role is required' : null,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveUser,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(isAdding ? Icons.add : Icons.check, size: 18),
                        label: Text(isAdding ? 'Add User' : 'Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                    if (!isAdding && widget.currentUser.isAdmin()) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _resetForm,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[300]!),
                            foregroundColor: Colors.grey[600],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersList() {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppBorderRadius.small),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Icon(Icons.people_outline, size: 18,
                    color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Users',
                  style: TextStyle(
                    fontSize: AppFontSize.medium,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    '${_filteredUsers.length}',
                    style: TextStyle(
                      fontSize: AppFontSize.xsmall,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.currentUser.isAdmin()) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(fontSize: AppFontSize.small, color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          color: Colors.grey[400],
                          onPressed: _searchController.clear,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.xsmall),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Divider(color: Colors.grey[200], height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchController.text.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.person_add_outlined,
                              size: 48,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty
                                  ? 'No users found'
                                  : 'No users yet',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: AppFontSize.small),
                            ),
                          ],
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          itemCount: _filteredUsers.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final user = _filteredUsers[index];
                            final isEditing = _editingUserId == user.id;
                            final isAdmin = user.userType == 'admin';
                            final primaryColor = Theme.of(context).primaryColor;
                            final avatarColor = isAdmin ? Colors.purple : Colors.blue;

                            return Container(
                              decoration: BoxDecoration(
                                color: isEditing
                                    ? primaryColor.withValues(alpha: 0.05)
                                    : Colors.grey[50],
                                borderRadius:
                                    BorderRadius.circular(AppBorderRadius.xsmall),
                                border: Border.all(
                                  color: isEditing
                                      ? primaryColor.withValues(alpha: 0.4)
                                      : Colors.grey[200]!,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor:
                                      avatarColor.withValues(alpha: 0.12),
                                  child: Text(
                                    user.username.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: avatarColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  user.username,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: AppFontSize.medium,
                                    color: isEditing ? primaryColor : Colors.grey[800],
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: _buildUserTypeChip(user.userType),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.edit_outlined,
                                      color: Colors.blue,
                                      tooltip: 'Edit',
                                      onPressed: () {
                                        _usernameController.text = user.username;
                                        _passwordController.text = user.password;
                                        _userTypeController.text = user.userType;
                                        setState(() => _editingUserId = user.id);
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    _buildActionButton(
                                      icon: Icons.lock_reset,
                                      color: Colors.orange,
                                      tooltip: 'Change Password',
                                      onPressed: () => _showChangePasswordDialog(
                                          user.id, user.username),
                                    ),
                                    if (widget.currentUser.isAdmin()) ...[
                                      const SizedBox(width: 6),
                                      _buildActionButton(
                                        icon: Icons.delete_outline,
                                        color: Colors.red,
                                        tooltip: 'Delete',
                                        onPressed: () => _confirmDeleteUser(user),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "User Management",
          style: TextStyle(letterSpacing: 0.5),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              children: [
                Expanded(flex: 2, child: _buildUserForm()),
                Expanded(flex: 4, child: _buildUsersList()),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(flex: 2, child: _buildUserForm()),
                Expanded(flex: 3, child: _buildUsersList()),
              ],
            );
          }
        },
      ),
    );
  }
}

