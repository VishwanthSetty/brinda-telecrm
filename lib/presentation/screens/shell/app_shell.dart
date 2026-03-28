import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  static const _tabs = [
    (path: '/', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    (path: '/history', icon: Icons.call_outlined, activeIcon: Icons.call, label: 'History'),
    (path: '/settings', icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
    (path: '/uploads', icon: Icons.cloud_upload_outlined, activeIcon: Icons.cloud_upload, label: 'Uploads'),
  ];

  int _locationToIndex(String location) {
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/settings')) return 2;
    if (location.startsWith('/uploads')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => context.go(_tabs[i].path),
          destinations: _tabs
              .map(
                (t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
