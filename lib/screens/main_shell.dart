import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'dashboard_screen.dart';
import 'beneficiaries/beneficiaries_screen.dart';
import 'inventory/inventory_screen.dart';
import 'distribute/distribute_flow_screen.dart';
import 'more/more_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BeneficiariesScreen(),
    const InventoryScreen(),
    const DistributeFlowScreen(),
    const MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.cardColor, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: AppTheme.backgroundColor,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Beneficiaries'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), label: 'Inventory'),
            BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), label: 'Distribute'),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'More'),
          ],
        ),
      ),
    );
  }
}