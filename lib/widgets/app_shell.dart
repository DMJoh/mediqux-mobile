import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mediqux_mobile/widgets/floating_nav_bar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  static const _items = [
    NavBarItem(icon: Icons.home_outlined, label: 'Home'),
    NavBarItem(icon: Icons.people_outline_rounded, label: 'Patients'),
    NavBarItem(icon: Icons.science_outlined, label: 'Records'),
    NavBarItem(icon: Icons.grid_view_outlined, label: 'More'),
  ];

  int _selectedIndex() {
    if (location.startsWith('/patients')) {
      return 1;
    }
    if (location.startsWith('/records') ||
        location.startsWith('/lab-reports') ||
        location.startsWith('/diagnostic-studies') ||
        location.startsWith('/prescriptions')) {
      return 2;
    }
    if (location.startsWith('/more') ||
        location.startsWith('/appointments') ||
        location.startsWith('/doctors') ||
        location.startsWith('/institutions') ||
        location.startsWith('/conditions') ||
        location.startsWith('/medications')) {
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _selectedIndex();

    return PopScope(
      // Only allow the OS back to exit when on the Home tab root.
      // On any other tab root, intercept and navigate home instead.
      canPop: idx == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: Scaffold(
        body: child,
        bottomNavigationBar: FloatingNavBar(
          items: _items,
          selectedIndex: idx,
          onSelected: (i) {
            switch (i) {
              case 0:
                context.go('/');
              case 1:
                context.go('/patients');
              case 2:
                context.go('/records');
              case 3:
                context.go('/more');
            }
          },
        ),
      ),
    );
  }
}
