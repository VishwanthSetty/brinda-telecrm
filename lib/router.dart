import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/login/login_screen.dart';
import 'presentation/screens/shell/app_shell.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/call_history/call_history_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/screens/settings/number_list_screen.dart';
import 'presentation/screens/upload_status/upload_status_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authAsync.valueOrNull ?? false;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/history',
            builder: (context, state) => const CallHistoryScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
            routes: [
              GoRoute(
                path: 'numbers',
                builder: (context, state) {
                  final mode = state.uri.queryParameters['mode'] ?? 'whitelist';
                  return NumberListScreen(mode: mode);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/uploads',
            builder: (context, state) => const UploadStatusScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
