import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // Import dart:convert for JSON encoding/decoding
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:bookswap/edit_profile_page.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  _AdminProfilePageState createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  String _username = 'Loading...';
  String _email = 'Loading...';
  String? _profilePic; // To store the profile picture URL or base64
  bool _isLoading = true; // Initial loading state

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/admin_auth',
      ); // Redirect to admin login
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Successfully logged out.')));
    }
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in to view profile.')),
          );
          Navigator.pushReplacementNamed(
            context,
            '/admin_auth',
          ); // Redirect to admin login
          return;
        }
      }

      final url = Uri.parse('http://10.0.2.2:4000/api/auth/me');
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (!mounted) return; // Check if the widget is still mounted

      if (response.statusCode == 200) {
        final userData = json.decode(response.body)['user'];
        setState(() {
          _username = userData['name'] ?? 'N/A';
          _email = userData['email'] ?? 'N/A';
          _profilePic =
              userData['profilePic']; // Assuming profilePic is a URL or base64
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: ${response.statusCode}'),
          ),
        );
        // Optionally, navigate back or to login if profile loading fails
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5), // Light purple background
      appBar: AppBar(
        title: Text(
          _username == 'Loading...' ? 'Admin Profile' : _username,
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false, // This removes the back arrow
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  // Profile Picture
                  Positioned(
                    top:
                        40, // Adjusted position after removing purple background
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
                              _profilePic != null && _profilePic!.isNotEmpty
                                  ? DecorationImage(
                                    image: NetworkImage(
                                      'http://10.0.2.2:4000/' + _profilePic!,
                                    ), // Prepend base URL
                                    fit: BoxFit.cover,
                                  ) // For network image
                                  : null, // No image if _profilePic is null or empty
                        ),
                        child:
                            _profilePic == null || _profilePic!.isEmpty
                                ? const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.lightBlue,
                                )
                                : null, // No icon if image is loaded
                      ),
                    ),
                  ),

                  // Profile Details and Actions
                  Positioned(
                    top: 180, // Adjusted based on new profile picture position
                    left: 0,
                    right: 0,
                    bottom:
                        0, // Allow content to extend to the bottom before nav bar
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        children: [
                          // Username
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
                                _username,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          // Email
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
                                _email,
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          // Change Password
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
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/change_password',
                                );
                              },
                            ),
                          ),
                          // Edit Profile
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 2.0,
                            child: ListTile(
                              leading: const Icon(
                                Icons.edit,
                                color: Colors.purple,
                              ),
                              title: const Text(
                                'Edit Profile',
                                style: TextStyle(fontSize: 16),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => EditProfilePage(
                                          currentUsername: _username,
                                          currentEmail: _email,
                                          // Pass isAdminEditing: true for admin's own profile edit
                                          isAdminEditing: true,
                                        ),
                                  ),
                                );
                                if (result == true) {
                                  _fetchUserProfile(); // Refresh profile after edit
                                }
                              },
                            ),
                          ),
                          // Logout
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 2.0,
                            child: ListTile(
                              leading: const Icon(
                                Icons.logout,
                                color: Colors.red,
                              ),
                              title: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                              onTap: _logout,
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
