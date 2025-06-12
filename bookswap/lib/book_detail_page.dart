import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/providers/books_provider.dart';
import 'package:bookswap/providers/auth_provider.dart';
import 'package:dio/dio.dart';

class BookDetailPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> book;

  const BookDetailPage({super.key, required this.book});

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  @override
  void initState() {
    super.initState();
    // No need to load auth token explicitly here as authProvider handles it.
  }

  Future<void> _requestSwap() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be logged in to request a swap.'),
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    final requestedBookId = widget.book['_id'];

    if (requestedBookId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requested Book ID not found.')),
        );
      }
      return;
    }

    try {
      // Assuming requestSwap in BooksNotifier takes bookId and an optional message
      await ref.read(booksProvider.notifier).requestSwap(
            requestedBookId,
            'Swap request for ${widget.book['title']}',
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Swap request sent successfully!')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to send swap request.';
        if (e.response?.data?['message'] != null) {
          errorMessage = e.response!.data['message'];
        } else if (e.response?.statusCode != null) {
          errorMessage =
              'Failed to send swap request: ${e.response!.statusCode}';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final booksState = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5), // Light purple background
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Book Detail',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: booksState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Book Image
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 7,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: book['photo'] != null && book['photo'].isNotEmpty
                            ? Image.network(
                                'http://10.0.2.2:4000/${book['photo'].replaceAll('\\', '/')}',
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                'assets/default_book.png',
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Book Title
                    Text(
                      book['title'] ?? 'N/A',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Book Owner
                    Text(
                      'Owner: ${book['owner']?['name'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Book Description
                    Text(
                      book['description'] ?? 'No description available.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // PDF Info
                    if (book['pdf_file'] != null && book['pdf_file'].isNotEmpty)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.redAccent,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    Uri.decodeComponent(
                                      book['pdf_file']
                                          .toString()
                                          .replaceAll('\\', '/')
                                          .split('/')
                                          .last
                                          .split('-')
                                          .skip(1)
                                          .join('-'),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blueGrey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: booksState.isLoading ? null : _requestSwap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8A2BE2),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: booksState.isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              )
                            : const Text(
                                'Request Swap',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
