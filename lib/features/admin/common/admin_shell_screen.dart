import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';

class AdminShellScreen extends StatelessWidget {
  final String location;
  final Widget child;

  const AdminShellScreen({
    super.key,
    required this.location,
    required this.child,
  });

  int get _selectedIndex {
    if (location.startsWith('/admin/bookings')) {
      return 1;
    }

    if (location.startsWith('/admin/items')) {
      return 2;
    }

    if (location.startsWith('/admin/profile')) {
      return 3;
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
        context.go('/admin/items');
        break;
      case 3:
        context.go('/admin/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: AppColors.white,
              indicatorColor: AppColors.primary,
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
                states,
              ) {
                final isSelected = states.contains(WidgetState.selected);

                return TextStyle(
                  color: isSelected ? AppColors.black : AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
                states,
              ) {
                final isSelected = states.contains(WidgetState.selected);

                return IconThemeData(
                  color: isSelected ? AppColors.black : AppColors.textSecondary,
                  size: 24,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              height: 72,
              elevation: 0,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              onDestinationSelected: (index) {
                _onDestinationSelected(context, index);
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Sewa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2_rounded),
                  label: 'Barang',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
