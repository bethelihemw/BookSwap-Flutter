import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import 'edit_profile_page.dart';
import 'admin_profile_page.dart';
import 'add_user_page.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoadData();
    });
  }

  Future<void> _checkAuthAndLoadData() async {
    final authState = ref.read(authProvider);
    print('Auth state: ${authState.isAuthenticated}'); // Debug log

    if (!authState.isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin token not found. Please log in.'),
          ),
        );
        Navigator.pushReplacementNamed(context, '/admin_auth');
      }
      return;
    }

    try {
      print('Fetching users and books...'); // Debug log
      await ref.read(adminProvider.notifier).fetchUsers();
      await ref.read(adminProvider.notifier).fetchBooks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  void _confirmDeleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete user \'$userName\'?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(adminProvider.notifier).deleteUser(userId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteBook(String bookId, String bookTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete book \'$bookTitle\'?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(adminProvider.notifier).deleteBook(bookId);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    print(
      'Admin state: ${adminState.users.length} users, ${adminState.books.length} books',
    ); // Debug log

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.purple,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Users'),
              Tab(icon: Icon(Icons.menu_book), text: 'Books'),
              Tab(icon: Icon(Icons.person), text: 'Profile'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
          ),
        ),
        body:
            adminState.error != null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        adminState.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkAuthAndLoadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
                : TabBarView(
                  children: [
                    // Users Management Content
                    adminState.isLoadingUsers
                        ? const Center(child: CircularProgressIndicator())
                        : adminState.users.isEmpty
                        ? const Center(child: Text('No users found.'))
                        : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  final result = await Navigator.pushNamed(
                                    context,
                                    '/add_user',
                                  );
                                  if (result == true) {
                                    ref
                                        .read(adminProvider.notifier)
                                        .fetchUsers();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text(
                                  'Add New User',
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: adminState.users.length,
                                itemBuilder: (context, index) {
                                  final user = adminState.users[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12.0),
                                    elevation: 2.0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Name: ${user['name'] ?? 'N/A'}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Email: ${user['email'] ?? 'N/A'}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Role: ${user['role'] ?? 'N/A'}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              ElevatedButton(
                                                onPressed: () async {
                                                  final result = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            context,
                                                          ) => EditProfilePage(
                                                            currentUsername:
                                                                user['name'] ??
                                                                '',
                                                            currentEmail:
                                                                user['email'] ??
                                                                '',
                                                            userId: user['_id'],
                                                            isAdminEditing:
                                                                true,
                                                          ),
                                                    ),
                                                  );
                                                  if (result == true) {
                                                    ref
                                                        .read(
                                                          adminProvider
                                                              .notifier,
                                                        )
                                                        .fetchUsers();
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blueAccent,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.0,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text('Edit User'),
                                              ),
                                              const SizedBox(width: 8),
                                              ElevatedButton(
                                                onPressed:
                                                    () => _confirmDeleteUser(
                                                      user['_id'],
                                                      user['name'],
                                                    ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  foregroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.0,
                                                        ),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Delete User',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                    // Books Management Content
                    adminState.isLoadingBooks
                        ? const Center(child: CircularProgressIndicator())
                        : adminState.books.isEmpty
                        ? const Center(child: Text('No books found.'))
                        : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: adminState.books.length,
                          itemBuilder: (context, index) {
                            final book = adminState.books[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              elevation: 2.0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/edit_book',
                                    arguments: book,
                                  ).then((result) {
                                    if (result == true) {
                                      ref
                                          .read(adminProvider.notifier)
                                          .fetchBooks();
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        height: 150,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                          color: Colors.grey[200],
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                          child:
                                              book['photo'] != null &&
                                                      book['photo'].isNotEmpty
                                                  ? Image.network(
                                                    'http://10.0.2.2:4000/${book['photo'].replaceAll('\\', '/')}',
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return const Center(
                                                        child: Icon(
                                                          Icons.broken_image,
                                                          size: 40,
                                                        ),
                                                      );
                                                    },
                                                  )
                                                  : const Center(
                                                    child: Icon(
                                                      Icons.book,
                                                      size: 40,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book['title'] ?? 'N/A',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Author : ${book['author'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Owner : ${book['owner']?['name'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      '/edit_book',
                                                      arguments: book,
                                                    ).then((result) {
                                                      if (result == true) {
                                                        ref
                                                            .read(
                                                              adminProvider
                                                                  .notifier,
                                                            )
                                                            .fetchBooks();
                                                      }
                                                    });
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blueAccent,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.0,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text('Edit'),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed:
                                                      () => _confirmDeleteBook(
                                                        book['_id'],
                                                        book['title'],
                                                      ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.redAccent,
                                                    foregroundColor:
                                                        Colors.white,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.0,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    const AdminProfilePage(),
                  ],
                ),
      ),
    );
  }
}
