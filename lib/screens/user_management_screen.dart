import 'package:flutter/material.dart';
import 'package:invoiso/database/user_service.dart';
import '../models/user.dart';
import '../database/database_helper.dart';

class UserManagementScreen extends StatefulWidget {
  final User currentUser;
  const UserManagementScreen({super.key, required this.currentUser});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
{
  List<User> _users = [];

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userTypeController = TextEditingController();
  String? _editingUserId;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if(widget.currentUser.isAdmin())
    {
      final users = await UserService.getAllUsers();
      setState(() {
        _users = users;
      });
    }
    else
    {
      setState(() {
        _users = [widget.currentUser];
        _editingUserId  = widget.currentUser.id;
      });
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final user = User(
        id: _editingUserId ?? UniqueKey().toString(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        userType: _userTypeController.text,
      );

      if (_editingUserId == null) {
        await UserService.insertUser(user);
        _showSnackBar('User added successfully', Colors.green);
      } else {
        await UserService.updateUser(user);
        _showSnackBar('User updated successfully', Theme.of(context).primaryColor);
      }

      _resetForm();
      _loadUsers();
    }
  }

  void _resetForm() {
    _usernameController.clear();
    _passwordController.clear();
    _userTypeController.clear();
    if(widget.currentUser.isAdmin())
    {
      setState(() {
        _editingUserId = null;
        _obscurePassword = true;
      });
    }
    else
    {
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
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Text('Change Password'),
                ],
              ),
              content: SizedBox(
                width: 300,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User: $username',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: obscureOldPassword,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureOldPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureOldPassword = !obscureOldPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                              obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureNewPassword = !obscureNewPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
                              obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                obscureConfirmPassword = !obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
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
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // Verify old password
                      final user = _users.firstWhere((u) => u.id == userId);
                      if (user.password == oldPasswordController.text) {
                        await UserService.updatePassword(userId, newPasswordController.text);
                        Navigator.of(context).pop();
                        _showSnackBar('Password changed successfully', Colors.green);
                        _loadUsers();
                      } else {
                        _showSnackBar('Current password is incorrect', Colors.red);
                      }
                    }
                  },
                  child: const Text('Change Password'),
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
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              const Text('Delete User'),
            ],
          ),
          content: Text('Are you sure you want to delete user "${user.username}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await UserService.deleteUserSafely(user.id);
                Navigator.of(context).pop();
                _showSnackBar('User deleted successfully', Colors.orange);
                _loadUsers();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildUserTypeChip(String userType) {
    Color chipColor = userType == 'admin' ? Colors.purple : Colors.blue;
    return Row(
      children: [
        Text("User Type : "),
        Chip(
          label: Text(
            userType.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: chipColor,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _userTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Management"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          //user Form
          Expanded(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha:  0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _editingUserId == null ? Icons.person_add : Icons.edit,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _editingUserId == null ? 'Add New User' : 'Edit User',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
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
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _userTypeController.text.isNotEmpty ? _userTypeController.text : null,
                              decoration: InputDecoration(
                                labelText: 'User Type',
                                prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: widget.currentUser.isAdmin() ? [
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings, size: 20, color: Colors.purple),
                                      SizedBox(width: 8),
                                      Text('Admin'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'user',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, size: 20, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('User'),
                                    ],
                                  ),
                                ),
                              ] :
                              [
                                DropdownMenuItem(
                                  value: 'user',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, size: 20, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('User'),
                                    ],
                                  ),
                                ),
                              ]
                              ,
                              onChanged: (value) {
                                _userTypeController.text = value!;
                              },
                              validator: (value) => value == null ? 'User type is required' : null,
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _saveUser,
                                icon: Icon(
                                  _editingUserId == null ? Icons.add : Icons.update,
                                ),
                                label: Text(
                                  _editingUserId == null ? 'Add User' : 'Update User',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            if (_editingUserId != null) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _resetForm,
                                  icon: const Icon(Icons.cancel),
                                  label: const Text(
                                    'Cancel Edit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
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
            ),
          ),
          // Users List
          Expanded(
            flex: 2,
            child: Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Users (${_users.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _users.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_add,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a new user to get started',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isEditing = _editingUserId == user.id;

                        return Container(
                          width: MediaQuery.sizeOf(context).width*0.1,
                          decoration: BoxDecoration(
                            color: isEditing
                                ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                                : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: user.userType == 'admin'
                                  ? Colors.purple
                                  : Colors.blue,
                              child: Icon(
                                user.userType == 'admin'
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    Text("Username: "),
                                    Text(
                                      textAlign: TextAlign.center,
                                      user.username,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: isEditing
                                            ? Theme.of(context).primaryColor
                                            : null,
                                      ),
                                    )
                                  ],
                                ),
                                SizedBox(width: 20,),
                                _buildUserTypeChip(user.userType),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    color: Colors.blue[600],
                                  ),
                                  tooltip: 'Edit User',
                                  onPressed: () {
                                    _usernameController.text = user.username;
                                    _passwordController.text = user.password;
                                    _userTypeController.text = user.userType;
                                    setState(() {
                                      _editingUserId = user.id;
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.lock_reset,
                                    color: Colors.orange[600],
                                  ),
                                  tooltip: 'Change Password',
                                  onPressed: () => _showChangePasswordDialog(
                                    user.id,
                                    user.username,
                                  ),
                                ),
                                  widget.currentUser.isAdmin() ?
                                  IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Colors.red[600],
                                  ),
                                  tooltip: 'Delete User',
                                  onPressed: () => _confirmDeleteUser(user),
                                ) : SizedBox(width: 0,)
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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