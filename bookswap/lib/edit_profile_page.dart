import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/providers/auth_provider.dart';
import 'package:dio/dio.dart'; // Import DioException

class EditProfilePage extends ConsumerStatefulWidget {
  final String currentUsername;
  final String currentEmail;
  final String? userId;
  final bool
  isAdminEditing; // Keeping this for now, but likely to be removed if not used

  const EditProfilePage({
    super.key,
    required this.currentUsername,
    required this.currentEmail,
    this.userId,
    this.isAdminEditing = false,
  });

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.currentUsername);
    _emailController = TextEditingController(text: widget.currentEmail);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final newUsername = _usernameController.text;
    final newEmail = _emailController.text;

    if (newUsername.isEmpty || newEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username and Email cannot be empty.')),
        );
      }
      return;
    }

    try {
      await ref
          .read(profileProvider.notifier)
          .updateProfile(username: newUsername, email: newEmail);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update profile.';
        if (e is DioException) {
          errorMessage = e.response?.data?['message'] ?? errorMessage;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    // Update controllers if profile state changes, in case user navigates back and forth
    // and data was refetched in ProfilePage.
    if (_usernameController.text != profileState.username &&
        !profileState.isLoading) {
      _usernameController.text = profileState.username;
    }
    if (_emailController.text != profileState.email &&
        !profileState.isLoading) {
      _emailController.text = profileState.email;
    }
return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          profileState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: profileState.isLoading ? null : _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8A2BE2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                      ),
                      child:
                          profileState.isLoading
                              ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              )
                              : const Text(
                                'Save Changes',
                                style: TextStyle(fontSize: 18),
                              ),
                    ),
                  ],
                ),
              ),
    );
  }
}
