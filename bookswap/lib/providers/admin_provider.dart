import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/dio_client.dart';

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  return AdminNotifier();
});

class AdminState {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> books;
  final bool isLoadingUsers;
  final bool isLoadingBooks;
  final String? error;

  const AdminState({
    this.users = const [],
    this.books = const [],
    this.isLoadingUsers = false,
    this.isLoadingBooks = false,
    this.error,
  });

  AdminState copyWith({
    List<Map<String, dynamic>>? users,
    List<Map<String, dynamic>>? books,
    bool? isLoadingUsers,
    bool? isLoadingBooks,
    String? error,
  }) {
    return AdminState(
      users: users ?? this.users,
      books: books ?? this.books,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      isLoadingBooks: isLoadingBooks ?? this.isLoadingBooks,
      error: error,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(const AdminState());

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoadingUsers: true, error: null);

    try {
      print('Fetching users...');
      final response = await DioClient.dio.get(
        '/api/auth/',
        queryParameters: {
          'limit': 100, // Set a high limit to get all users
          'page': 1,
        },
      );
      print('Users response: ${response.data}');

      if (response.data == null) {
        throw Exception('No data received from server');
      }

      final usersData = response.data['users'];
      if (usersData == null) {
        throw Exception('No users data in response');
      }

      if (usersData is! List) {
        throw Exception('Users data is not a list');
      }

      final List<Map<String, dynamic>> users =
          usersData.map((user) => Map<String, dynamic>.from(user)).toList();

      print('Parsed users: $users');

      state = state.copyWith(users: users, isLoadingUsers: false);
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      print('Response status: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      state = state.copyWith(
        isLoadingUsers: false,
        error: e.response?.data?['message'] ?? 'Failed to fetch users',
      );
    } catch (e) {
      print('Unexpected error: $e');
      state = state.copyWith(
        isLoadingUsers: false,
        error: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<void> fetchBooks() async {
    state = state.copyWith(isLoadingBooks: true, error: null);

    try {
      print('Fetching books...');
      final response = await DioClient.dio.get('/api/books/book');
      print('Books response: ${response.data}');

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

      final List<Map<String, dynamic>> books =
          booksData.map((book) => Map<String, dynamic>.from(book)).toList();

      print('Parsed books: $books');

      state = state.copyWith(books: books, isLoadingBooks: false);
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      print('Response status: ${e.response?.statusCode}');
      print('Response data: ${e.response?.data}');
      state = state.copyWith(
        isLoadingBooks: false,
        error: e.response?.data?['message'] ?? 'Failed to fetch books',
      );
    } catch (e) {
      print('Unexpected error: $e');
      state = state.copyWith(
        isLoadingBooks: false,
        error: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await DioClient.dio.delete('/api/auth/$userId');
      await fetchUsers(); // Refresh the list
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['message'] ?? 'Failed to delete user',
      );
    } catch (e) {
      state = state.copyWith(error: 'An unexpected error occurred');
    }
  }

  Future<void> deleteBook(String bookId) async {
    try {
      await DioClient.dio.delete('/api/books/book/$bookId');
      await fetchBooks(); // Refresh the list
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['message'] ?? 'Failed to delete book',
      );
    } catch (e) {
      state = state.copyWith(error: 'An unexpected error occurred');
    }
  }
}