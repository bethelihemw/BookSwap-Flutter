import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AdminAuthPage extends ConsumerStatefulWidget {
  const AdminAuthPage({super.key});

  @override
  _AdminAuthPageState createState() => _AdminAuthPageState();
}

class _AdminAuthPageState extends ConsumerState<AdminAuthPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminStatus() async {
    try {
      await ref.read(authProvider.notifier).checkAdminStatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Network error checking admin status: ${e.toString()}',
            ),
          ),
        );
      }
    }
  }

  Future<void> _adminSignup() async {
    try {
      await ref
          .read(authProvider.notifier)
          .adminSignup(
            _usernameController.text,
            _emailController.text,
            _passwordController.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin registered successfully!')),
        );
        _usernameController.clear();
        _emailController.clear();
        _passwordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register admin: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _adminLogin() async {
    try {
      await ref
          .read(authProvider.notifier)
          .adminLogin(_emailController.text, _passwordController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin logged in successfully!')),
        );
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log in: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        title: Text(
          authState.isAdminRegistered ? 'Admin Login' : 'Admin Signup',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
      body:
          authState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      authState.isAdminRegistered
                          ? 'Welcome back, Admin! Please log in.'
                          : 'No admin found. Please create the first admin account.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (!authState.isAdminRegistered) ...[
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                        ),
                      ),
                      const SizedBox(height: 15),
                    ],
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed:
                          authState.isAdminRegistered
                              ? _adminLogin
                              : _adminSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        authState.isAdminRegistered
                            ? 'Login'
                            : 'Sign Up as Admin',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
