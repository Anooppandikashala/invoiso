import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:invoiso/constants.dart';
import 'package:invoiso/database/user_service.dart';

import '../database/database_helper.dart';
import 'dashboard_screen.dart';


// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final user = await UserService.getUser(username, password);
    if (!mounted) return;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen(user)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Card(
          elevation: 8,
          color: Colors.white,
          child: Container(
            width: MediaQuery.sizeOf(context).width*0.25,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon(Icons.description, size: 88, color: Theme.of(context).primaryColor),
                // AppSpacing.hXlarge,
                // const Text(
                //   AppConfig.name,
                //   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                // ),
                Image.asset(
                  'assets/images/logo.png',
                  width: 230,
                  height: 100,
                  fit: BoxFit.contain,
                ),
                AppSpacing.hXlarge,
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
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                AppSpacing.hXlarge,
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white
                  ),
                  child: const Text('Login'),
                ),
                AppSpacing.hSmall,
                const Text('Default: admin/admin',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}