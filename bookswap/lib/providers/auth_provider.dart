import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../core/dio_client.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;
  final List<Map<String, dynamic>> users;
  final bool isAdminRegistered;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.user,
    this.users = const [],
    this.isAdminRegistered = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? user,
    List<Map<String, dynamic>>? users,
    bool? isAdminRegistered,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      users: users ?? this.users,
      isAdminRegistered: isAdminRegistered ?? this.isAdminRegistered,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    print(
      'Attempting to load auth token from SharedPreferences...',
    ); // Debug log
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      print('Auth token found in SharedPreferences: $token'); // Debug log
      await _fetchUser();
    } else {
      print('No auth token found in SharedPreferences.'); // Debug log
    }
  }

  Future<void> _fetchUser() async {
    try {
      final response = await DioClient.dio.get('/api/auth/me');
      state = state.copyWith(
        isAuthenticated: true,
        user: response.data['user'],
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await DioClient.clearToken();
        state = state.copyWith(
          isAuthenticated: false,
          user: null,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isAuthenticated: false,
          user: null,
          isLoading: false,
          error: e.response?.data?['message'] ?? 'Failed to fetch user',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticated: false,
        user: null,
        isLoading: false,
        error: 'Failed to fetch user',
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      print('Attempting login with email: $email'); // Debug log
      final response = await DioClient.dio.post(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      print('Login response: ${response.data}'); // Debug log

      final token = response.data['token'];
      if (token == null) {
        throw Exception('No token received from server');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      print('Token saved: $token'); // Debug log

      // Fetch user data after successful login
      await _fetchUser();
      print('Login successful and user fetched.'); // Debug log
    } on DioException catch (e) {
      print('Login error: ${e.message}'); // Debug log
      print('Response status: ${e.response?.statusCode}'); // Debug log
      print('Response data: ${e.response?.data}'); // Debug log
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to login',
      );
    } catch (e) {
      print('Unexpected error during login: $e'); // Debug log
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }
Future<void> signup(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await DioClient.dio.post(
        '/api/auth/register',
        data: {'name': username, 'email': email, 'password': password},
      );

      final token = response.data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      state = state.copyWith(
        isAuthenticated: true,
        user: response.data['user'],
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to signup',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> logout() async {
    try {
      await DioClient.clearToken();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: 'Failed to logout');
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await DioClient.dio.put(
        '/auth/change-password',
        data: {'oldPassword': currentPassword, 'newPassword': newPassword},
      );

      state = state.copyWith(isLoading: false, error: null);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to change password',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await DioClient.dio.delete('/api/auth/me');
      await logout();
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to delete account',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> updateProfile({
    required String username,
    required String email,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await DioClient.dio.put(
        '/auth/me',
        data: {'name': username, 'email': email},
      );

      state = state.copyWith(
        user: response.data['user'],
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to update profile',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<bool> checkAdminStatus() async {
    try {
      final response = await DioClient.dio.get('/api/auth/admin-status');
      final isAdminRegistered = response.data['isAdminRegistered'] as bool;
      state = state.copyWith(isAdminRegistered: isAdminRegistered);
      return isAdminRegistered;
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data?['message'] ?? 'Failed to check admin status',
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(error: 'An unexpected error occurred');
      rethrow;
    }
  }

  Future<void> adminSignup(
    String username,
    String email,
    String password,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await DioClient.dio.post(
        '/api/auth/admin-signup',
        data: {'name': username, 'email': email, 'password': password},
      );
state = state.copyWith(
        isAdminRegistered: true,
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to signup admin',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> adminLogin(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await DioClient.dio.post(
        '/api/auth/admin-login',
        data: {'email': email, 'password': password},
      );

      final token = response.data['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      state = state.copyWith(
        isAuthenticated: true,
        user: response.data['user'],
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to login admin',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> fetchAllUsers() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await DioClient.dio.get('/auth/users');
      final List<dynamic> usersData = response.data;
      state = state.copyWith(
        users:
            usersData.map((user) => Map<String, dynamic>.from(user)).toList(),
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to fetch users',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> deleteUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await DioClient.dio.delete('/auth/users/$userId');
      await fetchAllUsers();
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to delete user',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await DioClient.dio.post(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      );

      await fetchAllUsers();
      state = state.copyWith(isLoading: false, error: null);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to register user',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }
}

class ProfileState {
  final String username;
  final String email;
  final String? profilePic;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.username = 'Loading...',
    this.email = 'Loading...',
    this.profilePic,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    String? username,
    String? email,
    String? profilePic,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      username: username ?? this.username,
      email: email ?? this.email,
      profilePic: profilePic ?? this.profilePic,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;
  ProfileNotifier(this._ref) : super(const ProfileState());

  Future<void> fetchUserProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authState = _ref.read(authProvider);
      if (!authState.isAuthenticated) {
        state = state.copyWith(
          isLoading: false,
          error: 'User not authenticated. Cannot fetch profile.',
        );
        return;
      }

      final response = await DioClient.dio.get('/api/auth/me');

      final userData = response.data['user'];
      state = state.copyWith(
        username: userData['name'] ?? 'N/A',
        email: userData['email'] ?? 'N/A',
        profilePic: userData['profilePic'],
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to load profile',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  Future<void> updateProfile({String? username, String? email}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await DioClient.dio.put(
        '/api/auth/me',
        data: {
          if (username != null) 'name': username,
          if (email != null) 'email': email,
        },
      );
      final updatedUser = response.data['user'];
      state = state.copyWith(
        username: updatedUser['name'] ?? 'N/A',
        email: updatedUser['email'] ?? 'N/A',
        profilePic: updatedUser['profilePic'],
        isLoading: false,
        error: null,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data?['message'] ?? 'Failed to update profile',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier(ref);
});
