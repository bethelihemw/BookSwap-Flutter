import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/edit_profile_page.dart';
import 'package:bookswap/providers/auth_provider.dart';
import 'package:bookswap/providers/books_provider.dart'; // Needed for navigation
import 'package:dio/dio.dart'; // Import DioException

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(profileProvider.notifier).fetchUserProfile();
    });
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Successfully logged out.')));
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
                _deleteAccount(); // Call delete function
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully.')),
        );
        Navigator.pushReplacementNamed(
          context,
          '/login',
        ); // Navigate to login page
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to delete account.';
        if (e is DioException) {
          errorMessage = e.response?.data?['message'] ?? errorMessage;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/my_book');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/add_book');
        break;
      case 3:
        // Already on Profile page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5), // Light purple background
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          profileState.username,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          profileState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : profileState.error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profileState.error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed:
                          () =>
                              ref
                                  .read(profileProvider.notifier)
                                  .fetchUserProfile(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.purple, width: 3),
                          image:
                              profileState.profilePic != null &&
                                      profileState.profilePic!.isNotEmpty
                                  ? DecorationImage(
                                    image: NetworkImage(
                                      'http://10.0.2.2:4000/' +
                                          profileState.profilePic!,
                                    ),
                                    fit: BoxFit.cover,
                                  )
                                  : null,
                        ),
                        child:
                            profileState.profilePic == null ||
                                    profileState.profilePic!.isEmpty
                                ? const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.lightBlue,
                                )
                                : null,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 160,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        children: [
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 2.0,
                            child: ListTile(
                              leading: const Icon(
                                Icons.person,
                                color: Colors.purple,
                              ),
                              title: Text(
                                profileState.username,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 2.0,
                            child: ListTile(
                              leading: const Icon(
                                Icons.email,
                                color: Colors.purple,
                              ),
                              title: Text(
                                profileState.email,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 2.0,
                            child: ListTile(
                              leading: const Icon(
                                Icons.lock,
                                color: Colors.purple,
                              ),
                              title: const Text(
                                'Change Password',
                                style: TextStyle(fontSize: 16),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/change_password',
                                );
                              },
                            ),
                          ),
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 2.0,
                            child: ListTile(
                              leading: const Icon(
                                Icons.logout,
                                color: Colors.purple,
                              ),
                              title: const Text(
                                'Logging out',
                                style: TextStyle(fontSize: 16),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: _logout,
                            ),
                          ),
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 2.0,
                            child: ListTile(
                              leading: const Icon(
                                Icons.delete,
                                color: Colors.purple,
                              ),
                              title: const Text(
                                'Delete Account',
                                   style: TextStyle(fontSize: 16),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                _showDeleteConfirmationDialog();
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => EditProfilePage(
                                        currentUsername: profileState.username,
                                        currentEmail: profileState.email,
                                      ),
                                ),
                              );
                              if (result == true) {
                                ref
                                    .read(profileProvider.notifier)
                                    .fetchUserProfile();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8A2BE2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 15,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30.0),
                              ),
                            ),
                            child: const Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'My Books'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add Book'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
