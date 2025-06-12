import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5), // Light purple background
      body: Stack(
        children: [
          // Admin Login Icon
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(
                Icons.admin_panel_settings,
                color: Colors.purple,
                size: 30,
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/admin_auth');
              },
            ),
          ),
          // Background Shapes
          Positioned(
            top: -100,
            left: -100,
            child: Image.asset(
              'assets/images/ellipse.png',
              width: 400,
              height: 400,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Image.asset(
              'assets/images/ellipse2.png',
              width: 400,
              height: 400,
              fit: BoxFit.contain,
            ),
          ),

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/icon.png', width: 120, height: 120),
                const SizedBox(height: 24),
                Text(
                  'BookSwap',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Welcome to BookSwap: Exchange your favorite books easily!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Start Swapping',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
