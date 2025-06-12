import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookswap/welcome_page.dart';
import 'package:bookswap/home_page.dart';
import 'package:bookswap/login_page.dart';
import 'package:bookswap/signup_page.dart';
import 'package:bookswap/add_books_page.dart';
import 'package:bookswap/profile_page.dart';
import 'package:bookswap/change_password _page.dart';
import 'package:bookswap/edit_profile_page.dart';
import 'package:bookswap/edit_book_page.dart';
import 'package:bookswap/book_detail_page.dart';
import 'package:bookswap/my_swap_request_page.dart';
import 'package:bookswap/my_book_list_page.dart';
import 'package:bookswap/admin_auth_page.dart';
import 'package:bookswap/admin_dashboard_page.dart';
import 'package:bookswap/admin_profile_page.dart';
import 'package:bookswap/add_user_page.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'BookSwap',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          primary: Colors.purple,
          secondary: Colors.deepPurple,
        ),
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.purple,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
        '/home': (context) => const HomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        '/add_book': (context) => const AddBookPage(),
        '/my_book': (context) => const MySwapRequestsPage(),
        '/profile': (context) => const ProfilePage(),
        '/change_password': (context) => const ChangePasswordPage(),
        '/edit_profile': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return EditProfilePage(
            currentUsername: args['currentUsername'],
            currentEmail: args['currentEmail'],
          );
        },
        '/edit_book': (context) {
          final book =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return EditBookPage(book: book);
        },
        '/book_detail': (context) {
          final book =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return BookDetailPage(book: book);
        },
        '/my_swap_requests': (context) => const MySwapRequestsPage(),
        '/my_book_list': (context) => const MyBookListPage(),
        '/admin_auth': (context) => const AdminAuthPage(),
        '/admin_dashboard': (context) => const AdminDashboardPage(),
        '/admin_profile': (context) => const AdminProfilePage(),
        '/add_user': (context) => const AddUserPage(),
      },
    );
  }
}
