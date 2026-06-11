import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

class AdminShellScreen extends StatelessWidget {
  final Widget child;
  final String location;

  const AdminShellScreen({
    super.key,
    required this.child,
    required this.location,
  });

  int get _selectedIndex {
    if (location.startsWith('/admin/bookings')) {
      return 1;
    }

    if (location.startsWith('/admin/verifications/identity')) {
      return 2;
    }

    if (location.startsWith('/admin/verifications/condition')) {
      return 3;
    }

    if (location.startsWith('/admin/items')) {
      return 4;
    }

    return 0;
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/admin/dashboard');
        break;
      case 1:
        context.go('/admin/bookings');
        break;
      case 2:
        context.go('/admin/verifications/identity');
        break;
      case 3:
        context.go('/admin/verifications/condition');
        break;
      case 4:
        context.go('/admin/items');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primary.withOpacity(0.35),
        onDestinationSelected: (index) {
          _onDestinationSelected(context, index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Booking',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user_rounded),
            label: 'KTP',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Kondisi',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_other_outlined),
            selectedIcon: Icon(Icons.devices_other_rounded),
            label: 'Barang',
          ),
        ],
      ),
    );
  }
}
