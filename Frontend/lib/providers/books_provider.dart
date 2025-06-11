import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/dio_client.dart';
import 'package:bookswap/providers/auth_provider.dart';

class BooksState {
  final List<Map<String, dynamic>> books;
  final List<Map<String, dynamic>> sentSwapRequests;
  final List<Map<String, dynamic>> receivedSwapRequests;
  final bool isLoading;
  final String? error;

  BooksState({
    this.books = const [],
    this.sentSwapRequests = const [],
    this.receivedSwapRequests = const [],
    this.isLoading = false,
    this.error,
  });

  BooksState copyWith({
    List<Map<String, dynamic>>? books,
    List<Map<String, dynamic>>? sentSwapRequests,
    List<Map<String, dynamic>>? receivedSwapRequests,
    bool? isLoading,
    String? error,
  }) {
    return BooksState(
      books: books ?? this.books,
      sentSwapRequests: sentSwapRequests ?? this.sentSwapRequests,
      receivedSwapRequests: receivedSwapRequests ?? this.receivedSwapRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class BooksNotifier extends StateNotifier<BooksState> {
  final Ref _ref;
  BooksNotifier(this._ref) : super(BooksState());

  Future<void> fetchBooks({String? searchQuery}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      print('Fetching books...');

      final response = await DioClient.dio.get(
        '/api/books/book',
        queryParameters: searchQuery != null ? {'search': searchQuery} : null,
      );

      print('Response received: ${response.data}');

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      final booksData = response.data['Books'];
      if (booksData == null) {
        throw Exception('No books data in response');
      }

      if (booksData is! List) {
        throw Exception('Books data is not a list');
      }

      print('Books data: $booksData');

      final List<Map<String, dynamic>> books =
          booksData.map((book) => Map<String, dynamic>.from(book)).toList();

      state = state.copyWith(books: books, isLoading: false, error: null);
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      print('Response data: ${e.response?.data}');
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to fetch books',
      );
    } catch (e) {
      print('Unexpected error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<void> fetchSwapRequests() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) {
        throw Exception('User not authenticated. Cannot fetch swap requests.');
      }
      final currentUserId = currentUser['_id'];

      final response = await DioClient.dio.get('/api/trades/trade');
      final List<dynamic> allTrades = response.data;

      final List<Map<String, dynamic>> sentRequests =
          allTrades
              .where((trade) => trade['requester']['_id'] == currentUserId)
              .map((request) => Map<String, dynamic>.from(request))
              .toList();

      final List<Map<String, dynamic>> receivedRequests =
          allTrades
              .where((trade) => trade['owner']['_id'] == currentUserId)
              .map((request) => Map<String, dynamic>.from(request))
              .toList();

      state = state.copyWith(
        sentSwapRequests: sentRequests,
        receivedSwapRequests: receivedRequests,
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to fetch swap requests',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
Future<void> handleSwapRequest(String requestId, bool accept) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final endpoint =
          accept
              ? '/api/trades/trade/$requestId/accept'
              : '/api/trades/trade/$requestId/reject';
      await DioClient.dio.put(endpoint);
      await fetchSwapRequests();
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to handle swap request',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> addBook(dynamic bookData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await DioClient.dio.post(
        '/api/books/book',
        data: bookData,
        options: Options(
          contentType:
              bookData is FormData ? 'multipart/form-data' : 'application/json',
        ),
      );
      final newBook = Map<String, dynamic>.from(response.data['book']);
      state = state.copyWith(
        books: [...state.books, newBook],
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to add book',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> updateBook(String bookId, dynamic bookData) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await DioClient.dio.put(
        '/api/books/book/$bookId',
        data: bookData,
        options: Options(
          contentType:
              bookData is FormData ? 'multipart/form-data' : 'application/json',
        ),
      );
      final updatedBook = Map<String, dynamic>.from(
        response.data['updatedBook'],
      );
      state = state.copyWith(
        books:
            state.books.map((book) {
              if (book['_id'] == bookId) {
                return updatedBook;
              }
              return book;
            }).toList(),
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to update book',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> deleteBook(String bookId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await DioClient.dio.delete('/api/books/book/$bookId');
      state = state.copyWith(
        books: state.books.where((book) => book['_id'] != bookId).toList(),
        isLoading: false,
        error: null,
      );
      await fetchUserBooks();
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to delete book',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> requestSwap(String bookId, String message) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await DioClient.dio.post(
        '/api/trades/trade',
        data: {'requestedBookId': bookId, 'notes': message},
      );
      await fetchSwapRequests();
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to request swap',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> fetchUserBooks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final currentUser = _ref.read(authProvider).user;
      if (currentUser == null) {
        throw Exception('User not authenticated. Cannot fetch user books.');
      }
      final response = await DioClient.dio.get('/api/books/mybooks');
      final List<dynamic> booksData = response.data['Books'] ?? [];
      state = state.copyWith(
        books:
            booksData.map((book) => Map<String, dynamic>.from(book)).toList(),
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to fetch user books',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
}

final booksProvider = StateNotifierProvider<BooksNotifier, BooksState>((ref) {
  return BooksNotifier(ref);
});
