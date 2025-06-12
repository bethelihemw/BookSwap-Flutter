import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static Dio? _dio;
  static const String baseUrl = 'http://10.0.2.2:4000';

  static Dio get dio {
    _dio ??= Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio!.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('Auth token set: Bearer $token'); // Debug log
          } else {
            print('No auth token found'); // Debug log
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          print('Dio error: ${e.message}'); // Debug log
          print('Response status: ${e.response?.statusCode}'); // Debug log
          print('Response data: ${e.response?.data}'); // Debug log
          if (e.response?.statusCode == 401) {
            // Clear token and user data on unauthorized error
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            _dio?.options.headers.remove('Authorization');
          }
          return handler.next(e);
        },
      ),
    );

    return _dio!;
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _dio?.options.headers.remove('Authorization');
  }
}
