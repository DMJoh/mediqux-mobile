import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, required this.location, super.key});

  final Widget child;
  final String location;

  int _selectedIndex() {
    if (location.startsWith('/patients')) {
      return 1;
    }
    if (location.startsWith('/appointments')) {
      return 2;
    }
    if (location.startsWith('/records') ||
        location.startsWith('/lab-reports') ||
        location.startsWith('/diagnostic-studies') ||
        location.startsWith('/prescriptions')) {
      return 3;
    }
    if (location.startsWith('/more') ||
        location.startsWith('/doctors') ||
        location.startsWith('/institutions') ||
        location.startsWith('/conditions') ||
        location.startsWith('/medications')) {
      return 4;
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
        bottomNavigationBar: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                context.go('/');
              case 1:
                context.go('/patients');
              case 2:
                context.go('/appointments');
              case 3:
                context.go('/records');
              case 4:
                context.go('/more');
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline_rounded),
              selectedIcon: Icon(Icons.people_rounded),
              label: 'Patients',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month_rounded),
              label: 'Schedule',
            ),
            NavigationDestination(
              icon: Icon(Icons.science_outlined),
              selectedIcon: Icon(Icons.science_rounded),
              label: 'Records',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'More',
            ),
          ],
        ),
      ),
    );
  }
}
