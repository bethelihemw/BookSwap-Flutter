import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/providers/books_provider.dart';
import 'package:bookswap/providers/auth_provider.dart';

class MySwapRequestsPage extends ConsumerStatefulWidget {
  const MySwapRequestsPage({super.key});

  @override
  ConsumerState<MySwapRequestsPage> createState() => _MySwapRequestsPageState();
}

class _MySwapRequestsPageState extends ConsumerState<MySwapRequestsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSwapRequests();
    });
  }

  Future<void> _fetchSwapRequests() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to view swap requests.')),
        );
        Navigator.pushReplacementNamed(context, '/');
      }
      return;
    }
    await ref.read(booksProvider.notifier).fetchSwapRequests();
  }

  Future<void> _handleSwapRequest(String requestId, bool accept) async {
    await ref.read(booksProvider.notifier).handleSwapRequest(requestId, accept);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBookTradeInfo(Map<String, dynamic> trade, bool isSent) {
    final book = trade['requestedBook'];
    final requester = trade['requester'];
    final owner = trade['owner'];
    final status = trade['status'];

    final offeredBook = trade['offeredBook'];
    String offeredBookTitle =
        offeredBook != null ? offeredBook['title'] : 'No book offered';

    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: ${book['title']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('Author: ${book['author']}'),
            Text(
              'Description: ${book['description']}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isSent && offeredBook != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Offered by ${requester['username']}: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Book Title: $offeredBookTitle'),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              'Status: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              status,
              style: TextStyle(
                color: _getStatusColor(status),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!isSent && status == 'pending')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => _handleSwapRequest(trade['_id'], true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleSwapRequest(trade['_id'], false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reject'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booksState = ref.watch(booksProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Swap Requests',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body:
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
                      onPressed: _fetchSwapRequests,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/my_book_list');
                      },
                      icon: const Icon(Icons.book, color: Colors.white),
                      label: const Text(
                        'My Book List',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          const TabBar(
                            tabs: [
                              Tab(text: 'Sent Requests'),
                              Tab(text: 'Received Requests'),
                            ],
                            labelColor: Colors.purple,
                            unselectedLabelColor: Colors.grey,
                            indicatorColor: Colors.purple,
                          ),
                          Expanded(
                            child: TabBarView(
                              children: [
                                booksState.sentSwapRequests.isEmpty
                                    ? const Center(
                                      child: Text('No sent swap requests.'),
                                    )
                                    : ListView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      itemCount:
                                          booksState.sentSwapRequests.length,
                                      itemBuilder: (context, index) {
                                        final trade =
                                            booksState.sentSwapRequests[index];
                                        return _buildBookTradeInfo(trade, true);
                                      },
                                    ),
                                booksState.receivedSwapRequests.isEmpty
                                    ? const Center(
                                      child: Text('No received swap requests.'),
                                    )
                                    : ListView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      itemCount:
                                          booksState
                                              .receivedSwapRequests
                                              .length,
                                      itemBuilder: (context, index) {
                                        final trade =
                                            booksState
                                                .receivedSwapRequests[index];
                                        return _buildBookTradeInfo(
                                          trade,
                                          false,
                                        );
                                      },
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Set to 1 for 'My Books' tab
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              // Current page, do nothing or refresh
              _fetchSwapRequests(); // Refresh only this tab
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/add_book');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
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
