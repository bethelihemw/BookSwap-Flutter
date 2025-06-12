import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/providers/books_provider.dart';
import 'package:bookswap/providers/auth_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoadBooks();
    });
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndLoadBooks() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
      return;
    }
    await _loadBooks();
  }

  Future<void> _loadBooks() async {
    await ref.read(booksProvider.notifier).fetchBooks();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      _loadBooks(); // If search is cleared, load all books
    } else {
      ref
          .read(booksProvider.notifier)
          .fetchBooks(searchQuery: _searchController.text);
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        // Current page, do nothing or refresh
        _loadBooks();
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/my_book');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/add_book');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final booksState = ref.watch(booksProvider);
    // final authState = ref.watch(authProvider);
return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'BookSwap',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged();
                  },
                ),
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  ref
                      .read(booksProvider.notifier)
                      .fetchBooks(searchQuery: value);
                }
              },
            ),
          ),
          Expanded(
            child:
                booksState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : booksState.error != null
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            booksState.error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadBooks,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                    : booksState.books.isEmpty
                    ? const Center(
                      child: Text(
                        'No books found',
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    )
                    : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: booksState.books.length,
                      itemBuilder: (context, index) {
                        final book = booksState.books[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/book_detail',
                              arguments: book,
                            );
                          },
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
Expanded(
                                  child:
                                      book['photo'] != null
                                          ? Image.network(
                                            'http://10.0.2.2:4000/${book['photo'].replaceAll('\\', '/')}',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Icon(
                                                  Icons.book,
                                                  size: 50,
                                                ),
                                              );
                                            },
                                          )
                                          : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(
                                              Icons.book,
                                              size: 50,
                                            ),
                                          ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book['title'] ?? 'Unknown Title',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        book['author'] ?? 'Unknown Author',
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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
